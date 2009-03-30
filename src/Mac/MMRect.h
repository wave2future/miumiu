/*
 *  MMRect.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 23/10/08.
 *  Copyright 2008 Peter Zion. All rights reserved.
 *
 */

typedef NSRect MMRect;
#define MMRectMake( x, y, w, h ) NSMakeRect( (x), (y), (w), (h) )
#define MMRectGetMinX( r ) ((r).origin.x)
#define MMRectGetMidX( r ) ((r).origin.x+(r).size.width/2)
#define MMRectGetMaxX( r ) ((r).origin.x+(r).size.width)
#define MMRectGetMinY( r ) ((r).origin.y)
#define MMRectGetMidY( r ) ((r).origin.y+(r).size.height/2)
#define MMRectGetMaxY( r ) ((r).origin.y+(r).size.height)
#define MMRectGetWidth( r ) ((r).size.width)
#define MMRectGetHeight( r ) ((r).size.height)
#define MMRectInset( r, dx, dy ) NSMakeRect( (r).origin.x+(dx), (r).origin.y+(dy), (r).size.width-2*(dx), (r).size.height-2*(dy) )