library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.XtrDef.all;

entity TbDma is
end entity TbDma;

architecture rtl of TbDma is
    constant CLK_PER    : time := 20 ns;
    type TB_ST is (ST_IDLE, ST_WRITE, ST_WXTR, ST_RXTR, ST_READ);
    signal ARst         : std_logic;
    signal Clk          : std_logic;
    signal XtrDmaCmd    : XtrDmaCmd_t;
    signal vXtrDmaCmd   : XtrDmaCmd_t;
    signal XtrDmaRsp    : XtrDmaRsp_t;
    signal XtrCmd       : XtrCmd_t;
    signal XtrRsp       : XtrRsp_t;
    signal vXtrRsp      : XtrRsp_t;
    signal vSet         : std_logic;
    signal vWr          : std_logic;
    signal vRd          : std_logic;
    signal Cnt          : std_logic_vector(7 downto 0);
begin
    
    uInfra : entity work.TbInfra
        generic map
        (
            CLK_PER     => CLK_PER,
            ARstHold    => 63 ns
        )
        port map
        (
            ARst        => ARst,
            Clk         => Clk
        );
    
    uDMA : entity work.Dma
        generic map
        (
            C_Depth     => 64
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

    process (Clk, ARst)
    begin
        if ARst = '1' then
            XtrDmaCmd.Adr.Set <= '0';
            XtrDmaCmd.WrXtr <= '0';
            XtrDmaCmd.RdXtr <= '0';
            XtrRsp.RRDY <= '0';
            Cnt <= (others => '0');
        elsif rising_edge(Clk) then
            XtrDmaCmd <= vXtrDmaCmd;
            XtrRsp.Dat <= Cnt;
            XtrRsp.RRDY <= XtrCmd.Stb;
            if XtrCmd.Stb = '1' then
                Cnt <= Cnt + 1;
            end if;
        end if;
    end process;
    XtrRsp.CRDY <= XtrCmd.Stb;
    pRtl: process
    begin
        vXtrDmaCmd.Adr.Adr <= x"10"; vXtrDmaCmd.Adr.Incr <= x"01"; vXtrDmaCmd.Adr.Set <= '0'; vXtrDmaCmd.Adr.Len <= x"02";
        vXtrDmaCmd.Dat.Dat <= x"00"; vXtrDmaCmd.Dat.Stb <= '0'; vXtrDmaCmd.Dat.We <= '0';
        vXtrDmaCmd.WrXtr <= '0'; vXtrDmaCmd.RdXtr <= '0';
        wait for 5*CLK_PER;
        vXtrDmaCmd.Adr.Set <= '1';
        wait for 1*CLK_PER;
        vXtrDmaCmd.Adr.Set <= '0';
        wait for 1*CLK_PER;
        vXtrDmaCmd.Dat.Dat <= x"11"; vXtrDmaCmd.Dat.Stb <= '1'; vXtrDmaCmd.Dat.We <= '1';
        --wait for 1*CLK_PER;
        --vXtrDmaCmd.Dat.Dat <= x"12"; vXtrDmaCmd.Dat.Stb <= '1'; vXtrDmaCmd.Dat.We <= '1';
        --wait for 1*CLK_PER;
        --vXtrDmaCmd.Dat.Dat <= x"13"; vXtrDmaCmd.Dat.Stb <= '1'; vXtrDmaCmd.Dat.We <= '1';
        wait for 1*CLK_PER;
        vXtrDmaCmd.Dat.Stb <= '0';
        vXtrDmaCmd.WrXtr <= '1';
        wait for 1*CLK_PER;
        vXtrDmaCmd.WrXtr <= '0';
        wait for 10*CLK_PER;
        vXtrDmaCmd.RdXtr <= '1';
        wait for 1*CLK_PER;
        vXtrDmaCmd.Adr.Set <= '0';
        vXtrDmaCmd.RdXtr <= '0';
        wait for 10*CLK_PER;
        vXtrDmaCmd.Dat.Stb <= '1'; vXtrDmaCmd.Dat.We <= '0';
        wait for 3*CLK_PER;
        vXtrDmaCmd.Dat.Stb <= '0';
        wait;
    end process pRtl;
end architecture rtl;

