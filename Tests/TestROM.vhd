library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestROM is
end TestROM;

architecture test of TestROM is
	component FILTER_KERNELS is
    port (
        CLK, en: in std_logic;
        address: in std_logic_vector(5 downto 0);
        data: out std_logic_vector(7 downto 0)
    );
    end component;

	
	signal CLK, en: std_logic := '0';
    signal addr: std_logic_vector(5 downto 0);
    signal data: std_logic_vector(7 downto 0);

begin

    rom: FILTER_KERNELS port map(CLK, en, addr, data);

    CLK <= not CLK after 50 ns;

    process
    begin
        en <= '1';
        -- check 0
        addr <= (others => '0');

        wait until rising_edge(CLK)   
        wait for 10 ns;

        -- assert 1
        assert (signed(data) = to_signed(1, 8));
                report "Error at " & integer'image(to_integer(unsigned(addr)))
                severity failure;
        
        wait for 10 ns;

        -- check 4
        addr <= "000100";

        wait until rising_edge(CLK)   
        wait for 10 ns;

        -- assert 4
        assert (signed(data) = to_signed(4, 8));
                report "Error at " & integer'image(to_integer(unsigned(addr)))
                severity failure;
        
        wait for 10 ns;

        -- check 19
        addr <= "010011";

        wait until rising_edge(CLK)   
        wait for 10 ns;

        -- assert -1
        assert (signed(data) = to_signed(-1, 8));
                report "Error at " & integer'image(to_integer(unsigned(addr)))
                severity failure;
        
        wait for 10 ns;

        -- check 27
        addr <= "011011";

        wait until rising_edge(CLK)   
        wait for 10 ns;

        -- assert -1
        assert (signed(data) = to_signed(-1, 8));
                report "Error at " & integer'image(to_integer(unsigned(addr)))
                severity failure;
        
        wait for 10 ns;

        -- check 35
        addr <= "100011";

        wait until rising_edge(CLK)   
        wait for 10 ns;

        -- assert 1
        assert (signed(data) = to_signed(1, 8));
                report "Error at " & integer'image(to_integer(unsigned(addr)))
                severity failure;
        
        wait for 10 ns;

        -- if no problems are encountered
        report "Tests: OK";
    end process;
end test;