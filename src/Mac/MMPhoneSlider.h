//
//  MMPhoneSlider.h
//  MiuMiu
//
//  Created by Peter Zion on 31/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMRect.h"
#import "MMView.h"

@protocol MMPhoneSliderDelegate;

@interface MMPhoneSlider : NSObject
{
@private
	NSSlider *slider;
	id <MMPhoneSliderDelegate> delegate;
}

@property ( nonatomic, readonly ) MMView *view;
@property ( nonatomic, assign ) MMRect frame;
@property ( nonatomic, assign ) id <MMPhoneSliderDelegate> delegate;
@property ( nonatomic, assign ) float value;

@end
