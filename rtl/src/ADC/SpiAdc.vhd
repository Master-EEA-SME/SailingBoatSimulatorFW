library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity SpiAdc is
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        En      : in    std_logic;
        Reg     : in    std_logic_vector(11 downto 0);
        RxVld   : in    std_logic;
        TxDat   : out   std_logic_vector(7 downto 0)
    );
end entity SpiAdc;

architecture rtl of SpiAdc is
    signal sAddress : std_logic_vector(7 downto 0);
begin
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            sAddress <= (others => '0');
        elsif rising_edge(Clk) then
            if SRst = '1' then
                sAddress <= (others => '0');
            else
                if En = '1' then
                    if RxVld = '1' then
                        sAddress <= sAddress + 1;
                    end if;
                else
                    sAddress <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    TxDat <= Reg(7 downto 0) when sAddress(0) = '1' else x"0" & Reg(11 downto 8);
    
end architecture rtl;