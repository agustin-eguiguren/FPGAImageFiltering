library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


-- GAUSSIAN BLUR KERNEL = [[1 2 1],[2 4 2],[1 2 1]]*1/16 (shift right by 4)
-- BLUR = [[1 1 1],[1 0 1],[1 1 1]]*1/8
-- Sharpening = [[0 -1 0],[-1 5 -1],[0 -1 0]]
-- Horizontal Edge = [[-1 -1 -1],[0 0 0],[1 1 1]]
entity ImageFilter is
    generic (
        IMG_HEIGHT: INTEGER := 480;
        IMG_WIDTH: INTEGER := 640;
        RAM_ADDR_SIZE: INTEGER := 20 -- 2^20 = 1048576 > 921600 = (307200)*3 = (640*480)*3
    );
    port (
        CLK, filter_en: in std_logic;
        ram_in: in std_logic_vector(7 downto 0);
        rom_in: in std_logic_vector(7 downto 0);
        filter_sel: in std_logic_vector(1 downto 0);
        ram_out_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        ram_in_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        ram_out_en: out std_logic;
        rom_addr: out std_logic_vector(5 downto 0);
        rom_r_en: out std_logic;
        data_out: out std_logic_vector(7 downto 0);
        READY: out std_logic;
        FilterLED: out std_logic_vector(9 downto 0)
    );
end entity ImageFilter;


architecture arch of ImageFilter is
    -- reads image pixels from RAM, multiplies them and adds them to kernel, and writes result to other RAM
    type states is (START, READ, INFO_WAIT, OP, WRITE, DISPLAY);

    signal current_state: states := START;
    signal next_state: states;


    -- filter constants 
    constant GAUSS_BLUR: integer := 0;
    constant AVG_BLUR: integer := 9;
    constant SHARP_FILTER: integer := 18;
    constant EDGE_FILTER: integer := 27;

    constant GAUSS_SHIFT: integer := 4; -- divide by 16
    constant AVG_SHIFT: integer := 3; -- divide by 8

    constant KERNEL_SIZE: integer := 9; -- 3x3 kernel
    
    -- signal definitions

    -- define row and column to start at 1, skipping the first row and column to avoid overflow
    signal row, col, next_row, next_col : integer := 1;
    signal pos, next_pos : integer := 0;

    -- addr_Input and addr_Filter are used for RAMs
    -- the external edges of the images are never touched
    -- so both RAMs should be loaded in with the original image
    signal addr_Input, addr_Filter : std_logic_vector(RAM_ADDR_SIZE-1 downto 0);
    
    signal rom_Input_addr: std_logic_vector(5 downto 0);

    signal rom_en, ram_w_en : std_logic;

    --MAC signals
    -- 17 downto 0 because of DSP block size and signed number representations
    signal mac_in1, mac_in2: std_logic_vector(17 downto 0);
    signal mac_out, result: std_logic_vector(17 downto 0);
    signal mac_en, mac_init : std_logic;

    component MAC is
    port (
        CLK, en, init: in std_logic;
        data_1, data_2: in std_logic_vector(17 downto 0);
        data_out: out std_logic_vector(17 downto 0)
    );
    end component;

