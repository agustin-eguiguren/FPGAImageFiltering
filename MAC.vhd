library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- four 3x3 kernels = 36 bytes ~= 64 bytes storage
entity MAC is
    port (
        CLK, en, init: in std_logic;
        data_1, data_2: in std_logic_vector(17 downto 0);
        data_out: out std_logic_vector(17 downto 0)
    );
end entity MAC;

architecture arch of MAC is
    signal sum, product: signed (17 downto 0) := (others => '0');
begin
    data_out <= std_logic_vector(sum);
    product <= signed(data_1) * signed(data_2);
    
    
    process(CLK)
    begin
        if(CLK'event and CLK='1' and en = '1') then
            if (init = '1') then
                sum <= product;
            else
                sum <= sum + product;
            end if;
              
        end if;
    end process;
end arch;