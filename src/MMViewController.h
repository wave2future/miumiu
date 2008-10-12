//
//  MMViewController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMView.h"
#import "MMIAX.h"
#import "MMCall.h"

@class MMCodec;
@class MMRingInjector;
@class MMBusyInjector;
@class MMFastBusyInjector;
@class MMAudioController;
@class MMDTMFInjector;
@class MMNullProducer;

@interface MMViewController : UIViewController <MMViewDelegate, MMIAXDelegate, MMCallDelegate>
{
@private
	MMView *view;
	MMAudioController *audioController;
	MMCodec *encoder, *decoder;
	MMIAX *iax;
	MMCall *call;
	MMRingInjector *ringtoneInjector;
	MMBusyInjector *busyInjector;
	MMFastBusyInjector *fastBusyInjector;
	MMDTMFInjector *dtmfInjector;
	MMNullProducer *nullProducer;
}

@end

