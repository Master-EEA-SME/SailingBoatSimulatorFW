library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package XtrDef is
    type XtrAdr_t is record
        Adr : std_logic_vector(7 downto 0);
        Set : std_logic;
        Incr: std_logic_vector(7 downto 0);
        Len : std_logic_vector(7 downto 0);
    end record XtrAdr_t;

    type XtrDat_t is record
        Dat : std_logic_vector(7 downto 0);
        Stb : std_logic;
        We  : std_logic;
    end record XtrDat_t;

    type XtrCmd_t is record
        Adr : std_logic_vector(7 downto 0);
        Dat : std_logic_vector(7 downto 0);
        Stb : std_logic;
        We  : std_logic;
    end record XtrCmd_t;

    type XtrRsp_t is record
        Dat : std_logic_vector(7 downto 0);
        CRdy: std_logic;
        RRdy: std_logic;
    end record XtrRsp_t;

    type XtrDmaCmd_t is record
        Adr     : XtrAdr_t;
        Dat     : XtrDat_t;
        WrXtr   : std_logic;
        RdXtr   : std_logic;
    end record XtrDmaCmd_t;
    
    type XtrDmaRsp_t is record
        Rsp     : XtrRsp_t;
        LenCnt  : std_logic_vector(7 downto 0);
        Empty   : std_logic;
        Full    : std_logic;
        Busy    : std_logic;
    end record XtrDmaRsp_t;

    type vXtrCmd_t is array (natural range <>) of XtrCmd_t;
    type vXtrRsp_t is array (natural range <>) of XtrRsp_t;
    
end package XtrDef;