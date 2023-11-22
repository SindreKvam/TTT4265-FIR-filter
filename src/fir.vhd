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
        data_out : out sfixed(0 downto -23)
    );
end fir;

architecture rtl of fir is

    type T_STATE is (IDLE, SHIFT_DATA_IN, CALCULATE, HOLD_DATA_OUT);
    signal state : T_STATE := IDLE;

    type T_DATA is array(0 to FIR_LENGTH - 1) of std_logic_vector(0 downto 0); -- 1 bit
    signal delay_line : T_DATA := (others => (others => '0'));

    type T_COEFF is array(0 to FIR_LENGTH - 1) of sfixed(0 downto -21); -- 22 bit
    signal coeff : T_COEFF :=  ("00"&x"002FF", "11"&x"FF937", "00"&x"005A8", "11"&x"FFF84", "11"&x"FFB02", "00"&x"006D3", "11"&x"FFC42", "11"&x"FFDFF", "00"&x"0063E", "11"&x"FFA0A", "00"&x"00166", "00"&x"0041D", "11"&x"FF963", "00"&x"00455", "00"&x"00106", "11"&x"FFA6A", 
                                "00"&x"00614", "11"&x"FFDCA", "11"&x"FFCCD", "00"&x"0063D", "11"&x"FFB3B", "11"&x"FFFE5", "00"&x"004D4", "11"&x"FF9F8", "00"&x"002E3", "00"&x"00246", "11"&x"FFA44", "00"&x"00507", "11"&x"FFF43", "11"&x"FFBFC", "00"&x"005D0", "11"&x"FFC94", 
                                "11"&x"FFE9E", "00"&x"0051C", "11"&x"FFAE1", "00"&x"00176", "00"&x"0032B", "11"&x"FFA8C", "00"&x"003CA", "00"&x"0008C", "11"&x"FFB97", "00"&x"00509", "11"&x"FFDF1", "11"&x"FFDAB", "00"&x"004F5", "11"&x"FFC02", "00"&x"00031", "00"&x"003A7", 
                                "11"&x"FFB32", "00"&x"0027F", "00"&x"00187", "11"&x"FFBA2", "00"&x"00404", "11"&x"FFF2F", "11"&x"FFD1D", "00"&x"0046D", "11"&x"FFD39", "11"&x"FFF32", "00"&x"003B4", "11"&x"FFC1D", "00"&x"0014B", "00"&x"00222", "11"&x"FFC10", "00"&x"002E2", 
                                "00"&x"0002E", "11"&x"FFCFD", "00"&x"0039A", "11"&x"FFE61", "11"&x"FFE90", "00"&x"0035B", "11"&x"FFD2C", "00"&x"00050", "00"&x"00250", "11"&x"FFCCE", "00"&x"001C7", "00"&x"000D4", "11"&x"FFD45", "00"&x"0029C", "11"&x"FFF56", "11"&x"FFE58", 
                                "00"&x"002AE", "11"&x"FFE3B", "11"&x"FFFAA", "00"&x"00214", "11"&x"FFDBD", "00"&x"000D8", "00"&x"00110", "11"&x"FFDE6", "00"&x"00198", "11"&x"FFFFB", "11"&x"FFE8C", "00"&x"001C9", "11"&x"FFF24", "11"&x"FFF6B", "00"&x"0017B", "11"&x"FFEBA", 
                                "00"&x"00035", "00"&x"000E0", "11"&x"FFEC4", "00"&x"000B3", "00"&x"0003A", "11"&x"FFF22", "00"&x"000D0", "11"&x"FFFC5", "11"&x"FFF9B", "00"&x"0009E", "11"&x"FFF9E", "11"&x"FFFF7", "00"&x"00049", "11"&x"FFFBE", "00"&x"00012", "00"&x"00009", 
                                "00"&x"00002", "11"&x"FFFEA", "00"&x"00003", "00"&x"00035", "11"&x"FFF9F", "00"&x"00041", "00"&x"0002B", "11"&x"FFF62", "00"&x"000AB", "11"&x"FFFD3", "11"&x"FFF68", "00"&x"0010C", "11"&x"FFF3F", "11"&x"FFFCC", "00"&x"00128", "11"&x"FFEA5", 
                                "00"&x"00085", "00"&x"000D4", "11"&x"FFE48", "00"&x"00163", "00"&x"0000B", "11"&x"FFE67", "00"&x"00218", "11"&x"FFEF3", "11"&x"FFF1B", "00"&x"00255", "11"&x"FFDDC", "00"&x"00050", "00"&x"001E5", "11"&x"FFD25", "00"&x"001BE", "00"&x"000C1", 
                                "11"&x"FFD21", "00"&x"002FA", "11"&x"FFF21", "11"&x"FFDFA", "00"&x"00396", "11"&x"FFD6B", "11"&x"FFF96", "00"&x"00345", "11"&x"FFC23", "00"&x"0019D", "00"&x"001F2", "11"&x"FFBBE", "00"&x"00387", "11"&x"FFFD9", "11"&x"FFC7F", "00"&x"004BE", 
                                "11"&x"FFD77", "11"&x"FFE59", "00"&x"004CE", "11"&x"FFB72", "00"&x"000ED", "00"&x"00389", "11"&x"FFA6B", "00"&x"00398", "00"&x"0011E", "11"&x"FFACD", "00"&x"0059B", "11"&x"FFE17", "11"&x"FFCA9", "00"&x"00652", "11"&x"FFB3B", "11"&x"FFFA6", 
                                "00"&x"00564", "11"&x"FF959", "00"&x"00310", "00"&x"002E4", "11"&x"FF912", "00"&x"00602", "11"&x"FFF58", "11"&x"FFAA5", "00"&x"007A0", "11"&x"FFB9F", "11"&x"FFDD1", "00"&x"00757", "11"&x"FF8B9", "00"&x"001E0", "00"&x"0050D", "11"&x"FF784", 
                                "00"&x"005CC", "00"&x"00135", "11"&x"FF879", "00"&x"00882", "11"&x"FFCB4", "11"&x"FFB86", "00"&x"0092C", "11"&x"FF8B6", "00"&x"00005", "00"&x"00771", "11"&x"FF657", "00"&x"004DE", "00"&x"00399", "11"&x"FF65A", "00"&x"008CA", "11"&x"FFE81", 
                                "11"&x"FF8EE", "00"&x"00AAB", "11"&x"FF970", "11"&x"FFD91", "00"&x"009DB", "11"&x"FF5BF", "00"&x"0032C", "00"&x"00661", "11"&x"FF483", "00"&x"00852", "00"&x"000FB", "11"&x"FF63B", "00"&x"00B9C", "11"&x"FFAF9", "11"&x"FFAA2", "00"&x"00C0D", 
                                "11"&x"FF5E9", "00"&x"000BA", "00"&x"00959", "11"&x"FF330", "00"&x"00700", "00"&x"00405", "11"&x"FF3AC", "00"&x"00BCE", "11"&x"FFD53", "11"&x"FF76B", "00"&x"00DCA", "11"&x"FF6F2", "11"&x"FFDA2", "00"&x"00C44", "11"&x"FF296", "00"&x"004CE", 
                                "00"&x"00772", "11"&x"FF181", "00"&x"00B1C", "00"&x"0006B", "11"&x"FF428", "00"&x"00ED5", "11"&x"FF8EB", "11"&x"FFA0B", "00"&x"00EDF", "11"&x"FF2E3", "00"&x"001C8", "00"&x"00B06", "11"&x"FEFFB", "00"&x"0096E", "00"&x"0041D", "11"&x"FF11E", 
                                "00"&x"00EFD", "11"&x"FFBCE", "11"&x"FF62F", "00"&x"010E5", "11"&x"FF433", "11"&x"FFE0B", "00"&x"00E7D", "11"&x"FEF54", "00"&x"006C3", "00"&x"00834", "11"&x"FEE94", "00"&x"00E1A", "11"&x"FFF82", "11"&x"FF254", "00"&x"01217", "11"&x"FF693", 
                                "11"&x"FF9CA", "00"&x"0118A", "11"&x"FEFB8", "00"&x"0032B", "00"&x"00C6A", "11"&x"FECD0", "00"&x"00C1A", "00"&x"003DC", "11"&x"FEEC6", "00"&x"0123F", "11"&x"FF9F8", "11"&x"FF547", "00"&x"013E4", "11"&x"FF144", "11"&x"FFECE", "00"&x"01071", 
                                "11"&x"FEC0F", "00"&x"008FF", "00"&x"0089B", "11"&x"FEBD4", "00"&x"01139", "11"&x"FFE42", "11"&x"FF0D0", "00"&x"01548", "11"&x"FF400", "11"&x"FF9E6", "00"&x"013F9", "11"&x"FEC7E", "00"&x"004E0", "00"&x"00D74", "11"&x"FE9C7", "00"&x"00EF4", 
                                "00"&x"0033D", "11"&x"FECB9", "00"&x"0157F", "11"&x"FF7DB", "11"&x"FF4BD", "00"&x"016B1", "11"&x"FEE38", "11"&x"FFFEB", "00"&x"01210", "11"&x"FE8E0", "00"&x"00B75", "00"&x"008A1", "11"&x"FE957", "00"&x"01463", "11"&x"FFCB0", "11"&x"FEFAA", 
                                "00"&x"01851", "11"&x"FF141", "11"&x"FFA62", "00"&x"01617", "11"&x"FE94C", "00"&x"006DB", "00"&x"00E1A", "11"&x"FE6F9", "00"&x"011E7", "00"&x"00243", "11"&x"FEB08", "00"&x"018A2", "11"&x"FF586", "11"&x"FF499", "00"&x"01933", "11"&x"FEB25", 
                                "00"&x"0015A", "00"&x"0134A", "11"&x"FE5E0", "00"&x"00E14", "00"&x"00844", "11"&x"FE732", "00"&x"01780", "11"&x"FFAD8", "11"&x"FEEED", "00"&x"01B1A", "11"&x"FEE6C", "11"&x"FFB3C", "00"&x"017D2", "11"&x"FE63B", "00"&x"0090E", "00"&x"00E56", 
                                "11"&x"FE47A", "00"&x"014DD", "00"&x"000F4", "11"&x"FE9C1", "00"&x"01B92", "11"&x"FF308", "11"&x"FF4DD", "00"&x"01B57", "11"&x"FE824", "00"&x"00312", "00"&x"01415", "11"&x"FE326", "00"&x"010C8", "00"&x"00785", "11"&x"FE575", "00"&x"01A77", 
                                "11"&x"FF8C5", "11"&x"FEEA1", "00"&x"01D8C", "11"&x"FEB97", "11"&x"FFC6F", "00"&x"0191C", "11"&x"FE364", "00"&x"00B6A", "00"&x"00E25", "11"&x"FE260", "00"&x"017BF", "11"&x"FFF5A", "11"&x"FE8F0", "00"&x"01E36", "11"&x"FF076", "11"&x"FF587", 
                                "00"&x"01D0B", "11"&x"FE54B", "00"&x"00504", "00"&x"0146B", "11"&x"FE0C8", "00"&x"0137B", "00"&x"0066A", "11"&x"FE430", "00"&x"01D31", "11"&x"FF68B", "11"&x"FEEC6", "00"&x"01F94", "11"&x"FE8D8", "11"&x"FFDEF", "00"&x"019EB", "11"&x"FE0DD", 
                                "00"&x"00DD9", "00"&x"00D8A", "11"&x"FE0BB", "00"&x"01A74", "11"&x"FFD84", "11"&x"FE89A", "00"&x"02078", "11"&x"FEDE7", "11"&x"FF690", "00"&x"01E43", "11"&x"FE2B4", "00"&x"00721", "00"&x"01449", "11"&x"FDED9", "00"&x"01616", "00"&x"004FE", 
                                "11"&x"FE36C", "00"&x"01F96", "11"&x"FF43B", "11"&x"FEF5A", "00"&x"02121", "11"&x"FE647", "11"&x"FFFAE", "00"&x"01A3A", "11"&x"FDEBB", "00"&x"01047", "00"&x"00C8B", "11"&x"FDF99", "00"&x"01CE7", "11"&x"FFB81", "11"&x"FE8BF", "00"&x"02247", 
                                "11"&x"FEB6F", "11"&x"FF7EE", "00"&x"01EF5", "11"&x"FE074", "00"&x"00953", "00"&x"013B4", "11"&x"FDD6A", "00"&x"01882", "00"&x"00350", "11"&x"FE32D", "00"&x"02193", "11"&x"FF1ED", "11"&x"FF057", "00"&x"02227", "11"&x"FE3FB", "00"&x"0019D", 
                                "00"&x"01A07", "11"&x"FDD10", "00"&x"0129D", "00"&x"00B33", "11"&x"FDF01", "00"&x"01F00", "11"&x"FF966", "11"&x"FE95E", "00"&x"02393", "11"&x"FE927", "11"&x"FF993", "00"&x"01F1D", "11"&x"FDE9F", "00"&x"00B87", "00"&x"012B1", "11"&x"FDC86", 
                                "00"&x"01AA8", "00"&x"0016F", "11"&x"FE373", "00"&x"02315", "11"&x"FEFB5", "11"&x"FF1B1", "00"&x"0229F", "11"&x"FE209", "00"&x"003A6", "00"&x"01957", "11"&x"FDBEC", "00"&x"014C4", "00"&x"00990", "11"&x"FDEF7", "00"&x"020AC", "11"&x"FF748", 
                                "11"&x"FEA6E", "00"&x"02451", "11"&x"FE725", "11"&x"FFB6D", "00"&x"01EBB", "11"&x"FDD45", "00"&x"00DA6", "00"&x"0114E", "11"&x"FDC33", "00"&x"01C74", "11"&x"FFF70", "11"&x"FE43B", "00"&x"02411", "11"&x"FEDAB", "11"&x"FF358", "00"&x"02286", 
                                "11"&x"FE084", "00"&x"005B5", "00"&x"01833", "11"&x"FDB57", "00"&x"016A7", "00"&x"007B5", "11"&x"FDF7A", "00"&x"021DD", "11"&x"FF53C", "11"&x"FEBE2", "00"&x"0247B", "11"&x"FE57B", "11"&x"FFD69", "00"&x"01DD5", "11"&x"FDC74", "00"&x"00F9A", 
                                "00"&x"00F9A", "11"&x"FDC74", "00"&x"01DD5", "11"&x"FFD69", "11"&x"FE57B", "00"&x"0247B", "11"&x"FEBE2", "11"&x"FF53C", "00"&x"021DD", "11"&x"FDF7A", "00"&x"007B5", "00"&x"016A7", "11"&x"FDB57", "00"&x"01833", "00"&x"005B5", "11"&x"FE084", 
                                "00"&x"02286", "11"&x"FF358", "11"&x"FEDAB", "00"&x"02411", "11"&x"FE43B", "11"&x"FFF70", "00"&x"01C74", "11"&x"FDC33", "00"&x"0114E", "00"&x"00DA6", "11"&x"FDD45", "00"&x"01EBB", "11"&x"FFB6D", "11"&x"FE725", "00"&x"02451", "11"&x"FEA6E", 
                                "11"&x"FF748", "00"&x"020AC", "11"&x"FDEF7", "00"&x"00990", "00"&x"014C4", "11"&x"FDBEC", "00"&x"01957", "00"&x"003A6", "11"&x"FE209", "00"&x"0229F", "11"&x"FF1B1", "11"&x"FEFB5", "00"&x"02315", "11"&x"FE373", "00"&x"0016F", "00"&x"01AA8", 
                                "11"&x"FDC86", "00"&x"012B1", "00"&x"00B87", "11"&x"FDE9F", "00"&x"01F1D", "11"&x"FF993", "11"&x"FE927", "00"&x"02393", "11"&x"FE95E", "11"&x"FF966", "00"&x"01F00", "11"&x"FDF01", "00"&x"00B33", "00"&x"0129D", "11"&x"FDD10", "00"&x"01A07", 
                                "00"&x"0019D", "11"&x"FE3FB", "00"&x"02227", "11"&x"FF057", "11"&x"FF1ED", "00"&x"02193", "11"&x"FE32D", "00"&x"00350", "00"&x"01882", "11"&x"FDD6A", "00"&x"013B4", "00"&x"00953", "11"&x"FE074", "00"&x"01EF5", "11"&x"FF7EE", "11"&x"FEB6F", 
                                "00"&x"02247", "11"&x"FE8BF", "11"&x"FFB81", "00"&x"01CE7", "11"&x"FDF99", "00"&x"00C8B", "00"&x"01047", "11"&x"FDEBB", "00"&x"01A3A", "11"&x"FFFAE", "11"&x"FE647", "00"&x"02121", "11"&x"FEF5A", "11"&x"FF43B", "00"&x"01F96", "11"&x"FE36C", 
                                "00"&x"004FE", "00"&x"01616", "11"&x"FDED9", "00"&x"01449", "00"&x"00721", "11"&x"FE2B4", "00"&x"01E43", "11"&x"FF690", "11"&x"FEDE7", "00"&x"02078", "11"&x"FE89A", "11"&x"FFD84", "00"&x"01A74", "11"&x"FE0BB", "00"&x"00D8A", "00"&x"00DD9", 
                                "11"&x"FE0DD", "00"&x"019EB", "11"&x"FFDEF", "11"&x"FE8D8", "00"&x"01F94", "11"&x"FEEC6", "11"&x"FF68B", "00"&x"01D31", "11"&x"FE430", "00"&x"0066A", "00"&x"0137B", "11"&x"FE0C8", "00"&x"0146B", "00"&x"00504", "11"&x"FE54B", "00"&x"01D0B", 
                                "11"&x"FF587", "11"&x"FF076", "00"&x"01E36", "11"&x"FE8F0", "11"&x"FFF5A", "00"&x"017BF", "11"&x"FE260", "00"&x"00E25", "00"&x"00B6A", "11"&x"FE364", "00"&x"0191C", "11"&x"FFC6F", "11"&x"FEB97", "00"&x"01D8C", "11"&x"FEEA1", "11"&x"FF8C5", 
                                "00"&x"01A77", "11"&x"FE575", "00"&x"00785", "00"&x"010C8", "11"&x"FE326", "00"&x"01415", "00"&x"00312", "11"&x"FE824", "00"&x"01B57", "11"&x"FF4DD", "11"&x"FF308", "00"&x"01B92", "11"&x"FE9C1", "00"&x"000F4", "00"&x"014DD", "11"&x"FE47A", 
                                "00"&x"00E56", "00"&x"0090E", "11"&x"FE63B", "00"&x"017D2", "11"&x"FFB3C", "11"&x"FEE6C", "00"&x"01B1A", "11"&x"FEEED", "11"&x"FFAD8", "00"&x"01780", "11"&x"FE732", "00"&x"00844", "00"&x"00E14", "11"&x"FE5E0", "00"&x"0134A", "00"&x"0015A", 
                                "11"&x"FEB25", "00"&x"01933", "11"&x"FF499", "11"&x"FF586", "00"&x"018A2", "11"&x"FEB08", "00"&x"00243", "00"&x"011E7", "11"&x"FE6F9", "00"&x"00E1A", "00"&x"006DB", "11"&x"FE94C", "00"&x"01617", "11"&x"FFA62", "11"&x"FF141", "00"&x"01851", 
                                "11"&x"FEFAA", "11"&x"FFCB0", "00"&x"01463", "11"&x"FE957", "00"&x"008A1", "00"&x"00B75", "11"&x"FE8E0", "00"&x"01210", "11"&x"FFFEB", "11"&x"FEE38", "00"&x"016B1", "11"&x"FF4BD", "11"&x"FF7DB", "00"&x"0157F", "11"&x"FECB9", "00"&x"0033D", 
                                "00"&x"00EF4", "11"&x"FE9C7", "00"&x"00D74", "00"&x"004E0", "11"&x"FEC7E", "00"&x"013F9", "11"&x"FF9E6", "11"&x"FF400", "00"&x"01548", "11"&x"FF0D0", "11"&x"FFE42", "00"&x"01139", "11"&x"FEBD4", "00"&x"0089B", "00"&x"008FF", "11"&x"FEC0F", 
                                "00"&x"01071", "11"&x"FFECE", "11"&x"FF144", "00"&x"013E4", "11"&x"FF547", "11"&x"FF9F8", "00"&x"0123F", "11"&x"FEEC6", "00"&x"003DC", "00"&x"00C1A", "11"&x"FECD0", "00"&x"00C6A", "00"&x"0032B", "11"&x"FEFB8", "00"&x"0118A", "11"&x"FF9CA", 
                                "11"&x"FF693", "00"&x"01217", "11"&x"FF254", "11"&x"FFF82", "00"&x"00E1A", "11"&x"FEE94", "00"&x"00834", "00"&x"006C3", "11"&x"FEF54", "00"&x"00E7D", "11"&x"FFE0B", "11"&x"FF433", "00"&x"010E5", "11"&x"FF62F", "11"&x"FFBCE", "00"&x"00EFD", 
                                "11"&x"FF11E", "00"&x"0041D", "00"&x"0096E", "11"&x"FEFFB", "00"&x"00B06", "00"&x"001C8", "11"&x"FF2E3", "00"&x"00EDF", "11"&x"FFA0B", "11"&x"FF8EB", "00"&x"00ED5", "11"&x"FF428", "00"&x"0006B", "00"&x"00B1C", "11"&x"FF181", "00"&x"00772", 
                                "00"&x"004CE", "11"&x"FF296", "00"&x"00C44", "11"&x"FFDA2", "11"&x"FF6F2", "00"&x"00DCA", "11"&x"FF76B", "11"&x"FFD53", "00"&x"00BCE", "11"&x"FF3AC", "00"&x"00405", "00"&x"00700", "11"&x"FF330", "00"&x"00959", "00"&x"000BA", "11"&x"FF5E9", 
                                "00"&x"00C0D", "11"&x"FFAA2", "11"&x"FFAF9", "00"&x"00B9C", "11"&x"FF63B", "00"&x"000FB", "00"&x"00852", "11"&x"FF483", "00"&x"00661", "00"&x"0032C", "11"&x"FF5BF", "00"&x"009DB", "11"&x"FFD91", "11"&x"FF970", "00"&x"00AAB", "11"&x"FF8EE", 
                                "11"&x"FFE81", "00"&x"008CA", "11"&x"FF65A", "00"&x"00399", "00"&x"004DE", "11"&x"FF657", "00"&x"00771", "00"&x"00005", "11"&x"FF8B6", "00"&x"0092C", "11"&x"FFB86", "11"&x"FFCB4", "00"&x"00882", "11"&x"FF879", "00"&x"00135", "00"&x"005CC", 
                                "11"&x"FF784", "00"&x"0050D", "00"&x"001E0", "11"&x"FF8B9", "00"&x"00757", "11"&x"FFDD1", "11"&x"FFB9F", "00"&x"007A0", "11"&x"FFAA5", "11"&x"FFF58", "00"&x"00602", "11"&x"FF912", "00"&x"002E4", "00"&x"00310", "11"&x"FF959", "00"&x"00564", 
                                "11"&x"FFFA6", "11"&x"FFB3B", "00"&x"00652", "11"&x"FFCA9", "11"&x"FFE17", "00"&x"0059B", "11"&x"FFACD", "00"&x"0011E", "00"&x"00398", "11"&x"FFA6B", "00"&x"00389", "00"&x"000ED", "11"&x"FFB72", "00"&x"004CE", "11"&x"FFE59", "11"&x"FFD77", 
                                "00"&x"004BE", "11"&x"FFC7F", "11"&x"FFFD9", "00"&x"00387", "11"&x"FFBBE", "00"&x"001F2", "00"&x"0019D", "11"&x"FFC23", "00"&x"00345", "11"&x"FFF96", "11"&x"FFD6B", "00"&x"00396", "11"&x"FFDFA", "11"&x"FFF21", "00"&x"002FA", "11"&x"FFD21", 
                                "00"&x"000C1", "00"&x"001BE", "11"&x"FFD25", "00"&x"001E5", "00"&x"00050", "11"&x"FFDDC", "00"&x"00255", "11"&x"FFF1B", "11"&x"FFEF3", "00"&x"00218", "11"&x"FFE67", "00"&x"0000B", "00"&x"00163", "11"&x"FFE48", "00"&x"000D4", "00"&x"00085", 
                                "11"&x"FFEA5", "00"&x"00128", "11"&x"FFFCC", "11"&x"FFF3F", "00"&x"0010C", "11"&x"FFF68", "11"&x"FFFD3", "00"&x"000AB", "11"&x"FFF62", "00"&x"0002B", "00"&x"00041", "11"&x"FFF9F", "00"&x"00035", "00"&x"00003", "11"&x"FFFEA", "00"&x"00002", 
                                "00"&x"00009", "00"&x"00012", "11"&x"FFFBE", "00"&x"00049", "11"&x"FFFF7", "11"&x"FFF9E", "00"&x"0009E", "11"&x"FFF9B", "11"&x"FFFC5", "00"&x"000D0", "11"&x"FFF22", "00"&x"0003A", "00"&x"000B3", "11"&x"FFEC4", "00"&x"000E0", "00"&x"00035", 
                                "11"&x"FFEBA", "00"&x"0017B", "11"&x"FFF6B", "11"&x"FFF24", "00"&x"001C9", "11"&x"FFE8C", "11"&x"FFFFB", "00"&x"00198", "11"&x"FFDE6", "00"&x"00110", "00"&x"000D8", "11"&x"FFDBD", "00"&x"00214", "11"&x"FFFAA", "11"&x"FFE3B", "00"&x"002AE", 
                                "11"&x"FFE58", "11"&x"FFF56", "00"&x"0029C", "11"&x"FFD45", "00"&x"000D4", "00"&x"001C7", "11"&x"FFCCE", "00"&x"00250", "00"&x"00050", "11"&x"FFD2C", "00"&x"0035B", "11"&x"FFE90", "11"&x"FFE61", "00"&x"0039A", "11"&x"FFCFD", "00"&x"0002E", 
                                "00"&x"002E2", "11"&x"FFC10", "00"&x"00222", "00"&x"0014B", "11"&x"FFC1D", "00"&x"003B4", "11"&x"FFF32", "11"&x"FFD39", "00"&x"0046D", "11"&x"FFD1D", "11"&x"FFF2F", "00"&x"00404", "11"&x"FFBA2", "00"&x"00187", "00"&x"0027F", "11"&x"FFB32", 
                                "00"&x"003A7", "00"&x"00031", "11"&x"FFC02", "00"&x"004F5", "11"&x"FFDAB", "11"&x"FFDF1", "00"&x"00509", "11"&x"FFB97", "00"&x"0008C", "00"&x"003CA", "11"&x"FFA8C", "00"&x"0032B", "00"&x"00176", "11"&x"FFAE1", "00"&x"0051C", "11"&x"FFE9E", 
                                "11"&x"FFC94", "00"&x"005D0", "11"&x"FFBFC", "11"&x"FFF43", "00"&x"00507", "11"&x"FFA44", "00"&x"00246", "00"&x"002E3", "11"&x"FF9F8", "00"&x"004D4", "11"&x"FFFE5", "11"&x"FFB3B", "00"&x"0063D", "11"&x"FFCCD", "11"&x"FFDCA", "00"&x"00614", 
                                "11"&x"FFA6A", "00"&x"00106", "00"&x"00455", "11"&x"FF963", "00"&x"0041D", "00"&x"00166", "11"&x"FFA0A", "00"&x"0063E", "11"&x"FFDFF", "11"&x"FFC42", "00"&x"006D3", "11"&x"FFB02", "11"&x"FFF84", "00"&x"005A8", "11"&x"FF937", "00"&x"002FF"
    );

    -- 24 bit accumulator
    signal accumulator : sfixed(0 downto -23) := (others => '0');
    -- 12 bit because max sum is 1286.28
    --signal accumulator : signed(23 downto 0) := (others => '0');
    signal sfixed_data_in : sfixed(0 downto 0) := (others => '0');

    signal tap_counter : unsigned(11 downto 0) := (others => '0');
    

begin

    FIR_PROC : process(clk)

        variable v_prev_ready : std_logic := '0';
        variable v_next_valid : std_logic := '0';
        variable v_index : integer range 0 to FIR_LENGTH * 2 - 1 := 0;
        variable v_coeff : sfixed(0 downto -21);
        variable v_delay_line : sfixed(0 downto 0);
        variable v_mult_result : sfixed(0 downto -21);

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

                        v_mult_result := resize(v_coeff * v_delay_line , v_mult_result); -- * to_sfixed(-1, v_delay_line)

                        accumulator <= resize(accumulator + v_mult_result, accumulator);--fixed_saturate, fixed_round);

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