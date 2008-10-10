//
//  MMULawDecoder.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCodec.h"

@interface MMULawDecoder : MMCodec
{
@private
	short uLawToLinear[256];
}

@end
