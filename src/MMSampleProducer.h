/*
 *  MMSampleProducer.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 08/03/09.
 *  Copyright 2009 Peter Zion. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@protocol MMSampleConsumer;

@protocol MMSampleProducer <NSObject>

-(void) connectToSampleConsumer:(id <MMSampleConsumer>)consumer;
-(id <MMSampleConsumer>) disconnectFromSampleConsumer;

@end
