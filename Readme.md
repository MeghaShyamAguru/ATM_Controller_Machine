# ATM Controller FSM (Verilog)

This repository contains the Verilog HDL implementation of a Finite State Machine (FSM) modeling a comprehensive ATM controller. Designed as part of the EE-210 Digital Circuits curriculum at the Indian Institute of Technology Guwahati, this project successfully handles user authentication, dynamic cash dispensing, PIN management, and error handling.

## Features

* **Cash Withdrawal:** Validates account balance, checks ATM cash availability, and dynamically displays available denominations (Rs. 100, Rs. 500, Rs. 2000) based on current bin levels.
* **PIN Management:** Supports New PIN setup for fresh cards and PIN reset for existing cards via external OTP verification.
* **Security Lock-out:** Implements a strict mechanism that tracks incorrect entries and blocks the card after three wrong PIN attempts.
* **User Inquiries:** Includes standard menu options for Balance Inquiry and Mini Statement generation.
* **Global Cancel:** Allows users to press the cancel button at any stage to safely abort the active transaction and eject the card immediately.

---

## FSM Architecture

The controller is built using a synchronous state machine, with sequential logic updating the current state and tracking PIN attempts on every positive clock edge. The combinational block evaluates the next-state logic, where a global cancel condition holds the absolute highest priority.

* **Total States:** The FSM transitions cleanly between 24 distinct states, ranging from `IDLE` and `PIN_ENTRY` to `DENOMINATION_SELECT`, `CANCELLED`, and `ERROR`.
* **State Encoding:** A 5-bit register tracks the current FSM state, supporting up to 32 states for full operational flow monitoring.
* **Error Handling:** If resources are short (e.g., insufficient ATM cash) or invalid inputs are detected, the system safely routes to an `ERROR` state and triggers card ejection.

---

## Testbench & Simulation

The included testbench (`atm_tb.v`) simulates a 10 ns clock period and validates the controller by exercising eight distinct real-world scenarios. 

* **Scenario 1:** Complete cash withdrawal sequence with denomination display.
* **Scenario 2:** New PIN setup utilizing account verification and OTP.
* **Scenario 3:** Existing PIN reset flow.
* **Scenario 4:** Balance inquiry execution.
* **Scenario 5:** Mini statement printing.
* **Scenario 6:** Mid-operation cancellation.
* **Scenario 7:** Complete card block after three consecutive wrong PINs.
* **Scenario 8:** Transaction failure and error path due to an empty ATM cash bin.

---

## Hardware Synthesis & Performance

The FSM was synthesized and analyzed for the ZedBoard (XC7Z020-CLG484) FPGA device, producing highly efficient logic utilization and timing results.

| Metric | Reported Value | Utilization / Detail |
| :--- | :--- | :--- |
| **Slice LUTs** | 42 | 0.08% utilization, used purely for combinational logic |
| **Slice Registers** | 7 | <0.01% utilization, implemented as synchronous flip-flops |
| **Total Power** | 4.942 W | Dynamic: 4.636 W, Static: 0.306 W |
| **Critical Path Delay** | 8.301 ns | Represents the longest combinational delay between input and output |
| **Max Frequency (fmax)** | ~120.4 MHz | Design meets all constraints with no timing violations |
| **Latency** | 1 clock cycle | State transitions process per rising clock edge |

---

## Usage & Simulation

1. Clone this repository to your local machine.
2. Import `atm.v` and `atm_tb.v` into your preferred design suite (e.g., Vivado).
3. Run the behavioral simulation.
4. Observe the `state_out` bus and control signals (`dispense_cash`, `eject_card`, etc.) in the waveform viewer to verify the synchronous FSM transitions alongside the input stimuli.