//
//  main.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright Peter Zion 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain( argc, argv, @"MMApplication", @"MMApplication" );
	[pool release];
	return retVal;
}
