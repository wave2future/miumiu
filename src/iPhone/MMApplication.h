//
//  MMApplication.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MMPhoneController;

@interface MMApplication : UIApplication <UIApplicationDelegate>
{
@private
	UIWindow *window;
	MMPhoneController *phoneController;
}

@end
