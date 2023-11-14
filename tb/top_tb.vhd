library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

    signal clk : std_logic := '1';
    signal rst_n : std_logic := '0';

    -- LFSR 
    signal d_ready : std_logic := '0';
    signal d_valid : std_logic;
    signal data_lfsr : std_logic_vector(0 downto 0);

    -- FIR 
    signal next_ready : std_logic;
    signal next_valid : std_logic;
    signal data_out : sfixed(10 downto -13);

begin

    clk <= not clk after clk_period / 2;

    LFSR_DUT : entity work.lfsr(rtl)
    generic map (
        SEED => x"DEADBABE"
    )
    port map (
        clk => clk,
        rst_n => rst_n,

        ready => d_ready,
        valid => d_valid,
        data => data_lfsr
    );

    FIR_DUT : entity work.fir(rtl)
    generic map(
        FIR_LENGTH => 256
    )
    port map (
        clk => clk,
        rst_n => rst_n,

        prev_ready => d_ready,
        prev_valid => d_valid,
        data_in => data_lfsr,

        next_ready => next_ready,
        next_valid => next_valid,
        data_out => data_out
    );

    FIFO_DUT : entity work.mock_fifo(rtl)
    port map (
        clk => clk,
        rst_n => rst_n,

        ready => next_ready,
        valid => next_valid,
        data => data_out(0)
    );
    

    SEQUENCER_PROC : process
    begin

        -------------------------------
        -- VUNIT setup
        -------------------------------

        test_runner_setup(runner, runner_cfg);

        wait for clk_period * 20;

        rst_n <= '1';

        wait for clk_period * 1e6;

        -------------------------------
        -- VUNIT cleanup
        -------------------------------

        test_runner_cleanup(runner);

    end process;

end architecture;