library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestRAM is
end TestRAM;

architecture test of TestRAM is
	component RAM is
    generic(
        ADDR_SPACE: INTEGER
    );
    port (
        CLK, we1, we2: in std_logic;
        data_in1: in std_logic_vector(7 downto 0);
        data_in2: in std_logic_vector(7 downto 0);
        address1: in std_logic_vector((ADDR_SPACE-1) downto 0);
        address2: in std_logic_vector((ADDR_SPACE-1) downto 0);
        data_out1: out std_logic_vector(7 downto 0);
        data_out2: out std_logic_vector(7 downto 0)
    );
    end component;
	
	signal CLK, w1, w2: std_logic := '0';
	signal in1, in2: std_logic_vector(7 downto 0);
    signal addr1, addr2: std_logic_vector(1 downto 0); --testing with 4B RAM
	signal out1, out2: std_logic_vector(7 downto 0);

begin

    ram: RAM generic map(2) port map(CLK, w1, w2, in1, in2, addr1, addr2, out1, out2);

    CLK <= not CLK after 50 ns;

    process
    begin
        w1 <= '1';
        w2 <= '0';

        for i in 0 to 3 loop
            wait until rising_edge(CLK)
            -- alternate between input ports
            w1 <= not w1;
            w2 <= not w2;
            
            -- cycle through all memory addresses and store their index
            addr1 <= std_logic_vector(to_unsigned(i, 2));
            in1 <= std_logic_vector(to_unsigned(i, 8));

            addr2 <= std_logic_vector(to_unsigned(i, 2));
            in2 <= std_logic_vector(to_unsigned(i, 8));
        end loop;

        w1 <= '0';
        w2 <= '0';

        for i in 0 to 3 loop
            addr1 <= std_logic_vector(to_unsigned(i, 2));
            addr2 <= std_logic_vector(to_unsigned(i, 2));
            wait until rising_edge(CLK)   
            
            wait for 10 ns;

            assert (out1 = std_logic_vector(to_unsigned(i, 8)));
                report "Error at " & integer'image(i)
                severity failure;
            assert (out2 = std_logic_vector(to_unsigned(i, 8)));
                report "Error at " & integer'image(i)
                severity failure;
        end loop;

        report "Tests: OK";

        wait;
    end process;
end test;