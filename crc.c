/***************************************************************************
 ** USPS_MSB_Math_CRC11GenerateFrameCheckSequence
 **
 ** Inputs:
 **   ByteArrayPtr is the address of a 13 byte array holding 102 bits which
 **   are right justified - ie: the leftmost 2 bits of the first byte do not
 **   hold data and must be set to zero.
 **
 ** Outputs:
 **   return unsigned short - 11 bit Frame Check Sequence (right justified)
 ***************************************************************************/

extern unsigned short
USPS_MSB_Math_CRC11GenerateFrameCheckSequence( unsigned char *ByteArrayPtr )
{
	unsigned short  GeneratorPolynomial = 0x0F35;
	unsigned short  FrameCheckSequence  = 0x07FF;
	unsigned short  Data;
	int             ByteIndex,Bit;

	/* Do most significant byte skipping the 2 most significant bits */
	Data = *ByteArrayPtr << 5;
	ByteArrayPtr++;

	for ( Bit = 2; Bit < 8; Bit++ ) {
		if ( (FrameCheckSequence ^ Data) & 0x400 )
			FrameCheckSequence = (FrameCheckSequence << 1) ^ GeneratorPolynomial;
		else
			FrameCheckSequence = (FrameCheckSequence << 1);
		FrameCheckSequence &= 0x7FF;
		Data <<= 1;
	}

	/* Do rest of the bytes */
	for ( ByteIndex = 1; ByteIndex < 13; ByteIndex++ ) {
		Data = *ByteArrayPtr << 3;
		ByteArrayPtr++;
		for ( Bit = 0; Bit < 8; Bit++ ) {
			if ( (FrameCheckSequence ^ Data) & 0x0400 )
				FrameCheckSequence = (FrameCheckSequence << 1) ^ GeneratorPolynomial;
			else
				FrameCheckSequence = (FrameCheckSequence << 1);

			FrameCheckSequence &= 0x7FF;
			Data <<= 1;
		}
	}

	return FrameCheckSequence;
}
