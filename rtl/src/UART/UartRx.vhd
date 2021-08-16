library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity UartRx is
    port 
    (
        ARst    : in    std_logic := '0';
        Clk     : in    std_logic;
        SRst    : in    std_logic := '0';
        Baud16  : in    std_logic;
        En      : in    std_logic := '1';
        RxEn    : out   std_logic;
        RxDat   : out   std_logic_vector(7 downto 0);
        Rx      : in    std_logic
    );
end entity UartRx;

architecture rtl of UartRx is
    type UART_ST is (ST_IDLE, ST_START, ST_DATA, ST_STOP);
    signal CurrentST    : UART_ST;
    signal BaudEn       : std_logic;
    signal CptBit       : std_logic_vector(7 downto 0);
    signal vRx          : std_logic;
begin

    pSampleRx: process(Clk)
    begin
        if rising_edge(Clk) then
            vRx <= Rx;
        end if;
    end process pSampleRx;

    pFSM: process(Clk, ARst)
    begin
        if ARst = '1' then
            CurrentST <= ST_IDLE;
        elsif rising_edge(Clk) then
            if SRst = '1' then
                CurrentST <= ST_IDLE;
            else
                case CurrentST is
                    when ST_IDLE =>
                        if En = '1' and vRx = '0' then
                            CurrentST <= ST_START;
                        end if;
                    when ST_START =>
                        if BaudEn = '1' then
                            CurrentST <= ST_DATA;
                        end if;
                    when ST_DATA =>
                        if BaudEn = '1' and CptBit(7) = '1' then
                            CurrentST <= ST_STOP;
                        end if;
                    when ST_STOP =>
                        if BaudEn = '1' then
                            CurrentST <= ST_IDLE;
                        end if;
                    when others =>
                        CurrentST <= ST_IDLE;
                end case;
            end if;
        end if;
    end process pFSM;
    pBaudGen : process (Clk)
        variable CptBaud    : std_logic_vector(3 downto 0);
    begin
        if rising_edge(Clk) then
            if CurrentST /= ST_IDLE then
                if Baud16 = '1' then
                    CptBaud := CptBaud + 1;
                end if;
            else
                CptBaud := (others => '0');
            end if;
            if CptBaud = 8 and Baud16 = '1' then
                BaudEn <= '1';
            else
                BaudEn <= '0';
            end if;
        end if;
    end process pBaudGen;
    pRx: process(Clk)
        variable vRxDat : std_logic_vector(7 downto 0);
    begin
        if rising_edge(Clk) then
            case CurrentST is
                when ST_IDLE =>
                    CptBit <= x"01";
                    RxEn <= '0';
                when ST_DATA =>
                    if BaudEn = '1' then
                        vRxDat := vRx & vRxDat(7 downto 1);
                        CptBit <= CptBit(6 downto 0) & CptBit(7);
                    end if;
                when ST_STOP =>
                    RxDat <= vRxDat;
                    if BaudEn = '1' then
                        if vRx = '1' then
                            RxEn <= '1';
                        end if;
                    end if;
                when others =>
            end case;
        end if;
    end process pRx;
end architecture rtl;