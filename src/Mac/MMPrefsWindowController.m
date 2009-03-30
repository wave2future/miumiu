//
//  MMPrefsWindowController.m
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMPrefsWindowController.h"

@implementation MMPrefsWindowController

-(id) init
{
	return [super initWithWindowNibName:@"PrefsWindow"];
}

-(void) windowDidLoad
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[serverPrefTextField setStringValue:[userDefaults stringForKey:@"server"]];
	[usernamePrefTextField setStringValue:[userDefaults stringForKey:@"username"]];
	[passwordPrefTextField setStringValue:[userDefaults stringForKey:@"password"]];
}

-(IBAction) savePreferences:(id)sender
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setValue:[serverPrefTextField stringValue] forKey:@"server"];
	[userDefaults setValue:[usernamePrefTextField stringValue] forKey:@"username"];
	[userDefaults setValue:[passwordPrefTextField stringValue] forKey:@"password"];
}

@end
