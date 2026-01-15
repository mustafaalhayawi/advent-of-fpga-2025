open! Core
open Hardcaml
open Signal

module Logic = struct
  module I = struct
    type 'a t = {
      clk : 'a;
      clear : 'a;
      enable : 'a;
      direction: 'a; (* 0 for left, 1 for right *)
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
    let _ = inputs.clk in
    { O.ans = of_int_trunc ~width:64 0;
      cur = of_int_trunc ~width:7 0;
    }
end
