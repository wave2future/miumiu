//
//  MMULawEncoder.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCodec.h"

@interface MMULawEncoder : MMCodec
{
@private
	unsigned char linearToULaw[16384];
}

@end
