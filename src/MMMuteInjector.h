//
//  MMMuteInjector.h
//  MiuMiu
//
//  Created by Peter Zion on 27/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDataProcessor.h"

@interface MMMuteInjector : MMDataProcessor
{
@private
	BOOL muted;
}

-(void) mute;
-(void) unmute;

@end
