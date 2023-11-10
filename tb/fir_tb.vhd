library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;

entity fir_tb is
    generic(runner_cfg : string);
end fir_tb;

architecture sim of fir_tb is

    constant clk_hz : integer := 100e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';

    signal prev_ready : std_logic;
    signal prev_valid : std_logic;
    signal data_in : std_logic_vector(0 downto 0);

    signal next_ready : std_logic;
    signal next_valid : std_logic;
    signal data_out : std_logic_vector(23 downto 0);

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.fir(rtl)
    generic map(
        FIR_LENGTH => 256
    )
    port map (
        clk => clk,
        rst => rst,

        prev_ready => prev_ready,
        prev_valid => prev_valid,
        data_in => data_in,

        next_ready => next_ready,
        next_valid => next_valid,
        data_out => data_out
    );

    SEQUENCER_PROC : process
    begin
        wait for clk_period * 2;

        rst <= '0';
        next_ready <= '1';

        wait for clk_period * 10;

        -- Send an impulse response
        -- First 1 and then every bit after should be 0
        data_in(0) <= '1';
        prev_valid <= '1';

        wait for clk_period * 2;

        data_in(0) <= '0';

        wait for clk_period * 256;

        -- The output register of the FIR filter should contain the coefficients

    end process;

end architecture;