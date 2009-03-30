//
//  MMLoopback.m
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMLoopback.h"
#import "MMLoopbackCall.h"

@implementation MMLoopback

-(void) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate
{
	[[[MMLoopbackCall alloc] initWithCallDelegate:callDelegate] autorelease];
}

@end
