library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.XtrDef.all;

entity XtrAdc is
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        XtrCmd  : in    XtrCmd_t;
        XtrRsp  : out   XtrRsp_t;
        Sck     : in    std_logic;
        Mosi    : in    std_logic;
        Miso    : out   std_logic;
        Ss      : in    std_logic
    );
end entity XtrAdc;

architecture rtl of XtrAdc is
    -- Infra
    signal sAnalog      : std_logic_vector(11 downto 0);
    -- Spi interface
    signal SpiTxDat     : std_logic_vector(7 downto 0);
    signal SpiRxVld     : std_logic;
    signal sSs          : std_logic;
    attribute mark_debug                : string;
    attribute mark_debug of sAnalog     : signal is "true";
begin
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            sAnalog <= (others => '0');
        elsif rising_edge(Clk) then
            if SRst = '1' then
                sAnalog <= (others => '0');
            else
                if XtrCmd.Stb = '1' then
                    if XtrCmd.We = '1' then
                        if XtrCmd.Adr(0) = '1' then
                            sAnalog(11 downto 8) <= XtrCmd.Dat(3 downto 0);
                        else
                            sAnalog(7 downto 0) <= XtrCmd.Dat;
                        end if;
                    else
                        if XtrCmd.Adr(0) = '1' then
                            XtrRsp.Dat <= x"0" & sAnalog(11 downto 8);
                        else
                            XtrRsp.Dat <= sAnalog(7 downto 0);
                        end if;
                    end if;
                end if;
                XtrRsp.RRDY <= XtrCmd.Stb;
            end if;
        end if;
    end process;
    XtrRsp.CRDY <= XtrCmd.Stb;

    -- SPI SLAVE
    uSpiSlave : entity work.SpiSlave
        port map
        (
            ARst    => ARst,
            Clk     => Clk,
            SRst    => SRst,
            TxDat   => SpiTxDat,
            TxRdy   => open,
            RxDat   => open,
            RxVld   => SpiRxVld,
            Sck     => Sck,
            Mosi    => Mosi,
            Miso    => Miso,
            Ss      => sSs
        );
    sSs <= Ss;
    -- SPI ADC
    uSpiAdc : entity work.SpiAdc
        port map
        (
            ARst    => ARst,
            Clk     => Clk,
            SRst    => SRst,
            En      => sSs,
            Reg     => sAnalog,
            RxVld   => SpiRxVld,
            TxDat   => SpiTxDat
        );
    
end architecture rtl;