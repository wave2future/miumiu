//
//  MMSettingsHelper.m
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMSettingsHelper.h"

void MMSetupDefaultSettings( void )
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
}
