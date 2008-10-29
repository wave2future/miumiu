//
//  MMDataProcessor.h
//  MiuMiu
//
//  Created by Peter Zion on 14/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataPipe.h"

@interface MMDataProcessor : MMDataPipe
{
}

// A subclass of MMDataProcessor MUST override this function
// to provide its functionality
-(void) processData:(void *)data ofSize:(unsigned)size numSamples:(unsigned *)numSamples;

@end
