//
//  MMIAX.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
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

-(void) connectWithServer:(NSString *)_server
	username:(NSString *)_username
	password:(NSString *)_password
	cidName:(NSString *)_cidName
	cidNumber:(NSString *)_cidNumber
{
	hostname = [_server retain];
	username = [_username retain];
	password = [_password retain];
	cidName = [_cidName retain];
	cidNumber = [_cidNumber retain];
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
