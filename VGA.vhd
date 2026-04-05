library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity VGA is
	port (
		CLOCK_50       : in  std_logic;             --                                       clk.clk
		KEY            : in  std_logic_vector(3 downto 0);  		--                                     reset.reset_n
		pixel_data  	: in  std_logic_vector(7 downto 0);
      pixel_addr  	: out std_logic_vector(19 downto 0);
		VGA_CLK        : out std_logic;                                        -- video_vga_controller_0_external_interface.CLK
		VGA_HS         : out std_logic;                                        --                                          .HS
		VGA_VS         : out std_logic;                                        --                                          .VS
		VGA_BLANK_N    : out std_logic;                                        --                                          .BLANK
		VGA_SYNC_N     : out std_logic;                                        --                                          .SYNC
		VGA_R          : out std_logic_vector(7 downto 0);                     --                                          .R
		VGA_G          : out std_logic_vector(7 downto 0);                     --                                          .G
		VGA_B          : out std_logic_vector(7 downto 0)                      --                                          .B
	);
end entity VGA;

architecture rtl of VGA is
signal VGA_R_S, VGA_G_S, VGA_B_S: std_logic_vector(7 downto 0);
signal vga_startofpacket, vga_endofpacket, vga_valid, vga_ready, vga_clk_s, clk_25, VGA_HS_S, VGA_VS_S:  std_logic;
signal counter_H, counter_V : integer:=0;---640*480


component VGA_controller is
	port (
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
		video_vga_controller_0_external_interface_B          : out std_logic_vector(7 downto 0)                      --                                          .B
	);
end component VGA_controller;

begin

vga0 : component VGA_controller
		port map (
			clk_clk                                              => CLOCK_50,                              --                clk.clk
			reset_reset_n                                        => KEY(0),                       --              reset.reset
			video_vga_controller_0_avalon_vga_sink_data          => VGA_R_S&"00"&VGA_G_S&"00"&VGA_B_S&"00",          --    avalon_vga_sink.data
			video_vga_controller_0_avalon_vga_sink_startofpacket => vga_startofpacket, --                   .startofpacket
			video_vga_controller_0_avalon_vga_sink_endofpacket   => vga_endofpacket,   --                   .endofpacket
			video_vga_controller_0_avalon_vga_sink_valid         => vga_valid,         --                   .valid
			video_vga_controller_0_avalon_vga_sink_ready         => vga_ready,         --                   .ready
			video_vga_controller_0_external_interface_CLK        => vga_clk_s,        -- external_interface.export
			video_vga_controller_0_external_interface_HS         => VGA_HS_S,         --                   .export
			video_vga_controller_0_external_interface_VS         => VGA_VS_S,         --                   .export
			video_vga_controller_0_external_interface_BLANK      => VGA_BLANK_N,      --                   .export
			video_vga_controller_0_external_interface_SYNC       => VGA_SYNC_N,       --                   .export
			video_vga_controller_0_external_interface_R          => VGA_R,          --                   .export
			video_vga_controller_0_external_interface_G          => VGA_G,          --                   .export
			video_vga_controller_0_external_interface_B          => VGA_B         --                   .export
		);
		
	VGA_HS<=VGA_HS_S;	
	VGA_VS<=VGA_VS_S;	
	VGA_CLK <= vga_clk_s;
	
				
	vga_startofpacket<= '1' when (counter_H=0 and counter_v=0)
							else '0';
							
	vga_endofpacket<= '1'	when (counter_H=703 and counter_v=522)
                     else '0';			
							
	pixel_addr <= std_logic_vector(
		 to_unsigned(
			  (counter_V - 33) * 640 + (counter_H - 47), 20)
		 ) when (counter_H >= 47 and counter_H < 688
					and counter_V >= 33 and counter_V < 513)
		 else (others => '0');

process(VGA_HS_S, clk_25)
begin
		if (VGA_HS_S='0')then
			counter_H<=0;
		elsif (clk_25' event and clk_25='1') then
				counter_H<=counter_H+1;
			end if;

end process;


process(VGA_VS_S, clk_25, counter_H)
begin
		if (VGA_VS_S='0')then
			counter_v<=0;
		elsif (clk_25' event and clk_25='1' and counter_H=703) then
				counter_v<=counter_v+1;
			end if;

end process;




process(CLOCK_50)
begin
		if (CLOCK_50' event and CLOCK_50='1') then
				clk_25<=not clk_25;
			end if;

end process;

process(clk_25)
begin
	if (clk_25'event and clk_25 = '1') then
		if (counter_H >= 48 and counter_H < 688 and counter_V >= 33 and counter_V < 513) then
			VGA_R_S <= pixel_data;
			VGA_G_S <= pixel_data;
			VGA_B_S <= pixel_data;
			vga_valid <= '1';
		else
			VGA_R_S <= (others => '0');
			VGA_G_S <= (others => '0');
			VGA_B_S <= (others => '0');
			vga_valid <= '0';
		end if;
	end if;
end process;


end rtl;
