library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity SpiMaster is
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        Freq    : in    std_logic_vector(15 downto 0);
        En      : in    std_logic;
        Trg     : in    std_logic;
        TxDat   : in    std_logic_vector(7 downto 0);
        RxDat   : out   std_logic_vector(7 downto 0);
        RxVld   : out   std_logic;
        BusyFlag: out   std_logic;
        Sck     : out   std_logic;
        Mosi    : out   std_logic;
        Miso    : in    std_logic;
        Ss      : out   std_logic
    );
end entity SpiMaster;

architecture rtl of SpiMaster is
    type SPI_ST             is (ST_IDLE, ST_DATA);
    signal sSckReg          : std_logic_vector(16 downto 0);
    signal sSckEn           : std_logic;
    signal CurrentST        : SPI_ST;
    signal sBitCnt          : std_logic_vector(7 downto 0);
    signal sSck             : std_logic;
    signal sSckRE, sSckFE   : std_logic;
    signal sMosi            : std_logic;
    signal sMiso            : std_logic;
    signal sSs              : std_logic;
    signal sTxDat           : std_logic_vector(7 downto 0);
    signal sRxDat           : std_logic_vector(7 downto 0);
    signal sRxVld           : std_logic;
begin
    process (Clk)
    begin
        if rising_edge(Clk) then
            sMiso <= Miso;
        end if;
    end process;
    pGenFreq: process(Clk, ARst)
    begin
        if ARst = '1' then
            sSck <= '0';
        elsif rising_edge(Clk) then
            if SRst = '1' then
                sSck <= '0';
            else
                if sSckEn = '1' then
                    sSckReg <= ('0' & sSckReg(15 downto 0)) + ('0' & Freq);
                else
                    sSckReg <= (others => '0');
                end if;
                if sSckReg(16) = '1' then
                    sSck <= not sSck;
                end if;
            end if;
        end if;
    end process pGenFreq;
    sSckRE <= '1' when sSckReg(16) = '1' and sSck = '0' else '0';
    sSckFE <= '1' when sSckReg(16) = '1' and sSck = '1' else '0';
    process (Clk, ARst)
    begin
        if ARst = '1' then
            CurrentST <= ST_IDLE;
        elsif rising_edge(Clk) then
            if SRst = '1' then
                CurrentST <= ST_IDLE;
            else
                case CurrentST is
                    when ST_IDLE =>
                        if En = '1' then
                            if Trg = '1' then
                                CurrentST <= ST_DATA;
                            end if;
                        end if;
                    when ST_DATA =>
                        if sBitCnt(7) = '1' and sSckFE = '1' then
                            CurrentST <= ST_IDLE;
                        end if;
                    when others =>
                        CurrentST <= ST_IDLE;
                end case;
            end if;
        end if;
    end process;

    process (Clk)
        variable vTxDat : std_logic_vector(7 downto 0);
    begin
        if rising_edge(Clk) then
            case CurrentST is
                when ST_IDLE =>
                    sBitCnt <= x"01";
                    sRxVld  <= '0';
                    if En = '1' then
                        sSs <= '1';
                    else
                        sSs <= '0';
                    end if;
                    sTxDat <= TxDat;
                    vTxDat := TxDat;
                when ST_DATA => -- Complete here when more modes are added
                    if sSckFE = '1' then
                        sBitCnt <= sBitCnt(6 downto 0) & sBitCnt(7);
                        sTxDat <= sTxDat(6 downto 0) & '0';
                    end if; 
                    if sSckRE = '1' then
                        sRxDat <= sRxDat(6 downto 0) & sMiso;
                        if sBitCnt(7) = '1' then
                            sRxVld <= '1';
                        end if;
                    else
                        sRxVld <= '0';
                    end if;
                when others =>
            end case;
        end if;
    end process;
    sMosi <= sTxDat(7);
    BusyFlag <= '1' when CurrentST = ST_DATA else '0';
    sSckEn <= '1' when CurrentST = ST_DATA else '0'; -- Complete this signal when more modes are added 
    Sck  <= sSck;
    Mosi <= sMosi;
    Ss   <= sSs;
    RxDat <= sRxDat;
    RxVld <= sRxVld;
end architecture rtl;