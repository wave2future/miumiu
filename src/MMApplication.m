//
//  MMApplication.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMApplication.h"

@implementation MMApplication

-(void) dealloc
{
	[viewController release];
	[window release];
	[super dealloc];
}

-(void) applicationDidFinishLaunching:(UIApplication *)application
{
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	CGRect windowBounds = window.bounds;
	CGRect statusBarFrame = application.statusBarFrame;
	CGRect viewControllerFrame = CGRectMake( CGRectGetMinX(windowBounds), CGRectGetMaxY(statusBarFrame), CGRectGetWidth(windowBounds), CGRectGetMaxY(windowBounds) - CGRectGetMaxY(statusBarFrame) );
	
	viewController = [[MMViewController alloc] init];
	viewController.view.frame = viewControllerFrame;
	[window addSubview:viewController.view];

	[window makeKeyAndVisible];	
}

@end
