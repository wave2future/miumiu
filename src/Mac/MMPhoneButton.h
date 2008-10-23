//
//  MMPhoneButton.h
//  MiuMiu
//
//  Created by Peter Zion on 23/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMRect.h"
#import "MMView.h"

@interface MMPhoneButton : NSObject
{
@private
	NSButton *button;
	id pressTarget;
	SEL pressAction;
	id releaseTarget;
	SEL releaseAction;
}

-(id) initWithTitle:(NSString *)title;

-(void) setPressTarget:(id)target action:(SEL)action;
-(void) setReleaseTarget:(id)target action:(SEL)action;

@property ( nonatomic, readonly ) MMView *view;
@property ( nonatomic, assign ) BOOL enabled;
@property ( nonatomic, assign ) BOOL hidden;
@property ( nonatomic, assign ) MMRect frame;
@property ( nonatomic, readonly ) NSString *title;

@end
