library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir is
    generic (
        FIR_LENGTH : integer := 256
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        
        prev_ready : out std_logic;
        prev_valid : in std_logic;
        data_in : in std_logic_vector(0 downto 0);

        next_ready : in std_logic;
        next_valid : out std_logic;
        data_out : out std_logic_vector(23 downto 0)
    );
end fir;

architecture rtl of fir is

    type T_STATE is (IDLE, SHIFT_DATA_IN, CALCULATE, HOLD_DATA_OUT);
    signal state : T_STATE := IDLE;

    type T_DATA is array(0 to FIR_LENGTH - 1) of std_logic_vector(0 downto 0); -- 2 bit
    signal delay_line : T_DATA := (others => (others => '0'));
    --signal delay_line : std_logic_vector(0 to FIR_LENGTH - 1) := (others => '0');

    type T_COEFF is array(0 to FIR_LENGTH - 1) of signed(8 downto 0); -- 9 bit
    signal coeff : T_COEFF :=  ('1'&x"90", '0'&x"53", '0'&x"05", '1'&x"A4", '0'&x"6E", '1'&x"CF", '1'&x"CE", '0'&x"6F", '1'&x"A4", '0'&x"04", '0'&x"56", '1'&x"8D", '0'&x"3A", '0'&x"28", '1'&x"91", '0'&x"63", 
                                '1'&x"F0", '1'&x"AF", '0'&x"75", '1'&x"BB", '1'&x"E0", '0'&x"6C", '1'&x"95", '0'&x"19", '0'&x"49", '1'&x"88", '0'&x"4D", '0'&x"15", '1'&x"96", '0'&x"70", '1'&x"DB", '1'&x"BE", 
                                '0'&x"78", '1'&x"A9", '1'&x"F5", '0'&x"64", '1'&x"8A", '0'&x"2F", '0'&x"39", '1'&x"87", '0'&x"5F", '1'&x"FF", '1'&x"A0", '0'&x"79", '1'&x"C5", '1'&x"D0", '0'&x"77", '1'&x"98", 
                                '0'&x"0B", '0'&x"59", '1'&x"83", '0'&x"44", '0'&x"25", '1'&x"8A", '0'&x"6E", '1'&x"E9", '1'&x"AE", '0'&x"7E", '1'&x"B1", '1'&x"E4", '0'&x"71", '1'&x"8B", '0'&x"22", '0'&x"49", 
                                '1'&x"80", '0'&x"58", '0'&x"10", '1'&x"93", '0'&x"7A", '1'&x"D2", '1'&x"BF", '0'&x"7F", '1'&x"9E", '1'&x"FB", '0'&x"67", '1'&x"81", '0'&x"38", '0'&x"36", '1'&x"81", '0'&x"69", 
                                '1'&x"F8", '1'&x"9F", '0'&x"81", '1'&x"BC", '1'&x"D4", '0'&x"7B", '1'&x"8F", '0'&x"13", '0'&x"58", '1'&x"7C", '0'&x"4D", '0'&x"20", '1'&x"88", '0'&x"76", '1'&x"E1", '1'&x"B0", 
                                '0'&x"84", '1'&x"A8", '1'&x"EA", '0'&x"72", '1'&x"83", '0'&x"2A", '0'&x"46", '1'&x"7C", '0'&x"60", '0'&x"09", '1'&x"93", '0'&x"80", '1'&x"CA", '1'&x"C3", '0'&x"82", '1'&x"97", 
                                '0'&x"02", '0'&x"65", '1'&x"7C", '0'&x"40", '0'&x"31", '1'&x"80", '0'&x"6F", '1'&x"F1", '1'&x"A2", '0'&x"84", '1'&x"B5", '1'&x"D9", '0'&x"7B", '1'&x"89", '0'&x"1A", '0'&x"54", 
                                '1'&x"7A", '0'&x"54", '0'&x"1A", '1'&x"89", '0'&x"7B", '1'&x"D9", '1'&x"B5", '0'&x"84", '1'&x"A2", '1'&x"F1", '0'&x"6F", '1'&x"80", '0'&x"31", '0'&x"40", '1'&x"7C", '0'&x"65", 
                                '0'&x"02", '1'&x"97", '0'&x"82", '1'&x"C3", '1'&x"CA", '0'&x"80", '1'&x"93", '0'&x"09", '0'&x"60", '1'&x"7C", '0'&x"46", '0'&x"2A", '1'&x"83", '0'&x"72", '1'&x"EA", '1'&x"A8", 
                                '0'&x"84", '1'&x"B0", '1'&x"E1", '0'&x"76", '1'&x"88", '0'&x"20", '0'&x"4D", '1'&x"7C", '0'&x"58", '0'&x"13", '1'&x"8F", '0'&x"7B", '1'&x"D4", '1'&x"BC", '0'&x"81", '1'&x"9F", 
                                '1'&x"F8", '0'&x"69", '1'&x"81", '0'&x"36", '0'&x"38", '1'&x"81", '0'&x"67", '1'&x"FB", '1'&x"9E", '0'&x"7F", '1'&x"BF", '1'&x"D2", '0'&x"7A", '1'&x"93", '0'&x"10", '0'&x"58", 
                                '1'&x"80", '0'&x"49", '0'&x"22", '1'&x"8B", '0'&x"71", '1'&x"E4", '1'&x"B1", '0'&x"7E", '1'&x"AE", '1'&x"E9", '0'&x"6E", '1'&x"8A", '0'&x"25", '0'&x"44", '1'&x"83", '0'&x"59", 
                                '0'&x"0B", '1'&x"98", '0'&x"77", '1'&x"D0", '1'&x"C5", '0'&x"79", '1'&x"A0", '1'&x"FF", '0'&x"5F", '1'&x"87", '0'&x"39", '0'&x"2F", '1'&x"8A", '0'&x"64", '1'&x"F5", '1'&x"A9", 
                                '0'&x"78", '1'&x"BE", '1'&x"DB", '0'&x"70", '1'&x"96", '0'&x"15", '0'&x"4D", '1'&x"88", '0'&x"49", '0'&x"19", '1'&x"95", '0'&x"6C", '1'&x"E0", '1'&x"BB", '0'&x"75", '1'&x"AF", 
                                '1'&x"F0", '0'&x"63", '1'&x"91", '0'&x"28", '0'&x"3A", '1'&x"8D", '0'&x"56", '0'&x"04", '1'&x"A4", '0'&x"6F", '1'&x"CE", '1'&x"CF", '0'&x"6E", '1'&x"A4", '0'&x"05", '0'&x"53");

    signal accumulator : signed(23 downto 0) := (others => '0');
    

begin

    FIR_PROC : process(clk)

        variable v_prev_ready : std_logic := '0';
        variable v_next_valid : std_logic := '0';
        variable v_accumulator : signed(23 downto 0);

    begin
        
        if rising_edge(clk) then

            -- Default values
            v_prev_ready := '0';
            v_accumulator := (others => '0');
            v_next_valid := '0';
            
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
                    -- What does timing violation mean?
                    for i in 0 to FIR_LENGTH - 1 loop
                        v_accumulator := v_accumulator + (coeff(i) * to_signed(-1, 1) *  signed(delay_line(i)(0 downto 0)));
                        -- Signed delay_line gives -1 and 0 as outputs from LFSR, multiply by -1 to revert this back
                    end loop;

                    accumulator <= v_accumulator;
                    state <= HOLD_DATA_OUT;

                -------------------------------
                when HOLD_DATA_OUT =>
                    -------------------------------
                    v_next_valid := '1';

                    data_out <= std_logic_vector(accumulator);
                    
                    if next_ready = '1' then
                        v_next_valid := '0';
                        state <= IDLE;
                    end if;

            end case;

            prev_ready <= v_prev_ready;
            next_valid <= v_next_valid;

        end if;
        
    end process;

end architecture;