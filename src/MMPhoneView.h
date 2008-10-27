//
//  MMPhoneView.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMView.h"
#import "MMPhoneTextFieldDelegate.h"
#import "MMRect.h"

@class MMPhoneView;
@class MMPhoneButton;

@protocol MMPhoneViewDelegate <NSObject>

@required

-(void) view:(MMPhoneView *)view requestedBeginCallWithNumber:(NSString *)number;
-(void) view:(MMPhoneView *)view pressedDTMF:(NSString *)dtmf;
-(void) view:(MMPhoneView *)view releasedDTMF:(NSString *)dtmf;
-(void) viewMuted:(MMPhoneView *)view;
-(void) viewUnmuted:(MMPhoneView *)view;
-(void) viewRequestedEndCall:(MMPhoneView *)view;

@end

@interface MMPhoneView : MMView <MMPhoneTextFieldDelegate>
{
@private
	id <MMPhoneViewDelegate> delegate;
	MMPhoneTextField *numberTextField;
	MMPhoneButton *beginCallButton;
	MMPhoneButton *endCallButton;
	MMPhoneButton *clearNumberButton;
	MMPhoneButton *muteButton;
	MMPhoneButton *unmuteButton;
	NSMutableArray *digitButtons;
	BOOL inCall, muted;
}

-(id) initWithFrame:(MMRect)frame number:(NSString *)number inProgress:(BOOL)inProgress;

-(void) didBeginCall;
-(void) didEndCall;

@property ( nonatomic, assign ) id <MMPhoneViewDelegate> delegate;

@end
