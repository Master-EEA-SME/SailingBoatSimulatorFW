library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TbUART is
end entity TbUART;

architecture rtl of TbUART is
    constant CLK_PER    : time := 20 ns;
    constant BAUD_PER   : time := 8.68055 us;
    --constant BAUD_PER1  : real := 1.0/115200.0;
    signal ARst         : std_logic;
    signal Clk          : std_logic;

    signal Rx           : std_logic;
    signal TxVld        : std_logic;
    signal TxDat        : std_logic_vector(7 downto 0);
    signal TxBusy       : std_logic;
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
    
    Uart_inst : entity work.Uart
        generic map 
        (
            C_FreqIn    => 50_000_000,
            C_FreqOut   => 115_200
        )
        port map 
        (
            ARst        => ARst,
            Clk         => Clk,
            SRst        => '0',
            En          => '1',
            TxVld       => TxVld,
            TxDat       => TxDat,
            RxVld       => open,
            RxDat       => open,
            TxBusyFlag  => TxBusy,
            Rx          => Rx,
            Tx          => open
        );
    process (Clk, ARst)
    begin
        if ARst = '1' then
            TxDat <= (others => '0');
            TxVld <= '0';
        elsif rising_edge(Clk) then
            TxDat <= x"55";
            TxVld <= not TxBusy;
        end if;
    end process;
    pRTL: process
    begin
        Rx <= '1';
        wait for 3*CLK_PER;
        Rx <= '0';          -- START
        wait for BAUD_PER;
        Rx <= '1';          -- B0
        wait for BAUD_PER;
        Rx <= '0';          -- B1
        wait for BAUD_PER;
        Rx <= '1';          -- B2
        wait for BAUD_PER;
        Rx <= '0';          -- B3
        wait for BAUD_PER;
        Rx <= '1';          -- B4
        wait for BAUD_PER;
        Rx <= '0';          -- B5
        wait for BAUD_PER;
        Rx <= '1';          -- B6
        wait for BAUD_PER;
        Rx <= '0';          -- B7
        wait for BAUD_PER;
        Rx <= '1';          -- STOP
        wait;
    end process pRTL;
      
end architecture rtl;