library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

entity top_tb is
    generic(runner_cfg : string);
end top_tb;

architecture sim of top_tb is

    constant clk_hz : integer := 50e6;
    constant clk_period : time := 1 sec / clk_hz;

    -- Constants used to generate sine-wave
    constant f : real := 500.0;
    constant f_s : real := 48000.0;
    constant f_d : real := f / f_s;
    signal sine : std_logic_vector(0 downto 0);

    signal clk : std_logic := '1';
    signal rst_n : std_logic := '0';

    -- LFSR
    signal lfsr_ready : std_logic := '0';
    signal lfsr_valid : std_logic := '0';
    signal d_valid : std_logic;
    signal data_lfsr : std_logic_vector(0 downto 0);

    -- FIR 
    signal fir_data_in : std_logic_vector(0 downto 0) := "0";
    signal fir_prev_ready : std_logic := '0';
    signal next_ready : std_logic;
    signal next_valid : std_logic;
    signal data_out : sfixed(0 downto -23);
    signal clk_8k : std_logic;

    signal unsigned_data_out : unsigned(23 downto 0);
    signal data_test : std_logic_vector(23 downto 0) := (others => '0');

begin

    clk <= not clk after clk_period / 2;

    LFSR_DUT : entity work.lfsr(rtl)
    generic map (
        SEED => x"DEADBABE"
    )
    port map (
        clk => clk,
        rst_n => rst_n,

        ready => lfsr_ready,
        valid => lfsr_valid,
        data => data_lfsr
    );

    FIR_DUT : entity work.fir(rtl)
    generic map(
        FIR_LENGTH => 1024
    )
    port map (
        clk => clk,
        rst_n => rst_n,

        prev_ready => lfsr_ready,
        prev_valid => lfsr_valid,
        data_in => data_lfsr, --fir_data_in,

        next_ready => next_ready,
        next_valid => open,
        data_out => data_out
    );

    FIFO_DUT : entity work.mock_fifo(rtl)
    port map (
        clk => clk,
        rst_n => rst_n,

        ready => next_ready,
        valid => next_valid,
        data => data_out(0),

        clk_8k => clk_8k
    );
    

    SINE_GEN : entity work.sine(rtl) 
    port map(
        clk => clk,
        rst_n => rst_n,

        ready => next_ready,
        valid => next_valid,
        data  => data_test
    );

    fir_data_in <= sine;
    unsigned_data_out <= unsigned(resize(data_out + to_sfixed(0.7083 , data_out), data_out)); -- resize(  * 2, unsigned_data_out)

    SEQUENCER_PROC : process
    begin

        -------------------------------
        -- VUNIT setup
        -------------------------------

        test_runner_setup(runner, runner_cfg);

        wait for clk_period * 20;

        rst_n <= '1';

        wait for clk_period * 1e8;

        -------------------------------
        -- VUNIT cleanup
        -------------------------------

        test_runner_cleanup(runner);

    end process;

    SINE_PROC : process(clk)
--
        variable v_tstep : real := 0.0;
        variable v_sin : real := 0.0;
--
    begin
        if rising_edge(clk) then
            v_sin := sin(MATH_2_PI * f_d * v_tstep);
            
            --d_valid <= '0';
            if clk_8k = '1' then
                v_tstep := v_tstep + 1.0;
                --d_valid <= '1';
            end if;
            
--
            if v_sin <= 0.0 then
                sine <= "1";
            else
                sine <= "0";
            end if;

        end if;
        
    end process;

end architecture;