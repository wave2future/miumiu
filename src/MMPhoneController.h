//
//  MMPhoneController.h
//  MiuMiu
//
//  Created by Peter Zion on 12/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMIAX.h"
#import "MMCall.h"
#import "MMPhoneView.h"

@class MMCodec;
@class MMRingInjector;
@class MMBusyInjector;
@class MMFastBusyInjector;
@class MMDTMFInjector;
@class MMClock;
@class MMComfortNoiseInjector;
@class MMDataProcessorChain;
@class MMAudioController;

@interface MMPhoneController : NSThread <MMIAXDelegate, MMCallDelegate, MMPhoneViewDelegate>
{
@private
	MMPhoneView *phoneView;

	MMIAX *iax;

	MMAudioController *audioController;
	MMCall *call;
	MMClock *clock;
	MMDataProcessorChain *postClockDataProcessorChain;
	MMRingInjector *ringtoneInjector;
	MMBusyInjector *busyInjector;
	MMFastBusyInjector *fastBusyInjector;
	MMDTMFInjector *dtmfInjector;
	MMComfortNoiseInjector *comfortNoiseInjector;
}

@property ( nonatomic, assign ) MMPhoneView *phoneView;

@end
