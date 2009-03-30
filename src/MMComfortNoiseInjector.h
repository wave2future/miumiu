//
//  MMComfortNoiseInjector.h
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSimpleSamplePipe.h"

@interface MMComfortNoiseInjector : MMSimpleSamplePipe
{
@private
	unsigned short lfsr;
	short lastInjection;
}

@end
