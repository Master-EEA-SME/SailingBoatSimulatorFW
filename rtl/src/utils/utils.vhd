library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package utils is


    function bitWidth(value : in integer) return integer;
    function freq2reg(freq : real; sys_freq : real; N : integer) return std_logic_vector;
    
    
end package utils;

package body utils is
    function bitWidth(value : in integer) return integer is
        variable ret : integer;
    begin
        ret := integer(ceil(log2(real(value))));
        return ret;
    end function;  
    
    function freq2reg(freq : real; sys_freq : real; N : integer) return std_logic_vector is
        variable ret : std_logic_vector(N - 1 downto 0);
    begin
        ret := std_logic_vector(to_unsigned(integer(freq * (2.0**16) / sys_freq), N));
        return ret;
    end function;
end package body;