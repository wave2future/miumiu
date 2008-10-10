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
	AudioStreamBasicDescription audioFormat;
	AudioQueueRef inputQueue, outputQueue;
	AudioQueueBufferRef *inputBuffers, *outputBuffers;
	unsigned numAvailableOutputBuffers;
	AudioQueueBufferRef *availableOutputBuffers;
	MMCircularBuffer *recordBuffer;
	BOOL running;
}

-(void) start;
-(void) stop;

-(void) playbackFromBuffer:(MMCircularBuffer *)buffer;

-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription;
-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer;

@property ( nonatomic, assign ) id <MMAudioControllerDelegate> delegate;
@property ( nonatomic, readonly ) unsigned frameSize;

@end
