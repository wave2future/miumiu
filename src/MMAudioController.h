//
//  MMAudioController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MMDataProducer.h"
#import "MMDataConsumer.h"

@class MMAudioController;
@class MMToneGenerator;

// [pzion 20081010] Audio is broken on the iPhone simulator;
// work around this by detecting the target architecture and
// simulating audio instead
#ifdef __i386__
#define SIMULATE_AUDIO
#endif

#define MM_AUDIO_CONTROLLER_NUM_BUFFERS 16
#define MM_AUDIO_CONTROLLER_NUM_BUFFERS_TO_PUSH 2
#define MM_AUDIO_CONTROLLER_BUFFER_SIZE 320

@interface MMAudioController : MMDataProducer <MMDataConsumer>
{
@private
	BOOL running;
#ifdef SIMULATE_AUDIO
	MMToneGenerator *toneGenerator;
	unsigned toneGeneratorOffset;
	NSTimer *recordTimer;
#else
	AudioStreamBasicDescription audioFormat;
	AudioQueueRef inputQueue, outputQueue;
	AudioQueueBufferRef inputBuffers[MM_AUDIO_CONTROLLER_NUM_BUFFERS], outputBuffers[MM_AUDIO_CONTROLLER_NUM_BUFFERS];
	unsigned numAvailableOutputBuffers;
	AudioQueueBufferRef availableOutputBuffers[MM_AUDIO_CONTROLLER_NUM_BUFFERS];
#endif
}

-(void) start;
-(void) stop;

#ifndef SIMULATE_AUDIO
-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription;
-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer;
#endif

@end
