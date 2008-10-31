//
//  MMPhoneLabel.h
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMRect.h"
#import "MMView.h"

@interface MMPhoneLabel : NSObject
{
@private
	NSTextField *textField;
}

@property ( nonatomic, readonly ) MMView *view;
@property ( nonatomic, assign ) MMRect frame;
@property ( nonatomic, assign ) NSString *text;

@end
