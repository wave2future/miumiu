//
//  MMRingtoneGenerator.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMRingtoneGenerator.h"

#include <ringtone.h> // [pzion 20081011] From libiax2

@implementation MMRingtoneGenerator

-(id) init
{
	return [super initWithFrequency:8000 samplesPerChunk:160 sampleLoop:ringtone ofLength:sizeof(ringtone)/sizeof(ringtone[0]) onSeconds:2 offSeconds:4];
}

@end
