-- #############################################################################
-- DE1_SoC_top_level.vhd
-- =====================
--
-- BOARD : DE1-SoC from Terasic
-- Author : Sahand Kashani-Akhavan from Terasic documentation
-- Revision : 1.7
-- Last updated : 2017-06-11 12:48:26 UTC
--
-- Syntax Rule : GROUP_NAME_N[bit]
--
-- GROUP  : specify a particular interface (ex: SDR_)
-- NAME   : signal name (ex: CONFIG, D, ...)
-- bit    : signal index
-- _N     : to specify an active-low signal
-- #############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all; -- ieee_proposed for VHDL-93 version
use ieee_proposed.fixed_pkg.all; -- ieee_proposed for compatibility version

entity DE1_SoC_top_level is
    port(
        -- ADC
        ADC_CS_n : out std_logic;
        ADC_DIN  : out std_logic;
        ADC_DOUT : in  std_logic;
        ADC_SCLK : out std_logic;

        -- Audio
        AUD_ADCDAT  : in    std_logic;
        AUD_ADCLRCK : inout std_logic;
        AUD_BCLK    : inout std_logic;
        AUD_DACDAT  : out   std_logic;
        AUD_DACLRCK : inout std_logic;
        AUD_XCK     : out   std_logic;

        -- CLOCK
        CLOCK_50  : in std_logic;
        CLOCK2_50 : in std_logic;
        CLOCK3_50 : in std_logic;
        CLOCK4_50 : in std_logic;

        -- SDRAM
        DRAM_ADDR  : out   std_logic_vector(12 downto 0);
        DRAM_BA    : out   std_logic_vector(1 downto 0);
        DRAM_CAS_N : out   std_logic;
        DRAM_CKE   : out   std_logic;
        DRAM_CLK   : out   std_logic;
        DRAM_CS_N  : out   std_logic;
        DRAM_DQ    : inout std_logic_vector(15 downto 0);
        DRAM_LDQM  : out   std_logic;
        DRAM_RAS_N : out   std_logic;
        DRAM_UDQM  : out   std_logic;
        DRAM_WE_N  : out   std_logic;

        -- I2C for Audio and Video-In
        FPGA_I2C_SCLK : out   std_logic;
        FPGA_I2C_SDAT : inout std_logic;

        -- SEG7
        HEX0_N : out std_logic_vector(6 downto 0);
        HEX1_N : out std_logic_vector(6 downto 0);
        HEX2_N : out std_logic_vector(6 downto 0);
        HEX3_N : out std_logic_vector(6 downto 0);
        HEX4_N : out std_logic_vector(6 downto 0);
        HEX5_N : out std_logic_vector(6 downto 0);

        -- IR
        IRDA_RXD : in  std_logic;
        IRDA_TXD : out std_logic;

        -- KEY_N
        KEY_N : in std_logic_vector(3 downto 0);

        -- LED
        LEDR : out std_logic_vector(9 downto 0);

        -- PS2
        PS2_CLK  : inout std_logic;
        PS2_CLK2 : inout std_logic;
        PS2_DAT  : inout std_logic;
        PS2_DAT2 : inout std_logic;

        -- SW
        SW : in std_logic_vector(9 downto 0);

        -- Video-In
        TD_CLK27   : inout std_logic;
        TD_DATA    : out   std_logic_vector(7 downto 0);
        TD_HS      : out   std_logic;
        TD_RESET_N : out   std_logic;
        TD_VS      : out   std_logic;

        -- VGA
        VGA_B       : out std_logic_vector(7 downto 0);
        VGA_BLANK_N : out std_logic;
        VGA_CLK     : out std_logic;
        VGA_G       : out std_logic_vector(7 downto 0);
        VGA_HS      : out std_logic;
        VGA_R       : out std_logic_vector(7 downto 0);
        VGA_SYNC_N  : out std_logic;
        VGA_VS      : out std_logic;

        -- GPIO_0
        GPIO_0 : inout std_logic_vector(35 downto 0);

        -- GPIO_1
        GPIO_1 : inout std_logic_vector(35 downto 0)

    );
end entity DE1_SoC_top_level;

