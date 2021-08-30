library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SpiSlave is
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        TxDat   : in    std_logic_vector(7 downto 0);
        TxRdy   : out   std_logic;
        RxDat   : out   std_logic_vector(7 downto 0);
        RxVld   : out   std_logic;
        Sck     : in    std_logic;
        Mosi    : in    std_logic;
        Miso    : out   std_logic;
        Ss      : in    std_logic
    );
end entity SpiSlave;

architecture rtl of SpiSlave is
    type SPI_ST             is (ST_IDLE, ST_DATA);
    signal CurrentST        : SPI_ST;
    signal CptBit           : std_logic_vector(7 downto 0);
    signal vSck             : std_logic;
    signal vMosi            : std_logic;
    signal vMiso            : std_logic;
    signal vSs              : std_logic;
    signal vSckRE, vSckFE   : std_logic;
    signal vTxDat : std_logic_vector(7 downto 0);
    signal vRxDat : std_logic_vector(7 downto 0);
    signal vRxVld : std_logic;

    attribute mark_debug                : string;
    attribute mark_debug of CurrentST   : signal is "true";
    attribute mark_debug of CptBit      : signal is "true";
    attribute mark_debug of vTxDat      : signal is "true";
    attribute mark_debug of vRxVld      : signal is "true";
    attribute mark_debug of vSck        : signal is "true";
    attribute mark_debug of vMosi       : signal is "true";
    attribute mark_debug of vMiso       : signal is "true";
    attribute mark_debug of vSs         : signal is "true";
begin
    process (Clk)
    begin
        if rising_edge(Clk) then
            vSck    <= Sck; 
            vMosi   <= Mosi; 
            vSs     <= Ss; 
        end if;
    end process;
    uSckED : entity work.EdgeDetector
        generic map (C_ASYNC => False)
        port map (ARst => ARst, Clk => Clk,   SRst => SRst, 
                  E    => vSck, RE  => vSckRE,FE   => vSckFE);
    
    pFsm : process (Clk, ARst)
    begin
        if ARst = '1' then
            CurrentST <= ST_IDLE;
        elsif rising_edge(Clk) then
            if SRst = '1' then
                CurrentST <= ST_IDLE;
            else
                case CurrentST is
                    when ST_IDLE =>
                        if vSs = '1' and vSck = '0' then
                            CurrentST <= ST_DATA;
                        end if;
                    when ST_DATA =>
                        if vSs = '0' then
                            CurrentST <= ST_IDLE;
                        elsif CptBit(7) = '1' and vSckFE = '1' then
                            CurrentST <= ST_IDLE;
                        end if;
                    when others =>
                        CurrentST <= ST_IDLE;
                end case;
            end if;
        end if;
    end process pFsm;

    process (Clk)
    begin
        if rising_edge(Clk) then
            case CurrentST is
                when ST_IDLE =>
                    CptBit   <= x"01";
                    vRxVld   <= '0';
                    vTxDat   <= TxDat;
                when ST_DATA =>
                    if vSckRE = '1' then
                        vRxDat <= vRxDat(6 downto 0) & vMosi;
                        vTxDat <= vTxDat(6 downto 0) & '0';
                        if CptBit(7) = '1' then
                            vRxVld <= '1';
                        end if;
                    else
                        vRxVld <= '0';
                    end if;
                    if vSckFE = '1' then
                        CptBit <= CptBit(6 downto 0) & CptBit(7);
                    end if;
                when others =>
            end case;
        end if;
    end process;
    vMiso <= vTxDat(7);
    Miso <= vMiso when vSs = '1' else '1';
    RxDat <= vRxDat;
    RxVld <= vRxVld;
end architecture rtl;