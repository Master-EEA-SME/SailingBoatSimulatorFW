library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.utils.all;

entity TbSpiAdc is
end entity TbSpiAdc;

architecture rtl of TbSpiAdc is
    constant CLK_PER    : time := 20 ns;
    signal ARst         : std_logic;
    signal Clk          : std_logic;

    signal tEn          : std_logic;
    signal tTrg         : std_logic;
    signal tAdcReg      : std_logic_vector(11 downto 0);

    signal sEn          : std_logic;
    signal sTrg         : std_logic;

    signal SpiSck       : std_logic;
    signal SpiMosi      : std_logic;
    signal SpiMiso      : std_logic;
    signal SpiSs        : std_logic;

    signal SpiSlvRxDat  : std_logic_vector(7 downto 0);
    signal SpiSlvRxVld  : std_logic;
    signal SpiSlvTxDat  : std_logic_vector(7 downto 0);
begin
    
    uInfra : entity work.TbInfra
        generic map (CLK_PER    => CLK_PER, ARstHold    => 63 ns)
        port map    (ARst       => ARst,    Clk         => Clk);
    -- SPI MASTER
    uSpiMaster : entity work.SpiMaster
        port map
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => '0',
            Freq        => freq2reg(real(25e6), real(50e6), 16),
            En          => sEn,
            Trg         => sTrg,
            TxDat       => x"AA",
            RxDat       => open,
            RxVld       => open,
            BusyFlag    => open,
            Sck         => SpiSck,
            Mosi        => SpiMosi,
            Miso        => SpiMiso,
            Ss          => SpiSs
        );

    -- SPI SLAVE
    uSpiSlave : entity work.SpiSlave
        port map
        (
            ARst    => ARst,
            Clk     => Clk,
            SRst    => '0',
            TxDat   => SpiSlvTxDat,
            TxRdy   => open,
            RxDat   => SpiSlvRxDat,
            RxVld   => SpiSlvRxVld,
            Sck     => SpiSck,
            Mosi    => SpiMosi,
            Miso    => SpiMiso,
            Ss      => SpiSs
        );
    -- SPI ADC
    uSpiAdc : entity work.SpiAdc
        port map
        (
            ARst    => ARst,
            Clk     => Clk,
            SRst    => '0',
            En      => SpiSs,
            Reg     => tAdcReg,
            RxVld   => SpiSlvRxVld,
            RxDat   => SpiSlvRxDat,
            TxDat   => SpiSlvTxDat
        );
    process (Clk, ARst)
    begin
        if ARst = '1' then
            sEn  <= '0';
            sTrg <= '0';
        elsif rising_edge(Clk) then
            sEn  <= tEn;
            sTrg <= tTrg;
        end if;
    end process;
    pRTL: process
    begin
        tEn     <= '0';
        tTrg    <= '0';
        tAdcReg <= x"456";
        wait for 3*CLK_PER;
        tEn <= '1';
        wait for CLK_PER;
        tTrg <= '1';
        wait;
    end process pRTL;
end architecture rtl;