begin
    
    M1 : MAC port map(CLK, mac_en, mac_init, mac_in1, mac_in2, mac_out);

    process(CLK)
    begin
        if(CLK'event and CLK = '1') then
            current_state <= next_state;
            row <= next_row;
            col <= next_col;
            pos <= next_pos; 
        end if;
    end process;


    process(current_state, filter_en, filter_sel, pos, row, col, rom_in, ram_in, mac_out, result, addr_Filter, addr_Input, rom_Input_addr, rom_en, ram_w_en, next_row, next_col, next_pos)
            variable rom_base_addr: integer;
    begin 
        -- default values
        rom_en <= '0';
        ram_w_en <= '0';
        mac_init <= '0';
        mac_en <= '0';
        READY <= '0'; 
        next_state <= current_state;
        next_row <= row;
        next_col <= col;
        next_pos <= pos;

        -- defaulting data out to 0 when not writing
        data_out  <= (others => '0');

        FilterLED <= (others => '0');
        
        -- considering center pixel, move to 8 neighbour pixels        
        case pos is
        when 0 => addr_Input <= std_logic_vector(to_unsigned(((row-1)*IMG_WIDTH + (col-1)), RAM_ADDR_SIZE));
        when 1 => addr_Input <= std_logic_vector(to_unsigned(((row-1)*IMG_WIDTH + col), RAM_ADDR_SIZE));
        when 2 => addr_Input <= std_logic_vector(to_unsigned(((row-1)*IMG_WIDTH + (col+1)), RAM_ADDR_SIZE));
        when 3 => addr_Input <= std_logic_vector(to_unsigned((row*IMG_WIDTH + (col-1)), RAM_ADDR_SIZE));
        when 4 => addr_Input <= std_logic_vector(to_unsigned((row*IMG_WIDTH + col), RAM_ADDR_SIZE));
        when 5 => addr_Input <= std_logic_vector(to_unsigned((row*IMG_WIDTH + (col+1)), RAM_ADDR_SIZE));
        when 6 => addr_Input <= std_logic_vector(to_unsigned(((row+1)*IMG_WIDTH + (col-1)), RAM_ADDR_SIZE));
        when 7 => addr_Input <= std_logic_vector(to_unsigned(((row+1)*IMG_WIDTH + col), RAM_ADDR_SIZE));
        when others => addr_Input <= std_logic_vector(to_unsigned(((row+1)*IMG_WIDTH + (col+1)), RAM_ADDR_SIZE));
        end case;
        
        addr_Filter <= std_logic_vector(to_unsigned((row*IMG_WIDTH + col), RAM_ADDR_SIZE));

        case current_state is
        
            when START =>
                if (filter_en = '1') then
                    -- skip the first row and col to avoid edges
                    next_row <= 1;
                    next_col <= 1;
                    next_pos <= 0;
                    
                    -- defines what kernel is used
                    case filter_sel is
                        when "00" => rom_base_addr := GAUSS_BLUR;
                        when "01" => rom_base_addr := AVG_BLUR;
                        when "10" => rom_base_addr := SHARP_FILTER;
                        when "11" => rom_base_addr := EDGE_FILTER;
                    end case;

                    next_state <= READ;
                end if;

                FilterLED(9) <= '1';

            when READ =>
                -- set read and write addresses 

                rom_Input_addr <= std_logic_vector( to_unsigned((pos + rom_base_addr),6));
                
                mac_in1 <= (others => '0');
                mac_in2 <= (others => '0');

                
                next_state <= INFO_WAIT;

                FilterLED(8) <= '1'; 

            when INFO_WAIT =>
                rom_en <= '1';

                -- this state is used to wait for RAM and ROM because of latency
                next_state <= OP;

            when OP =>
                rom_en <= '1';
                mac_en <= '1';
                
                -- we are using 8-bit output from ROM and RAM for 18 bit input for MAC
                mac_in1 <= std_logic_vector( resize( signed(rom_in), mac_in1'length));
                mac_in2 <= std_logic_vector( resize( unsigned(ram_in), mac_in1'length));

                if(pos = 8) then
                    next_pos <= 0;
                    next_state <= WRITE;
                elsif (pos = 0) then
                    mac_init <= '1';
                    next_pos <= pos + 1;
                    next_state <= READ;
                else 
                    mac_init <= '0';
                    next_pos <= pos + 1;
                    next_state <= READ;
                end if;
                
                FilterLED(7) <= '1';
            
            when WRITE =>
                ram_w_en <= '1';

                -- capping data for write
                -- if result is smaller than 0
                if(mac_out(17) = '1') then
                    data_out <= (others => '0');
                -- result is bigger than 255
                elsif (to_integer(signed(mac_out)) > 255) then
                    data_out <= (others => '1');
                else
                    if (rom_base_addr = GAUSS_BLUR) then
                        data_out <= std_logic_vector(shift_right(unsigned(mac_out), GAUSS_SHIFT))(7 downto 0);
                    elsif (rom_base_addr = AVG_BLUR) then
                        data_out <= std_logic_vector(shift_right(unsigned(mac_out), AVG_SHIFT))(7 downto 0);
                    else
                        data_out <= mac_out(7 downto 0);
                    end if;

                end if;

                -- col and row should not reach the image's edges
                -- width = IMG_WIDTH -1
                -- edge-1 = width-1
                -- max(col) = (edge-1)-1
                if (col = (IMG_WIDTH-3)) then
                    next_col <= 1;
                    
                    if (row = (IMG_HEIGHT-3)) then
                        next_row <= 1;
                        next_state <= DISPLAY;
                    else
                        next_row <= row + 1;
                        next_state <= READ;
                    end if;
                else 
                    next_col <= col + 1;
                    next_state <= READ;
                end if;
                
                FilterLED(6) <= '1';
            
            when DISPLAY =>
                READY <= '1';

                if (filter_en = '1') then
                    next_row <= 1;
                    next_col <= 1;
                    next_pos <= 0;
                    
                    -- defines what kernel is used
                    case filter_sel is
                        when "00" => rom_base_addr := GAUSS_BLUR;
                        when "01" => rom_base_addr := AVG_BLUR;
                        when "10" => rom_base_addr := SHARP_FILTER;
                        when "11" => rom_base_addr := EDGE_FILTER;
                    end case;

                    next_state <= READ;
                end if;

                FilterLED(5) <= '1';
            
            when others =>
                next_state <= START;
        
        end case;

        ram_out_addr <= addr_Filter;
        ram_in_addr <= addr_Input;
        rom_addr <= rom_Input_addr;
        rom_r_en <= rom_en;
        ram_out_en <= ram_w_en;

    end process;
end arch;