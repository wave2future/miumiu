//
//  MMIAX.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMProtocol.h"

@implementation MMProtocol

-(id) init
{
	if ( self = [super init] )
	{
		hostname = [@"lickmypony.com" retain];
		username = [@"miumiu" retain];
		password = [@"snowdog1" retain];
		cidName = [@"Peter Zion" retain];
		cidNumber = [@"5146515041" retain];
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

-(MMCall *) beginCall:(NSString *)number
{
	return nil;
}

@synthesize delegate;
@synthesize hostname;
@synthesize username;
@synthesize password;
@synthesize cidName;
@synthesize cidNumber;

@end
