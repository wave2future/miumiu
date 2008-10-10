//
//  MMViewController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import "MMView.h"
#import "MMAudioController.h"
#import "MMSpeexEncoder.h"
#import "MMSpeexDecoder.h"
#import "MMCircularBuffer.h"
#import "MMIAX.h"

@interface MMViewController : UIViewController <MMViewDelegate, MMIAXDelegate>
{
@private
	MMSpeexEncoder *speexEncoder;
	MMSpeexDecoder *speexDecoder;
	MMAudioController *audioController;
	MMView *view;
	MMIAX *iax;
	BOOL inCall;
	
	CFURLRef		soundFileURLRef;
	SystemSoundID	soundFileObject;
}

@property (readwrite)	CFURLRef		soundFileURLRef;
@property (readonly)	SystemSoundID	soundFileObject;

@end

