library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_Controller_Test is
end entity VGA_Controller_Test;

architecture testbench of VGA_Controller_Test is 
	component VGA_controller is
		port(
		clk_clk                                              : in  std_logic                     := '0';             --                                       clk.clk
		reset_reset_n                                        : in  std_logic                     := '0';             --                                     reset.reset_n
		video_vga_controller_0_avalon_vga_sink_data          : in  std_logic_vector(29 downto 0) := (others => '0'); --    video_vga_controller_0_avalon_vga_sink.data
		video_vga_controller_0_avalon_vga_sink_startofpacket : in  std_logic                     := '0';             --                                          .startofpacket
		video_vga_controller_0_avalon_vga_sink_endofpacket   : in  std_logic                     := '0';             --                                          .endofpacket
		video_vga_controller_0_avalon_vga_sink_valid         : in  std_logic                     := '0';             --                                          .valid
		video_vga_controller_0_avalon_vga_sink_ready         : out std_logic;                                        --                                          .ready
		video_vga_controller_0_external_interface_CLK        : out std_logic;                                        -- video_vga_controller_0_external_interface.CLK
		video_vga_controller_0_external_interface_HS         : out std_logic;                                        --                                          .HS
		video_vga_controller_0_external_interface_VS         : out std_logic;                                        --                                          .VS
		video_vga_controller_0_external_interface_BLANK      : out std_logic;                                        --                                          .BLANK
		video_vga_controller_0_external_interface_SYNC       : out std_logic;                                        --                                          .SYNC
		video_vga_controller_0_external_interface_R          : out std_logic_vector(7 downto 0);                     --                                          .R
		video_vga_controller_0_external_interface_G          : out std_logic_vector(7 downto 0);                     --                                          .G
		video_vga_controller_0_external_interface_B          : out std_logic_vector(7 downto 0)                      --                                          .B)
	);
	end component VGA_controller;
	
		signal 	clk_tb : std_logic := '0';     
		signal	reset_n_tb : std_logic:= '0';      
		signal	sink_data_tb : std_logic_vector(29 downto 0) := (others => '0');
		signal	sink_startofpacket_tb : std_logic:= '0';          
		signal	sink_endofpacket_tb : std_logic:= '0';         
		signal	sink_valid_tb : std_logic:= '0';          
		signal	sink_ready_tb : std_logic;                                 
		signal	exti_CLK_tb : std_logic;                                   
		signal	exti_HS_tb : std_logic;                                      
		signal	exti_VS_tb : std_logic;                                      
		signal	exti_BLANK_tb : std_logic;                              
		signal	exti_SYNC_tb : std_logic;               
		signal	exti_R_tb : std_logic_vector(7 downto 0); 
		signal	exti_G_tb : std_logic_vector(7 downto 0);
		signal	exti_B_tb : std_logic_vector(7 downto 0);
		
		constant clk_period : time := 20 ns;
		
	begin 
		t1: VGA_controller port map ( clk_clk => clk_tb,
												reset_reset_n => reset_n_tb,                            
												video_vga_controller_0_avalon_vga_sink_data => sink_data_tb,
												video_vga_controller_0_avalon_vga_sink_startofpacket => sink_startofpacket_tb,
												video_vga_controller_0_avalon_vga_sink_endofpacket => sink_endofpacket_tb,
												video_vga_controller_0_avalon_vga_sink_valid => sink_valid_tb,
												video_vga_controller_0_avalon_vga_sink_ready => sink_ready_tb,
												video_vga_controller_0_external_interface_CLK => exti_CLK_tb,
												video_vga_controller_0_external_interface_HS => exti_HS_tb,
												video_vga_controller_0_external_interface_VS => exti_VS_tb,
												video_vga_controller_0_external_interface_BLANK => exti_BLANK_tb,
												video_vga_controller_0_external_interface_SYNC => exti_SYNC_tb,
												video_vga_controller_0_external_interface_R => exti_R_tb,
												video_vga_controller_0_external_interface_G => exti_G_tb,
												video_vga_controller_0_external_interface_B => exti_B_tb);
												
		
		clk_tb <= not clk_tb after clk_period/2;
		
		stim_proc : process()
		begin
			reset_n_tb <= '0';
			wait for 100ns;
			reset_n_tb <= '1';
			wait until rising_edge(clk_tb);
			
			sink_startofpacket <= '1';
			
			for i in 0 to 100 loop
				wait until rising_edge(clk_tb);
				if sink_ready_tb = '1' then
					sink_valid_tb <= '1';
					sink_data_tb <= std_logic_vector(to_unsigned(i, 30));
					sink_startofpacket_tb <= '0';
				end if;
			end loop;
			
			sink_valid_tb <= '0';
			wait;
		end process;
		
		hs_monitor : process(exti_HS_tb)
			begin
				report "HS edge detected" severity note;
			end process;
	
		vs_monitor : process(exti_VS_tb)
			begin
				report "VS edge detected" severity note;
			end process;
		
		trans_proc : process(clk_tb)
		begin
			if rising_edge(clk_tb) then
				if sink_valid_tb = '1' and sink_ready_tb = '1' then 
					assert (not is_x(exti_R_tb))
						report "error: vga red output undefinied"
						severity error;
					assert (not is_x(exti_G_tb))
						report "error: vga green output undefined"
						severity error;
					assert (not is_x(exti_B_tb))
						report "error: vga blue output undefined"
						severity error;
				end if;
			end if;
		end process;
				
end architecture;
				
