library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx lfsr
-- https://docs.xilinx.com/v/u/en-US/xapp052

entity sine is
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        ready : in std_logic;
        valid : out std_logic;
        data : out std_logic_vector(23 downto 0) := (others => '0')
    );
end sine;

architecture rtl of sine is

    type T_LOOKUP is array(0 to 31) of std_logic_vector(23 downto 0); 
    signal delay_line : T_LOOKUP := (others => (others => '0'));

    type T_STATE is (CALCULATE, HOLD_DATA_OUT);
    signal state : T_STATE := CALCULATE;
    signal phase : unsigned(4 downto 0) := (others => '0');

    constant coeff : T_LOOKUP := (
        x"800000",x"98f8b8",x"b0fbc5",x"c71cec",x"da8279",x"ea6d98",x"f641ae",x"fd8a5e",
        x"ffffff",x"fd8a5e",x"f641ae",x"ea6d98",x"da8279",x"c71cec",x"b0fbc5",x"98f8b8",
        x"800000",x"670747",x"4f043a",x"38e313",x"257d86",x"159267",x"09be51",x"0275a1",
        x"000000",x"0275a1",x"09be51",x"159267",x"257d86",x"38e313",x"4f043a",x"670747");
begin


    SINE_PROC : process(clk)

        variable v_valid : std_logic;

    begin
        if rising_edge(clk) then

            v_valid := '0';

            if rst_n = '0' then

                data  <= (others => '0');
                state <= CALCULATE;

            else

                case state is

                    -------------------------------
                    when CALCULATE =>
                        -------------------------------

                        state <= HOLD_DATA_OUT;
                        data  <= coeff(to_integer(phase));

                    -------------------------------
                    when HOLD_DATA_OUT =>
                        -------------------------------

                        v_valid  := '1';

                        if ready = '1' then
                            phase <= phase + 1;
                            state <= CALCULATE;
                        end if;
                
                    -------------------------------
                    when others =>
                        -------------------------------

                        state <= CALCULATE;
                
                end case;

            end if;
            
            valid <= v_valid;
        end if;
        
    end process;

end architecture;