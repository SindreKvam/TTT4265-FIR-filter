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
        rst : in std_logic;
        d_ready : in std_logic;
        d_valid : out std_logic;
        data : out std_logic_vector(0 downto 0) := (others => '1')
    );
end lfsr;

architecture rtl of lfsr is

    signal r_lfsr : std_logic_vector(32 downto 1) := SEED;
    signal w_mask : std_logic_vector(32 downto 1);
    signal w_poly : std_logic_vector(32 downto 1);

begin

    -- Unclocked output
    data(0) <= r_lfsr(1);

    w_poly  <= POLY;
    g_mask : for k in 32 downto 1 generate
        w_mask(k)  <= w_poly(k) and r_lfsr(1);
    end generate g_mask;
    

    LFSR_PROC : process(clk)
    begin
        if rising_edge(clk) then

            if (rst = '1') then
                -- Reset
                r_lfsr <= SEED;

            elsif (d_ready = '1') then
                -- LFSR logic
                r_lfsr   <= '0' & r_lfsr(32 downto 2) xor w_mask;
                d_valid  <= '1';

            else
                d_valid <= '0';

            end if;

        end if;
        
    end process;

end architecture;