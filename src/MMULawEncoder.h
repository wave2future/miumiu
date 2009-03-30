//
//  MMULawEncoder.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMEncoder.h"

@interface MMULawEncoder : NSObject <MMEncoder>
{
@private
	unsigned char linearToULaw[16384];
}

@end
