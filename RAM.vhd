library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity RAM is
    generic(
        ADDR_SPACE: INTEGER := 2
    );
    port (
        clock_1, clock_2, we1, we2: in std_logic;
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
    constant DATA_WIDTH: integer := 8;
    constant IMAGE_FILE_NAME: string := "hamed_bw.mif";
    
    type mem is ARRAY (0 to ((2**ADDR_SPACE)-1)) of std_logic_vector((DATA_WIDTH-1) downto 0);

impure function init_mem(mif_file_name : in string) return mem is
    file mif_file : text open read_mode is mif_file_name;
    variable mif_line : line;
    variable temp_bv : bit_vector(DATA_WIDTH-1 downto 0);
    variable temp_mem : mem;
begin
    for i in mem'range loop
        readline(mif_file, mif_line);
        read(mif_line, temp_bv);
        temp_mem(i) := to_stdlogicvector(temp_bv);
    end loop;
    return temp_mem;
end function;

    signal ram_block: mem := init_mem(IMAGE_FILE_NAME);

begin
    process(clock_1)
    begin
        if(clock_1'event and clock_1 = '1') then
            if(we1 = '1') then
                ram_block(to_integer( unsigned(address1))) <= data_in1;
            end if;
            data_out1 <= ram_block(to_integer( unsigned(address1)));
        end if;
    end process;
    process(clock_2)
    begin
        if(clock_2'event and clock_2 = '1') then
            if(we2 = '1') then
                ram_block(to_integer( unsigned(address2))) <= data_in2;
            end if;
            data_out2 <= ram_block(to_integer( unsigned(address2)));
        end if;
    end process;
end arch; 