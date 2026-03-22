library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--- GAUSSIAN BLUR KERNEL = [[1 2 1],[2 4 2],[1 2 1]]*1/16 (shift right by 4)
--- BLUR = [[1 1 1],[1 1 1],[1 1 1]]
--- Sharpening = [[0 -1 0],[-1 5 -1],[0 -1 0]]
--- Horizontal Edge = [[-1 -1 -1],[0 0 0],[1 1 1]]
entity ImageFilter is
    generic (
        IMG_HEIGHT: INTEGER := 480;
        IMG_WIDTH: INTEGER := 640;
        RAM_ADDR_SIZE: INTEGER := 20 -- 2^20 = 1048576 > 921600 = (307200)*3 = (640*480)*3
        ROM_ADDR_SIZE: INTEGER := 2 -- 4 possible filters
    );
    port (
        CLK, filter_en: in std_logic;
        ram_in: in std_logic_vector(7 downto 0);
        rom_in: in std_logic_vector(7 downto 0);
        ram_addr: out std_logic_vector(3 downto 0);
        rom_addr: out std_logic_vector(9 downto 0);
        data_out: out std_logic(7 downto 0);
        READY: out std_logic
    );
end entity ImageFilter;

architecture arch of ImageFilter is
    -- reads image pixels from RAM, multiplies them and adds them to kernel, and writes result to other RAM


    -- signal definitions
    signal row, col : integer := 0;
    signal pos : integer := 0;
    signal addr_Input, addr_Filter : std_logic_vector(15 downto 0);

    -- component definitions

    -- MAC component
    -- ROW and COL counters

begin


end arch;