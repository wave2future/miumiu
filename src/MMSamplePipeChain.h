//
//  MMSamplePipeChain.h
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSamplePipe.h"

@interface MMSamplePipeChain : NSObject <MMSamplePipe>
{
@private
	NSMutableArray *dataPipes;
}

#pragma mark Public

-(void) zap;
-(void) pushDataPipeOntoFront:(id <MMSamplePipe>)dataPipe;

@end
