//
//  MMDataProducer.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMDataConsumer.h"

#include <limits.h>

#define MM_DATA_NUM_SAMPLES_UNKNOWN UINT_MAX

@interface MMDataProducer : NSObject
{
@private
	id <MMDataConsumer> connectedConsumer;
}

// [pzion 20081010] Note that the data here is explicitly not
// const: the consumer is allow to modify it in place if it likes
-(void) produceData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples;

-(void) connectToConsumer:(id <MMDataConsumer>)consumer;
-(void) disconnect;

@property ( nonatomic, readonly ) id <MMDataConsumer> connectedConsumer;

@end
