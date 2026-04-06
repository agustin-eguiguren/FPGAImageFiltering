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
signal START, RESETb, oldSTART: std_logic;
signal FILTER_SEL: std_logic_vector(1 downto 0);
signal buffer_select : std_logic := '0';

signal address1_a : std_logic_vector(15 downto 0);
signal dataout1_b, dataout2_b, dataout2_a, dataout1_a : std_logic_vector(7 downto 0);

signal we1_b, we2_b, we1_a, we2_a : std_logic:= '0';
signal datain1_b, datain2_b, datain1_a, datain2_a : std_logic_vector(7 downto 0) := (others => '0');
signal address1_b : std_logic_vector(15 downto 0);
signal address2_b, address2_a : std_logic_vector(15 downto 0);

signal kernal_en, filter_en : std_logic := '0';
signal kernal_address : std_logic_vector(5 downto 0);
signal kernal_data : std_logic_vector(7 downto 0);

signal filter_ready : std_logic;

signal filter_read_addr : std_logic_vector(15 downto 0);
signal filter_write_addr : std_logic_vector(15 downto 0);
signal filter_write_data : std_logic_vector(7 downto 0);
signal filter_we : std_logic;

signal vga_pixel_addr : std_logic_vector(15 downto 0);
signal vga_pixel_data, filter_data_out, filter_data_in : std_logic_vector(7 downto 0);

signal clk_25 : std_logic := '0';

type state_type is (IDLE, FILTERING, DISPLAY);
signal current_state : state_type := IDLE;

signal LEDSIGNAL: std_logic_vector(9 downto 0);

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
    generic (
        IMG_HEIGHT: INTEGER := 480;
        IMG_WIDTH: INTEGER := 640;
        RAM_ADDR_SIZE: INTEGER := 20 -- 2^20 = 1048576 > 921600 = (307200)*3 = (640*480)*3
    );
    port (
        CLK, filter_en: in std_logic;
        ram_in: in std_logic_vector(7 downto 0);
        rom_in: in std_logic_vector(7 downto 0);
        filter_sel: in std_logic_vector(1 downto 0);
        ram_out_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        ram_in_addr: out std_logic_vector((RAM_ADDR_SIZE-1) downto 0);
        ram_out_en: out std_logic;
        rom_addr: out std_logic_vector(5 downto 0);
        rom_r_en: out std_logic;
        data_out: out std_logic_vector(7 downto 0);
        READY: out std_logic;
		FilterLED: out std_logic_vector(9 downto 0)
    );
end component;

component VGA is
	port ( CLOCK_50       : in  std_logic;             --                                       clk.clk
			 clk_25         : in  std_logic;
			 KEY            : in  std_logic_vector(3 downto 0);             --                                     reset.reset_n
			 pixel_data  	: in  std_logic_vector(7 downto 0);
			 pixel_addr  	: out std_logic_vector(15 downto 0);
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
			address_b => address2_a,
			clock_a => CLOCK_50,
			clock_b => clk_25,
			data_a => datain1_a,
			data_b => datain2_a,
			wren_a => we1_a,
			wren_b => we2_a,
			q_a => dataout1_a,
			q_b => dataout2_a
		);
	
	ram_b : component RAM_IP
	port map (
		address_a => address1_b,
		address_b => address2_b,
		clock_a => CLOCK_50,
		clock_b => clk_25,
		data_a => datain1_b,
		data_b => datain2_b,
		wren_a => we1_b,
		wren_b => we2_b,
		q_a => dataout1_b,
		q_b => dataout2_b
	);
			
	ROM : component FILTER_KERNELS
		port map (
			CLK => CLOCK_50,
			en => kernal_en,
			address => kernal_address,
			data => kernal_data
	);
			
	img_filter : component ImageFilter
    generic map(
        IMG_HEIGHT    => 160,
        IMG_WIDTH     => 213,
        RAM_ADDR_SIZE => 16)
    port map(
        CLK        => CLOCK_50,
        filter_en  => filter_en,
        ram_in     => filter_data_in,
        rom_in     => kernal_data,
        filter_sel => FILTER_SEL(1 downto 0),
        ram_out_addr   => filter_write_addr,
		ram_in_addr => filter_read_addr, 
        ram_out_en => filter_we,
		rom_addr   => kernal_address,
		rom_r_en => kernal_en,
        data_out   => filter_data_out,
        READY      => filter_ready,
		FilterLED => LEDSIGNAL
    );	

	vga1 : component VGA
		port map (
			CLOCK_50 => CLOCK_50,
			clk_25 => clk_25,
			KEY => KEY,
			pixel_data  => vga_pixel_data,
			pixel_addr  => vga_pixel_addr,
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

		
	process(CLOCK_50)
	begin
		if (CLOCK_50' event and CLOCK_50='1') then
				clk_25<=not clk_25;
		end if;
	end process;
	 
	
	 process(CLOCK_50)
	 begin
		if CLOCK_50'event and CLOCK_50 = '1' then

	        oldSTART <= START;

			if RESETb = '0' then
				buffer_select <= '0';
				current_state <= IDLE;
				filter_en <= '0';
			else
				case current_state is
					when IDLE =>
						filter_en <= '0';
						buffer_select <= '0';
						
						if (oldSTART = '1') and (START = '0') then
							current_state <= FILTERING;
						end if;

					when FILTERING =>
						filter_en <= '1';

						if filter_ready = '1' then
							buffer_select <= not buffer_select;
							current_state <= DISPLAY;
							filter_en <= '0';
						end if;
						
					when DISPLAY =>
						filter_en <= '0';

						if (oldSTART = '1') and (START = '0') then
							current_state <= FILTERING;
						end if;

				end case;
			end if;
		end if;

		LEDR <= LEDSIGNAL;
end process;

	-- RAM A Logic
	address1_a <= filter_read_addr  when buffer_select = '0' else filter_write_addr;
	we1_a      <= '0'               when buffer_select = '0' else filter_we;
	datain1_a  <= filter_data_out; 

	-- RAM B Logic
	address1_b <= filter_write_addr when buffer_select = '0' else filter_read_addr;
	we1_b      <= filter_we         when buffer_select = '0' else '0';
	datain1_b  <= filter_data_out; 

	-- Filter
	filter_data_in <= dataout1_a when buffer_select = '0' else dataout1_b;

	-- VGA SIGNALS 
	vga_pixel_data <= dataout2_a when buffer_select = '0' else dataout2_b;
	address2_a     <= vga_pixel_addr when buffer_select = '0' else (others => '0');
	address2_b     <= vga_pixel_addr when buffer_select = '1' else (others => '0');

end arch;
