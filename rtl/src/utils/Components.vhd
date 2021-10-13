library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library Sim;
use Sim.XtrDef.all;

package Components is
    
    component Dma is
        generic (
            C_Depth     : integer := 512
        );
        port (
            ARst        : in    std_logic := '0';
            Clk         : in    std_logic;
            SRst        : in    std_logic := '0';
            XtrDmaCmd   : in    XtrDmaCmd_t;
            XtrDmaRsp   : out   XtrDmaRsp_t;
            XtrCmd      : out   XtrCmd_t;
            XtrRsp      : in    XtrRsp_t
        );
    end component;

    component EdgeDetector is
        generic (
            C_ASYNC : boolean := false
        );
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            E       : in    std_logic;
            RE      : out   std_logic;
            FE      : out   std_logic
        );
    end component;

    component Fifo is
        generic (
            C_Depth     : integer := 512;
            C_Width     : integer := 16
        );
        port (
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
    end component;

    component Pulse is
        generic (
            N       : integer := 16
        );
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            En      : in    std_logic := '1';
            Freq    : in    std_logic_vector(N - 1 downto 0);
            Cnt     : out   std_logic_vector(N downto 0);
            Q       : out   std_logic
        );
    end component;

    component PulseC is
        generic (
            C_FreqIn    : integer := 50_000_000;
            C_FreqOut   : integer := 1_000_000;
            N           : integer := 16
        );
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            En      : in    std_logic := '1';
            Q       : out   std_logic
        );
    end component;

    component Timeout is
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
    end component;

    component XtrAbr is
        generic (
            C_MMSB  : integer := 31;
            C_MLSB  : integer := 16;
            C_MASK  : integer := 16#00000000#;
            C_Slave : integer := 4
        );
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            XtrCmd  : in    XtrCmd_t;
            XtrRsp  : out   XtrRsp_t;
            vXtrCmd : out   vXtrCmd_t(0 to C_Slave - 1);
            vXtrRsp : in    vXtrRsp_t(0 to C_Slave - 1)
        );
    end component;

    component Comm is
        generic (
            C_Freq      : integer := 50_000_000
        );
        port (
            ARst        : in    std_logic := '0';
            Clk         : in    std_logic;
            SRst        : in    std_logic := '0';
            RxVld       : in    std_logic;
            RxDat       : in    std_logic_vector(7 downto 0);
            TxVld       : out   std_logic;
            TxDat       : out   std_logic_vector(7 downto 0);
            TxRdy       : in    std_logic;
            TxBusy      : in    std_logic;
            XtrRst      : out   std_logic;
            XtrDmaCmd   : out   XtrDmaCmd_t;
            XtrDmaRsp   : in    XtrDmaRsp_t
        );
    end component;

    component SpiAdc is
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            En      : in    std_logic;
            Reg     : in    std_logic_vector(11 downto 0);
            RxVld   : in    std_logic;
            TxDat   : out   std_logic_vector(7 downto 0)
        );
    end component;

    component XtrAdc is
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            XtrCmd  : in    XtrCmd_t;
            XtrRsp  : out   XtrRsp_t;
            Sck     : in    std_logic;
            Mosi    : in    std_logic;
            Miso    : out   std_logic;
            Ss      : in    std_logic
        );
    end component;

    component PwmMaster is
        generic (
            N   : integer := 16
        );
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            En      : in    std_logic;
            Duty    : in    std_logic_vector(N - 1 downto 0);
            Freq    : in    std_logic_vector(N - 1 downto 0);
            Q       : out   std_logic
        );
    end component;

    component PwmSlave is
        generic (
            C_Freq  : integer := 50_000_000;
            N       : integer := 16
        );
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            En      : in    std_logic;
            E       : in    std_logic;
            Duty    : out   std_logic_vector(N - 1 downto 0);
            Freq    : out   std_logic_vector(N - 1 downto 0)
        );
    end component;

    component XtrPwmMaster is
        port (
            ARst    : in    std_logic;
            Clk     : in    std_logic;
            SRst    : in    std_logic;
            XtrCmd  : in    XtrCmd_t;
            XtrRsp  : out   XtrRsp_t;
            Q       : out   std_logic
        );
    end component;

    component XtrPwmSlave is
        generic (
            C_Freq  : integer := 50_000_000
        );
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            E       : in    std_logic;
            XtrCmd  : in    XtrCmd_t;
            XtrRsp  : out   XtrRsp_t
        );
    end component;

    component SpiSlave is
        port (
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
    end component;

    component Uart is
        generic (
            C_FreqIn    : integer := 50_000_000;
            C_FreqOut   : integer := 115_200
        );
        port (
            ARst        : in    std_logic := '0';
            Clk         : in    std_logic;
            SRst        : in    std_logic := '0';
            En          : in    std_logic;
            TxVld       : in    std_logic;
            TxDat       : in    std_logic_vector(7 downto 0);
            RxVld       : out   std_logic;
            RxDat       : out   std_logic_vector(7 downto 0);
            TxBusyFlag  : out   std_logic;
            Rx          : in    std_logic;
            Tx          : out   std_logic
        );
    end component;

    component UartRx is
        port (
            ARst    : in    std_logic := '0';
            Clk     : in    std_logic;
            SRst    : in    std_logic := '0';
            Baud16  : in    std_logic;
            En      : in    std_logic := '1';
            RxEn    : out   std_logic;
            RxDat   : out   std_logic_vector(7 downto 0);
            Rx      : in    std_logic
        );
    end component;

    component UartTx is
        port (
            ARst        : in    std_logic := '0';
            Clk         : in    std_logic;
            SRst        : in    std_logic := '0';
            Baud16      : in    std_logic;
            En          : in    std_logic := '1';
            TxEn        : in    std_logic;
            TxDat       : in    std_logic_vector(7 downto 0);
            BusyFlag    : out   std_logic;
            Tx          : out   std_logic
        );
    end component;
    
end package Components;