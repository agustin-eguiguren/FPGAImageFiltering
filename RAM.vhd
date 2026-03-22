library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(
        ADDR_SPACE: INTEGER
    );
    port (
        CLK: in std_logic;
        data_in: in std_logic_vector(7 downto 0);
        address_in: in std_logic_vector((ADDR_SPACE-1) downto 0);
        address_r1: in std_logic_vector((ADDR_SPACE-1) downto 0);
        address_r2: in std_logic_vector((ADDR_SPACE-1) downto 0);
        we: in std_logic;
        data_out1: out std_logic_vector(7 downto 0);
        data_out2: out std_logic_vector(7 downto 0)
    );
end entity RAM;

architecture arch of RAM is
    -- generic address space, so we need 
    type mem is ARRAY (0 to ((2**ADDR_SPACE)-1)) of std_logic_vector(7 downto 0);
    signal ram_block: mem;
begin
    process(CLK)
    begin
        if(CLK'event and CLK = '1') then
            if(we = '1') then
                ram_block(to_integer( unsigned(address_in))) <= data_in;
            end if;
            data_out1 <= ram_block(to_integer( unsigned(address_r1)));
            data_out2 <= ram_block(to_integer( unsigned(address_r2)));
        end if;
    end process;
end arch; 