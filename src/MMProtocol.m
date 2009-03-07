//
//  MMIAX.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMProtocol.h"
#import "MMUtils.h"

@implementation MMProtocol

-(id) initWithProtocolDelegate:(id <MMProtocolDelegate>)_delegate
{
	if ( self = [super init] )
	{
		delegate = _delegate;
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

-(BOOL) loginWithServer:(NSString *)_server
	username:(NSString *)_username
	password:(NSString *)_password
	cidName:(NSString *)_cidName
	cidNumber:(NSString *)_cidNumber
	withResultingError:(NSError **)error
{
	if ( MMIsConnection3G() )
	{
		if ( error != NULL )
			*error = [NSError errorWithDomain:@"MiuMiu" code:1 userInfo:[NSDictionary dictionaryWithObject:@"Cannot use on 3G network" forKey:NSLocalizedDescriptionKey]];
		return NO;
	}
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	hostname = [[userDefaults stringForKey:@"server"] retain];
	username = [[userDefaults stringForKey:@"username"] retain];
	if ( [username length] == 0 )
		username = [@"dfcarney" retain];
	password = [[userDefaults stringForKey:@"password"] retain];
	if ( [password length] == 0 )
		password = [@"scsscs" retain];
	cidName = [[userDefaults stringForKey:@"cidName"] retain];
	cidNumber = [[userDefaults stringForKey:@"cidNumber"] retain];
	
	return TRUE;
}

-(void) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate
{
}

-(void) answerCallWithCallDelegate:(id <MMCallDelegate>)callDelegate
{
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
