//
//  MMPhoneView.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMRect.h"
#import "MMView.h"
#import "MMPhoneTextFieldDelegate.h"
#import "MMPhoneAlertDelegate.h"
#import "MMPhoneSliderDelegate.h"

@class MMPhoneView;
@class MMPhoneButton;
@class MMPhoneAlert;
@class MMPhoneLabel;
@class MMPhoneSlider;

@protocol MMPhoneViewDelegate <NSObject>

@required

-(void) view:(MMPhoneView *)view requestedBeginCallWithNumber:(NSString *)number;
-(void) view:(MMPhoneView *)view pressedDTMF:(NSString *)dtmf;
-(void) view:(MMPhoneView *)view releasedDTMF:(NSString *)dtmf;
-(void) viewMuted:(MMPhoneView *)view;
-(void) viewUnmuted:(MMPhoneView *)view;
-(void) viewRequestedEndCall:(MMPhoneView *)view;
-(void) viewDidAnswerCall:(MMPhoneView *)view;
-(void) viewDidIgnoreCall:(MMPhoneView *)view;
-(void) view:(MMPhoneView *)view didSetPlaybackLevelTo:(float)playbackLevel;

@end

@interface MMPhoneView : MMView <MMPhoneTextFieldDelegate, MMPhoneAlertDelegate, MMPhoneSliderDelegate>
{
@private
	id <MMPhoneViewDelegate> delegate;
	MMPhoneLabel *statusLabel;
	MMPhoneSlider *playbackLevelSlider;
	MMPhoneTextField *numberTextField;
	MMPhoneButton *beginCallButton;
	MMPhoneButton *endCallButton;
	MMPhoneButton *clearNumberButton;
	MMPhoneButton *muteButton;
	MMPhoneButton *unmuteButton;
	NSMutableArray *digitButtons;
	MMPhoneAlert *incommingAlert;
	BOOL inCall, muted;
}

-(id) initWithFrame:(MMRect)frame number:(NSString *)number inProgress:(BOOL)inProgress;

-(void) didBeginCall;
-(void) didEndCall;
-(void) callIsBeingReceivedFrom:(NSString *)cidInfo;
-(void) setStatusMessage:(NSString *)statusMessage;

@property ( nonatomic, assign ) id <MMPhoneViewDelegate> delegate;

@end
