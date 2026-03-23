library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TestMAC is
end TestMAC;

architecture test of TestMAC is
	component MAC is
    port (
        CLK, en, init: in std_logic;
        data_1, data_2: in std_logic_vector(17 downto 0);
        data_out: out std_logic_vector(17 downto 0)
    );
    end component;
	
	signal CLK, en, init: std_logic := '0';
	signal in1, in2: std_logic_vector(17 downto 0);
    signal data: std_logic_vector(17 downto 0);
    variable tmp, prod: integer := 0;

begin

    mac: MAC port map(CLK, en, init, in1, in2, data);

    CLK <= not CLK after 100 ns;

    process
    begin
        en <= '1';
        init <= '1';
        
        in1 <= (others => '0');
        in2 <= (others => '0');            
        
        wait until rising_edge(CLK)   
            
        wait for 10 ns;

        assert (data = std_logic_vector(to_signed(0, 18)));
            report "Error at init"
            severity failure;
        
        init <= '0';
        for i in 1 to 255 loop
            prod := i * (128 - i);
            tmp := tmp + prod;

            in1 <= std_logic_vector(to_signed(i, 18));
            in2 <= std_logic_vector(to_signed((128-i), 18));
                
            wait until rising_edge(CLK)   
                
            wait for 10 ns;

            assert (to_integer(signed(data)) = tmp);
                report "Error at " & integer'image(i) & " Expected value: " & integer'image(tmp) & " but received: " & integer'image(to_integer(signed(data)))
                severity failure;
        end loop;

        report "Tests: OK";

        wait;
    end process;
end test;