//
//  MMPhoneTextField.h
//  MiuMiu
//
//  Created by Peter Zion on 23/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMPhoneTextFieldDelegate.h"
#import "MMView.h"
#import "MMRect.h"

@interface MMPhoneTextField : NSObject <UITextFieldDelegate>
{
@private
	UITextField *textField;
	id <MMPhoneTextFieldDelegate> delegate;
}

@property ( nonatomic, readonly ) MMView *view;
@property ( nonatomic, assign ) MMRect frame;
@property ( nonatomic, assign ) NSString *text;
@property ( nonatomic, assign ) id <MMPhoneTextFieldDelegate> delegate;
@property ( nonatomic, assign ) BOOL hidden;

@end
