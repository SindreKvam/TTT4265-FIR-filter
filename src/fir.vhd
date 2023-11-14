library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all; -- ieee_proposed for VHDL-93 version
use ieee_proposed.fixed_pkg.all; -- ieee_proposed for compatibility version

entity fir is
    generic (
        FIR_LENGTH : integer
    );
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        prev_ready : out std_logic;
        prev_valid : in std_logic;
        data_in : in std_logic_vector(0 downto 0);

        next_ready : in std_logic;
        next_valid : out std_logic;
        data_out : out sfixed(11 downto -12)
    );
end fir;

architecture rtl of fir is

    type T_STATE is (IDLE, SHIFT_DATA_IN, CALCULATE, HOLD_DATA_OUT);
    signal state : T_STATE := IDLE;

    type T_DATA is array(0 to FIR_LENGTH - 1) of std_logic_vector(0 downto 0); -- 1 bit
    signal delay_line : T_DATA := (others => (others => '0'));

    type T_COEFF is array(0 to FIR_LENGTH - 1) of sfixed(5 downto -16); -- 22 bit
    signal coeff : T_COEFF :=  ("11"&x"21D32", "00"&x"A6B9C", "00"&x"0B968", "11"&x"49A09", "00"&x"DC0BE", "11"&x"9FCF9", "11"&x"9CF74", "00"&x"DE835", "11"&x"48E42", "00"&x"08ECB", "00"&x"ACB90", "11"&x"1BA10", "00"&x"747A2", "00"&x"51936", "11"&x"2353B", "00"&x"C64D5", 
                                "11"&x"E1E47", "11"&x"5EF97", "00"&x"EAC26", "11"&x"77A59", "11"&x"C14CD", "00"&x"D89D1", "11"&x"2BE8D", "00"&x"33BA2", "00"&x"935CD", "11"&x"10EAE", "00"&x"9B91E", "00"&x"2A977", "11"&x"2DAD3", "00"&x"E0460", "11"&x"B675D", "11"&x"7C280", 
                                "00"&x"F13C1", "11"&x"521DB", "11"&x"EA8B3", "00"&x"C9D1C", "11"&x"15551", "00"&x"5F4B5", "00"&x"729AC", "11"&x"0EDC8", "00"&x"BF0F3", "11"&x"FF842", "11"&x"40D9D", "00"&x"F31C3", "11"&x"8B43A", "11"&x"A0314", "00"&x"EEBE9", "11"&x"3120E",
                                "00"&x"16FDD", "00"&x"B263A", "11"&x"0689E", "00"&x"899BF", "00"&x"4BA31", "11"&x"15F78", "00"&x"DD1BF", "11"&x"D22E6", "11"&x"5C5AD", "00"&x"FD9B4", "11"&x"62563", "11"&x"C9B37", "00"&x"E3038", "11"&x"166B8", "00"&x"44B57", "00"&x"930CD",
                                "11"&x"008A7", "00"&x"B0A75", "00"&x"20046", "11"&x"2645B", "00"&x"F41C7", "11"&x"A4993", "11"&x"7F3CA", "00"&x"FEF5C", "11"&x"3DA72", "11"&x"F6F82", "00"&x"CE3ED", "11"&x"03726", "00"&x"71A2C", "00"&x"6CF77", "11"&x"03EB1", "00"&x"D2861",
                                "11"&x"F1971", "11"&x"3F554", "01"&x"02C84", "11"&x"78D8A", "11"&x"A8227", "00"&x"F6D34", "11"&x"1F049", "00"&x"260B6", "00"&x"B11EB", "10"&x"F94C4", "00"&x"9BB44", "00"&x"41AEC", "11"&x"10C68", "00"&x"ED8A5", "11"&x"C263E", "11"&x"603D9",
                                "01"&x"083EA", "11"&x"50F40", "11"&x"D557C", "00"&x"E557A", "11"&x"07F5A", "00"&x"54D70", "00"&x"8CC3A", "10"&x"F8A07", "00"&x"C0F45", "00"&x"130A4", "11"&x"26BA6", "01"&x"00594", "11"&x"9486E", "11"&x"87AA1", "01"&x"0414A", "11"&x"2EC84", 
                                "00"&x"04E86", "00"&x"CB227", "10"&x"F9A3C", "00"&x"8140A", "00"&x"62B1A", "11"&x"019BB", "00"&x"DFA58", "11"&x"E3143", "11"&x"44EB9", "01"&x"09FF7", "11"&x"6A113", "11"&x"B3EC7", "00"&x"F65C8", "11"&x"13ECC", "00"&x"34BB7", "00"&x"A947B",
                                "10"&x"F4C8C", "00"&x"A947B", "00"&x"34BB7", "11"&x"13ECC", "00"&x"F65C8", "11"&x"B3EC7", "11"&x"6A113", "01"&x"09FF7", "11"&x"44EB9", "11"&x"E3143", "00"&x"DFA58", "11"&x"019BB", "00"&x"62B1A", "00"&x"8140A", "10"&x"F9A3C", "00"&x"CB227",
                                "00"&x"04E86", "11"&x"2EC84", "01"&x"0414A", "11"&x"87AA1", "11"&x"9486E", "01"&x"00594", "11"&x"26BA6", "00"&x"130A4", "00"&x"C0F45", "10"&x"F8A07", "00"&x"8CC3A", "00"&x"54D70", "11"&x"07F5A", "00"&x"E557A", "11"&x"D557C", "11"&x"50F40",
                                "01"&x"083EA", "11"&x"603D9", "11"&x"C263E", "00"&x"ED8A5", "11"&x"10C68", "00"&x"41AEC", "00"&x"9BB44", "10"&x"F94C4", "00"&x"B11EB", "00"&x"260B6", "11"&x"1F049", "00"&x"F6D34", "11"&x"A8227", "11"&x"78D8A", "01"&x"02C84", "11"&x"3F554",
                                "11"&x"F1971", "00"&x"D2861", "11"&x"03EB1", "00"&x"6CF77", "00"&x"71A2C", "11"&x"03726", "00"&x"CE3ED", "11"&x"F6F82", "11"&x"3DA72", "00"&x"FEF5C", "11"&x"7F3CA", "11"&x"A4993", "00"&x"F41C7", "11"&x"2645B", "00"&x"20046", "00"&x"B0A75", 
                                "11"&x"008A7", "00"&x"930CD", "00"&x"44B57", "11"&x"166B8", "00"&x"E3038", "11"&x"C9B37", "11"&x"62563", "00"&x"FD9B4", "11"&x"5C5AD", "11"&x"D22E6", "00"&x"DD1BF", "11"&x"15F78", "00"&x"4BA31", "00"&x"899BF", "11"&x"0689E", "00"&x"B263A",
                                "00"&x"16FDD", "11"&x"3120E", "00"&x"EEBE9", "11"&x"A0314", "11"&x"8B43A", "00"&x"F31C3", "11"&x"40D9D", "11"&x"FF842", "00"&x"BF0F3", "11"&x"0EDC8", "00"&x"729AC", "00"&x"5F4B5", "11"&x"15551", "00"&x"C9D1C", "11"&x"EA8B3", "11"&x"521DB",
                                "00"&x"F13C1", "11"&x"7C280", "11"&x"B675D", "00"&x"E0460", "11"&x"2DAD3", "00"&x"2A977", "00"&x"9B91E", "11"&x"10EAE", "00"&x"935CD", "00"&x"33BA2", "11"&x"2BE8D", "00"&x"D89D1", "11"&x"C14CD", "11"&x"77A59", "00"&x"EAC26", "11"&x"5EF97",
                                "11"&x"E1E47", "00"&x"C64D5", "11"&x"2353B", "00"&x"51936", "00"&x"747A2", "11"&x"1BA10", "00"&x"ACB90", "00"&x"08ECB", "11"&x"48E42", "00"&x"DE835", "11"&x"9CF74", "11"&x"9FCF9", "00"&x"DC0BE", "11"&x"49A09", "00"&x"0B968", "00"&x"A6B9C");

    signal accumulator : sfixed(11 downto -12) := (others => '0');
    -- 12 bit because max sum is 1286.28
    --signal accumulator : signed(23 downto 0) := (others => '0');
    signal sfixed_data_in : sfixed(0 downto 0) := (others => '0');

    signal tap_counter : unsigned(11 downto 0) := (others => '0');
    

