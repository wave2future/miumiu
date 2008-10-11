//
//  MMDataConsumer.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MMDataConsumer <NSObject>

@required

// [pzion 20081010] Note that the data here is explicitly not
// const: the consumer is allow to modify it in place if it likes
-(void) consumeData:(void *)data ofSize:(unsigned)size numSamples:(unsigned)numSamples;

@end
