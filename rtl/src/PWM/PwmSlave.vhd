library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
library Sim;
use Sim.Components.all;
entity PwmSlave is
    generic (
        C_Freq  : integer := 50_000_000;
        N       : integer := 16
    );
    port (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        En      : in    std_logic;
        E       : in    std_logic;
        Duty    : out   std_logic_vector(N - 1 downto 0);
        Freq    : out   std_logic_vector(N - 1 downto 0)
    );
end entity PwmSlave;

architecture rtl of PwmSlave is
    signal sPwm         : std_logic;
    signal sPwmRE       : std_logic;
    signal vDutyCnt, vFreqCnt : std_logic_vector(31 downto 0);
    signal RstTimeout   : std_logic;
    signal Timeout_Q    : std_logic;
    signal Timeout_En   : std_logic;
begin
    process (Clk)
    begin
        if rising_edge(Clk) then
            sPwm <= E;
        end if;
    end process;
    EdgeDetector_inst : EdgeDetector
        generic map(C_ASYNC => False)
        port map(ARst => ARst, Clk => Clk, SRst => SRst,
                 E    => sPwm,    RE  => sPwmRE,  FE   => open);
    process (Clk, ARst)
    begin
        if ARst = '1' then
            vDutyCnt <= (others => '0');
            vFreqCnt <= (others => '0');
        elsif rising_edge(Clk) then
            if SRst = '1' then
                vDutyCnt <= (others => '0');
                vFreqCnt <= (others => '0');
            else
                if En = '1' then
                    if Timeout_Q = '1' then
                        vFreqCnt <= (others => '0');
                        Freq <= (others => '0');
                    elsif sPwmRE = '1' then
                        vFreqCnt <= (others => '0');
                        Freq <= vFreqCnt;
                    else
                        vFreqCnt <= vFreqCnt + 1;
                    end if;
                    if Timeout_Q = '1' then
                        vDutyCnt <= (others => '0');
                        Duty <= (others => '0');
                    elsif sPwmRE = '1' then
                        vDutyCnt <= (others => '0');
                        Duty <= vDutyCnt;
                    elsif sPwm = '1' then
                        vDutyCnt <= vDutyCnt + 1;
                    end if;
                end if; 
            end if;
        end if;
    end process;

    uTimeout : Timeout
        generic map (
            C_FreqIn    => C_Freq,
            C_FreqOut   => 100)   
        port map (
            ARst        => ARst,        Clk => Clk,         SRst    => RstTimeout, 
            En          => Timeout_En,  Q   => Timeout_Q);
    Timeout_En <= not Timeout_Q;
    RstTimeout <= sPwmRE;
end architecture rtl;