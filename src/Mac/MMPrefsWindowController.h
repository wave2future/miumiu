//
//  MMPrefsWindowController.h
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MMPrefsWindowController : NSWindowController
{
@private
    IBOutlet NSTextField *passwordPrefTextField;
    IBOutlet NSTextField *serverPrefTextField;
    IBOutlet NSTextField *usernamePrefTextField;
}

-(IBAction) savePreferences:(id)sender;

@end
