library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

entity lfsr_tb is
    generic(runner_cfg : string);
end lfsr_tb;

architecture sim of lfsr_tb is

    constant clk_hz : integer := 25e6;
    constant clk_period : time := 1 sec / clk_hz;

    constant N : integer := 32;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal d_ready : std_logic := '0';
    signal d_valid : std_logic;
    signal data : std_logic_vector(0 downto 0);

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.lfsr(rtl)
    generic map (
        SEED => x"DEADBABE"
    )
    port map (
        clk => clk,
        rst => rst,
        d_ready => d_ready,
        d_valid => d_valid,
        data => data
    );

    SEQUENCER_PROC : process
    begin

        -------------------------------
        -- VUNIT setup
        -------------------------------

        test_runner_setup(runner, runner_cfg);


        wait for clk_period * 2;

        rst <= '0';

        wait for clk_period;

        d_ready <= '1';

        wait for clk_period * 2;
        d_ready <= '0';

        wait for clk_period * 2;

        d_ready <= '1';

        wait for clk_period * 10;

        -------------------------------
        -- VUNIT cleanup
        -------------------------------

        test_runner_cleanup(runner);
    end process;

end architecture;