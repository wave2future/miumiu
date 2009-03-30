//
//  MMBusyInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMBusyInjector.h"
#import "MMToneGenerator.h"

@implementation MMBusyInjector

-(id) init
{
	static const unsigned numTones = 2;
	static const float amplitudes[] = { 8192, 8192 };
	static const float frequencies[] = { 480, 620 };
	return [super initWithSamplingFrequency:8000
		numTones:numTones
		amplitudes:amplitudes
		frequencies:frequencies
		onSeconds:0.5
		offSeconds:0.5];
}

@end
