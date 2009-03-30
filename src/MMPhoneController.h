//
//  MMPhoneController.h
//  MiuMiu
//
//  Created by Peter Zion on 12/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "MMProtocolDelegate.h"
#import "MMCallDelegate.h"
#import "MMPhoneView.h"
#import "MMAudioControllerDelegate.h"

#ifdef IPHONE
typedef SCNetworkReachabilityFlags NetworkReachabilityFlags;
static const int kNetworkReachabilityFlagsReachable = kSCNetworkReachabilityFlagsReachable;
#else
typedef SCNetworkConnectionFlags NetworkReachabilityFlags;
static const int kNetworkReachabilityFlagsReachable = kSCNetworkFlagsReachable;
#endif

@class MMProtocol;
@protocol MMCall;
@class MMRingInjector;
@class MMBusyInjector;
@class MMFastBusyInjector;
@class MMDTMFInjector;
@class MMComfortNoiseInjector;
@class MMMuteInjector;
@class MMSamplePipeChain;
@class MMAudioController;
@class MMPreprocessor;
@class MMOnHookSamplePipe;

@interface MMPhoneController : NSThread <MMProtocolDelegate, MMCallDelegate, MMAudioControllerDelegate, MMPhoneViewDelegate>
{
@private
	MMPhoneView *phoneView;

	SCNetworkReachabilityRef networkReachability;
	MMProtocol *protocol;

	MMAudioController *audioController;
	id <MMCall> mCall;
	MMOnHookSamplePipe *onHookSamplePipe;
	MMSamplePipeChain *callToAudioChain;
	MMSamplePipeChain *audioToCallChain;
	MMRingInjector *ringtoneInjector;
	MMBusyInjector *busyInjector;
	MMFastBusyInjector *fastBusyInjector;
	MMDTMFInjector *dtmfInjector;
	MMComfortNoiseInjector *comfortNoiseInjector;
	MMMuteInjector *muteInjector;
}

@property ( nonatomic, assign ) MMPhoneView *phoneView;

#pragma mark Private methods

-(void) handleNetworkReachabilityCallbackWithFlags:(NetworkReachabilityFlags)flags;

@end
