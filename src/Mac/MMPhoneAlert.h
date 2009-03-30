//
//  MMPhoneAlert.h
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMWindow.h"

@protocol MMPhoneAlertDelegate;

@interface MMPhoneAlert : NSObject
{
@private
	id <MMPhoneAlertDelegate> delegate;
	NSString *cidInfo;
}

-(id) initWithWindow:(MMWindow *)_window cidInfo:(NSString *)_cidInfo;

-(void) post;

@property ( nonatomic, assign ) id <MMPhoneAlertDelegate> delegate;

@end
