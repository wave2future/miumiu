//
//  MMDataProcessorChain.h
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProcessor.h"

@interface MMDataProcessorChain : MMDataProcessor
{
@private
	MMDataProcessor *lastConsumer;
	MMDataProcessor *firstConsumer;
}

-(void) zap;
-(void) pushDataProcessorOntoFront:(MMDataProcessor *)item;

@end
