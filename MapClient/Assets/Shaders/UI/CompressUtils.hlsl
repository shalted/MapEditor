void DecompressFloat(float compressed, out float a, out float b)
{
    uint combined = asuint(compressed);
    uint aInt = (combined >> 16) & 65535; 
    uint bInt = combined & 65535;    
    a = float(aInt) / 1024;
    b = float(bInt) / 1024;
}