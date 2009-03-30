/*
 *  MMSampleConsumer.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 08/03/09.
 *  Copyright 2009 Peter Zion. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

#include <limits.h>
#define MM_DATA_NUM_SAMPLES_UNKNOWN UINT_MAX

@protocol MMSampleProducer;

@protocol MMSampleConsumer <NSObject>

@required

-(void) reset;
-(void) consumeSamples:(short *)data count:(unsigned)count;

@end
