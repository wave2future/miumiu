/*
 *  MMRect.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 22/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

typedef CGRect MMRect;
#define MMRectMake( x, y, w, h ) CGRectMake( x, y, w, h )
#define MMRectGetMinX( r ) CGRectGetMinX( r )
#define MMRectGetMidX( r ) CGRectGetMidX( r )
#define MMRectGetMaxX( r ) CGRectGetMaxX( r )
#define MMRectGetMinY( r ) CGRectGetMinY( r )
#define MMRectGetMidY( r ) CGRectGetMidY( r )
#define MMRectGetMaxY( r ) CGRectGetMaxY( r )
#define MMRectGetWidth( r ) CGRectGetWidth( r )
#define MMRectGetHeight( r ) CGRectGetHeight( r )
#define MMRectInset( r, dx, dy ) CGRectInset( r, dx, dy )