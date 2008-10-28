//
//  MMLoopback.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMLoopback.h"
#import "MMLoopbackCall.h"

@implementation MMLoopback

-(MMCall *) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate
{
	return [[[MMLoopbackCall alloc] initWithCallDelegate:callDelegate] autorelease];
}

@end
