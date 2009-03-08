/*
 *  MMDecoderTarget.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 08/03/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

@protocol MMDecoder;

@protocol MMDecoderTarget

@required

-(void) decoder:(id <MMDecoder>)decoder
	didDecodeSamples:(short *)samples
	count:(unsigned)count
	fromData:(const void *)data
	ofSize:(unsigned)size;

@end