begin

    FIR_PROC : process(clk)

        variable v_prev_ready : std_logic := '0';
        variable v_next_valid : std_logic := '0';
        variable v_index : integer range 0 to FIR_LENGTH * 2 - 1 := 0;
        variable v_coeff : sfixed(5 downto -16);
        variable v_delay_line : sfixed(0 downto 0);
        variable v_mult_result : sfixed(10 downto -12);

    begin
        
        if rising_edge(clk) then

            -- Default values
            v_prev_ready := '0';
            v_next_valid := '0';

            if rst_n = '0' then

                state <= IDLE;
                
            else
                
                case state is

                    -------------------------------
                    when IDLE =>
                        -------------------------------
                        v_prev_ready := '1';

                        if prev_valid = '1' then
                            state <= SHIFT_DATA_IN;
                            v_prev_ready := '0';
                        end if;

                    -------------------------------
                    when SHIFT_DATA_IN =>
                        -------------------------------
                        delay_line <= data_in & delay_line(delay_line'low to delay_line'high - 1);

                        -- Get accumulator ready
                        accumulator <=  (others => '0');
                        state <= CALCULATE;


                    -------------------------------
                    when CALCULATE =>
                        -------------------------------

                        v_index := to_integer(tap_counter);

                        v_coeff := coeff(v_index);
                        v_delay_line := to_sfixed(delay_line(v_index)(0 downto 0), v_delay_line);

                        v_mult_result := resize(v_coeff * v_delay_line, v_mult_result);


                        accumulator <= resize(accumulator + v_mult_result, accumulator); --signed(-1, 1)

                        if (tap_counter < FIR_LENGTH - 1) then
                            tap_counter <= tap_counter + 1;
                        else
                            tap_counter <= (others => '0');
                            state <= HOLD_DATA_OUT;
                        end if;

                    -------------------------------
                    when HOLD_DATA_OUT =>
                        -------------------------------
                        v_next_valid := '1';

                        data_out <= accumulator;
                        
                        if next_ready = '1' then
                            state <= IDLE;
                        end if;

                end case;

            end if;

            prev_ready <= v_prev_ready;
            next_valid <= v_next_valid;

        end if;
        
    end process;

end architecture;