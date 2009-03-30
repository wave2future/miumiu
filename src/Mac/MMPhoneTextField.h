//
//  MMPhoneTextField.h
//  MiuMiu
//
//  Created by Peter Zion on 23/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMRect.h"
#import "MMView.h"
#import "MMPhoneTextFieldDelegate.h"

@interface MMPhoneTextField : NSObject
{
@private
	NSTextField *textField;
	id <MMPhoneTextFieldDelegate> delegate;
}

@property ( nonatomic, readonly ) MMView *view;
@property ( nonatomic, assign ) MMRect frame;
@property ( nonatomic, assign ) NSString *text;
@property ( nonatomic, assign ) BOOL hidden;
@property ( nonatomic, assign ) id <MMPhoneTextFieldDelegate> delegate;

@end
