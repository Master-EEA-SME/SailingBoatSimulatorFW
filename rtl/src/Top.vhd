library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.XtrDef.all;

entity Top is
    generic
    (
        C_Freq      : integer := 100_000_000
    );
    port 
    (
        PinARst_N   : in    std_logic;
        PinClk      : in    std_logic;
        PinSw       : in    std_logic_vector(3 downto 0);
        PinRx       : in    std_logic;
        PinTx       : out   std_logic;
        --PinLed      : out   std_logic_vector(7 downto 0) 
        PinLed      : out   std_logic_vector(3 downto 0) 
    );
end entity Top;

architecture rtl of Top is
    -- Infra
    signal ARst_N       : std_logic;
    signal ARst         : std_logic;
    signal Clk          : std_logic;
    signal SRst         : std_logic;
    -- Application Layer
    type Reg_t is array (natural range<>) of std_logic_vector(7 downto 0);
    signal Reg          : Reg_t(0 to 15);
    -- Network Layer
    signal XtrDmaCmd    : XtrDmaCmd_t;
    signal XtrDmaRsp    : XtrDmaRsp_t;
    -- Datalink Layer
    signal XtrCmd       : XtrCmd_t;
    signal XtrRsp       : XtrRsp_t;
    -- Physical Layer
    signal TxVld        : std_logic;
    signal TxDat        : std_logic_vector(7 downto 0);
    signal TxBusy       : std_logic;
    signal TxRdy        : std_logic;
    signal RxVld        : std_logic;
    signal RxDat        : std_logic_vector(7 downto 0);
    signal Sw           : std_logic_vector(3 downto 0);
    -- Debug
    signal XtrCmdAdr    : std_logic_vector(7 downto 0);
    signal XtrCmdDat    : std_logic_vector(7 downto 0);
    signal XtrCmdStb    : std_logic;
    signal XtrCmdWe     : std_logic;
    signal XtrRspDat    : std_logic_vector(7 downto 0);
    signal XtrRspCRdy   : std_logic;
    signal XtrRspRRdy   : std_logic;

    signal XtrDmaCmdAdrAdr  : std_logic_vector(7 downto 0);
    signal XtrDmaCmdAdrSet  : std_logic;
    signal XtrDmaCmdAdrIncr : std_logic_vector(7 downto 0);
    signal XtrDmaCmdAdrLen  : std_logic_vector(7 downto 0);
    signal XtrDmaCmdDatDat  : std_logic_vector(7 downto 0);
    signal XtrDmaCmdDatStb  : std_logic;
    signal XtrDmaCmdDatWe   : std_logic;
    signal XtrDmaCmdWrXtr   : std_logic;
    signal XtrDmaCmdRdXtr   : std_logic;
    signal XtrDmaRspDatDat  : std_logic_vector(7 downto 0);
    signal XtrDmaRspDatCRdy : std_logic;
    signal XtrDmaRspDatRRdy : std_logic;
    signal XtrDmaRspLenCnt  : std_logic_vector(7 downto 0);
    signal XtrDmaRspEmpty   : std_logic;
    signal XtrDmaRspFull    : std_logic;
    signal XtrDmaRspBusy    : std_logic;

    attribute mark_debug                        : string;
    attribute mark_debug of XtrDmaCmdAdrAdr     : signal is "true";
    attribute mark_debug of XtrDmaCmdAdrSet     : signal is "true";
    attribute mark_debug of XtrDmaCmdAdrIncr    : signal is "true";
    attribute mark_debug of XtrDmaCmdAdrLen     : signal is "true";
    attribute mark_debug of XtrDmaCmdDatDat     : signal is "true";
    attribute mark_debug of XtrDmaCmdDatStb     : signal is "true";
    attribute mark_debug of XtrDmaCmdDatWe      : signal is "true";
    attribute mark_debug of XtrDmaCmdWrXtr      : signal is "true";
    attribute mark_debug of XtrDmaCmdRdXtr      : signal is "true";
    attribute mark_debug of XtrDmaRspDatDat     : signal is "true";
    attribute mark_debug of XtrDmaRspDatCRdy    : signal is "true";
    attribute mark_debug of XtrDmaRspDatRRdy    : signal is "true";
    attribute mark_debug of XtrDmaRspLenCnt     : signal is "true";
    attribute mark_debug of XtrDmaRspEmpty      : signal is "true";
    attribute mark_debug of XtrDmaRspFull       : signal is "true";
    attribute mark_debug of XtrDmaRspBusy       : signal is "true";
    attribute mark_debug of XtrCmdAdr           : signal is "true";
    attribute mark_debug of XtrCmdDat           : signal is "true";
    attribute mark_debug of XtrCmdStb           : signal is "true";
    attribute mark_debug of XtrCmdWe            : signal is "true";
    attribute mark_debug of XtrRspDat           : signal is "true";
    attribute mark_debug of XtrRspCRdy          : signal is "true";
    attribute mark_debug of XtrRspRRdy          : signal is "true";