architecture rtl of DE1_SoC_top_level is

    component audio_driver is
		port (
			audio_0_avalon_left_channel_sink_data            : in    std_logic_vector(23 downto 0) := (others => 'X'); -- data
			audio_0_avalon_left_channel_sink_valid           : in    std_logic                     := 'X';             -- valid
			audio_0_avalon_left_channel_sink_ready           : out   std_logic;                                        -- ready
			audio_0_avalon_right_channel_sink_data           : in    std_logic_vector(23 downto 0) := (others => 'X'); -- data
			audio_0_avalon_right_channel_sink_valid          : in    std_logic                     := 'X';             -- valid
			audio_0_avalon_right_channel_sink_ready          : out   std_logic;                                        -- ready
			audio_0_clk_clk                                  : in    std_logic                     := 'X';             -- clk
			audio_0_external_interface_BCLK                  : in    std_logic                     := 'X';             -- BCLK
			audio_0_external_interface_DACDAT                : out   std_logic;                                        -- DACDAT
			audio_0_external_interface_DACLRCK               : in    std_logic                     := 'X';             -- DACLRCK
			audio_0_reset_reset                              : in    std_logic                     := 'X';             -- reset
			audio_and_video_config_0_external_interface_SDAT : inout std_logic                     := 'X';             -- SDAT
			audio_and_video_config_0_external_interface_SCLK : out   std_logic;                                        -- SCLK
			audio_pll_0_audio_clk_clk                        : out   std_logic;                                        -- clk
			audio_pll_0_reset_source_reset                   : out   std_logic;                                        -- reset
			clk_clk                                          : in    std_logic                     := 'X';             -- clk
			rst_reset_n                                      : in    std_logic                     := 'X';             -- reset_n
			dc_fifo_0_in_clk_clk                             : in    std_logic                     := 'X';             -- clk
			dc_fifo_0_in_clk_reset_reset_n                   : in    std_logic                     := 'X';             -- reset_n
			dc_fifo_0_out_clk_clk                            : in    std_logic                     := 'X';             -- clk
			dc_fifo_0_out_clk_reset_reset_n                  : in    std_logic                     := 'X';             -- reset_n
			dc_fifo_0_in_data                                : in    std_logic_vector(23 downto 0) := (others => 'X'); -- data
			dc_fifo_0_in_valid                               : in    std_logic                     := 'X';             -- valid
			dc_fifo_0_in_ready                               : out   std_logic;                                        -- ready
			dc_fifo_0_out_data                               : out   std_logic_vector(23 downto 0);                    -- data
			dc_fifo_0_out_valid                              : out   std_logic;                                        -- valid
			dc_fifo_0_out_ready                              : in    std_logic                     := 'X'              -- ready
		);
	end component audio_driver;

    -- LFSR
    signal lfsr_ready : std_logic;
    signal lfsr_ready_fir : std_logic;
    signal lfsr_valid : std_logic;
    signal lfsr_data : std_logic_vector(0 downto 0);
    signal lfsr_raw_data : std_logic_vector(31 downto 0);

    -- FIR
    signal fir_valid : std_logic;
    signal fir_ready : std_logic;
    signal fir_data : sfixed(0 downto -23);

    -- DAC
    signal dac_valid : std_logic;
    signal dac_ready_left : std_logic;
    signal dac_ready_right : std_logic;
    signal dac_data : std_logic_vector(23 downto 0);

    -- Mux
    signal random_counter : std_logic_vector(23 downto 0) := (others => '0');
    signal mux_sel  : std_logic_vector(1 downto 0) := (others => '0');

    -- Reset counter
    signal reset_counter : unsigned(31 downto 0) := to_unsigned(50000000, 32);
    signal rst_n : std_logic := '0';

    -- Audio PLL
    signal audio_clk : std_logic;
    signal audio_rst : std_logic;

    -- Sine gen
    signal sine_valid : std_logic;
    signal sine_ready : std_logic;
    signal sine_data  : std_logic_vector(23 downto 0);

    -- Clock domain crossing fifo
    signal fifo_data_in : std_logic_vector(23 downto 0);
    signal fifo_valid_in : std_logic;
    signal fifo_ready_in : std_logic;

