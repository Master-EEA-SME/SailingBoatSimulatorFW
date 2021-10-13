library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library Sim;
use Sim.XtrDef.all;
use Sim.Components.all;
entity XtrPwmSlave is
    generic (
        C_Freq  : integer := 50_000_000
    );
    port (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        E       : in    std_logic;
        XtrCmd  : in    XtrCmd_t;
        XtrRsp  : out   XtrRsp_t
    );
end entity XtrPwmSlave;

architecture rtl of XtrPwmSlave is
    signal sDuty    : std_logic_vector(31 downto 0);
    signal sFreq    : std_logic_vector(31 downto 0);
begin
    
    process (Clk)
    begin
        if rising_edge(Clk) then
            if XtrCmd.Stb = '1' then
                if XtrCmd.We = '0' then
                    case XtrCmd.Adr(2 downto 0) is
                        when "000" =>
                            XtrRsp.Dat <= sDuty(7 downto 0);
                        when "001" =>
                            XtrRsp.Dat <= sDuty(15 downto 8);
                        when "010" =>
                            XtrRsp.Dat <= sDuty(23 downto 16);
                        when "011" =>
                            XtrRsp.Dat <= sDuty(31 downto 24);
                        when "100" =>
                            XtrRsp.Dat <= sFreq(7 downto 0);
                        when "101" =>
                            XtrRsp.Dat <= sFreq(15 downto 8);
                        when "110" =>
                            XtrRsp.Dat <= sFreq(23 downto 16);
                        when "111" =>
                            XtrRsp.Dat <= sFreq(31 downto 24);
                        when others =>
                    end case;
                end if;
            end if;
            XtrRsp.RRDY <= XtrCmd.Stb;
        end if;
    end process;
    XtrRsp.CRDY <= XtrCmd.Stb;

    uPwmSlave : PwmSlave
        generic map (
            C_Freq  => C_Freq,
            N       => 32
        )
        port map
        (
            ARst    => ARst,
            Clk     => Clk,
            SRst    => SRst,
            En      => '1',
            E       => E,
            Duty    => sDuty,
            Freq    => sFreq
        );
    
end architecture rtl;