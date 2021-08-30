library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity EdgeDetector is
    generic
    (
        C_ASYNC : boolean := false
    );
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        E       : in    std_logic;
        RE      : out   std_logic;
        FE      : out   std_logic
    );
end entity EdgeDetector;

architecture rtl of EdgeDetector is
    signal r0 : std_logic;
    signal r1 : std_logic;
begin
    genAsync : if C_ASYNC = true generate
        process (Clk, ARst)
        begin
            if ARst = '1' then
                r0 <= '0';
            elsif rising_edge(Clk) then
                if SRst = '1' then
                    r0 <= '0';
                else
                    r0 <= E;
                end if;
            end if;
        end process;
    end generate;
    genSync : if C_ASYNC = false generate
        r0 <= E;
    end generate;
    process (Clk, ARst)
    begin
        if ARst = '1' then
            r1 <= '0';
        elsif rising_edge(Clk) then
            if SRst = '1' then
                r1 <= '0';
            else
                r1 <= r0;
            end if;
        end if;
    end process;
    RE <= (not r1) and r0;
    FE <= r1 and (not r0);
    
end architecture rtl;