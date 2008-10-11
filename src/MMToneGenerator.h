//
//  MMToneGenerator.h
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

@interface MMToneGenerator : NSObject
{
}

+ (NSData *)generateSampleForAmplitudes:(const short *)amplitudes
	frequencies:(const unsigned *)frequencies
	count:(unsigned)count
	numSamples:(unsigned)numSamples
	samplingFrequency:(unsigned)samplingFrequency;

@end
