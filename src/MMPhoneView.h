//
//  MMPhoneView.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef IPHONE
# import <AddressBookUI/AddressBookUI.h>
#endif
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
@class MMPhoneLevel;

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

@interface MMPhoneView : MMView
	<MMPhoneTextFieldDelegate
		,MMPhoneAlertDelegate
		,MMPhoneSliderDelegate
#ifdef IPHONE
		,ABPeoplePickerNavigationControllerDelegate
#endif		
		>
{
@private
	id <MMPhoneViewDelegate> delegate;
	MMPhoneLabel *statusLabel;
#ifdef MACOSX
	MMPhoneSlider *playbackLevelSlider;
#endif
	MMPhoneLevel *outputLevelMeter;
	MMPhoneLevel *inputLevelMeter;
	MMPhoneTextField *numberTextField;
	MMPhoneButton *beginCallButton;
	MMPhoneButton *endCallButton;
	MMPhoneButton *clearNumberButton;
	MMPhoneButton *contactsButton;
	MMPhoneButton *muteButton;
	MMPhoneButton *unmuteButton;
	NSMutableArray *digitButtons;
	MMPhoneAlert *incommingAlert;
	BOOL connected, inCall, muted;
#ifdef IPHONE	
	ABPeoplePickerNavigationController *peoplePickerNavigationController;
#endif
}

-(id) initWithFrame:(MMRect)frame number:(NSString *)number inProgress:(BOOL)inProgress;

-(void) didConnect;
-(void) didBeginCall;
-(void) didEndCall;
-(void) didDisconnect;
-(void) callIsBeingReceivedFrom:(NSString *)cidInfo;
-(void) setStatusMessage:(NSString *)statusMessage;
-(void) inputLevelIs:(float)level;
-(void) outputLevelIs:(float)level;

@property ( nonatomic, assign ) id <MMPhoneViewDelegate> delegate;

@end
