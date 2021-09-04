library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.utils.all;

entity Timeout is
    generic (
        C_FreqIn    : integer := 50_000_000;
        C_FreqOut   : integer := 1_000_000
    );
    port (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        En      : in    std_logic;
        Q       : out   std_logic
    );
end entity Timeout;

architecture rtl of Timeout is
    constant incr   : std_logic_vector(23 downto 0) := freq2reg(real(C_FreqOut), real(C_FreqIn), 24);
    signal r        : std_logic_vector(24 downto 0);
    signal sQ       : std_logic;
    signal sEn      : std_logic;
begin
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            r <= (others => '0');
        elsif rising_edge(Clk) then
            if SRst = '1' then
                r <= (others => '0');
            else
                if sEn = '1' then
                    r <= std_logic_vector(('0' & unsigned(r(23 downto 0))) + ('0' & unsigned(incr)));
                end if;
            end if;
        end if;
    end process;
    sQ  <= r(r'left);
    sEn <= '0' when sQ = '1' else En;
    Q   <= sQ;
end architecture rtl;