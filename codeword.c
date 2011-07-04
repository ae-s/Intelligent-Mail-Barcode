#include <stdio.h>
#include <stdlib.h>

int main(int *argc, char **argv)
{
	int *table5, *table2, i;

	table5 = malloc(1286 * sizeof(int));
	table2 = malloc(78 * sizeof(int));

	InitializeNof13Table(table5, 5, 1287);
	InitializeNof13Table(table2, 2, 78);

	printf("module USPScode\n  CODEWORDS = [");
	for (i = 0; i < 1287; i++) {
		printf("%d, ", table5[i]);
	}

	for (i = 0; i < 78; i++) {
		printf("%d, ", table2[i]);
	}
	printf("]\nend\n");

	return;
}

extern unsigned short
ReverseUnsignedShort( unsigned short  Input )
{
	unsigned short  Reverse = 0;
	int             Index;

	for ( Index = 0; Index < 16; Index++ ) {
		Reverse <<= 1;
		Reverse  |= Input & 1;
		Input   >>= 1;
	}

	return Reverse;
}

/******************************************************************************
 ** InitializeNof13Table
 **
 ** Inputs:
 **  N is the type of table (i.e. 5 for 5of13 table, 2 for 2of13 table
 **  TableLength is the length of the table requested (i.e. 78 for 2of13 table)
 ** Output:
 **  TableNof13 is a pointer to the resulting table
 ******************************************************************************/

int InitializeNof13Table( int *TableNof13  ,
                      int  N           ,
                      int  TableLength )
{
	int  Count,Reverse;
	int  LUT_LowerIndex,LUT_UpperIndex;
	int  BitCount;
	int  BitIndex;

	/* Count up to 2^13 - 1 and find all those values that have N bits on */
	LUT_LowerIndex = 0;
	LUT_UpperIndex = TableLength - 1;

	for ( Count = 0; Count < 8192; Count++ ) {
		BitCount = 0;
		for ( BitIndex = 0; BitIndex < 13; BitIndex++ )
			BitCount += ((Count & (1 << BitIndex)) != 0);

		/* If we don't have the right number of bits on, go on to the next value */
		if ( BitCount != N )
			continue;

		/* If the reverse is less than count, we have already visited this pair before */
		Reverse = ReverseUnsignedShort( Count ) >> 3;
		if ( Reverse < Count )
			continue;

		/* If Count is symmetric, place it at the first free slot from the end of the  */
		/* list. Otherwise, place it at the first free slot from the beginning of the  */
		/* list AND place Reverse at the next free slot from the beginning of the list.*/

		if ( Count == Reverse ) {
			TableNof13[LUT_UpperIndex] = Count;
			LUT_UpperIndex -= 1;
		} else {
			TableNof13[LUT_LowerIndex] = Count;
			LUT_LowerIndex += 1;
			TableNof13[LUT_LowerIndex] = Reverse;
			LUT_LowerIndex += 1;
		}
	}

	/* Make sure the lower and upper parts of the table meet properly */
	if ( LUT_LowerIndex != (LUT_UpperIndex+1) )
		return 0;

	return 1;
}
