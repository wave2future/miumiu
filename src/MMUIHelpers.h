//
//  untitled.h
//  MiuMiu
//
//  Created by Peter Zion on 28/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMFloat.h"
#import "MMRect.h"

void MMDistributeEvenly( MMFloat start, MMFloat size, unsigned count, MMFloat starts[], MMFloat sizes[] );
void MMSubdivideRectEvenly( MMRect rect, unsigned rows, unsigned cols, MMRect subRects[] );
