//
//  MMAudioController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "MMSimpleSamplePipe.h"

@protocol MMAudioControllerDelegate;
@class MMToneGenerator;
@class MMCircularBuffer;

#ifdef IPHONE
#define MM_AUDIO_CONTROLLER_NUM_INPUT_BUFFERS 8
#define MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS 8
#else
#define MM_AUDIO_CONTROLLER_NUM_INPUT_BUFFERS 4
#define MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS 4
#endif
#define MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER 160
#define MM_AUDIO_CONTROLLER_BUFFER_SIZE (MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER*sizeof(short))
#define MM_AUDIO_CONTROLLER_BUFFERS_PER_LEVEL_METER 10

@interface MMAudioController : MMSimpleSamplePipe
{
@private
	id <MMAudioControllerDelegate> delegate;

	AudioStreamBasicDescription audioFormat;

	AudioQueueRef inputQueue;
	AudioQueueRef outputQueue;
	
	BOOL outputStarted;
	MMCircularBuffer *outputBuffer;
	
	unsigned inputLevelMeterCountdown;
	unsigned outputLevelMeterCountdown;
	
	NSMutableString *status;
}

-(void) setPlaybackLevelTo:(float)playbackLevel;

-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription;
-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer;

@property ( nonatomic, assign ) id <MMAudioControllerDelegate> delegate;

@end
