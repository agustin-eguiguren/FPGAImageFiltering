library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FPGA_Filter_Test is
end entity FPGA_Filter_Test;

archiecture testbench of FPGA_Filter_Test is
	component Main_FPGA_Filter is 
	port (clk : in std_logic;
			start : in std_logic;
			filter_select : in std_logic;
			reset : in std_logic;
			VGA_R : out std_logic_vector(7 downto 0);
			VGA_G : out std_logic_vector(7 downto 0);
			VGA_B : out std_logic_vector(7 downto 0);
			VGA_HS : out std_logic;
			VGA_VS : out std_logic;
			VGA_blank : out std_logic;
			done : out std_logic);
			
	end component Main_FPGA_Filter;
	
	signal clk_tb : std_logic := '0';
	signal start_tb : std_logic := '0';
	signal filter_select_tb : std_logic := '0';
	signal reset_tb : std_logic := '1';
	signal VGA_R_tb : std_logic_vector(7 downto 0);
	signal VGA_G_tb : std_logic_vector(7 downto 0);
	signal VGA_B_tb : std_logic_vector(7 downto 0);
	signal VGA_HS_tb : std_logic;
	signal VGA_VS_tb : std_logic;
	signal VGA_blank_tb : std_logic;
	signal done_tb : std_logic;
	
	constant clk_period : time := 20ns;
	
begin
		t1: Main_FPGA_Filter port map (
											clk => clk_tb,
											start => start_tb,
											filter_select => filter_select_tb,
											reset => reset_tb,
											VGA_R => VGA_R_tb,
											VGA_G => VGA_G_tb,
											VGA_B => VGA_B_tb,
											VGA_HS => VGA_HS_tb,
											VGA_VS => VGA_VS_tb,
											VGA_blank => VGA_blank_tb,
											done => done_tb);
											
		clk_tb <= not clk_tb after clk_period/2;
		
		stim_proc : process
		begin
			reset_tb <= '0';
			wait for 100 ns;
			
			assert (VGA_blank_tb = '0') 
            report "vga blanked during reset" 
            severity note;
			
			reset_tb <= '1';
			wait until rising_edge(clk_tb);
			
			start_tb <= '1';
			filter_select_tb <= '0';
			
			wait until done_tb = '1';
			wait until rising_edge(clk_tb);
			
			assert (VGA_R_tb = x"(expected value)") 
            report "error: filter X R output incorrect" 
            severity failure;
			
			assert (VGA_G_tb = x"(expected value)") 
            report "error: filter X G output incorrect" 
            severity failure;
				
			assert (VGA_B_tb = x"(expected value)") 
            report "error: filter X B output incorrect" 
            severity failure;
			
			start_tb <= '0'
			
			wait for 100 ns;
			
			start_tb <= '1';
			filter_select_tb <= '1';
			
			wait until done_tb = '1';
			wait until rising_edge(clk_tb);
			
			assert (VGA_R_tb = x"(expected value)") 
            report "error: filter X R output incorrect" 
            severity failure;
			
			assert (VGA_G_tb = x"(expected value") 
            report "error: filter X G output incorrect" 
            severity failure;
				
			assert (VGA_B_tb = x"(expected value)") 
            report "error: filter X B output incorrect" 
            severity failure;
			
			start_tb <= '0';
			
			report "successful simulation" severity note;
			
		wait;
		
	end process;
end architecture;
		
