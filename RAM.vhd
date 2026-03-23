library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic(
        ADDR_SPACE: INTEGER
    );
    port (
        CLK, we1, we2: in std_logic;
        data_in1: in std_logic_vector(7 downto 0);
        data_in2: in std_logic_vector(7 downto 0);
        address1: in std_logic_vector((ADDR_SPACE-1) downto 0);
        address2: in std_logic_vector((ADDR_SPACE-1) downto 0);
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
            if(we1 = '1') then
                ram_block(to_integer( unsigned(address1))) <= data_in1;
            end if;
            if(we2 = '1') then
                ram_block(to_integer( unsigned(address2))) <= data_in2;
            end if;
            data_out1 <= ram_block(to_integer( unsigned(address1)));
            data_out2 <= ram_block(to_integer( unsigned(address2)));
        end if;
    end process;
end arch; 