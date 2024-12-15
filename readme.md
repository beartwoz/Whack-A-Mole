# **Whack-A-Mole FPGA Game**

## **Overview**
This project implements a **Whack-A-Mole** game on an FPGA using VHDL. The game features:
1. A **4x4 grid** rendered on a VGA display.
2. Random mole activation using a **pseudo-random number generator (PRNG)**.
3. User input through a **4x4 keypad**, where each key corresponds to a mole.
4. A scoring system displayed on a **7-segment display**.

The project highlights VGA rendering, PRNG logic, real-time input handling, and integration of multiple VHDL components into a functional game.

## **Current State**
- The VGA grid and mole activation logic are functional.
- The keypad successfully maps inputs to holes.
- However, the mole updates are delayed and only occur when the key press timing aligns with the game clock.

---

## **Features**

### **1. VGA Display**
- Renders a 4x4 grid of holes.
- Active holes (moles) are displayed in **red**, while inactive holes remain **black**.
- Implemented using `ball.vhd` and `vga_top.vhd`.

### **2. Mole Activation Logic**
- A **pseudo-random number generator (PRNG)** activates one random hole at a time.
- PRNG is implemented using a Linear Feedback Shift Register (LFSR).

### **3. Keypad Input Mapping**
- A **4x4 keypad** is used for user input.
- Each key corresponds to one mole, mapped as follows:

| Keypad Key | Mole Index |
|------------|------------|
| 0          | 12         |
| 1          | 0          |
| 2          | 1          |
| 3          | 2          |
| 4          | 4          |
| 5          | 5          |
| 6          | 6          |
| 7          | 8          |
| 8          | 9          |
| 9          | 10         |
| A          | 3          |
| B          | 7          |
| C          | 11         |
| D          | 15         |
| E          | 14         |
| F          | 13         |

### **4. Scoring System**
- A score counter increments when the correct key is pressed for the active mole.
- Score is displayed on a **7-segment display** using the `leddec16.vhd` module.

### **How to Run**

1. Open the project in Vivado.
2. Add all VHDL files and the constraints file (`vga_top_moles.xdc`).
3. Synthesize, implement, and generate the bitstream.
4. Upload the bitstream to the FPGA board.

### **Connections**

| Peripheral         | FPGA Pins                      |
|--------------------|--------------------------------|
| VGA Display        | Defined in `vga_top_moles.xdc` |
| 4x4 Keypad         | Columns: 4 pins, Rows: 4 pins  |
| 7-Segment Display  | Defined in `leddec16.vhd`      |

---

### **Known Issues**

- The moles update only when the keypad input timing aligns with the game clock, causing delayed responses.
- Debouncing logic needs refinement for immediate input detection.

---

### **Future Improvements**

1. **Real-Time Input Detection:** Use a faster clock or state machine to handle keypad inputs more efficiently.
2. **Optimized Timing:** Synchronize mole updates and user input handling with a dedicated fast clock.
3. **Enhanced Display:** Add visual effects for hits or misses.

---

### **Contributors**

- **Chris Bertuzzi**
- **Simon Garcia**

---


