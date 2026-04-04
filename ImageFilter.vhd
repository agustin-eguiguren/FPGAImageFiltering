library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--- GAUSSIAN BLUR KERNEL = [[1 2 1],[2 4 2],[1 2 1]]*1/16 (shift right by 4)
--- BLUR = [[1 1 1],[1 0 1],[1 1 1]]*1/8
--- Sharpening = [[0 -1 0],[-1 5 -1],[0 -1 0]]
--- Horizontal Edge = [[-1 -1 -1],[0 0 0],[1 1 1]]
entity ImageFilter is
    generic (
        IMG_HEIGHT: INTEGER := 480;
        IMG_WIDTH: INTEGER := 640;
        RAM_ADDR_SIZE: INTEGER := 20; -- 2^20 = 1048576 > 921600 = (307200)*3 = (640*480)*3
    );
    port (
        CLK, filter_en: in std_logic;
        ram_in: in std_logic_vector(7 downto 0);
        rom_in: in std_logic_vector(7 downto 0);
        filter_sel: in std_logic_vector(1 downto 0);
        ram_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        rom_addr: out std_logic_vector(5 downto 0);
        data_out: out std_logic_vector(7 downto 0);
        READY: out std_logic
    );
end entity ImageFilter;

architecture arch of ImageFilter is
    -- reads image pixels from RAM, multiplies them and adds them to kernel, and writes result to other RAM
    type states is (START, READ, OP, WRITE, DISPLAY);

    signal current_state: states := START;
    signal next_state: states;

    -- signal definitions

    -- define row and column to start at 1, skipping the first row and column to avoid overflow
    signal row, col : integer := 1;
    signal pos : integer := 0;
    
    --- addr_Input and addr_Filter are used for RAMs
    --- should be the same 
    --- the external edges of the images are never touched
    --- so both RAMs should be loaded in with the original image
    signal addr_Input, addr_Filter : std_logic_vector(15 downto 0);
    signal rom_base_addr: std_logic_vector(5 downto 0);

    --MAC signals
    -- 17 downto 0 because of DSP block size and signed number representations
    signal mac_in1, mac_in2: std_logic_vector(17 downto 0);
    signal mac_out: std_logic_vector(17 downto 0);

    -- component definitions

    -- MAC component
    -- ROW and COL counters

begin
    process(CLK)
    begin
        if(CLK'event and CLK = '1') then
            current_state <= next_state;
        end if;
    end process;

    process
    begin
        if(current_state = START) then
            if (filter_en = '1') then
                row <= 0;
                col <= 0;
                pos <= 0;
                
                case filter_sel is
                    when "00" => rom_base_addr <= (others => '0');
                    when "01" => rom_base_addr <= "001001";
                    when "10" => rom_base_addr <= "010010";
                    when "11" => rom_base_addr <= "011011";
                end case;

                next_state <= READ;
            end if;
        else if (current_state = READ) then
            --- bring value from rom and ram

            next_state <= OP;

        else if (current_state = OP) then
            if(pos = 8) then
                pos <= 0;
                next_state <= WRITE;
            else
                pos <= pos + 1;
            end if;
        else if (current_state = WRITE) then
            if (col = (IMG_WIDTH-2)) then
                col <= 0;
                
                if (row = (IMG_HEIGHT-2)) then
                    row <= 0;
                    next_state <= DISPLAY;
                else
                    row <= row + 1;
                end if;
            else 
                col <= col + 1;
            end if;
        else if (current_state = DISPLAY) then
            READY <= '1';
        else
            next_state <= START;
        end if;
    end process;
end arch;