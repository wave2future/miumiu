//
//  MMUtils.m
//  MiuMiu
//
//  Created by Peter Zion on 07/03/09.
//  Copyright 2009 Peter Zion. All rights reserved.
//

#import "MMUtils.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>

BOOL MMIsConnection3G()
{
#ifdef IPHONE
	struct sockaddr_in sin;
	bzero(&sin, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);

	SCNetworkReachabilityRef addressReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&sin);
    SCNetworkReachabilityFlags addressReachabilityFlags;
    SCNetworkReachabilityGetFlags( addressReachability, &addressReachabilityFlags );
	CFRelease( addressReachability );
	
	return (addressReachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) != 0;
#else
	return FALSE;
#endif
}

