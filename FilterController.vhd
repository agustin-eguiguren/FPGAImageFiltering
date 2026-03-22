library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FilterController is
    port ( CLOCK_50: in std_logic;
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
signal CLK, START RESETb: std_logic;
signal FILTER_SEL: std_logic_vector(3 downto 0);

RESETb <= KEY(0);
START <= KEY(1);
FILTER_SEL <= SW(3 downto 0);

-- component definitions

-- TWO RAMs to store images
-- ONE ROMs to sotre filter kernel
-- IMAGE FILTER
-- VGA CONTROLLER
begin

end arch;