begin

    -- Turn off seven segment display
    HEX0_N <= (others => '1');
    HEX1_N <= (others => '1');
    HEX2_N <= (others => '1');
    HEX3_N <= (others => '1');
    HEX4_N <= (others => '1');
    HEX5_N <= (others => '1');
    
    -- Create mux
    mux_sel <= SW(1 downto 0);
    LEDR(1 downto 0) <= mux_sel;

    -- Set audio clock for wolfson module
    AUD_XCK <= audio_clk;

    -- Set GPIO pins for debugging
    GPIO_1(0) <= FPGA_I2C_SDAT;
    GPIO_1(1) <= FPGA_I2C_SCLK;

    GPIO_1(2) <= dac_valid;
    GPIO_1(3) <= dac_ready_left;
    GPIO_1(4) <= fifo_valid_in;
    GPIO_1(5) <= fifo_ready_in;

    GPIO_1(6) <= AUD_DACLRCK;
    GPIO_1(7) <= rst_n;
	GPIO_1(8) <= KEY_N(0);
    GPIO_1(9) <= audio_clk;
    GPIO_1(10) <= audio_rst;
    GPIO_1(11) <= AUD_XCK;

    LFSR_DUT : entity work.lfsr(rtl)
    generic map (
        SEED => x"DEADBABE"
    )
    port map (
        clk => CLOCK_50,
        rst_n => rst_n,

        ready => lfsr_ready,
        valid => lfsr_valid,
        data => lfsr_data,
        raw_data => lfsr_raw_data
    );

    FIR_DUT : entity work.fir(rtl)
    generic map(
        FIR_LENGTH => 1024
    )
    port map (
        clk => CLOCK_50,
        rst_n => rst_n,

        prev_ready => lfsr_ready_fir,
        prev_valid => lfsr_valid,
        data_in => lfsr_data,

        next_ready => fir_ready,
        next_valid => fir_valid,
        data_out => fir_data
    );

    RANDOM_PROC : process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            random_counter <= std_logic_vector(unsigned(random_counter) + 13);
        end if;
    end process;

    RESET_PROC : process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if reset_counter > 0 then
                reset_counter <= reset_counter - 1;
                rst_n <= '0';
            else
                rst_n <= '1';
            end if;

            if KEY_N(0) = '0' then
                reset_counter <=  to_unsigned(50000000, 32);
            end if;

        end if;
    end process;

    SINE_GEN : entity work.sine(rtl) 
    port map(
        clk => CLOCK_50,
        rst_n => rst_n,

        ready => sine_ready,
        valid => sine_valid,
        data  => sine_data
    );
    

    OUTPUT_PROC : process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            case mux_sel is
            
                when "00" =>
                    fifo_data_in <= sine_data;
                    fifo_valid_in <= sine_valid;
                    sine_ready <= fifo_ready_in;
                when "01" =>                    
                    fifo_data_in <= lfsr_raw_data(23 downto 0);
                    fifo_valid_in <= lfsr_valid;
                    lfsr_ready <= fifo_ready_in;
                when "10" =>
                    fifo_data_in <= std_logic_vector(fir_data);
                    fifo_valid_in <= fir_valid;
                    fir_ready <= fifo_ready_in;
                    lfsr_ready <= lfsr_ready_fir;
                when "11" =>
                    fifo_data_in <= random_counter;
                    fifo_valid_in <= '1';
                when others =>
            
            end case;
        end if;
    end process;


    AUDIO_INST : component audio_driver
        port map (
			audio_0_avalon_left_channel_sink_data            => dac_data,        -- data
			audio_0_avalon_left_channel_sink_valid           => dac_valid,       -- valid
			audio_0_avalon_left_channel_sink_ready           => dac_ready_left,  -- ready
			audio_0_avalon_right_channel_sink_data           => (others => '0'), -- data
			audio_0_avalon_right_channel_sink_valid          => '1',             -- valid
			audio_0_avalon_right_channel_sink_ready          => open,            -- ready
			audio_0_clk_clk                                  => audio_clk,       -- clk
			audio_0_external_interface_BCLK                  => AUD_BCLK,        -- BCLK
			audio_0_external_interface_DACDAT                => AUD_DACDAT,      -- DACDAT
			audio_0_external_interface_DACLRCK               => AUD_DACLRCK,     -- DACLRCK
			audio_0_reset_reset                              => audio_rst,       -- reset
			audio_and_video_config_0_external_interface_SDAT => FPGA_I2C_SDAT,   -- SDAT
			audio_and_video_config_0_external_interface_SCLK => FPGA_I2C_SCLK,   -- SCLK
			audio_pll_0_audio_clk_clk                        => audio_clk,       -- clk
			audio_pll_0_reset_source_reset                   => audio_rst,       -- reset
			clk_clk                                          => CLOCK_50,        -- clk
			rst_reset_n                                      => KEY_N(0),        -- reset_n
			dc_fifo_0_in_clk_clk                             => CLOCK_50,        -- clk
			dc_fifo_0_in_clk_reset_reset_n                   => rst_n,           -- reset_n
			dc_fifo_0_out_clk_clk                            => audio_clk,       -- clk
			dc_fifo_0_out_clk_reset_reset_n                  => rst_n,           -- reset_n
			dc_fifo_0_in_data                                => fifo_data_in,    -- data
			dc_fifo_0_in_valid                               => fifo_valid_in,   -- valid
			dc_fifo_0_in_ready                               => fifo_ready_in,   -- ready
			dc_fifo_0_out_data                               => dac_data,        -- data
			dc_fifo_0_out_valid                              => dac_valid,       -- valid
			dc_fifo_0_out_ready                              => dac_ready_left   -- ready
		);

end;