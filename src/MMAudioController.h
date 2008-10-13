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
@class MMCircularBuffer;

@protocol MMAudioControllerDelegate <NSObject>

@required

-(void) audioController:(MMAudioController *)audioController outputDelayIsNow:(float)playbackDelay;

@end


// [pzion 20081010] Audio is broken on the iPhone simulator;
// work around this by detecting the target architecture and
// simulating audio instead
#ifdef __i386__
#define SIMULATE_AUDIO
#endif

//#define MM_AUDIO_CONTROLLER_LOG

#define MM_AUDIO_CONTROLLER_NUM_INPUT_BUFFERS 50
#define MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS 6
#define MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER 160
#define MM_AUDIO_CONTROLLER_BUFFER_SIZE (MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER*sizeof(short))

@interface MMAudioController : MMDataProducer <MMDataConsumer>
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
	
	MMCircularBuffer *outputDataBuffer;
	AudioQueueRef outputQueue;
	unsigned numAvailableOutputBuffers;
	AudioQueueBufferRef availableOutputBuffers[MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS];
#endif
}

-(void) resetOutputDelay;

-(void) startRecording;
-(void) stopRecording;

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
