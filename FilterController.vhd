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
    VGA_B          : out std_logic_vector(7 downto 0);
	LEDR : out  std_logic_vector(9 downto 0) 
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

signal address1_a : std_logic_vector(15 downto 0);
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

signal clk_25 : std_logic := '0';

type state_type is (IDLE, DISPLAY);
signal current_state : state_type := IDLE;

signal testVGA_HS: std_logic;

-- component definitions

-- TWO RAMs to store images
-- ONE ROMs to sotre filter kernel X
-- IMAGE FILTER
-- VGA CONTROLLER

component Counter
		generic( N: natural);
		port(CLR, CLK, EN: std_logic;
			Q: out std_logic_vector(N-1 downto 0));
	end component;


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
	
component FILTER_KERNELS is
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
			 clk_25         : in  std_logic;
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

	ram_a : component RAM_IP
		port map (
			address_a => address1_a,
			address_b => (others => '0'),
			clock_a => clk_25,
			clock_b => clk_25,
			data_a => (others => '0'),
			data_b => (others => '0'),
			wren_a => '0',
			wren_b => '0',
			q_a => dataout1_a,
			q_b => open
		);
			
--	ROM : component FILTER_KERNELS
--		port map (
--			CLK => CLOCK_50,
--			en => kernal_en,
--			address => kernal_address,
--			data => kernal_data);
			
--	img_filter : component ImageFilter
--    generic map(
--        IMG_HEIGHT    => 480,
--        IMG_WIDTH     => 640,
--        RAM_ADDR_SIZE => 20)
--    port map(
--        CLK        => CLOCK_50,
--        filter_en  => filter_en,
--        ram_in     => dataout1_a,
--        rom_in     => kernal_data,
--        filter_sel => FILTER_SEL(1 downto 0),
--        ram_addr   => filter_read_addr,
--        rom_addr   => kernal_address,
--        data_out   => datain1_b,
--        READY      => filter_ready);
--			
	vga1 : component VGA
		port map (
			CLOCK_50 => CLOCK_50,
			clk_25 => clk_25,
			KEY => KEY,
			pixel_data  => dataout1_a,
			pixel_addr  => vga_pixel_addr,
			VGA_CLK => VGA_CLK,
			VGA_HS => testVGA_HS,
			VGA_VS => VGA_VS,
			VGA_BLANK_N => VGA_BLANK_N,
			VGA_SYNC_N => VGA_SYNC_N,
			VGA_R => VGA_R,
			VGA_G => VGA_G,
			VGA_B => VGA_B);
			
	 address1_a <= vga_pixel_addr(15 downto 0);
	
	LEDR(0) <= testVGA_HS; -- CORRECT LATERRR
	VGA_HS <= testVGA_HS;
			
    RESETb <= KEY(0);
    START <= KEY(1);
    FILTER_SEL <= SW(1 downto 0);
	 kernal_en <= filter_en;

		
	process(CLOCK_50)
	begin
		if (CLOCK_50' event and CLOCK_50='1') then
				clk_25<=not clk_25;
		end if;
	end process;
	 
	
	 process(CLOCK_50)
	 begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			if RESETb = '0' then
				current_state <= IDLE;
--				filter_en <= '0';
--				we1_b <= '0';
			else
				case current_state is
					when IDLE =>
--						filter_en <= '0';
--						we1_b <= '0';
						
						if START = '0' then
							current_state <= DISPLAY;
						end if;
							
--					when FILTERING =>
--						filter_en <= '1';
--						we1_b <= '1';
--						if filter_ready = '1' then
--							current_state <= DISPLAY;
--							filter_en <= '0';
--							we1_b <= '0';
--						end if;
							
					when DISPLAY =>
						if START = '1' then
--							buffer_select <= not buffer_select;
							current_state <= IDLE;
						end if;
				end case;
			end if;
		end if;
end process;
--	address1_a <= filter_read_addr  when buffer_select = '0' else filter_write_addr;
--	we1_a      <= '0'               when buffer_select = '0' else filter_we;
--
--	address1_b <= filter_write_addr when buffer_select = '0' else filter_read_addr;
--	we1_b      <= filter_we         when buffer_select = '0' else '0';
--	
--	vga_pixel_addr_to_ram <= address2_b when buffer_select = '0' else address2_a;
end arch;
