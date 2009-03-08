/*
 *  MMDecoder.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 08/03/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@protocol MMDecoderTarget;

@protocol MMDecoder <NSObject>

@required

-(void) reset;

-(void) decodeData:(void *)data
	ofSize:(unsigned)size
	toTarget:(id <MMDecoderTarget>)target;

@end
