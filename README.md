# Advent of FPGA 2025 Submission
This is my solution to [Day 1](https://adventofcode.com/2025/day/1), Part 2 of the 2025 Advent of Code in Hardcaml.
## 1. Approach
I implemented a circular buffer in Hardcaml by using a 7-bit position register and a 64-bit answer accumulator. To keep the design synthesisable and resource-efficient I implemented division and modulus by 100 with a fixed-point reciprocal multiplier ($\frac{41}{2^{12}}\approx0.01$) to calculate the number of laps completed and the remainder to update the answer and current positions. This ensured the design is fully combinational between registers which allows it to process one full rotation (e.g. "R46") per clock cycle. I also utilised the `Hardcaml.Always` DSL for sequential state updates while keeping the complex arithemtic within the combinational scope.
## 2. How to run
### Prerequisites
Ensure you have the OCaml toolchain and the necessary libraries installed via opam:
```bash
opam install core hardcaml
```
### Running the simulation
Run the following commands to build and execute the simulation
```bash
dune build
dune exec bin/main.exe
```
## 3. Verification
The provided testbench reads from input.txt, applies the stimulus to the Hardcaml simulation model, and compares the final `ans` register against the expected puzzle output (7199).
### Successful output:
```
final answer: 7199                
test status: passed
```
## 4. Circuit interface
| Port | Width | Description |
| -------- | ------- | -------- |
| `clk` | 1 | Clock |
| `clear` | 1 | Synchronous reset |
| `enable` | 1 | Active high signal to process a command |
| `direction` | 1 | 1 for left, 0 for right |
| `n_steps` | 12 | Number of steps to move |
| `ans` (out) | 64 | The cumulative answer |
| `cur` (out) | 7 | The current position (0-99 inclusive)