library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.XtrDef.all;

entity Dma is
    generic
    (
        C_Depth     : integer := 512
    );
    port 
    (
        ARst        : in    std_logic := '0';
        Clk         : in    std_logic;
        SRst        : in    std_logic := '0';
        XtrDmaCmd   : in    XtrDmaCmd_t;
        XtrDmaRsp   : out   XtrDmaRsp_t;
        XtrCmd      : out   XtrCmd_t;
        XtrRsp      : in    XtrRsp_t
    );
end entity Dma;

architecture rtl of Dma is
    type Dma_ST         is (ST_IDLE, ST_WXTR, ST_RXTR);
    signal CurrentST    : Dma_ST;
    signal dCurrentST   : Dma_ST;
    -- Write fifo
    signal wFifoPushEn  : std_logic;
    signal vwFifoPushEn : std_logic;
    signal wFifoPushDat : std_logic_vector(7 downto 0);
    signal wFifoPopEn   : std_logic;
    signal vwFifoPopEn  : std_logic;
    signal dvwFifoPopEn : std_logic;
    signal wFifoPopDat  : std_logic_vector(7 downto 0);
    signal wFifoEFlag   : std_logic;
    signal wFifoFFlag   : std_logic;
    signal wFifoPopVld  : std_logic;
    -- Read fifo
    signal rFifoPushEn  : std_logic;
    signal vrFifoPushEn : std_logic;
    signal rFifoPushDat : std_logic_vector(7 downto 0);
    signal rFifoPopEn   : std_logic;
    signal vrFifoPopEn  : std_logic;
    signal rFifoPopDat  : std_logic_vector(7 downto 0);
    signal rFifoEFlag   : std_logic;
    signal rFifoFFlag   : std_logic;
    signal rFifoPopVld  : std_logic;

    signal vXtrCmd      : XtrCmd_t;
    signal vXtrDmaCmdAdr: XtrAdr_t;
    signal vXtrDmaRsp   : XtrDmaRsp_t;
    signal IncrAdr      : std_logic;
    signal DecrLen      : std_logic;
    signal Last         : std_logic;
    attribute mark_debug                : string;
    attribute mark_debug of CurrentST   : signal is "true";
