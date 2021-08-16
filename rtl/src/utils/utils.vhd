library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package utils is


    function bitWidth (value : in integer) return integer;
    
    
end package utils;

package body utils is
    function bitWidth (value : in integer) return integer is
        variable ret : integer;
    begin
        ret := integer(ceil(log2(real(value))));
        return ret;
    end function;    
end package body;