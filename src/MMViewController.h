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
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMIAX.h"
#import "MMCall.h"

@class MMRingtoneGenerator;

@interface MMViewController : UIViewController <MMViewDelegate, MMIAXDelegate, MMCallDelegate>
{
@private
	MMSpeexEncoder *speexEncoder;
	MMSpeexDecoder *speexDecoder;
	MMAudioController *audioController;
	MMView *view;
	MMIAX *iax;
	MMCall *call;
	MMRingtoneGenerator *ringtoneGenerator;
	
	CFURLRef		soundFileURLRef;
	SystemSoundID	soundFileObject;
}

@property (readwrite)	CFURLRef		soundFileURLRef;
@property (readonly)	SystemSoundID	soundFileObject;

@end

