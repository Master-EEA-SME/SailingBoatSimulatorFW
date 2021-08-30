library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.XtrDef.all;

entity Pwm is
    port 
    (
        ARst    : in    std_logic;
        Clk     : in    std_logic;
        SRst    : in    std_logic;
        XtrCmd  : in    XtrCmd_t;
        XtrRsp  : out   XtrRsp_t;
        Q       : out   std_logic
    );
end entity Pwm;

architecture rtl of Pwm is
    signal Freq     : std_logic_vector(15 downto 0);
    signal Alpha    : std_logic_vector(15 downto 0);
    signal Cnt      : std_logic_vector(15 downto 0);
    signal vPwm     : std_logic;
begin
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            Freq  <= x"8000";
            Alpha <= x"4000";
            Cnt   <= (others => '0');
            vPwm  <= '0';
            Q     <= '0';
        elsif rising_edge(Clk) then
            if SRst = '1' then
                Freq  <= x"8000";
                Alpha <= x"4000";
                Cnt   <= (others => '0');
                vPwm  <= '0';
                Q     <= '0';    
            else
                if XtrCmd.Stb = '1' and XtrCmd.We = '1' then
                    if XtrCmd.Adr(7) = '1' then
                        case XtrCmd.Adr(1 downto 0) is
                            when "00" =>
                                Alpha(7 downto 0) <= XtrCmd.Dat;
                            when "01" =>
                                Alpha(15 downto 8) <= XtrCmd.Dat;
                            when "10" =>
                                Freq(7 downto 0) <= XtrCmd.Dat;
                            when "11" =>
                                Freq(15 downto 8) <= XtrCmd.Dat;
                            when others =>
                        end case;
                    end if; 
                end if;
                if XtrCmd.Stb = '1' and XtrCmd.We = '0' then
                    if XtrCmd.Adr(7) = '1' then
                        case XtrCmd.Adr(1 downto 0) is
                            when "00" =>
                                XtrRsp.Dat <= Alpha(7 downto 0);
                            when "01" =>
                                XtrRsp.Dat <= Alpha(15 downto 0);
                            when "10" =>
                                XtrRsp.Dat <= Freq(7 downto 0);
                            when "11" =>
                                XtrRsp.Dat <= Freq(15 downto 8);
                            when others =>
                        end case;
                    end if;
                end if;
                XtrRsp.RRdy <= XtrCmd.Stb;
                Cnt <= Cnt + 1;
                if Cnt >= Freq - 1 then
                    Cnt <= (others => '0');
                end if;
                if Cnt < Alpha - 1 then
                    vPwm <= '1';
                else
                    vPwm <= '0';
                end if;
                Q <= vPwm;
            end if;
        end if;
    end process;
    XtrRsp.CRdy <= XtrCmd.Stb;
    
end architecture rtl;