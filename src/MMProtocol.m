//
//  MMIAX.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMProtocol.h"

@implementation MMProtocol

-(id) initWithProtocolDelegate:(id <MMProtocolDelegate>)_delegate
{
	if ( self = [super init] )
	{
		delegate = _delegate;
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		
		hostname = [[userDefaults stringForKey:@"server"] retain];
		username = [[userDefaults stringForKey:@"username"] retain];
		if ( [username length] == 0 )
			username = [@"pzion" retain];
		password = [[userDefaults stringForKey:@"password"] retain];
		if ( [password length] == 0 )
			password = [@"snowdog1" retain];
		cidName = [[userDefaults stringForKey:@"cidName"] retain];
		cidNumber = [[userDefaults stringForKey:@"cidNumber"] retain];
	}
	return self;
}

-(void) dealloc
{
	[password release];
	[username release];
	[hostname release];
	[cidNumber release];
	[cidName release];
	[super dealloc];
}

-(MMCall *) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate
{
	return nil;
}

-(MMCall *) answerCallWithCallDelegate:(id <MMCallDelegate>)callDelegate
{
	return nil;
}

-(void) ignoreCall
{
}

@synthesize hostname;
@synthesize username;
@synthesize password;
@synthesize cidName;
@synthesize cidNumber;

@end
