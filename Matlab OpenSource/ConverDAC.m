function [Bytes] = ConverDAC(DACValue)
% This function coverts the required DAC Value into a commad for MCP4725 DAC
% note that this method uses the "fast mode" as per the datasheet

DACValue = min(DACValue,4095); %limits the DAC to the maximum value 2^12
DACValue = max(DACValue,0);    %limit2 the DAC to the minimum value 0

Bits = dec2bin(DACValue,12);

% Append '00xx' for fast mode
Bits = ['0000',Bits];

% Split the bits into two bytes
Bytes = [bin2dec(Bits(1:8)), bin2dec(Bits(9:16))];
end

