/*
 *  MMEncoderTarget.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 08/03/09.
 *  Copyright 2009 Peter Zion. All rights reserved.
 *
 */
 
@protocol MMEncoder;

@protocol MMEncoderTarget

@required

-(void) encoder:(id <MMEncoder>)encoder
	didEncodeData:(void *)data
	ofSize:(unsigned)size
	correspondingToSamples:(const short *)samples
	count:(unsigned)count;

@end
