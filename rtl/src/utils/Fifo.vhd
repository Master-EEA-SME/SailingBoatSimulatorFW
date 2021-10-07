library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library Sim;
use Sim.utils.all;

entity Fifo is
    generic
    (
        C_Depth : integer := 512;
        C_Width : integer := 16
    );
    port 
    (
        ARst        : in    std_logic := '0';
        Clk         : in    std_logic;
        SRst        : in    std_logic := '0';
        PushEn      : in    std_logic;
        PushDat     : in    std_logic_vector(C_Width - 1 downto 0);
        PopEn       : in    std_logic;
        PopDat      : out   std_logic_vector(C_Width - 1 downto 0);
        EmptyFlag   : out   std_logic;
        FullFlag    : out   std_logic
    );
end entity Fifo;

architecture rtl of Fifo is
    type Fifo_t is array (0 to C_Depth - 1) of std_logic_vector(C_Width - 1 downto 0);
    signal FifoDat      : Fifo_t;
    signal DataCount    : std_logic_vector(bitWidth(C_Depth + 1) - 1 downto 0);
    signal WrPtr, RdPtr : std_logic_vector(bitWidth(C_Depth) - 1 downto 0);
    signal vEmptyFlag   : std_logic;
    signal vFullFlag    : std_logic;
begin
    
    process (Clk, ARst)
    begin
        if ARst = '1' then
            WrPtr       <= (others => '0');
            RdPtr       <= (others => '0');
            DataCount   <= (others => '0');
        elsif rising_edge(Clk) then
            if SRst = '1' then
                WrPtr       <= (others => '0');
                RdPtr       <= (others => '0');
                DataCount   <= (others => '0');
            else
                if PushEn = '1' and vFullFlag = '0' then
                    FifoDat(to_integer(unsigned(WrPtr))) <= PushDat;
                    if WrPtr < C_Depth - 1 then
                        WrPtr <= WrPtr + 1;
                    else
                        WrPtr <= (others => '0');
                    end if;
                end if;
                if PopEn = '1' and vEmptyFlag = '0' then
                    PopDat <= FifoDat(to_integer(unsigned(RdPtr)));
                    if RdPtr < C_Depth - 1 then
                        RdPtr <= RdPtr + 1;
                    else
                        RdPtr <= (others => '0');
                    end if;
                end if;
                if PushEn = '1' and vFullFlag = '0' then
                    DataCount <= DataCount + 1;
                elsif PopEn = '1' and vEmptyFlag = '0' then
                    DataCount <= DataCount - 1;
                end if;
            end if;
        end if;
    end process;
    vFullFlag  <= '1' when DataCount = C_Depth else '0';
    vEmptyFlag <= '1' when DataCount = 0 else '0';
    FullFlag <= vFullFlag;
    EmptyFlag <= vEmptyFlag;
end architecture rtl;