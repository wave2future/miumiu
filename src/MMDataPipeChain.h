//
//  MMDataPipeChain.h
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataPipe.h"

@interface MMDataPipeChain : MMDataPipe
{
@private
	MMDataPipe *lastDataPipe;
	MMDataPipe *firstDataPipe;
}

-(void) zap;
-(void) pushDataPipeOntoFront:(MMDataPipe *)dataPipe;

@end
