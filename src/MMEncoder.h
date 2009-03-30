/*
 *  MMEncoder.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 08/03/09.
 *  Copyright 2009 Peter Zion. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@protocol MMEncoderTarget;

@protocol MMEncoder <NSObject>

@required

-(void) reset;

-(void) encodeSamples:(short *)samples
	count:(unsigned)count
	toTarget:(id <MMEncoderTarget>)target;

@end
