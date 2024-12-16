# CPE 487 Digital System Design Final Project: Whack-a-Mole
## Expected Behavior
<img src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fcdn.thisiswhyimbroke.com%2Fimages%2Fwhac-a-mole-arcade-game-640x532.jpg" width="400"><img src="https://i0.wp.com/photos.smugmug.com/Other/Blog/i-LptRcKW/0/O/whack%20a%20mole.gif?resize=320%2C180&ssl=1">

The goal of this project is to mimic the classic arcade game "Whac-a-Mole". Different holes in the grass light up in yellow when a mole pops out of the hole. The holes are arranged in a grid that correspond to a 4x4 Keypad. The player should be able to hit the button on the keypad that corresponds to the lit up hole to earn points. That hole then deactivates and another hole activates. If the hole goes a duration of time without getting "hit", it deactivates and the game ends. The duration of time that a hole stays lit gets shorter and shorter the longer the player plays the game.

![Flow chart showing game's loop](https://i.ibb.co/nPd711H/Screenshot-2024-12-16-004100.png)

## Necessary Hardware
- Nexys A7-100T FPGA Board
- Computer with Vivado installed
- Micro-USB cable to power Nexys A7-100T FPGA Board and connect it to computer
- VGA Cable
- Monitor with VGA port
- 4x4 Keypad

## Program Setup
1. Pull or download this repository onto the computer with Vivado installed
2. Connect the Nexys A7-100T board to the computer using the Micro-USB cable
3. Connect the VGA cable to the Nexys A7-100T board and the VGA monitor
4. Connect the keypad to the Nexys A7-100T board, ensuring it's not upside down
5. Open Vivado and create a new RTL Project
6. On the "Add Sources" page, click on "Add Files" and add all of the .vhd files from this repository 
7. On the "Add Constraints" page, click on "Add Files" and add all of the .xdc files from this repository
8. On the "Default Part" page, click on the "Boards" tab and find and select the "Nexys A7-100T" option
9. Click "Finish" in the New Project Setup window
10. In the "Flow Navigator" sidebar, click on Generate Bitstream under the Program and Debug tab
11. It will start Synthesis and Implementation, and will notify you when it's ready
12. Open the Hardware Manager
13. Select "Open Target" then "Autoconnect"
14. Select "Program device" then select the Nexys A7-100T it shows
15. Program should show up on the VGA monitor
    

![Alt Text](https://i.ibb.co/hCZn07C/gif-02.gif)

## Inputs and Outputs

*x_pos, y_pos* integer inputs in ball_moles.vhd determine the X and Y coordinate of each hole's top left corner.

*active* STD_LOGIC input in ball_moles.vhd determines the active state of the hole

*KB_col* STD_LOGIC_VECTOR output in vga_top_holes.vhd determines the keypad column pins

*KB_row* STD_LOGIC_VECTOR input in vga_top_holes.vhd determines the keypad row pins

*SEG7_anode* STD_LOGIC_VECTOR output in vga_top_holes.vhd sends to 7-segment anode outputs

*SEG7_seg* STD_LOGIC_VECTOR output in vga_top_holes.vhd sends to 7-segment segment outputs

## Modules
- ball_moles.vhd - houses the process for drawing the holes and the colors of the holes depending on whether they're active or not.
- clk_wiz_0 and clk_wiz_0_clk_wiz - Template clocks from lab 6 that are unmodified, used to control the clock
- keypad.vhd - template from hexcalculator that is used to determine which key was pressed and send that signal to vga_top_holes.vhd
- leddec16.vhd - template for 7-segment display used to show score on the board
- master.xdc - contraints file used to determine the pins
- vga_sync.vhd - template for the vga display timing
- vga_top_holes.vhd - connects the whole project together by comparing the keypad input to the current active hole

## Modifications
This project originally uses code from Lab 3, the bouncing ball lab, and Lab 4, the hexidecimal calculator lab.

## 4x4 Hole Grid

### ball.vhd from Lab 3
This vhdl file was adapted to draw the 16 "holes" in the 4x4 grid instead of the moving ball. The following describes the changes:

Added **x_pos** and **y_pos** generics for positioning each hole:

```
GENERIC (
  x_pos : INTEGER := 0;  -- X position
  y_pos : INTEGER := 0   -- Y position
);
```


Added an **active state** signal to render red (active hole) or black (inactive hole)

```
PROCESS (pixel_row, pixel_col, active)
BEGIN
    IF (pixel_col >= x_pos AND pixel_col < x_pos + hole_width) AND 
       (pixel_row >= y_pos AND pixel_row < y_pos + hole_height) THEN
        IF active = '1' THEN
            red_out <= '1';
            green_out <= '0';
            blue_out <= '0';
        ELSE
            red_out <= '0';
            green_out <= '0';
            blue_out <= '0';
        END IF;
    ELSE
        red_out <= '0';
        green_out <= '0';
        blue_out <= '0';
    END IF;
END PROCESS;
```

### vga_top.vhd from Lab 3
Repurposed to instantiate and position 16 holes on the VGA display

Added the **active_holes** signal to track active and inactive states for 16 holes

`SIGNAL active_holes : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');`

Used a **GENERATE loop** to produce 16 instances of ball with dynamic positioning

```
gen_moles : FOR i IN 0 TO 3 GENERATE
    FOR j IN 0 TO 3 GENERATE
        ball_inst : ball
            GENERIC MAP (
                x_pos => 150 + (i * 150),  -- Horizontal spacing
                y_pos => 50 + (j * 150)    -- Vertical spacing
            )
            PORT MAP (
                pixel_row => S_pixel_row,
                pixel_col => S_pixel_col,
                active    => active_holes(i * 4 + j),
                red_out   => S_red(i * 4 + j),
                green_out => S_green(i * 4 + j),
                blue_out  => S_blue(i * 4 + j)
            );
    END GENERATE;
END GENERATE;
```

## Mole Appearance Logic

### vga_top.vhd from Lab 3
Repurposed to introduce pseudo-random mole activation with a timer

Added a **4-bit LFSR** for random mole selection

```
  PROCESS (pxl_clk)
BEGIN
    IF rising_edge(pxl_clk) THEN
        lfsr <= lfsr(2 DOWNTO 0) & (lfsr(3) XOR lfsr(2));
    END IF;
END PROCESS;

random_index <= TO_INTEGER(unsigned(lfsr)) MOD 16; -- Map to 0-15
```

Used a **clock divider** to control mole activation frequency

```
PROCESS (pxl_clk)
BEGIN
    IF rising_edge(pxl_clk) THEN
        IF cnt = 10 THEN
            cnt <= 0;
            active_holes <= (OTHERS => '0');
            active_holes(random_index) <= '1'; -- Activate the selected mole
        ELSE
            cnt <= cnt + 1;
        END IF;
    END IF;
END PROCESS;
```

## Map Keypad Inputs to Holes

### vga_top.vhd from Lab 3
Repurposed to implement whacking logic and scoring based on the keypad's input

Added **kp_value_store** to store the keypad inputs

`SIGNAL kp_value_store : STD_LOGIC_VECTOR(3 DOWNTO 0);`

Compared the **keypad value** to the active mole
```
PROCESS (cnt)
BEGIN
    IF rising_edge(cnt(10)) THEN
        IF kp_hit = '1' THEN
            kp_value_store <= kp_value;

            -- Compare keypad input to active mole
            IF kp_value_store = hole_to_keypad_map(to_integer(unsigned(current_mole))) THEN
                score <= score + 1;            -- Increment score
                active_holes <= (OTHERS => '0'); -- Deactivate current mole
                active_holes(random_index) <= '1'; -- Activate new mole
            END IF;
        END IF;
    END IF;
END PROCESS;
```

## Scoring System
### vga_top.vhd from Lab 3
Repurposed to display the score on the 7-segment display

Added the **score signal** 
```
PROCESS (score)
BEGIN
    seg7_data(3 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(score MOD 10, 4));
    seg7_data(7 DOWNTO 4) <= STD_LOGIC_VECTOR(TO_UNSIGNED((score / 10) MOD 10, 4));
    seg7_data(11 DOWNTO 8) <= STD_LOGIC_VECTOR(TO_UNSIGNED((score / 100) MOD 10, 4));
    seg7_data(15 DOWNTO 12) <= "0000";
END PROCESS;
```

Instantiated the **leddec16 module**
```
led_driver : leddec16
    PORT MAP (
        dig   => led_mpx,
        data  => seg7_data,
        anode => SEG7_anode,
        seg   => SEG7_seg
    );
```
## Clocks
### Final vga_top.vhd integration
Everything that we had done so far was now combined: the mole activation logic, keypad detection, scoring updates, and the score display. The timing had to be updated.

Created a faster clock for **timing control**

`game_clk <= cnt(10); -- Faster clock bit for smooth updates`

Made sure to get quick response when **debouncing**

```
IF kp_hit = '1' THEN
    debounce_counter := debounce_counter + 1;
    IF debounce_counter = debounce_threshold THEN
        kp_hit_debounced <= '1';
    END IF;
END IF;
```

![Alt text](https://i.ibb.co/djMmDSQ/gif-03.gif)

## Conclusion
Chris was responsible for integrating components together, hole drawing logic, and keypad logic. Simon was responsible for hole activation logic and helping debug other parts of the project. A few difficulties were encountered throughout the duration of the project: 

- The game clock (made from cnt) doesn't run in time to the keypad inputs. This means that there are delayed responses because the mole updates only happen when the clock edge and key press align. Future improvements should include a dedicated fast clock for keypad input processing so that key presses are detected immediately and a response comes from the game immediately.
- Combining the hole activation logic, the keypad logic, and the score updating logic together made it difficult to get them to work together. Timing issues could be fixed if a unified fast clock was used.

