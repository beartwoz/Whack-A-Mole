LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY vga_top IS
    PORT (
        clk_in    : IN STD_LOGIC;
        vga_red   : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
        vga_green : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
        vga_blue  : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        vga_hsync : OUT STD_LOGIC;
        vga_vsync : OUT STD_LOGIC;
        KB_col : OUT STD_LOGIC_VECTOR (4 DOWNTO 1); -- keypad column pins
        KB_row : IN STD_LOGIC_VECTOR (4 DOWNTO 1);
        SEG7_anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- 7-segment anode outputs
        SEG7_seg   : OUT STD_LOGIC_VECTOR (0 TO 6)  -- 7-segment segment outputs
    );
END vga_top;

ARCHITECTURE Behavioral OF vga_top IS
    -- VGA Signals
    SIGNAL pxl_clk : STD_LOGIC;
    SIGNAL S_red, S_green, S_blue : STD_LOGIC_VECTOR (15 DOWNTO 0);
    SIGNAL combined_red, combined_green, combined_blue : STD_LOGIC;
    SIGNAL S_pixel_row, S_pixel_col : STD_LOGIC_VECTOR (10 DOWNTO 0);
    
    -- Mole Signals
    SIGNAL active_holes : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0'); -- Active mole holes
    SIGNAL current_mole : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"0"; -- Current active mole in hexadecimal
    
    -- Keypad Signals
    SIGNAL kp_hit : STD_LOGIC; -- Indicates if a keypad button was pressed
    SIGNAL kp_value : STD_LOGIC_VECTOR (3 DOWNTO 0); -- Hexadecimal value of the pressed keypad button
    SIGNAL kp_value_store : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0'); -- Stores the last pressed keypad value
    
    -- Clock Signals
    SIGNAL btn_clk : STD_LOGIC; -- Button clock
    SIGNAL kp_clk : STD_LOGIC; -- Faster clock for the keypad process
    SIGNAL game_clk : STD_LOGIC; -- Slower clock for mole activation
    SIGNAL cnt : STD_LOGIC_VECTOR(30 DOWNTO 0); -- Counter for generating clocks
    
    -- Score and Display Signals
    SIGNAL score : INTEGER RANGE 0 TO 999 := 0; -- Current score
    SIGNAL seg7_data : STD_LOGIC_VECTOR (15 DOWNTO 0); -- Score in BCD format for the 7-segment display
    SIGNAL led_mpx : STD_LOGIC_VECTOR (2 DOWNTO 0); -- Multiplexing control for 7-segment display
    
    -- Miscellaneous Signals
    SIGNAL random_index : INTEGER RANGE 0 TO 15; -- Randomly chosen mole index
    SIGNAL game_on : STD_LOGIC := '1'; -- Indicates if the game is active
    SIGNAL btnc : STD_LOGIC; -- Button control signal
    SIGNAL speed_bit : INTEGER RANGE 10 TO 26 := 26; -- Clock bit controlling the mole activation speed
    
    -- RNG (Random Number Generator) Variables
    SIGNAL lfsr : STD_LOGIC_VECTOR (3 DOWNTO 0) := "1001"; -- Linear feedback shift register for RNG
    SIGNAL rng_counter : INTEGER RANGE 0 TO 80000000 := 0; -- RNG counter
    SIGNAL rng_limit : INTEGER RANGE 100000 TO 80000000 := 80000000; -- Initial RNG limit
    
    TYPE integer_array IS ARRAY (0 TO 1) OF INTEGER;
    TYPE position_array IS ARRAY (0 TO 15) OF integer_array;
    TYPE keypad_map_type IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(3 DOWNTO 0);

    CONSTANT hole_positions : position_array := (
        (150, 50), (300, 50), (450, 50), (600, 50),  -- Row 1
        (150, 200), (300, 200), (450, 200), (600, 200),  -- Row 2
        (150, 350), (300, 350), (450, 350), (600, 350),  -- Row 3
        (150, 500), (300, 500), (450, 500), (600, 500)   -- Row 4
    );

    CONSTANT hole_to_keypad_map : keypad_map_type := (
        "0001", -- Hole 0 → 1
        "0010", -- Hole 1 → 2
        "0011", -- Hole 2 → 3
        "1010", -- Hole 3 → A
        "0100", -- Hole 4 → 4
        "0101", -- Hole 5 → 5
        "0110", -- Hole 6 → 6
        "1011", -- Hole 7 → B
        "0111", -- Hole 8 → 7
        "1000", -- Hole 9 → 8
        "1001", -- Hole 10 → 9
        "1100", -- Hole 11 → C
        "0000", -- Hole 12 → 0
        "1111", -- Hole 13 → F
        "1110", -- Hole 14 → E
        "1101"  -- Hole 15 → D
    );

    COMPONENT keypad IS
        PORT (
            samp_ck : IN STD_LOGIC;
            col     : OUT STD_LOGIC_VECTOR (4 DOWNTO 1);
            row     : IN STD_LOGIC_VECTOR (4 DOWNTO 1);
            value   : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
            hit     : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT vga_sync IS
        PORT (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC;
            green_in  : IN STD_LOGIC;
            blue_in   : IN STD_LOGIC;
            red_out   : OUT STD_LOGIC;
            green_out : OUT STD_LOGIC;
            blue_out  : OUT STD_LOGIC;
            hsync     : OUT STD_LOGIC;
            vsync     : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT clk_wiz_0 IS
        PORT (
            clk_in1  : IN STD_LOGIC;
            clk_out1 : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT leddec16 IS
        PORT (
            dig   : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- Multiplexing digit selector
            data  : IN STD_LOGIC_VECTOR (15 DOWNTO 0); -- 16-bit data to display
            anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- Active anode control
            seg   : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)  -- Segment control
        );
    END COMPONENT;

    COMPONENT ball IS
        PORT (
            pixel_row : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
            active    : IN STD_LOGIC;
            x_pos     : IN INTEGER;
            y_pos     : IN INTEGER;
            red       : OUT STD_LOGIC;
            green     : OUT STD_LOGIC;
            blue      : OUT STD_LOGIC
        );
    END COMPONENT;

    FUNCTION or_reduce(signal_vector : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
        VARIABLE result : STD_LOGIC := '0';
    BEGIN
        FOR i IN signal_vector'RANGE LOOP
            result := result OR signal_vector(i);
        END LOOP;
        RETURN result;
    END FUNCTION;
    

BEGIN
    -- VGA synchronization
    vga_driver : vga_sync
        PORT MAP (
            pixel_clk => pxl_clk,
            red_in    => combined_red,
            green_in  => combined_green,
            blue_in   => combined_blue,
            red_out   => vga_red(2),
            green_out => vga_green(2),
            blue_out  => vga_blue(1),
            pixel_row => S_pixel_row,
            pixel_col => S_pixel_col,
            hsync     => vga_hsync,
            vsync     => vga_vsync
        );

    -- Clock wizard
    clk_wiz_0_inst : clk_wiz_0
        PORT MAP (
            clk_in1 => clk_in,
            clk_out1 => pxl_clk
        );

    -- Keypad integration
    keypad_inst : keypad
        PORT MAP (
            samp_ck => game_clk, -- Use the derived keypad clock
            col => KB_col,
            row => KB_row,
            value => kp_value,
            hit => kp_hit
        );
        
        
--    game_on_control_proc: PROCESS (btn_clk, kp_hit)
--    BEGIN
--        IF rising_edge(btn_clk) THEN
--            -- Toggle game_on when the button is pressed
--            IF btnc = '1' THEN
--                game_on <= NOT game_on;
--            END IF;
--        ELSIF kp_hit = '1' THEN
--            -- End the game on incorrect hit
--            IF TO_INTEGER(unsigned(kp_value)) /= current_mole THEN
--                game_on <= '0';
--            END IF;
--        END IF;
--    END PROCESS;

 
        ck_proc : PROCESS (pxl_clk)
        BEGIN
            IF rising_edge(pxl_clk) THEN -- on rising edge of clock
                cnt <= cnt + 1; -- increment counter
            END IF;
        END PROCESS;
    
    
        game_clk <= cnt(25);
        -- Derive button clock
        btn_clk <= cnt(25); 
  
        
    hole_and_keypad_logic_proc: PROCESS (cnt)
        VARIABLE rng_seed : INTEGER := 42; -- Seed for random number generation
        VARIABLE random_index : INTEGER := 0; -- Random value holder
        CONSTANT kp_clk_bit : INTEGER := 10; -- Fast clock bit for updating
        VARIABLE debounce_counter : INTEGER RANGE 0 TO 10 := 0; -- Debounce counter
        VARIABLE kp_hit_debounced : STD_LOGIC := '0'; -- Debounced key press signal
    BEGIN
        IF rising_edge(cnt(kp_clk_bit)) THEN
            -- Ensure at least one hole is active at the start of the game
            IF active_holes = (15 DOWNTO 0 => '0') THEN
                -- Initialize the first active mole
                rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768; -- Initialize RNG
                random_index := rng_seed MOD 16; -- Generate a random mole
                active_holes <= (15 DOWNTO 0 => '0'); -- Deactivate all holes
                active_holes(random_index) <= '1'; -- Activate the random mole
                current_mole <= std_logic_vector(to_unsigned(random_index, 4)); -- Set the current mole in hex
            END IF;
    
            -- Debounce Keypad Input
            IF kp_hit = '1' THEN
                IF debounce_counter < 3 THEN -- Small debounce threshold
                    debounce_counter := debounce_counter + 1;
                ELSE
                    kp_hit_debounced := '1'; -- Confirm key press
                    kp_value_store <= kp_value; -- Store the pressed keypad value
                END IF;
            ELSE
                debounce_counter := 0;
                kp_hit_debounced := '0';
            END IF;
    
            -- Handle Keypad Input and Mole Matching
            IF kp_hit_debounced = '1' THEN
                -- Check if keypad input matches the current mole
                IF kp_value_store = hole_to_keypad_map(to_integer(unsigned(current_mole))) THEN
                    -- Correct match found
                    score <= score + 1; -- Increment score
                    active_holes <= (15 DOWNTO 0 => '0'); -- Deactivate current hole
    
                    -- Generate and Activate a New Mole
                    rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768; -- Update RNG
                    random_index := rng_seed MOD 16; -- Choose new mole
                    active_holes(random_index) <= '1'; -- Activate new mole
                    current_mole <= std_logic_vector(to_unsigned(random_index, 4)); -- Update current mole in hex
                END IF;
            END IF;
    
            -- Update 7-segment display with the score
            seg7_data(3 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(score MOD 10, 4)); -- Units place
            seg7_data(7 DOWNTO 4) <= STD_LOGIC_VECTOR(TO_UNSIGNED((score / 10) MOD 10, 4)); -- Tens place
            seg7_data(11 DOWNTO 8) <= STD_LOGIC_VECTOR(TO_UNSIGNED((score / 100) MOD 10, 4)); -- Hundreds place
            seg7_data(15 DOWNTO 12) <= "0000"; -- Thousands place (unused for scores < 1000)
        END IF;
    END PROCESS;

        

        
    -- Instantiate mole holes using `ball`
    gen_moles: FOR i IN 0 TO 15 GENERATE
        ball_inst : ball
            PORT MAP (
                pixel_row => S_pixel_row,
                pixel_col => S_pixel_col,
                active    => active_holes(i),
                x_pos     => hole_positions(i)(0),
                y_pos     => hole_positions(i)(1),
                red       => S_red(i),
                green     => S_green(i),
                blue      => S_blue(i)
            );
    END GENERATE;

    -- Combine signals for VGA
    combined_red <= or_reduce(S_red);
    combined_green <= or_reduce(S_green);
    combined_blue <= or_reduce(S_blue);

    -- Instantiate 7-segment display driver
    led_driver : leddec16
        PORT MAP (
            dig => led_mpx,
            data => seg7_data,
            anode => SEG7_anode,
            seg => SEG7_seg
        );
END Behavioral;
