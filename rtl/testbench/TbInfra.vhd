library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TbInfra is
    generic
    (
        CLK_PER     : time      := 20 ns;
        ARstHold    : time      := 63 ns
    );
    port 
    (
        ARst        : out std_logic;
        Clk         : out std_logic
    );
end entity TbInfra;

architecture rtl of TbInfra is
    
begin
    pARst: process
    begin
        ARst <= '1';
        wait for ARstHold;
        ARst <= '0';
        wait;
    end process pARst;
    
    pClk: process
    begin
        Clk <= '1';
        wait for CLK_PER / 2;
        Clk <= '0';
        wait for CLK_PER / 2;
    end process pClk;
    
end architecture rtl;