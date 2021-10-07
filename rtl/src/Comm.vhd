library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library Sim;
use Sim.XtrDef.all;
use Sim.Components.all;
entity Comm is
    generic (
        C_Freq      : integer := 50_000_000
    );
    port 
    (
        ARst        : in    std_logic := '0';
        Clk         : in    std_logic;
        SRst        : in    std_logic := '0';
        RxVld       : in    std_logic;
        RxDat       : in    std_logic_vector(7 downto 0);
        TxVld       : out   std_logic;
        TxDat       : out   std_logic_vector(7 downto 0);
        TxRdy       : in    std_logic;
        TxBusy      : in    std_logic;
        XtrRst      : out   std_logic;
        XtrDmaCmd   : out   XtrDmaCmd_t;
        XtrDmaRsp   : in    XtrDmaRsp_t
    );
end entity Comm;

architecture rtl of Comm is
    constant START_CODE : std_logic_vector(7 downto 0) := x"55";
    type COMM_ST is (ST_IDLE, ST_RX_HEADER, ST_WDAT, ST_WXTR, ST_WAIT_WXTR, ST_TX_HEADER, ST_RXTR, ST_WAIT_RXTR, ST_RDAT);
    signal CurrentST    : COMM_ST;
    signal Rw           : std_logic;
    signal HeaderCnt    : std_logic_vector(3 downto 0);
    signal IncAdr       : std_logic;
    signal Len          : std_logic_vector(7 downto 0);
    signal LenCnt       : std_logic_vector(7 downto 0);
    signal vTxVld       : std_logic;
    signal vTxDat       : std_logic_vector(7 downto 0);
    signal SendAck      : std_logic;
    signal TimeoutRst   : std_logic;
    signal TimeoutEn    : std_logic;
    signal TimeoutQ     : std_logic;

    attribute mark_debug                : string;
    attribute mark_debug of CurrentST   : signal is "true";
    attribute mark_debug of TxVld       : signal is "true";
    attribute mark_debug of TxDat       : signal is "true";
    attribute mark_debug of RxVld       : signal is "true";
    attribute mark_debug of RxDat       : signal is "true";
    attribute mark_debug of LenCnt      : signal is "true";
begin
    
    pFSM: process(Clk, ARst)
    begin
        if ARst = '1' then
            CurrentST <= ST_IDLE;
        elsif rising_edge(Clk) then
            if SRst = '1' or TimeoutQ = '1' then
                CurrentST <= ST_IDLE;
            else
                case CurrentST is
                    when ST_IDLE =>
                        if RxVld = '1' and RxDat = START_CODE then
                            CurrentST <= ST_RX_HEADER;
                        end if;
                    when ST_RX_HEADER =>
                        if HeaderCnt(3) = '1' then
                            if Rw = '1' then
                                CurrentST <= ST_RXTR;
                            else
                                CurrentST <= ST_WDAT;
                            end if;
                        end if;
                    when ST_WDAT =>
                        if LenCnt = 0 and RxVld = '1' then
                            CurrentST <= ST_WXTR;
                        end if;
                    when ST_WXTR =>
                        CurrentST <= ST_WAIT_WXTR;
                    when ST_WAIT_WXTR =>
                        if XtrDmaRsp.Busy = '0' then
                            CurrentST <= ST_TX_HEADER;
                        end if;
                    when ST_RXTR =>
                        CurrentST <= ST_WAIT_RXTR;
                    when ST_WAIT_RXTR =>
                        if XtrDmaRsp.Busy = '0' then
                            CurrentST <= ST_TX_HEADER;
                        end if;
                    when ST_TX_HEADER =>
                        if vTxVld = '1' and HeaderCnt(1) = '1' then
                            CurrentST <= ST_RDAT;
                        end if;
                    when ST_RDAT =>
                        if vTxVld = '1' and LenCnt = 0 then
                            CurrentST <= ST_IDLE;
                        end if;
                    when others =>
                        CurrentST <= ST_IDLE;
                end case;
