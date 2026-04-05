library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FilterController is
    port ( 
	 CLOCK_50: in std_logic;
    KEY: in std_logic_vector(3 downto 0);
    SW: in std_logic_vector(9 downto 0);
    VGA_CLK        : out std_logic;                                        -- video_vga_controller_0_external_interface.CLK
    VGA_HS         : out std_logic;                                        --                                          .HS
    VGA_VS         : out std_logic;                                        --                                          .VS
    VGA_BLANK_N    : out std_logic;                                        --                                          .BLANK
    VGA_SYNC_N     : out std_logic;                                        --                                          .SYNC
    VGA_R          : out std_logic_vector(7 downto 0);                     --                                          .R
    VGA_G          : out std_logic_vector(7 downto 0);                     --                                          .G
    VGA_B          : out std_logic_vector(7 downto 0)
    );
end entity FilterController;

architecture arch of FilterController is
-- deals with two clock frequencies (we could use the same frequency but it woul make filtering slower)
-- initializes the default read RAM to img (https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/hdl/vhdl/vhdl_file_dir_ram_init.htm)
-- when filtering is finished, RAMs are switched (the one used for reading is used for writing and vice versa)


-- signal definitions 
signal START, RESETb: std_logic;
signal FILTER_SEL: std_logic_vector(1 downto 0);
signal buffer_select : std_logic := '0';

signal address1_a : std_logic_vector(19 downto 0);
signal dataout1_a : std_logic_vector(7 downto 0);

signal we1_b : std_logic:= '0';
signal datain1_b : std_logic_vector(7 downto 0);
signal address1_b : std_logic_vector(19 downto 0);
signal address2_b : std_logic_vector(19 downto 0);
signal dataout2_b : std_logic_vector(7 downto 0);

signal kernal_en : std_logic := '0';
signal kernal_address : std_logic_vector(5 downto 0);
signal kernal_data : std_logic_vector(7 downto 0);

signal filter_en : std_logic := '0';
signal filter_ready : std_logic;

signal filter_read_addr : std_logic_vector(19 downto 0);
signal filter_write_addr : std_logic_vector(19 downto 0);
signal filter_write_data : std_logic_vector(7 downto 0);
signal filter_we : std_logic;

signal vga_pixel_addr : std_logic_vector(19 downto 0);
signal vga_pixel_data : std_logic_vector(7 downto 0);

type state_type is (IDLE, FILTERING, DISPLAY);
signal current_state : state_type := IDLE;

-- component definitions

-- TWO RAMs to store images
-- ONE ROMs to sotre filter kernel X
-- IMAGE FILTER
-- VGA CONTROLLER

component RAM is 
	generic(ADDR_SPACE: INTEGER);
	port ( CLK, we1, we2: in std_logic;
          data_in1: in std_logic_vector(7 downto 0);
			 data_in2: in std_logic_vector(7 downto 0);
			 address1: in std_logic_vector((ADDR_SPACE-1) downto 0);
          address2: in std_logic_vector((ADDR_SPACE-1) downto 0);
          data_out1: out std_logic_vector(7 downto 0);
          data_out2: out std_logic_vector(7 downto 0));
end component;
	
component FILTER_KERNALS is
	port ( CLK, en: in std_logic;
			 address: in std_logic_vector(5 downto 0);
			 data: out std_logic_vector(7 downto 0));
end component;

component ImageFilter is
	generic(IMG_HEIGHT: INTEGER := 480;
			  IMG_WIDTH: INTEGER := 640;
			  RAM_ADDR_SIZE: INTEGER := 20);
	port (
		  CLK : in std_logic;
		  filter_en: in std_logic;
        ram_in: in std_logic_vector(7 downto 0);
        rom_in: in std_logic_vector(7 downto 0);
        filter_sel: in std_logic_vector(1 downto 0);
        ram_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        rom_addr: out std_logic_vector(5 downto 0);
        data_out: out std_logic_vector(7 downto 0);
        READY: out std_logic);
end component;