begin
    pFsm: process(Clk, ARst)
    begin
        if ARst = '1' then
            CurrentST <= ST_IDLE;
        elsif rising_edge(Clk) then
            if SRst = '1' then
                CurrentST <= ST_IDLE;
            else
                case CurrentST is
                    when ST_IDLE =>
                        if XtrDmaCmd.WrXtr = '1' then
                            CurrentST <= ST_WXTR;
                        elsif XtrDmaCmd.RdXtr = '1' then
                            CurrentST <= ST_RXTR;
                        end if;
                    when ST_WXTR =>
                        if Last = '1' and XtrRsp.CRDY = '1' then
                            CurrentST <= ST_IDLE;
                        end if;
                    when ST_RXTR =>
                        if Last = '1' then
                            CurrentST <= ST_IDLE;
                        end if;
                    when others =>
                        CurrentST <= ST_IDLE;
                end case;
            end if;
        end if;
    end process pFsm;
    process (Clk)
    begin
        if rising_edge(Clk) then
            dCurrentST <= CurrentST;
        end if;
    end process;
    process (Clk)
    begin
        if rising_edge(Clk) then
            if CurrentST = ST_IDLE then
                if XtrDmaCmd.Adr.Set = '1' then
                    vXtrDmaCmdAdr <= XtrDmaCmd.Adr;
                else
                    if XtrRsp.CRDY = '1' then
                        vXtrDmaCmdAdr.Adr <= vXtrDmaCmdAdr.Adr + vXtrDmaCmdAdr.Incr;
                    end if;
                    vXtrDmaCmdAdr.Set <= '0';
                end if;
            else
                if XtrRsp.CRDY = '1' then
                    vXtrDmaCmdAdr.Adr <= vXtrDmaCmdAdr.Adr + vXtrDmaCmdAdr.Incr;
                end if;
                vXtrDmaCmdAdr.Set <= '0';
            end if;
            if CurrentST /= ST_IDLE then
                if XtrRsp.CRDY = '1' then
                    vXtrDmaRsp.LenCnt <= vXtrDmaRsp.LenCnt - 1;
                end if;
            else
                vXtrDmaRsp.LenCnt <= vXtrDmaCmdAdr.Len;
            end if;
        end if;
    end process;
    process (Clk, ARst)
    begin
        if ARst = '1' then
            dvwFifoPopEn <= '0';
        elsif rising_edge(Clk) then
            if SRst = '1' then
                dvwFifoPopEn <= '0';
            else
                dvwFifoPopEn <= vwFifoPopEn;
            end if;
        end if;
    end process;
    IncrAdr <= '1' when XtrRsp.CRDY = '1' else
               '0';
    Last <= '1' when vXtrDmaRsp.LenCnt = 0 else '0';
    -- Write Fifo
    vwFifoPushEn <= XtrDmaCmd.Dat.Stb and XtrDmaCmd.Dat.We;
    wFifoPushDat <= XtrDmaCmd.Dat.Dat;
    vwFifoPopEn  <= '1' when CurrentST = ST_IDLE and XtrDmaCmd.WrXtr = '1' else
                    XtrRsp.CRDY and (not Last) when CurrentST = ST_WXTR else
                    '0';
    XtrCmd.Dat <= wFifoPopDat;

    -- Read Fifo
    vrFifoPushEn <= XtrRsp.RRDY when CurrentST = ST_RXTR else
                    '0';
    rFifoPushDat <= XtrRsp.Dat;
    vrFifoPopEn  <= XtrDmaCmd.Dat.Stb and (not XtrDmaCmd.Dat.We);
    vXtrDmaRsp.Rsp.Dat <= rFifoPopDat;
    vXtrDmaRsp.Rsp.CRDY <= XtrDmaCmd.Dat.Stb;
    process (Clk)
    begin
        if rising_edge(Clk) then
            vXtrDmaRsp.Rsp.RRDY <= vrFifoPopEn;
        end if;
    end process;
    XtrCmd.Adr <= vXtrDmaCmdAdr.Adr;
    XtrCmd.Stb <= dvwFifoPopEn when CurrentST = ST_WXTR else
                  '1' when CurrentST = ST_IDLE and XtrDmaCmd.RdXtr = '1' else
                  XtrRsp.RRDY and (not Last) when CurrentST = ST_RXTR else
                  '0';
    XtrCmd.We  <= '1' when CurrentST = ST_WXTR else '0';
    XtrDmaRsp <= vXtrDmaRsp;

    
    uWriteFifo : entity work.Fifo
        generic map 
        (
            C_Depth => C_Depth,
            C_Width => 8
        )
        port map 
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => SRst,
            PushEn      => wFifoPushEn,
            PushDat     => wFifoPushDat,
            PopEn       => wFifoPopEn,
            PopDat      => wFifoPopDat,
--            PopVld      => wFifoPopVld,
            EmptyFlag   => wFifoEFlag,
            FullFlag    => wFifoFFlag
        );
    wFifoPushEn <= vwFifoPushEn and (not wFifoFFlag);
    wFifoPopEn  <= vwFifoPopEn  and (not wFifoEFlag);
    uReadFifo : entity work.Fifo
        generic map 
        (
            C_Depth => C_Depth,
            C_Width => 8
        )
        port map 
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => SRst,
            PushEn      => rFifoPushEn,
            PushDat     => rFifoPushDat,
            PopEn       => rFifoPopEn,
            PopDat      => rFifoPopDat,
--            PopVld      => rFifoPopVld,
            EmptyFlag   => rFifoEFlag,
            FullFlag    => rFifoFFlag
        );
    rFifoPushEn <= vrFifoPushEn and (not rFifoFFlag);
    rFifoPopEn  <= vrFifoPopEn and (not rFifoEFlag);
    vXtrDmaRsp.Empty <= rFifoEFlag;
    vXtrDmaRsp.Full <= wFifoFFlag;
    vXtrDmaRsp.Busy <= '1' when CurrentST /= ST_IDLE else '0';
end architecture rtl;