library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library Sim;
use Sim.XtrDef.all;
use Sim.Components.all;
entity Simu is
    generic (
        C_Freq          : integer := 50_000_000
    );
    port 
    (
        ARst            : in    std_logic := '0';
        Clk             : in    std_logic;
        SRst            : in    std_logic := '0';
        AnemoOut        : out   std_logic;
        GiroPwm         : out   std_logic;
        CapPwm          : out   std_logic;
        VerinPwm        : in    std_logic;
        VerinSens       : in    std_logic;
        VerinAngleSck   : in    std_logic;
        VerinAngleMiso  : out   std_logic;
        VerinAngleCs_N  : in    std_logic;
        BtnBabord       : out   std_logic;
        BtnTribord      : out   std_logic;
        BtnStandby      : out   std_logic;
        LedBabord       : in    std_logic;
        LedTribord      : in    std_logic;
        LedStandby      : in    std_logic;
        Rx              : in    std_logic;
        Tx              : out   std_logic
    );
end entity Simu;

architecture rtl of Simu is
    signal C_FreqSlv            : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(C_Freq, 32));
-- Layer 1
    signal XtrCmdLyr1           : vXtrCmd_t(0 to 1);
    signal XtrRspLyr1           : vXtrRsp_t(0 to 1);
-- Layer 2
    signal XtrCmdLyr2_1         : vXtrCmd_t(0 to 2);
    signal XtrRspLyr2_1         : vXtrRsp_t(0 to 2);
    signal XtrCmdLyr2_2         : vXtrCmd_t(0 to 2);
    signal XtrRspLyr2_2         : vXtrRsp_t(0 to 2);
-- Anemometre
    signal XtrCmdAnemoPwm       : XtrCmd_t;
    signal XtrRspAnemoPwm       : XtrRsp_t;
-- Girouette
    signal XtrCmdGiroPwm        : XtrCmd_t;
    signal XtrRspGiroPwm        : XtrRsp_t;
-- Cap
    signal XtrCmdCapPwm         : XtrCmd_t;
    signal XtrRspCapPwm         : XtrRsp_t;
-- Verin
    signal sVerinSens           : std_logic;
    signal XtrCmdVerinPwm       : XtrCmd_t;
    signal XtrRspVerinPwm       : XtrRsp_t;
    signal XtrCmdVerinAnalog    : XtrCmd_t;
    signal XtrRspVerinAnalog    : XtrRsp_t;
    signal VerinAngleCs         : std_logic;
-- Registers
    signal sLedBabord           : std_logic;
    signal sLedTribord          : std_logic;
    signal sLedStandby          : std_logic;
    signal sBtnBabord           : std_logic;
    signal sBtnTribord          : std_logic;
    signal sBtnStandby          : std_logic;
    signal XtrCmdReg            : XtrCmd_t;
    signal XtrRspReg            : XtrRsp_t;
-- NetSim Layer
    signal DmaRst               : std_logic;
    signal XtrCmd               : XtrCmd_t;
    signal XtrRsp               : XtrRsp_t;
-- Datalink Layer
    signal XtrDmaCmd            : XtrDmaCmd_t;
    signal XtrDmaRsp            : XtrDmaRsp_t;
    signal XtrRst               : std_logic;
-- Physical Layer
    signal TxVld                : std_logic;
    signal TxDat                : std_logic_vector(7 downto 0);
    signal TxBusy               : std_logic;
    signal TxRdy                : std_logic;
    signal RxVld                : std_logic;
    signal RxDat                : std_logic_vector(7 downto 0);

