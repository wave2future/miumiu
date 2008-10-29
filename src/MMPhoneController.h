//
//  MMPhoneController.h
//  MiuMiu
//
//  Created by Peter Zion on 12/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMProtocolDelegate.h"
#import "MMCallDelegate.h"
#import "MMPhoneView.h"

@class MMProtocol;
@class MMCodec;
@class MMRingInjector;
@class MMBusyInjector;
@class MMFastBusyInjector;
@class MMDTMFInjector;
@class MMClock;
@class MMComfortNoiseInjector;
@class MMMuteInjector;
@class MMDataPipeChain;
@class MMAudioController;

@interface MMPhoneController : NSThread <MMProtocolDelegate, MMCallDelegate, MMPhoneViewDelegate>
{
@private
	MMPhoneView *phoneView;

	MMProtocol *protocol;

	MMAudioController *audioController;
	MMCall *call;
	MMClock *clock;
	MMDataPipeChain *postClockDataProcessorChain;
	MMRingInjector *ringtoneInjector;
	MMBusyInjector *busyInjector;
	MMFastBusyInjector *fastBusyInjector;
	MMDTMFInjector *dtmfInjector;
	MMComfortNoiseInjector *comfortNoiseInjector;
	MMMuteInjector *muteInjector;
}

@property ( nonatomic, assign ) MMPhoneView *phoneView;

@end
