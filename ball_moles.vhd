LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ball IS
    PORT (
        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0); -- Current row on VGA
        pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0); -- Current column on VGA
        active    : IN STD_LOGIC; -- Active state of the hole
        x_pos     : IN INTEGER; -- X-coordinate of the hole's top-left corner
        y_pos     : IN INTEGER; -- Y-coordinate of the hole's top-left corner
        red       : OUT STD_LOGIC; -- Red color output
        green     : OUT STD_LOGIC; -- Green color output
        blue      : OUT STD_LOGIC -- Blue color output
    );
END ball;

ARCHITECTURE Behavioral OF ball IS
    CONSTANT hole_width  : INTEGER := 50; -- Width of each hole
    CONSTANT hole_height : INTEGER := 50; -- Height of each hole
BEGIN
    PROCESS (pixel_row, pixel_col)
    BEGIN
        -- Convert pixel_row and pixel_col from STD_LOGIC_VECTOR to INTEGER
        IF (TO_INTEGER(UNSIGNED(pixel_col)) >= x_pos AND 
            TO_INTEGER(UNSIGNED(pixel_col)) < x_pos + hole_width AND
            TO_INTEGER(UNSIGNED(pixel_row)) >= y_pos AND 
            TO_INTEGER(UNSIGNED(pixel_row)) < y_pos + hole_height) THEN
            
            IF active = '1' THEN
                red <= '1'; -- Hole is active (red)
                green <= '0';
                blue <= '0';
            ELSE
                red <= '0'; -- Hole is inactive (black)
                green <= '0';
                blue <= '1';
            END IF;
        ELSE
            red <= '0'; -- Outside the hole area (background color)
            green <= '1'; -- Green background
            blue <= '0';
        END IF;
    END PROCESS;
END Behavioral;
