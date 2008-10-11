//
//  MMViewController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MMView.h"
#import "MMAudioController.h"
#import "MMIAX.h"
#import "MMCall.h"

@class MMCodec;
@class MMRingtoneGenerator;
@class MMBusyGenerator;
@class MMFastBusyGenerator;

@interface MMViewController : UIViewController <MMViewDelegate, MMIAXDelegate, MMCallDelegate>
{
@private
	MMView *view;
	MMAudioController *audioController;
	MMCodec *encoder, *decoder;
	MMIAX *iax;
	MMCall *call;
	MMRingtoneGenerator *ringtoneGenerator;
	MMBusyGenerator *busyGenerator;
	MMFastBusyGenerator *fastBusyGenerator;
	
	CFURLRef		soundFileURLRef;
	SystemSoundID	soundFileObject;
}

@property (readwrite)	CFURLRef		soundFileURLRef;
@property (readonly)	SystemSoundID	soundFileObject;

@end

