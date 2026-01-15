open! Core
open Hardcaml

module Logic = struct
  module I = struct
    type 'a t = {
      clk : 'a;
      clear : 'a;
      enable : 'a;
      direction: 'a; (* 1 for left, 0 for right *)
      n_steps: 'a; [@bits 12] (* the number of steps to move in a direction *)
    } [@@deriving sexp_of, hardcaml]
  end

  module O = struct
    type 'a t = {
      ans : 'a; [@bits 64] (* the answer so far *)
      cur : 'a; [@bits 7] (* the current distance *)
    } [@@deriving sexp_of, hardcaml]
  end

  let create (inputs : _ I.t) = 
    let open Signal in
    let spec = Reg_spec.create ~clock:inputs.clk ~clear:inputs.clear () in

    let ans = Always.Variable.reg spec ~width:64 in
    let cur = Always.Variable.reg spec ~width:7 ~clear_to:(of_int_trunc ~width:7 50) in

    (* the distance to 0 depending on the direction being left or right *)
    let distance_to_0 = mux2 inputs.direction
      (mux2 (cur.value >: of_int_trunc ~width:7 0) (uresize cur.value ~width:12) (of_int_trunc ~width:12 100))
      (of_int_trunc ~width:12 100 -: uresize cur.value ~width:12)
    in

    let extra_steps = uresize inputs.n_steps ~width:12 -: distance_to_0 in
    (* integer divide extra_steps by 100 to obtain the number of extra laps*)
    let extra_laps =
      let prod = uresize extra_steps ~width:24 *: of_int_trunc ~width:24 41 in
      select prod ~high:23 ~low:12
    in

    (* calculate the current position by adding/subtracting number of steps depending on direction *)
    let total = 
      let cur_12 = uresize cur.value ~width:12 in
      let steps_12 = uresize inputs.n_steps ~width:12 in
      mux2 inputs.direction
        (cur_12 +: (of_int_trunc ~width:12 1000 -: steps_12))
        (cur_12 +: steps_12) 
    in

    (* perform modulo 100 on the current position*)
    let quotient = 
      let prod = uresize total ~width:24 *: of_int_trunc ~width:24 41 in
      select prod ~high:23 ~low:12
    in
    let remainder = total -: sel_bottom (quotient *: of_int_trunc ~width:12 100) ~width:12 in

    Always.(compile [
      if_ inputs.enable [
        (* checks if the number of steps is enough to reach 0 if so add the number of laps completed to ans *)
        if_ (uresize inputs.n_steps ~width:12 >=: distance_to_0) [
          ans <-- (ans.value +: (of_int_trunc ~width:64 1 +: uresize extra_laps ~width:64))
        ] [];

        cur <-- sel_bottom remainder ~width:7
      ] []
    ]);

    { O.ans = ans.value;
      cur = cur.value;
    }
end