begin
    -- Anemo
    uAnemoPwm : XtrPwmMaster
        port map (
            ARst    => ARst,                Clk     => Clk,             SRst => SRst,
            XtrCmd  => XtrCmdAnemoPwm,      XtrRsp  => XtrRspAnemoPwm,
            Q       => AnemoOut);
    -- Girouette
    uGiroPwm : XtrPwmMaster
        port map (
            ARst      => ARst,              Clk     => Clk,             SRst => SRst,
            XtrCmd    => XtrCmdGiroPwm,     XtrRsp  => XtrRspGiroPwm,
            Q         => GiroPwm);
    -- Cap
    uCapPwm : XtrPwmMaster
        port map (
            ARst      => ARst,              Clk     => Clk,             SRst => SRst,
            XtrCmd    => XtrCmdCapPwm,      XtrRsp  => XtrRspCapPwm,
            Q         => CapPwm);
    -- Verin
    uVerinPwm : XtrPwmSlave
        generic map (
            C_Freq    => C_Freq
        )
        port map(
            ARst      => ARst,              Clk     => Clk,             SRst => SRst,
            E         => VerinPwm,
            XtrCmd    => XtrCmdVerinPwm,    XtrRsp => XtrRspVerinPwm);
    uVerinAngle : XtrAdc
        port map (
            ARst    => ARst,                Clk     => Clk,                 SRst    => SRst,
            XtrCmd  => XtrCmdVerinAnalog,   XtrRsp  => XtrRspVerinAnalog,
            Sck     => VerinAngleSck,       Mosi    => '1',                 Miso    => VerinAngleMiso,  Ss  => VerinAngleCs);
    VerinAngleCs <= not VerinAngleCs_N;
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            sBtnTribord <= '0';
            sBtnStandby <= '0';
            sBtnBabord  <= '0';
        elsif rising_edge(Clk) then
            sVerinSens <= VerinSens;
            if XtrCmdReg.Stb = '1' then
                if XtrCmdReg.We = '1' then
                    sBtnTribord  <= XtrCmdReg.Dat(0);
                    sBtnStandby  <= XtrCmdReg.Dat(1);
                    sBtnBabord   <= XtrCmdReg.Dat(2);
                else
                    case XtrCmdReg.Adr(2 downto 0) is
                        when "000" =>
                            XtrRspReg.Dat <= C_FreqSlv(7 downto 0);
                        when "001" =>
                            XtrRspReg.Dat <= C_FreqSlv(15 downto 8);
                        when "010" =>
                            XtrRspReg.Dat <= C_FreqSlv(23 downto 16);
                        when "011" =>
                            XtrRspReg.Dat <= C_FreqSlv(31 downto 24);
                        when "100" =>
                            XtrRspReg.Dat <= x"0" & "000" & sVerinSens;
                        when "101" =>
                            XtrRspReg.Dat <= x"0" & "0" & sLedBabord & sLedStandby & sLedTribord;
                        when others =>
                            XtrRspReg.Dat <= (others => '-');
                    end case;
                end if;
            end if;
            XtrRspReg.RRDY <= XtrCmdReg.Stb;
        end if;
    end process;
    XtrRspReg.CRDY <= XtrCmdReg.Stb;
    process (Clk)
    begin
        if rising_edge(Clk) then
            sLedBabord  <= LedBabord; 
            sLedStandby <= LedStandby; 
            sLedTribord <= LedTribord;
            BtnBabord   <= not sBtnBabord;
            BtnStandby  <= not sBtnStandby;
            BtnTribord  <= not sBtnTribord; 
        end if;
    end process;

    uXtrAbrLyr1 : XtrAbr
        generic map (
            C_MMSB  => 7, C_MLSB  => 8, C_Slave => 2)
        port map (
            ARst    => ARst,        Clk     => Clk,         SRst    => SRst,
            XtrCmd  => XtrCmd,      XtrRsp  => XtrRsp,
            vXtrCmd => XtrCmdLyr1,  vXtrRsp => XtrRspLyr1);
    
    uXtrAbrLyr2_1 : XtrAbr
        generic map (
            C_MMSB  => 7, C_MLSB  => 7, C_MASK => 16#00#, C_Slave => 3)
        port map (
            ARst    => ARst,            Clk     => Clk,         SRst    => SRst,
            XtrCmd  => XtrCmdLyr1(0),   XtrRsp  => XtrRspLyr1(0),
            vXtrCmd => XtrCmdLyr2_1,    vXtrRsp => XtrRspLyr2_1);

    uXtrAbrLyr2_2 : XtrAbr
        generic map (
            C_MMSB  => 7, C_MLSB  => 7, C_MASK => 16#80#, C_Slave => 3)
        port map (
            ARst    => ARst,            Clk     => Clk,         SRst    => SRst,
            XtrCmd  => XtrCmdLyr1(1),   XtrRsp  => XtrRspLyr1(1),
            vXtrCmd => XtrCmdLyr2_2,    vXtrRsp => XtrRspLyr2_2);
    
    -- Anemometre
    XtrCmdAnemoPwm      <= XtrCmdLyr2_1(0);
    XtrRspLyr2_1(0)     <= XtrRspAnemoPwm;
    -- Girouette
    XtrCmdGiroPwm       <= XtrCmdLyr2_1(1);
    XtrRspLyr2_1(1)     <= XtrRspGiroPwm;
    -- Cap
    XtrCmdCapPwm        <= XtrCmdLyr2_1(2);
    XtrRspLyr2_1(2)     <= XtrRspCapPwm;
    -- Verin
    XtrCmdVerinPwm      <= XtrCmdLyr2_2(0);
    XtrRspLyr2_2(0)     <= XtrRspVerinPwm;
    XtrCmdVerinAnalog   <= XtrCmdLyr2_2(1);
    XtrRspLyr2_2(1)     <= XtrRspVerinAnalog;
    -- Regs
    XtrCmdReg           <= XtrCmdLyr2_2(2);
    XtrRspLyr2_2(2)     <= XtrRspReg;
    
    uDMA : Dma
        generic map (
            C_Depth => 16)
        port map (
            ARst        => ARst,        Clk         => Clk,         SRst => XtrRst,
            XtrDmaCmd   => XtrDmaCmd,   XtrDmaRsp   => XtrDmaRsp,
            XtrCmd      => XtrCmd,      XtrRsp      => XtrRsp);
    DmaRst <= SRst or XtrRst;
-- Data Link Layer
    uComm : Comm
        port map (
            ARst        => ARst,        Clk         => Clk,             SRst    => SRst,
            RxVld       => RxVld,       RxDat       => RxDat,
            TxVld       => TxVld,       TxDat       => TxDat,           TxRdy   => TxRdy,   TxBusy => TxBusy,
            XtrDmaCmd   => XtrDmaCmd,   XtrDmaRsp   => XtrDmaRsp,       XtrRst  => XtrRst);

    -- Physical Layer
    uUART : Uart
        generic map (
            C_FreqIn    => C_Freq, C_FreqOut   => 1_000_000)
        port map (
            ARst    => ARst,    Clk     => Clk, SRst => SRst,
            En      => '1',
            TxVld   => TxVld,   TxDat   => TxDat, TxBusyFlag  => TxBusy,
            RxVld   => RxVld,   RxDat   => RxDat,
            Rx      => Rx,      Tx      => Tx);
    TxRdy <= '0' when TxVld = '1' or TxBusy = '1' else '1';
    
end architecture rtl;