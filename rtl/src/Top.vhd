library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Top is
    port 
    (
        PinARst_N           : in    std_logic;
        PinClk              : in    std_logic;
        PinAnemoOut         : out   std_logic;
        PinGiroPwm          : out   std_logic;
        PinCapPwm           : out   std_logic;
        PinVerinPwm         : in    std_logic;
        PinVerinSens        : in    std_logic;
        PinVerinAngleSck    : in    std_logic;
        PinVerinAngleMiso   : out   std_logic;
        PinVerinAngleCs_N   : in    std_logic;
        PinLedBabord        : in    std_logic;
        PinLedStandby       : in    std_logic;
        PinLedTribord       : in    std_logic;
        PinBtnBabord        : out   std_logic;
        PinBtnStandby       : out   std_logic;
        PinBtnTribord       : out   std_logic;
        PinRx               : in    std_logic;
        PinTx               : out   std_logic;
        PinLed              : out   std_logic_vector(3 downto 0);
        PinTp               : out   std_logic_vector(2 downto 0)
    );
end entity Top;

architecture rtl of Top is
    signal ARst_N       : std_logic;
    signal ARst         : std_logic;
    signal Clk          : std_logic;
    signal SRst         : std_logic;
    signal sAnemoOut    : std_logic;
    signal sGiroPwm     : std_logic;
    signal sCapPwm      : std_logic;
    signal VerinAngleSck    : std_logic;
    signal VerinAngleMiso   : std_logic;
    signal VerinAngleCs_N   : std_logic;
begin
    ARst_N <= PinARst_N;
    ARst   <= not ARst_N;
    Clk    <= PinClk;
    SRst   <= '0';

    uSimu : entity Sim.Simu
        generic map (
            C_Freq  => 100e6)
        port map (
            ARst            => ARst,                Clk             => Clk,                 SRst            => SRst,
            AnemoOut        => sAnemoOut,
            GiroPwm         => sGiroPwm,            CapPwm          => sCapPwm,
            VerinPwm        => PinVerinPwm,         VerinSens       => PinVerinSens,
            VerinAngleSck   => VerinAngleSck,       VerinAngleMiso  => VerinAngleMiso,      VerinAngleCs_N  => VerinAngleCs_N,
            BtnBabord       => PinBtnBabord,        BtnStandby      => PinBtnStandby,       BtnTribord      => PinBtnTribord,
            LedBabord       => PinLedBabord,        LedStandby      => PinLedStandby,       LedTribord      => PinLedTribord,
            Rx              => PinRx,               Tx              => PinTx);
    PinLed <= '0' & sAnemoOut & sGiroPwm & sCapPwm;
    PinAnemoOut <= sAnemoOut;
    PinGiroPwm  <= sGiroPwm;
    PinCapPwm   <= sCapPwm;
    VerinAngleSck       <= PinVerinAngleSck;
    PinVerinAngleMiso   <= VerinAngleMiso;
    VerinAngleCs_N      <= PinVerinAngleCs_N;

    PinTp       <= VerinAngleSck & VerinAngleMiso & VerinAngleCs_N;
	 
end architecture rtl;