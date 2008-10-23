/*
 *  MMPhoneTextFieldDelegate.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 23/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@class MMPhoneTextField;

@protocol MMPhoneTextFieldDelegate <NSObject>

@optional

-(BOOL) textFieldShouldReturn:(MMPhoneTextField *)textField;

-(BOOL) textField:(MMPhoneTextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
	replacementString:(NSString *)string;

@end
