//
//  MMView.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMView;

@protocol MMViewDelegate <NSObject>

@required

-(void) view:(MMView *)view requestedBeginCallWithNumber:(NSString *)number;
-(void) view:(MMView *)view pressedDTMF:(NSString *)dtmf;
-(void) view:(MMView *)view releasedDTMF:(NSString *)dtmf;
-(void) viewRequestedEndCall:(MMView *)view;

@end

@interface MMView : UIView
{
@private
	id <MMViewDelegate> delegate;
	UITextField *numberTextField;
	UIButton *beginCallButton;
	UIButton *endCallButton;
	UIButton *clearNumberButton;
	NSMutableArray *digitButtons;
}

-(id) initWithNumber:(NSString *)number inProgress:(BOOL)inProgress;

-(void) didBeginCall;
-(void) didEndCall;

@property ( nonatomic, assign ) id <MMViewDelegate> delegate;

@end
