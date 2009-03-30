//
//  MMPhoneAlert.m
//  MiuMiu
//
//  Created by Peter Zion on 30/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMPhoneAlert.h"
#import "MMPhoneAlertDelegate.h"
#import "MMWindow.h"

@implementation MMPhoneAlert

-(id) initWithWindow:(MMWindow *)window cidInfo:(NSString *)_cidInfo
{
	if ( self = [super init] )
	{
		cidInfo = [_cidInfo retain];
	}
	return self;
}

-(void) dealloc
{
	[cidInfo release];
	[super dealloc];
}

-(void) post
{
	NSApplication *application = [NSApplication sharedApplication];
	NSInteger requestID = [application requestUserAttention:NSCriticalRequest];
	int result = NSRunAlertPanel( @"Incomming call", @"Incoming call from \"%@\"", @"Answer", @"Ignore", nil, cidInfo );
	[application cancelUserAttentionRequest:requestID];
	if ( result == NSAlertDefaultReturn )
		[delegate phoneAlertDidAccept:self];
	else
		[delegate phoneAlertDidIgnore:self];
}

@synthesize delegate;

@end
