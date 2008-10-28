//
//  untitled.m
//  MiuMiu
//
//  Created by Peter Zion on 28/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMUIHelpers.h"

void MMDistributeEvenly( MMFloat start, MMFloat size, unsigned count, MMFloat starts[], MMFloat sizes[] )
{
	MMFloat subSize = size/count;
	starts[0] = start;
	for ( int i=1; i<count; ++i )
	{
		starts[i] = MMFloatRound( starts[i-1] + subSize );
		sizes[i-1] = starts[i] - starts[i-1];
	}
	sizes[count-1] = start + size - starts[count-1];
}

void MMSubdivideRectEvenly( MMRect rect, unsigned rows, unsigned cols, MMRect subRects[] )
{
	MMFloat *rowStarts = alloca( rows * sizeof(MMFloat) );
	MMFloat *rowSizes = alloca( rows * sizeof(MMFloat) );
	MMDistributeEvenly( MMRectGetMinY(rect), MMRectGetHeight(rect), rows, rowStarts, rowSizes );
	
	MMFloat *colStarts = alloca( cols * sizeof(MMFloat) );
	MMFloat *colSizes = alloca( cols * sizeof(MMFloat) );
	MMDistributeEvenly( MMRectGetMinX(rect), MMRectGetWidth(rect), cols, colStarts, colSizes );
	
	for ( unsigned row=0; row<rows; ++row )
	{
		for ( unsigned col=0; col<cols; ++col )
		{
			subRects[row*cols + col] = MMRectMake( colStarts[col], rowStarts[row], colSizes[col], rowSizes[row] );
		}
	}
}
