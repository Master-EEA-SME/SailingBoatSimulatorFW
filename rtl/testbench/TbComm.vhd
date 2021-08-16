library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.XtrDef.all;

entity TbComm is
end entity TbComm;

architecture rtl of TbComm is
    constant CLK_PER    : time := 20 ns;
    signal ARst         : std_logic;
    signal Clk          : std_logic;

    signal RxVld        : std_logic;
    signal RxDat        : std_logic_vector(7 downto 0);
    signal vRxVld       : std_logic;
    signal vRxDat       : std_logic_vector(7 downto 0);
    signal TxVld        : std_logic;
    signal vTxBusy      : std_logic_vector(7 downto 0);
    signal TxBusy       : std_logic;
    signal TxReady      : std_logic;
    signal Cnt          : std_logic_vector(7 downto 0);
    type Reg_t          is array (natural range<>) of std_logic_vector(7 downto 0);
    signal Reg          : Reg_t(0 to 15);

    signal XtrDmaCmd    : XtrDmaCmd_t;
    signal XtrDmaRsp    : XtrDmaRsp_t;
    signal XtrCmd       : XtrCmd_t;
    signal XtrRsp       : XtrRsp_t;

begin
    
    uInfra : entity work.TbInfra
        generic map (CLK_PER    => CLK_PER, ARstHold    => 63 ns)
        port map    (ARst       => ARst,    Clk         => Clk);
    
    uDMA : entity work.Dma
        generic map
        (
            C_Depth     => 16
        )
        port map 
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => '0',
            XtrDmaCmd   => XtrDmaCmd,
            XtrDmaRsp   => XtrDmaRsp,
            XtrCmd      => XtrCmd,
            XtrRsp      => XtrRsp
        );
    uComm : entity work.Comm
        port map
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => '0',
            RxVld       => RxVld,
            RxDat       => RxDat,
            TxVld       => TxVld,
            TxDat       => open,
            TxRdy       => TxReady,
            TxBusy      => TxBusy,
            XtrDmaCmd   => XtrDmaCmd,
            XtrDmaRsp   => XtrDmaRsp
        );
    process (Clk, ARst)
    begin
        if ARst = '1' then
            --XtrDmaCmd.Adr.Set <= '0';
            --XtrDmaCmd.WrXtr <= '0';
            --XtrDmaCmd.RdXtr <= '0';
            XtrRsp.RRDY <= '0';
            Cnt <= (others => '0');
            Reg <= (others => (others => '0'));
        elsif rising_edge(Clk) then
            --XtrDmaCmd <= vXtrDmaCmd;
            RxDat <= vRxDat;
            RxVld <= vRxVld;
            XtrRsp.Dat <= Cnt;
            XtrRsp.RRDY <= XtrCmd.Stb;
            if XtrCmd.Stb = '1' and XtrCmd.We = '1' then
                Reg(to_integer(unsigned(XtrCmd.Adr(3 downto 0)))) <= XtrCmd.Dat;
            end if;
            if XtrCmd.Stb = '1' and XtrCmd.We = '0' then
                XtrRsp.Dat  <= Reg(to_integer(unsigned(XtrCmd.Adr(3 downto 0))));
            end if;
            vTxBusy <= vTxBusy(6 downto 0) & TxVld;
        end if;
    end process;
    XtrRsp.CRDY <= XtrCmd.Stb;
    TxBusy  <= '1' when vTxBusy /= 0 else '0';
    TxReady <= '0' when TxBusy = '1' or TxVld = '1' else '1';

    pRTL: process
    begin
        vRxVld <= '0';
        vRxDat <= (others => '0');
        wait for 5*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"55";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"80";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"10";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"02";
        wait for 1*CLK_PER;
        vRxVld <= '0';

        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"20";
        wait for 1*CLK_PER;
        vRxVld <= '0';

        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"21";
        wait for 1*CLK_PER;
        vRxVld <= '0';

        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"22";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 30*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"55";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"81";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"20";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"02";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        -- BURST
        wait for 100*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"55";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"80";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"00";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"0F";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        for i in 0 to 15 loop
            wait for 1*CLK_PER;
            vRxVld <= '1';
            vRxDat <= std_logic_vector(to_unsigned(i, 8));
            wait for 1*CLK_PER;
            vRxVld <= '0';
        end loop;
        wait for 100*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"55";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"81";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"00";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait for 1*CLK_PER;
        vRxVld <= '1';
        vRxDat <= x"0F";
        wait for 1*CLK_PER;
        vRxVld <= '0';
        wait;

    end process pRTL;
end architecture rtl;