//
//  MMPhoneLabel.h
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMRect.h"
#import "MMView.h"

@interface MMPhoneLabel : NSObject
{
@private
	UILabel *label;
}

@property ( nonatomic, readonly ) MMView *view;
@property ( nonatomic, assign ) MMRect frame;
@property ( nonatomic, assign ) NSString *text;

@end
