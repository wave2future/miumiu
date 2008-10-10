//
//  MMRingtoneGenerator.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProducer.h"

@interface MMRingtoneGenerator : MMDataProducer
{
@private
	NSTimer	*timer;
	unsigned timePosition;
}

@end
