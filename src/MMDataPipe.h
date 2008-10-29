//
//  MMDataPipe.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <limits.h>

@protocol MMDataPipeDelegate;

#define MM_DATA_NUM_SAMPLES_UNKNOWN UINT_MAX

@interface MMDataPipe : NSObject
{
@protected
	id <MMDataPipeDelegate> dataPipeDelegate;
@private
	MMDataPipe *source, *target;
}

@property ( nonatomic, assign ) id <MMDataPipeDelegate> dataPipeDelegate;
@property ( nonatomic, readonly ) MMDataPipe *source;
@property ( nonatomic, readonly ) MMDataPipe *target;

// You MUST NOT override these
-(void) connectToSource:(MMDataPipe *)source;
-(void) pullData:(void *)data ofSize:(unsigned)size;
-(void) disconnectFromSource;
-(void) connectToTarget:(MMDataPipe *)_dst;
-(void) pushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples;
-(void) disconnectFromTarget;

// You MUST override these to provide functionality
-(void) respondToPullData:(void *)data ofSize:(unsigned)size;
-(void) respondToPushData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples;

@end
