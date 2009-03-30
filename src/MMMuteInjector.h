//
//  MMMuteInjector.h
//  MiuMiu
//
//  Created by Peter Zion on 27/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSimpleSamplePipe.h"

@interface MMMuteInjector : MMSimpleSamplePipe
{
@private
	BOOL muted;
}

-(void) mute;
-(void) unmute;

@end
