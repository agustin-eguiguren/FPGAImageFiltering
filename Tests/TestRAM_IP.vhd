library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ram_check_tb is
end entity;

architecture tb of ram_check_tb is
    signal clk50 : std_logic := '0';
    signal addr  : std_logic_vector(15 downto 0) := (others=>'0');
    signal q_a   : std_logic_vector(7 downto 0);
    
    component RAM_IP is
	port
	(
		address_a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
    end component;

begin
    -- instantiate the generated RAM_IP
    uut: component RAM_IP
        port map (
            address_a => addr,
            address_b => (others=>'0'),
            clock_a   => clk50,
            clock_b   => clk50,
            data_a    => (others=>'0'),
            data_b    => (others=>'0'),
            wren_a    => '0',
            wren_b    => '0',
            q_a       => q_a,
            q_b       => open
        );

    -- 50 MHz clock
    clk_proc: process
    begin
        wait for 10 ns;
        clk50 <= not clk50;
    end process;

    stimulus: process
    begin
        wait for 50 ns;
        for i in 0 to 31 loop
            addr <= std_logic_vector(to_unsigned(i,16));
            wait until rising_edge(clk50);
            wait until rising_edge(clk50); 
            report "addr=" & integer'image(i) & " q_a=" & integer'image(to_integer(unsigned(q_a)));
        end loop;
        wait;
    end process;
end architecture;