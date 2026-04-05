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
        ram_out_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        ram_in_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        ram_out_en: std_logic;
        rom_addr: out std_logic_vector(5 downto 0);
        rom_r_en: out std_logic;
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
    --- the external edges of the images are never touched
    --- so both RAMs should be loaded in with the original image
    signal addr_Input, addr_Filter : std_logic_vector(15 downto 0);
    signal rom_base_addr: std_logic_vector(5 downto 0);
    signal rom_Input_addr: std_logic_vector(5 downto 0);

    signal rom_en, ram_w_en : std_logic;

    --MAC signals
    -- 17 downto 0 because of DSP block size and signed number representations
    signal mac_in1, mac_in2: std_logic_vector(17 downto 0);
    signal mac_out: std_logic_vector(17 downto 0);
    signal mac_en, mac_init : std_logic;


begin
    component MAC is
    port (
        CLK, en, init: in std_logic;
        data_1, data_2: in std_logic_vector(17 downto 0);
        data_out: out std_logic_vector(17 downto 0)
    );
    end component;
    
    MAC : MAC port map(CLK, mac_en, mac_in1, mac_in2, mac_out);

    process(CLK)
    begin
        if(CLK'event and CLK = '1') then
            current_state <= next_state;
        end if;
    end process;

    process(CLK, current_state)
    begin 
        rom_en <= '0';
        ram_w_en <= '0';
        init_mac <= '0';
        mac_en <= '0';

        if(current_state = START) then
            if (filter_en = '1') then
                -- skip the first row and col to avoid edges
                row <= 1;
                col <= 1;
                pos <= 0;
                
                -- defines what kernel is used
                case filter_sel is
                    when "00" => rom_base_addr <= (others => '0');
                    when "01" => rom_base_addr <= "001001";
                    when "10" => rom_base_addr <= "010010";
                    when "11" => rom_base_addr <= "011011";
                end case;

                next_state <= READ;
            end if;

        else if (current_state = READ) then
            --- set read and write addresses 

            rom_Input_addr <= pos + rom_base_addr;
            
            -- considering center pixel, move to 8 neighbour pixels
            case pos is
                when 0 => addr_Input <= (row - 1)*(IMG_WIDTH) + col - 1
                when 1 => addr_Input <= (row - 1)*(IMG_WIDTH) + col
                when 2 => addr_Input <= (row - 1)*(IMG_WIDTH) + col + 1
                when 3 => addr_Input <= row*(IMG_WIDTH) + col - 1 
                when 4 => addr_Input <= row*(IMG_WIDTH) + col
                when 5 => addr_Input <= row*(IMG_WIDTH) + col + 1
                when 6 => addr_Input <= (row + 1)*(IMG_WIDTH) + col - 1 
                when 7 => addr_Input <= (row + 1)*(IMG_WIDTH) + col
                when 8 => addr_Input <= (row + 1)*(IMG_WIDTH) + col + 1
            
            mac_in1 <= (others => '0');
            mac_in2 <= (others => '0');

            addr_Filter <= row*(IMG_WIDTH) + col;

            next_state <= OP;

        else if (current_state = OP) then
            rom_en <= "1";
            
            mac_in1 <= std_logic_vector( to_signed( to_integer( signed(rom_in)), 17));
            mac_in2 <= std_logic_vector( to_signed( to_integer( signed(ram_in)), 17));

            if(pos = 8) then
                pos <= 0;
                next_state <= WRITE;
            else if (pos = 0) then
                init_mac <= '1';
            else 
                init_mac <= '0';
                pos <= pos + 1;
            end if;
        
        else if (current_state = WRITE) then
            ram_w_en <= '1';

            -- capping data for write
            -- if result is smaller than 0
            if(data_out_mac(17) = '1') then
                data_out <= (others => '0');
            -- result is bigger than 255
            else if (signed(data_out_mac) > 255) then
                data_out <= (others => '1');
            else
                if (rom_base_addr = (others => '0')) then
                    data_out_mac <= shift_right(unsigned(data_out_mac), 4);
                else if (rom_base_addr = "001001") then
                    data_out_mac <= shift_right(unsigned(data_out_mac), 3);
                end if;

                data_out <= data_out_mac(7 downto 0);
            
            -- col and row should not reach the image's edges
            -- width = IMG_WIDTH -1
            -- edge-1 = width-1
            -- max(col) = (edge-1)-1
            if (col = (IMG_WIDTH-3)) then
                col <= 0;
                
                if (row = (IMG_HEIGHT-3)) then
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

            if (filter_en = '1') then
                row <= 0;
                col <= 0;
                pos <= 0;
                
                -- defines what kernel is used
                case filter_sel is
                    when "00" => rom_base_addr <= (others => '0');
                    when "01" => rom_base_addr <= "001001";
                    when "10" => rom_base_addr <= "010010";
                    when "11" => rom_base_addr <= "011011";
                end case;

                next_state <= READ;
            end if;
        
        else
            next_state <= START;
        end if;

        ram_out_addr <= addr_Filter;
        ram_in_addr <= addr_Input;
        rom_add <= rom_Input_addr;
        rom_r_en <= rom_en;
        ram_out_en <= ram_w_en;

    end process;
end arch;