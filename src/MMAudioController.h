//
//  MMAudioController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "MMDataPipe.h"

@protocol MMAudioControllerDelegate;
@class MMToneGenerator;

// [pzion 20081010] Audio is broken on the iPhone simulator;
// work around this by detecting the target architecture and
// simulating audio instead
#if defined(IPHONE) && defined(__i386__)
#define SIMULATE_AUDIO
#endif

//#define MM_AUDIO_CONTROLLER_LOG

#ifdef MACOSX
#define MM_AUDIO_CONTROLLER_NUM_INPUT_BUFFERS 2
#define MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS 2
#else
#define MM_AUDIO_CONTROLLER_NUM_INPUT_BUFFERS 2
#define MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS 6
#endif
#define MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER 160
#define MM_AUDIO_CONTROLLER_BUFFER_SIZE (MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER*sizeof(short))
#define MM_AUDIO_CONTROLLER_BUFFERS_PER_LEVEL_METER 10

@interface MMAudioController : MMDataPipe
{
@private
	id <MMAudioControllerDelegate> delegate;

#ifdef MM_AUDIO_CONTROLLER_LOG
	NSOutputStream *logStream;
#endif

#ifdef SIMULATE_AUDIO
	MMToneGenerator *toneGenerator;
	unsigned toneGeneratorOffset;
	NSTimer *recordTimer;
#else
	AudioStreamBasicDescription audioFormat;

	AudioQueueRef inputQueue;
	AudioQueueRef outputQueue;
	
	unsigned inputLevelMeterCountdown;
	unsigned outputLevelMeterCountdown;
#endif
}

-(void) setPlaybackLevelTo:(float)playbackLevel;

#ifndef SIMULATE_AUDIO
-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription;
-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer;
#endif

#ifdef MM_AUDIO_CONTROLLER_LOG
-(void) logWithFormatAndArgs:format, ...;
#endif

@property ( nonatomic, assign ) id <MMAudioControllerDelegate> delegate;

@end
