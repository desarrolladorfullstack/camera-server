// Calculate 16-bit CRC of the given-length data.
U16GetCrc16(constU8*pData,intnLength)
{
U16fcs=0xffff;//Initialize
while(nLength>0){
fcs=(fcs>>8)^crctab16[(fcs^*pData)&0xff];
nLength--;
pData++;
}
return ~fcs; // Negate
}