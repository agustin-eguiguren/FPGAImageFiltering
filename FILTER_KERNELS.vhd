library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- four 3x3 kernels = 36 bytes ~= 64 bytes storage
entity FILTER_KERNELS is
    port (
        CLK, en: in std_logic;
        address: in std_logic_vector(5 downto 0);
        data: out std_logic_vector(7 downto 0)
    );
end entity FILTER_KERNELS;

--- GAUSSIAN BLUR KERNEL = [[1 2 1],[2 4 2],[1 2 1]]*1/16 (shift right by 4)
--- BLUR = [[1 1 1],[1 0 1],[1 1 1]]*1/8
--- Sharpening = [[0 -1 0],[-1 5 -1],[0 -1 0]]
--- Horizontal Edge = [[-1 -1 -1],[0 0 0],[1 1 1]]

--- 2's complement components 
architecture arch of FILTER_KERNELS is
    type mem is ARRAY (0 to 35) of integer;
    constant rom: mem := 
    (
        1, 2, 1, 
        2, 4, 2, 
        1, 2, 1, 

        1, 1, 1, 
        1, 0, 1, 
        1, 1, 1, 

        0, -1, 0, 
        -1, 5, -1, 
        0, -1, 0, 

        -1, -1, -1, 
        0, 0, 0, 
        1, 1, 1
    );
begin
    process(CLK)
    begin
        if(CLK'event and CLK = '1' and en='1') then
            data <= std_logic_vector( to_signed( rom(to_integer( unsigned(address))), 8));
        end if;
    end process;
end arch; 