component VGA is
	port ( CLOCK_50       : in  std_logic;             --                                       clk.clk
			 KEY            : in  std_logic_vector(3 downto 0);             --                                     reset.reset_n
			 pixel_data  	: in  std_logic_vector(7 downto 0);
			 pixel_addr  	: out std_logic_vector(19 downto 0);
			 VGA_CLK        : out std_logic;                                        -- video_vga_controller_0_external_interface.CLK
			 VGA_HS         : out std_logic;                                        --                                          .HS
			 VGA_VS         : out std_logic;                                        --                                          .VS
			 VGA_BLANK_N    : out std_logic;                                        --                                          .BLANK
			 VGA_SYNC_N     : out std_logic;                                        --                                          .SYNC
			 VGA_R          : out std_logic_vector(7 downto 0);                     --                                          .R
			 VGA_G          : out std_logic_vector(7 downto 0);                     --                                          .G
			 VGA_B          : out std_logic_vector(7 downto 0));
end component;

begin

	ram_a : component RAM
		generic map(ADDR_SPACE => 20)
		port map(
			CLK => CLOCK_50,
			we1 => '0',
			we2 => '0',
			data_in1 => (others => '0'),
			data_in2 => (others => '0'),
			address1 => address1_a,
			address2 => (others => '0'),
			data_out1 => dataout1_a,
			data_out2 => open);
			
	ram_b : component RAM
		generic map(ADDR_SPACE => 20)
		port map(
			CLK => CLOCK_50,
			we1 => we1_b,
			we2 => '0',
			data_in1 => datain1_b,
			data_in2 => (others => '0'),
			address1 => address1_b,
			address2 => address2_b,
			data_out1 => open,
			data_out2 => dataout2_b);
			
	filter_kernal : component FILTER_KERNALS
		port map (
			CLK => CLOCK_50,
			en => kernal_en,
			address => kernal_address,
			data => kernal_data);
			
	img_filter : component ImageFilter
    generic map(
        IMG_HEIGHT    => 480,
        IMG_WIDTH     => 640,
        RAM_ADDR_SIZE => 20)
    port map(
        CLK        => CLOCK_50,
        filter_en  => filter_en,
        ram_in     => dataout1_a,
        rom_in     => kernal_data,
        filter_sel => FILTER_SEL(1 downto 0),
        ram_addr   => filter_read_addr,
        rom_addr   => kernal_address,
        data_out   => datain1_b,
        READY      => filter_ready);
			
	vga : component VGA
		port map (
			CLOCK_50 => CLOCK_50,
			KEY => KEY,
			pixel_data  => dataout2_b,
			pixel_addr  => address2_a,
			VGA_CLK => VGA_CLK,
			VGA_HS => VGA_HS,
			VGA_VS => VGA_VS,
			VGA_BLANK_N => VGA_BLANK_N,
			VGA_SYNC_N => VGA_SYNC_N,
			VGA_R => VGA_R,
			VGA_G => VGA_G,
			VGA_B => VGA_B);
			
    RESETb <= KEY(0);
    START <= KEY(1);
    FILTER_SEL <= SW(1 downto 0);
	 kernal_en <= filter_en;
	 
	 process(CLOCK_50)
		if CLOCK_50'event and CLOCK_50 = '1' then
			if RESETb = '0' then
				current_state = IDLE;
				filter_en <= '0';
				we1_b <= '0';
			else:
				case current_state is:
					when IDLE =>
						filter_en <= '0';
						we1_b <= '0';
						
						if START = '0' then
							current_state <= FILTERING;
						end if;
							
					when FILTERING =>
						filter_en <= '1';
						we1_b <= '1';
						if filter_ready = '1' then
							current_state <= DISPLAY;
							filter_en <= '0';
							we1_b <= '0';
						end if;
							
					when DISPLAY =>
						if START = '1' then
							buffer_select <= not buffer_select;
							current_state <= IDLE;
						end if;
				end case;
			end if;
		end if;
end process;
	address1_a <= filter_read_addr  when buffer_select = '0' else filter_write_addr;
	we1_a      <= '0'               when buffer_select = '0' else filter_we;

	address1_b <= filter_write_addr when buffer_select = '0' else filter_read_addr;
	we1_b      <= filter_we         when buffer_select = '0' else '0';
	
	vga_pixel_addr_to_ram <= address2_b when buffer_select = '0' else address2_a;
end arch;
