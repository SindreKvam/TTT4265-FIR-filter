library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx lfsr
-- https://docs.xilinx.com/v/u/en-US/xapp052

entity lfsr is
    generic (
        POLY : std_logic_vector(32 - 1 downto 0) := "10000000001000000000000000000011";
        SEED : std_logic_vector(32 - 1 downto 0)
    );
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        ready : in std_logic;
        valid : out std_logic;
        data : out std_logic_vector(0 downto 0) := (others => '1');
        raw_data : out std_logic_vector(31 downto 0)
    );
end lfsr;

architecture rtl of lfsr is

    signal r_lfsr : std_logic_vector(32 downto 1) := SEED;
    signal w_mask : std_logic_vector(32 downto 1);
    signal w_poly : std_logic_vector(32 downto 1);

    type T_STATE is (CALCULATE, HOLD_DATA_OUT);
    signal state : T_STATE := CALCULATE;

begin

    w_poly  <= POLY;
    g_mask : for k in 32 downto 1 generate
        w_mask(k)  <= w_poly(k) and r_lfsr(1);
    end generate g_mask;
    

    LFSR_PROC : process(clk)

        variable v_valid : std_logic;

    begin
        if rising_edge(clk) then

            v_valid := '0';

            if rst_n = '0' then

                r_lfsr <= SEED;
                state <= CALCULATE;

            else

                case state is

                    -------------------------------
                    when CALCULATE =>
                        -------------------------------

                        r_lfsr <= '0' & r_lfsr(32 downto 2) xor w_mask;
                        state <= HOLD_DATA_OUT;
                    
                    -------------------------------
                    when HOLD_DATA_OUT =>
                        -------------------------------

                        data(0) <= r_lfsr(1);
                        raw_data <= r_lfsr(32 downto 1);

                        v_valid  := '1';

                        if ready = '1' then
                            state <= CALCULATE;
                        end if;
                
                    when others =>
                
                end case;

            end if;
            
            valid <= v_valid;
        end if;
        
    end process;

end architecture;