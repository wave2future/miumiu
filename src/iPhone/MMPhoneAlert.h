//
//  MMPhoneAlert.h
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMWindow.h"

@protocol MMPhoneAlertDelegate;

@interface MMPhoneAlert : NSObject
{
@private
	id <MMPhoneAlertDelegate> delegate;
	UIAlertView *alertView;	
}

-(id) initWithWindow:(MMWindow *)_window cidInfo:(NSString *)_cidInfo;

-(void) post;

@property ( nonatomic, assign ) id <MMPhoneAlertDelegate> delegate;

@end
