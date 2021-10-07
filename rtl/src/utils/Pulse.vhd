library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Pulse is
    generic
    (
        N       : integer := 16
    );
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        En      : in    std_logic := '1';
        Freq    : in    std_logic_vector(N - 1 downto 0);
        Cnt     : out   std_logic_vector(N downto 0);
        Q       : out   std_logic
    );
end entity Pulse;

architecture rtl of Pulse is
    signal r : std_logic_vector(N downto 0);
begin
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            r <= (others => '0');
        elsif rising_edge(Clk) then
            if SRst = '1' then
                r <= (others => '0');
            else
                if En = '1' then
                    r <= ('0' & r(N - 1 downto 0)) + ('0' & Freq);
                else
                    r <= '0' & r(N - 1 downto 0);
                end if;
            end if;
        end if;
    end process;
    Q <= r(N);
    Cnt <= r; 
end architecture rtl;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library Sim;
use Sim.Components.all;

entity PulseC is
    generic
    (
        C_FreqIn    : integer := 50_000_000;
        C_FreqOut   : integer := 1_000_000;
        N           : integer := 16
    );
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        En      : in    std_logic := '1';
        Q       : out   std_logic
    );
end entity PulseC;

architecture rtl of PulseC is
    constant C_Freq : std_logic_vector(N - 1 downto 0) := std_logic_vector(to_unsigned(integer(real(C_FreqOut) * (2.0**16) / real(C_FreqIn)), N));
    
begin
    
    uPulse : Pulse
        generic map
        (
            N       => N
        )
        port map 
        (
            ARst    => ARst,    Clk    => Clk,      SRst    => SRst, 
            En      => En,      Freq   => C_Freq, 
            Q       => Q
        );
    
end architecture rtl;