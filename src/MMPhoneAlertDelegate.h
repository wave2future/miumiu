/*
 *  MMPhoneAlertDelegate.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 30/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@class MMPhoneAlert;

@protocol MMPhoneAlertDelegate <NSObject>

@required

-(void) phoneAlertDidAccept:(MMPhoneAlert *)phoneAlert;
-(void) phoneAlertDidIgnore:(MMPhoneAlert *)phoneAlert;

@end