--                case TxCurrentST is
--                    when ST_IDLE =>
--                        if RxCurrentST = ST_HEADER and RxVld = '1' and RxHeaderCnt(2) = '1' and Rw = '1' then
--                            TxCurrentST <= ST_XTR; 
--                        end if;
--                    when ST_XTR =>
--                        TxCurrentST <= ST_WAIT_XTR;
--                    when ST_WAIT_XTR =>
--                        if XtrDmaRsp.Busy = '0' then
--                            TxCurrentST <= ST_HEADER;
--                        end if;
--                    when ST_HEADER =>
--                        if vTxVld = '1' and TxHeaderCnt(1) = '1' then
--                            TxCurrentST <= ST_DATA;
--                        end if;
--                    when ST_DATA =>
--                        if vTxVld = '1' and TxLenCnt = 0 then
--                            TxCurrentST <= ST_IDLE;
--                        end if;
--                    when others =>
--                        TxCurrentST <= ST_IDLE;
--                end case;
            end if;
        end if;
    end process pFSM;

    process (Clk, ARst)
    begin
        if ARst = '1' then
            --XtrDmaCmd.Adr.Set <= '0';
            --XtrDmaCmd.Dat.Stb <= '0';
            null;
        elsif rising_edge(Clk) then
            if SRst = '1' then
                --XtrDmaCmd.Adr.Set <= '0';
                --XtrDmaCmd.Dat.Stb <= '0';
                null;
            else
                --XtrDmaCmd.Adr.Set <= '0';
                if CurrentST = ST_RX_HEADER then
                    if RxVld = '1' then
                        if HeaderCnt(0) = '1' then
                            XtrDmaCmd.Adr.Incr <= x"0" & "000" & RxDat(7);
                            Rw <= RxDat(0);
                        end if;
                        if HeaderCnt(1) = '1' then
                            XtrDmaCmd.Adr.Adr <= RxDat;
                        end if;
                        if HeaderCnt(2) = '1' then
                            XtrDmaCmd.Adr.Len <= RxDat;
                            --Len <= RxDat;
                        end if;  
                    end if;
                end if;
                -- Get Len
                if CurrentST = ST_RX_HEADER then
                    if RxVld = '1' then
                        Len <= RxDat;
                    end if;
                elsif CurrentST = ST_TX_HEADER then
                    if vTxVld = '1' then
                        if HeaderCnt(1) = '1' then
                            Len <= vTxDat;
                        end if;
                    end if;
                end if;
                if CurrentST = ST_RX_HEADER then
                    if RxVld = '1' then
                        HeaderCnt <= HeaderCnt(2 downto 0) & HeaderCnt(3);
                    end if;
                elsif CurrentST = ST_TX_HEADER then
                    if vTxVld = '1' then
                        HeaderCnt <= HeaderCnt(2 downto 0) & HeaderCnt(3);
                    end if;
                else
                    HeaderCnt <= x"1";
                end if;
                if CurrentST = ST_WDAT then
                    if RxVld = '1' then
                        LenCnt <= LenCnt - 1;
                    end if;
                elsif CurrentST = ST_RDAT then
                    if vTxVld = '1' then
                        LenCnt <= LenCnt - 1;
                    end if;
                else
                    if vTxVld = '1' then
                        LenCnt <= vTxDat;
                    elsif RxVld = '1' then
                        LenCnt <= RxDat;
                    end if;
                    --LenCnt <= Len;
                end if;
                if CurrentST = ST_WDAT then
                    SendAck <= '1';
                elsif CurrentST = ST_RDAT and vTxVld = '1' then
                    SendAck <= '0';
                end if;

                -- Build TxHeader
                --if CurrentST = ST_TX_HEADER then
                --    if TxBusy = '0' then
                --        vTxVld <= '1';
                --        if HeaderCnt(0) = '1' then
                --            vTxDat <= START_CODE;
                --        elsif HeaderCnt(1) = '1' then
                --            if SendAck = '1' then
                --                vTxDat <= x"00";
                --            else
                --                vTxDat <= Len;
                --            end if;
                --        end if;
                --    else
                --        vTxVld <= '0';
                --    end if;
                --elsif CurrentST = ST_RDAT then
                --    if TxBusy = '0' then
                --        if SendAck = '1' then
                --            vTxDat <= x"01";
                --            vTxVld <= '1';
                --        else
                --            vTxDat <= XtrDmaRsp.Rsp.Dat;
                --            vTxVld <= XtrDmaRsp.Rsp.RRDY;
                --        end if;
                --    else
                --        vTxVld <= '0';
                --    end if;
                --else
                --    vTxVld <= '0';
                --end if;
            end if;
        end if;
    end process;
    XtrDmaCmd.Adr.Set <= '1' when CurrentST = ST_RX_HEADER and HeaderCnt(3) = '1' else '0';
    XtrDmaCmd.Dat.Dat <= RxDat;
    XtrDmaCmd.Dat.We  <= RxVld when CurrentST = ST_WDAT else '0';
    XtrDmaCmd.Dat.Stb <= RxVld when CurrentST = ST_WDAT else 
                         '1' when ((CurrentST = ST_TX_HEADER and HeaderCnt(1) = '1') or CurrentST = ST_RDAT) and TxBusy = '0' and TxRdy = '1' else
                         '0';
    XtrDmaCmd.WrXtr <= '1' when CurrentST = ST_WXTR else '0';
    XtrDmaCmd.RdXtr <= '1' when CurrentST = ST_RXTR else '0';
    -- XTR will cause problem check it
    vTxVld <= '1' when CurrentST = ST_TX_HEADER and TxBusy = '0' else
              '1' when CurrentST = ST_RDAT and TxBusy = '0' and SendAck = '1' else
              XtrDmaRsp.Rsp.RRDY when CurrentST = ST_RDAT and TxBusy = '0' else
              '0';
    vTxDat <= START_CODE when CurrentST = ST_TX_HEADER and HeaderCnt(0) = '1' else
              x"00" when CurrentST = ST_TX_HEADER and HeaderCnt(1) = '1' and SendAck = '1' else
              x"01" when CurrentST = ST_RDAT and SendAck = '1' else
              Len when CurrentST = ST_TX_HEADER and HeaderCnt(1) = '1' else
              XtrDmaRsp.Rsp.Dat;
    --vTxVld <= '1' when CurrentST = ST_TX_HEADER and TxBusy = '0' else
    --          XtrDmaRsp.Rsp.RRDY when CurrentST = ST_RDAT and TxBusy = '0' else
    --          '0';
    TxVld <= vTxVld;
    TxDat <= vTxDat;
    uTimeout : Timeout
        generic map (
            C_FreqIn => C_Freq, C_FreqOut => 10)
        port map (
            ARst    => ARst,        Clk => Clk, SRst => TimeoutRst,
            En      => TimeoutEn,
            Q       => TimeoutQ);
    
    TimeoutRst  <=  '1' when SRst = '1' else
                    '1' when CurrentST = ST_IDLE else
                    '0';
    TimeoutEn   <=  '1' when CurrentST /= ST_IDLE else 
                    '0';
    XtrRst      <= TimeoutQ;
end architecture rtl;