begin
-- Infra
    ARst_N <= PinARst_N;
    ARst   <= not ARst_N; 
    Clk    <= PinClk;
    SRst   <= '0';
-- Application Layer
    process (Clk, ARst)
    begin
        if ARst = '1' then
            Reg <= (others => (others => '0'));
            Sw  <= (others => '0');
        elsif rising_edge(Clk) then
            if SRst = '1' then
                Reg <= (others => (others => '0'));
                Sw  <= (others => '0');
            else
                if XtrCmd.Stb = '1' and XtrCmd.We = '1' then
                    Reg(to_integer(unsigned(XtrCmd.Adr(3 downto 0)))) <= XtrCmd.Dat;
                end if;
                if XtrCmd.Stb = '1' and XtrCmd.We = '0' then
                    XtrRsp.Dat  <= Reg(to_integer(unsigned(XtrCmd.Adr(3 downto 0))));
                end if;
                XtrRsp.RRDY <= XtrCmd.Stb;
                Sw <= PinSw;
            end if;
        end if;
    end process;
    XtrRsp.CRDY <= XtrCmd.Stb;
-- Network Layer
    uDMA : entity work.Dma
        generic map 
        (
            C_Depth => 16
        )
        port map 
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => SRst,
            XtrDmaCmd   => XtrDmaCmd,
            XtrDmaRsp   => XtrDmaRsp,
            XtrCmd      => XtrCmd,
            XtrRsp      => XtrRsp
        );
-- Data Link Layer
    uComm : entity work.Comm
        port map 
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => SRst,
            RxVld       => RxVld,
            RxDat       => RxDat,
            TxVld       => TxVld,
            TxDat       => TxDat,
            TxRdy       => TxRdy,
            TxBusy      => TxBusy,
            XtrDmaCmd   => XtrDmaCmd,
            XtrDmaRsp   => XtrDmaRsp
        );

-- Physical Layer
    uUART : entity work.Uart
        generic map 
        (
            C_FreqIn    => C_Freq,
            C_FreqOut   => 115200
        )
        port map 
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => SRst,
            En          => '1',
            TxVld       => TxVld,
            TxDat       => TxDat,
            RxVld       => RxVld,
            RxDat       => RxDat,
            TxBusyFlag  => TxBusy,
            Rx          => PinRx,
            Tx          => PinTx
        );
    TxRdy <= '0' when TxVld = '1' or TxBusy = '1' else '1';
    PinLed <= Reg(to_integer(unsigned(Sw)))(7 downto 6) & Reg(to_integer(unsigned(Sw)))(1 downto 0);

    -- Debug
    XtrDmaCmdAdrAdr     <= XtrDmaCmd.Adr.Adr;
    XtrDmaCmdAdrSet     <= XtrDmaCmd.Adr.Set;
    XtrDmaCmdAdrIncr    <= XtrDmaCmd.Adr.Incr;
    XtrDmaCmdAdrLen     <= XtrDmaCmd.Adr.Len;
    XtrDmaCmdDatDat     <= XtrDmaCmd.Dat.Dat;
    XtrDmaCmdDatStb     <= XtrDmaCmd.Dat.Stb;
    XtrDmaCmdDatWe      <= XtrDmaCmd.Dat.We;
    XtrDmaCmdWrXtr      <= XtrDmaCmd.WrXtr;
    XtrDmaCmdRdXtr      <= XtrDmaCmd.RdXtr;
    XtrDmaRspDatDat     <= XtrDmaRsp.Rsp.Dat;
    XtrDmaRspDatCRdy    <= XtrDmaRsp.Rsp.CRdy;
    XtrDmaRspDatRRdy    <= XtrDmaRsp.Rsp.RRdy;
    XtrDmaRspLenCnt     <= XtrDmaRsp.LenCnt;
    XtrDmaRspEmpty      <= XtrDmaRsp.Empty;
    XtrDmaRspFull       <= XtrDmaRsp.Full;
    XtrDmaRspBusy       <= XtrDmaRsp.Busy;

    XtrCmdAdr           <= XtrCmd.Adr;
    XtrCmdDat           <= XtrCmd.Dat;
    XtrCmdStb           <= XtrCmd.Stb;
    XtrCmdWe            <= XtrCmd.We;
    XtrRspDat           <= XtrRsp.Dat;
    XtrRspCRdy          <= XtrRsp.CRdy;
    XtrRspRRdy          <= XtrRsp.RRdy;
    
end architecture rtl;