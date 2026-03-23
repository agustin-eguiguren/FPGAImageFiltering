library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestROM is
end TestROM;

architecture test of TestROM is
    component ImageFilter is
    generic (
        IMG_HEIGHT: INTEGER;
        IMG_WIDTH: INTEGER;
        RAM_ADDR_SIZE: INTEGER;
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
    end component;

	
	signal CLK, en, ready: std_logic := '0';
    signal ram_in, rom_in: std_logic_vector(7 downto 0);
    signal sel: std_logic_vector(1 downto 0);
    signal ram_addr: std_logic_vector(3 downto 0); -- create smallest image (3x3) so 9 possible addresses
    signal rom_addr: std_logic_vector(5 downto 0);
    signal data: std_logic_vector(7 downto 0);

begin

    filter: ImageFilter generic map(IMG_HEIGHT=>9, IMG_WIDTH=>9, RAM_ADDR_SIZE=>4)port map(CLK, en, ram_in, rom_in, sel, ram_addr, rom_addr, data, ready);

    CLK <= not CLK after 50 ns;

    process
        variable addr_int : integer;
    begin
        en <= '1';
        sel <= "00";
        
        -- until done
        while ready = '0' loop
            wait until rising_edge(CLK);
            
            r_in <= r_addr;            
            k_in <= rom_addr;
            
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