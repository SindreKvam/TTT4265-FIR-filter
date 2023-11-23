library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mock_fifo is
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        data : in std_logic := '0';
        valid : in std_logic := '0';
        ready : out std_logic;

        clk_8k : out std_logic
    );
end mock_fifo;

architecture rtl of mock_fifo is

    constant CLK_PERIODS_FOR_48K : integer := 1042;

    signal data_counter : integer range 0 to 127 := 0;
    signal counter_48k : integer range 0 to 2047 := CLK_PERIODS_FOR_48K - 1;

begin

    DATA_PROC : process(clk)

        variable v_data_counter : integer;
        variable v_clk          : std_logic;
    begin
        if rising_edge(clk) then

            v_data_counter := data_counter;
            v_clk := '0';

            if data_counter = 127 then
                ready <= '0';
            else
                ready <= '1';

                if valid = '1' then
                    v_data_counter := v_data_counter + 1;
                end if;

            end if;

            if counter_48k > 0 then
                counter_48k <= counter_48k - 1;
            else
                if data_counter > 0 then
                    v_data_counter := v_data_counter - 1;
                end if;

                counter_48k <= CLK_PERIODS_FOR_48K - 1;
                v_clk := '1';
            end if;
            
            clk_8k <= v_clk;
            data_counter <= v_data_counter;

        end if;
    end process;

end architecture;