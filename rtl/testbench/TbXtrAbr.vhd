library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.XtrDef.all;

entity TbXtrAbr is
end entity TbXtrAbr;

architecture rtl of TbXtrAbr is
    constant CLK_PER    : time := 20 ns;
    constant C_MASK     : integer := 16#80#;
    constant C_Slave    : integer := 2;
    signal ARst         : std_logic;
    signal Clk          : std_logic;

    signal tXtrCmd      : XtrCmd_t;
    signal XtrCmd       : XtrCmd_t;
    signal XtrRsp       : XtrRsp_t;
    signal vXtrCmd      : vXtrCmd_t(0 to C_Slave - 1);
    signal vXtrRsp      : vXtrRsp_t(0 to C_Slave - 1);
begin
    
    uInfra : entity work.TbInfra
        generic map
        (
            CLK_PER     => CLK_PER,
            ARstHold    => 63 ns
        )
        port map
        (
            ARst        => ARst,
            Clk         => Clk
        );

    uXtrAbr : entity work.XtrAbr
        generic map
        (
            C_MMSB  => 7,
            C_MLSB  => 7,
            C_MASK  => C_MASK,
            C_Slave => C_Slave
        )
        port map
        (
            ARst    => ARst,
            Clk     => Clk,
            SRst    => '0',
            XtrCmd  => XtrCmd,
            XtrRsp  => XtrRsp,
            vXtrCmd => vXtrCmd,
            vXtrRsp => vXtrRsp
        );
    process (Clk, ARst)
    begin
        if ARst = '1' then
            XtrCmd.Stb <= '0';
        elsif rising_edge(Clk) then
            XtrCmd <= tXtrCmd;
        end if;
    end process;
    --genRsp: for i in 0 to C_Slave - 1 generate
    --    --vXtrRsp(i).CRDY <= vXtrCmd(i).Stb;
    --end generate genRsp;

    process (Clk, ARst)
    begin
        if ARst = '1' then
            for i in 0 to C_Slave - 1 loop
                vXtrRsp(i).RRDY <= '0';
                --vXtrRsp(i).CRDY <= '0';
            end loop;
        elsif rising_edge(Clk) then
            for i in 0 to C_Slave - 1 loop
                vXtrRsp(i).RRDY <= vXtrCmd(i).Stb;
                --vXtrRsp(i).CRDY <= '1';
                vXtrRsp(i).Dat  <= x"55";
            end loop;
        end if;
--        for i in 0 to C_Slave - 1 loop
--            vXtrRsp(i).CRDY <= vXtrCmd(i).Stb;
--        end loop;
    end process;
    vXtrRsp(0).CRDY <= '1';
    vXtrRsp(1).CRDY <= '1';
    pRTL: process
    begin
        tXtrCmd.Stb <= '0';
        wait for 5*CLK_PER;
        tXtrCmd.Stb <= '1'; tXtrCmd.Adr <= x"50"; tXtrCmd.We <= '1'; tXtrCmd.Dat <= x"AA";
        wait for CLK_PER;
        tXtrCmd.Stb <= '0'; tXtrCmd.Adr <= x"20";
        wait for CLK_PER;
        tXtrCmd.Stb <= '1'; tXtrCmd.Adr <= x"C0"; tXtrCmd.We <= '0';
        wait for CLK_PER;
        tXtrCmd.Stb <= '0'; tXtrCmd.Adr <= x"60";
        wait;
    end process pRTL;

    
end architecture rtl;