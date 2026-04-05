library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestFilter is
end TestFilter;

architecture test of TestFilter is
    component ImageFilter is
    generic (
        IMG_HEIGHT: INTEGER;
        IMG_WIDTH: INTEGER;
        RAM_ADDR_SIZE: INTEGER
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
        READY: out std_logic
    );
    end component;

	
	signal CLK, en, ready: std_logic := '0';
    signal test_ram_in, test_rom_in: std_logic_vector(7 downto 0);
    signal test_sel: std_logic_vector(1 downto 0);
    signal test_ram_addr: std_logic_vector(3 downto 0); -- create smallest image (3x3) so 9 possible addresses
    signal test_rom_addr: std_logic_vector(5 downto 0);
    signal test_rom_en: std_logic;
    signal test_ram_en: std_logic;
    signal data: std_logic_vector(7 downto 0);

begin

    F1: ImageFilter generic map(IMG_HEIGHT=>9, IMG_WIDTH=>9, RAM_ADDR_SIZE=>4) port map(CLK, en, test_ram_in, test_rom_in, test_sel, test_ram_addr, test_ram_addr, test_ram_en, test_rom_addr, test_rom_en, data, ready);

    CLK <= not CLK after 50 ns;

    process
        variable addr_int : integer;
    begin
        en <= '1';
        test_sel <= "00";
        
        -- until done
        while ready = '0' loop
            wait until rising_edge(CLK);
            
            test_ram_in <= test_ram_addr;            
            test_rom_in <= test_rom_addr;
            
            wait for 10 ns; 
        end loop;

        -- loop sums i*i from 0 to 8 
        assert (signed(data) = to_signed(204, 18));
                report "Error: expected Data out = 204 but received: " & integer'image(to_integer(unsigned(data)))
                severity failure;
    
        -- if no problems are encountered
        report "Tests: OK";
        wait;
    end process;
end test;