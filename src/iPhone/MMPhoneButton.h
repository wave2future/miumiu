//
//  MMPhoneButton.h
//  MiuMiu
//
//  Created by Peter Zion on 22/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMView.h"
#import "MMRect.h"

@interface MMPhoneButton : NSObject
{
@private
	UIButton *button;
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
