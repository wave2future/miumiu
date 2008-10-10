//
//  MMAudioController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MMCircularBuffer.h"

// [pzion 20081010] Audio is broken on the iPhone simulator;
// work around this by detecting the target architecture and
// simulating audio instead
#ifdef __i386__
#define SIMULATE_AUDIO
#endif

#define MM_AUDIO_CONTROLLER_NUM_BUFFERS 16
#define MM_AUDIO_CONTROLLER_NUM_BUFFERS_TO_PUSH 2
#define MM_AUDIO_CONTROLLER_BUFFER_SIZE 320

@class MMAudioController;

@protocol MMAudioControllerDelegate <NSObject>

@required

-(void) audioController:(MMAudioController *)audioController recordedToBuffer:(MMCircularBuffer *)buffer;

@end

@interface MMAudioController : NSObject
{
@private
	id <MMAudioControllerDelegate> delegate;
	BOOL running;
	MMCircularBuffer *recordBuffer;
#ifdef SIMULATE_AUDIO
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

-(void) playbackFromBuffer:(MMCircularBuffer *)buffer;

#ifndef SIMULATE_AUDIO
-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription;
-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer;
#endif

@property ( nonatomic, assign ) id <MMAudioControllerDelegate> delegate;
@property ( nonatomic, readonly ) unsigned frameSize;

@end
