//
//  MMApplication.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMApplication.h"
#import "MMPhoneController.h"
#import "MMPhoneView.h"

@implementation MMApplication

-(void) dealloc
{
	[phoneController release];
	[window release];
	[super dealloc];
}

-(void) applicationDidFinishLaunching:(UIApplication *)application
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
    if ( [userDefaults stringForKey:@"server"] == nil
		|| [userDefaults stringForKey:@"username"] == nil
		|| [userDefaults stringForKey:@"password"] == nil )
    {
        NSString *pathStr = [[NSBundle mainBundle] bundlePath];
        NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
        NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];

        NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
        NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];

		NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
        for ( NSDictionary *prefItem in prefSpecifierArray )
		{
			NSString *key = [prefItem objectForKey:@"Key"];
			if ( key != nil )
				[appDefaults setObject:[prefItem objectForKey:@"DefaultValue"] forKey:key];
		}

        [userDefaults registerDefaults:appDefaults];
        [userDefaults synchronize];
    }
 
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	window = [[UIWindow alloc] initWithFrame:screenBounds];

	phoneController = [[MMPhoneController alloc] init];

	CGRect windowBounds = window.bounds;
	CGRect statusBarFrame = application.statusBarFrame;
	CGRect phoneViewFrame = CGRectMake( CGRectGetMinX(windowBounds), CGRectGetMaxY(statusBarFrame), CGRectGetWidth(windowBounds), CGRectGetMaxY(windowBounds) - CGRectGetMaxY(statusBarFrame) );
	
	MMPhoneView *phoneView = [[[MMPhoneView alloc] initWithFrame:phoneViewFrame number:@"" inProgress:NO] autorelease];
	phoneView.delegate = phoneController;
	phoneController.phoneView = phoneView;
	[window addSubview:phoneView];
	
	[window makeKeyAndVisible];
	[phoneController start];
	[NSThread setThreadPriority:0];
}

@end
