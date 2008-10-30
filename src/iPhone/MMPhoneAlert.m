//
//  MMPhoneAlert.m
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMPhoneAlert.h"
#import "MMPhoneAlertDelegate.h"

@implementation MMPhoneAlert

-(id) initWithWindow:(MMWindow *)_window cidInfo:(NSString *)_cidInfo
{
	if ( self = [super init] )
	{
		alertView = [[UIAlertView alloc] initWithTitle:@"Incomming Call"
			message:[NSString stringWithFormat:@"Incomming call from %@", _cidInfo]
			delegate:self
			cancelButtonTitle:@"Ignore"
			otherButtonTitles:@"Accept", nil];
		[_window addSubview:alertView];
	}
	return self;
}

-(void) dealloc
{
	[alertView removeFromSuperview];
	[alertView release];
	[super dealloc];
}

-(void) post
{
	[alertView show];
}

- (void)alertView:(UIAlertView *)_alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ( buttonIndex == 0 )
		[delegate phoneAlertDidIgnore:self];
	else
		[delegate phoneAlertDidAccept:self];
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

@synthesize delegate;

@end
