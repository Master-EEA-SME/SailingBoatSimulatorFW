library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library Sim;
use Sim.XtrDef.all;
use Sim.Components.all;
entity XtrPwmMaster is
    port 
    (
        ARst    : in    std_logic;
        Clk     : in    std_logic;
        SRst    : in    std_logic;
        XtrCmd  : in    XtrCmd_t;
        XtrRsp  : out   XtrRsp_t;
        Q       : out   std_logic
    );
end entity XtrPwmMaster;

architecture rtl of XtrPwmMaster is
    signal Duty : std_logic_vector(31 downto 0);
    signal Freq : std_logic_vector(31 downto 0);
begin
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            Duty <= x"00000001";
            Freq <= x"80000000";
        elsif rising_edge(Clk) then
            if SRst = '1' then
                Duty <= x"00000001";
                Freq <= x"80000000";
            else
                if XtrCmd.Stb = '1' then
                    if XtrCmd.We = '1' then
                        case XtrCmd.Adr(2 downto 0) is
                            when "000" =>
                                Duty(7 downto 0)  <= XtrCmd.Dat;
                            when "001" =>
                                Duty(15 downto 8) <= XtrCmd.Dat;
                            when "010" =>
                                Duty(23 downto 16) <= XtrCmd.Dat;
                            when "011" =>
                                Duty(31 downto 24) <= XtrCmd.Dat;
                            when "100" =>
                                Freq(7 downto 0) <= XtrCmd.Dat;
                            when "101" =>
                                Freq(15 downto 8) <= XtrCmd.Dat;
                            when "110" =>
                                Freq(23 downto 16) <= XtrCmd.Dat;
                            when "111" =>
                                Freq(31 downto 24) <= XtrCmd.Dat;
                            when others =>
                        end case;
                    else
                        case XtrCmd.Adr(2 downto 0) is
                            when "000" =>
                                XtrRsp.Dat <= Duty(7 downto 0);
                            when "001" =>
                                XtrRsp.Dat <= Duty(15 downto 8);
                            when "010" =>
                                XtrRsp.Dat <= Duty(23 downto 16);
                            when "011" =>
                                XtrRsp.Dat <= Duty(31 downto 24);
                            when "100" =>
                                XtrRsp.Dat <= Freq(7 downto 0);
                            when "101" =>
                                XtrRsp.Dat <= Freq(15 downto 8);
                            when "110" =>
                                XtrRsp.Dat <= Freq(23 downto 16);
                            when "111" =>
                                XtrRsp.Dat <= Freq(31 downto 24);
                            when others =>
                        end case;
                    end if;
                end if;
                XtrRsp.RRDY <= XtrCmd.Stb;    
            end if;
        end if;
    end process;
    XtrRsp.CRDY <= XtrCmd.Stb;
    uPwm : PwmMaster
        generic map(N => 32)
        port map(ARst => ARst, Clk  => Clk,  SRst => SRst, 
                 En   => '1',  Duty => Duty, Freq => Freq, 
                 Q    => Q);
end architecture rtl;
