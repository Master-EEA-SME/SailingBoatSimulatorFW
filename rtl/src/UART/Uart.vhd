library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Uart is
    generic
    (
        C_FreqIn    : integer := 50_000_000;
        C_FreqOut   : integer := 115_200
    );
    port 
    (
        ARst        : in    std_logic := '0';
        Clk         : in    std_logic;
        SRst        : in    std_logic := '0';
        En          : in    std_logic;
        TxVld       : in    std_logic;
        TxDat       : in    std_logic_vector(7 downto 0);
        RxVld       : out   std_logic;
        RxDat       : out   std_logic_vector(7 downto 0);
        TxBusyFlag  : out   std_logic;
        Rx          : in    std_logic;
        Tx          : out   std_logic
    );
end entity Uart;

architecture rtl of Uart is
    signal Baud16 : std_logic;
begin
    
    uBaud : entity work.PulseC
        generic map
        (
            C_FreqIn    => C_FreqIn, C_FreqOut  => C_FreqOut*16, N    => 16
        )
        port map
        (
            ARst    => ARst,    Clk     => Clk, SRst   => SRst, 
            En      => En,
            Q       => Baud16
        );
    
    uUartTx : entity work.UartTx
        port map
        (
            ARst    => ARst,    Clk     => Clk,     SRst        => SRst,
            En      => En,      Baud16  => Baud16,
            TxEn    => TxVld,   TxDat   => TxDat,   BusyFlag    => TxBusyFlag,
            Tx      => Tx
        );
    uUartRx : entity work.UartRx
        port map
        (
            ARst    => ARst,    Clk     => Clk,     SRst    => SRst,
            En      => En,      Baud16  => Baud16,
            RxEn    => RxVld,   RxDat   => RxDat,
            Rx      => Rx
        );
end architecture rtl;