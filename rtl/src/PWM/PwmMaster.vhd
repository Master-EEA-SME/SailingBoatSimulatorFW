library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PwmMaster is
    generic
    (
        N   : integer := 16
    );
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        En      : in    std_logic;
        Duty    : in    std_logic_vector(N - 1 downto 0);
        Freq    : in    std_logic_vector(N - 1 downto 0);
        Q       : out   std_logic
    );
end entity PwmMaster;

architecture rtl of PwmMaster is
    signal Cnt  : std_logic_vector(N downto 0);
    signal sPwm : std_logic;

    attribute mark_debug                        : string;
    attribute mark_debug of Cnt                 : signal is "true";
    attribute mark_debug of sPwm                : signal is "true";
    attribute mark_debug of Duty                : signal is "true";
    attribute mark_debug of Freq                : signal is "true";
begin
    
    uFreqGen : entity work.Pulse
        generic map(N => N)
        port map(ARst   => ARst, Clk    => Clk,  SRst => SRst,
                 En     => En,   Freq   => Freq,
                 Cnt    => Cnt,  Q      => open);

    pPWM: process(Clk, ARst)
    begin
        if ARst = '1' then
            sPwm <= '0';
        elsif rising_edge(Clk) then
            if SRst = '1' then
                sPwm <= '0';
            else
                if Cnt(N - 1 downto 0) <= Duty then
                    sPwm <= '1';
                else
                    sPwm <= '0';
                end if;
            end if;
        end if;
    end process pPWM;
    Q <= sPwm and En;

end architecture rtl;