/*
 *  NSPhoneSliderDelegate.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 31/10/08.
 *  Copyright 2008 Peter Zion. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@class MMPhoneSlider;

@protocol MMPhoneSliderDelegate <NSObject>

@required

-(void) phoneSlider:(MMPhoneSlider *)phoneSlider didChangeValueTo:(float)value;

@end
