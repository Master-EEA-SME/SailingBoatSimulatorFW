library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TbTimeout is
end entity TbTimeout;

architecture rtl of TbTimeout is
    constant CLK_PER    : time := 20 ns;
    signal ARst         : std_logic;
    signal Clk          : std_logic;
    signal TimeoutSRst  : std_logic;
    signal TimeoutEn    : std_logic;
    signal tTimeoutSRst : std_logic;
    signal tTimeoutEn   : std_logic;
begin
    
    uInfra : entity work.TbInfra
    generic map (
        CLK_PER => CLK_PER, ARstHold => 63 ns)
    port map (
        ARst => ARst, Clk => Clk);
    
    uTimeout : entity work.Timeout
        generic map (
            C_FreqIn    => 50e6,    C_FreqOut => 1e6)
        port map (
            ARst    => ARst,    Clk => Clk, SRst    => TimeoutSRst,
            En      => TimeoutEn,
            Q       => open);
    process (Clk, ARst)
    begin
        if ARst = '1' then
            TimeoutSRst <= '0';
            TimeoutEn   <= '0';
        elsif rising_edge(Clk) then
            TimeoutSRst <= tTimeoutSRst;
            TimeoutEn   <= tTimeoutEn;
        end if;
    end process;
    pRTL: process
    begin
        tTimeoutSRst    <= '0';
        tTimeoutEn      <= '0';
        wait for 5*CLK_PER;
        tTimeoutEn      <= '1';
        wait for 100*CLK_PER;
        tTimeoutEn      <= '0';
        wait for 5*CLK_PER;
        tTimeoutSRst    <= '1';
        wait for CLK_PER;
        tTimeoutSRst    <= '0';
        wait;
    end process pRTL;
end architecture rtl;