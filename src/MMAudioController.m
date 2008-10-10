//
//  MMAudioController.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMAudioController.h"

void playbackCallback(
    void *userdata,
    AudioQueueRef queue,
    AudioQueueBufferRef buffer
	)
{
	MMAudioController *audioController = (MMAudioController *)userdata;
	[audioController playbackCallbackCalledWithQueue:queue buffer:buffer];
}

static void recordingCallback(
    void *userdata,
    AudioQueueRef queue,
    AudioQueueBufferRef buffer,
    const AudioTimeStamp *startTime,
    UInt32 numPackets,
    const AudioStreamPacketDescription *packetDescription
	)
{
    MMAudioController *controller = (MMAudioController *)userdata;
	[controller recordingCallbackCalledWithQueue:queue
		buffer:buffer
		startTime:startTime
		numPackets:numPackets
		packetDescription:packetDescription];
}

static void interruptionCallback(
   void *inClientData,
   UInt32 inInterruptionState
   )
{
}

@implementation MMAudioController

-(id) init
{
	if ( self = [super init] )
	{
		AudioSessionInitialize( NULL, NULL, interruptionCallback, self );

		UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
        AudioSessionSetProperty(
            kAudioSessionProperty_AudioCategory,
            sizeof(sessionCategory),
            &sessionCategory
			);
            
		outputBuffers = malloc( MM_AUDIO_CONTROLLER_NUM_BUFFERS * sizeof(AudioQueueBufferRef) );
		availableOutputBuffers = malloc( MM_AUDIO_CONTROLLER_NUM_BUFFERS * sizeof(AudioQueueBufferRef) );
		inputBuffers = malloc( MM_AUDIO_CONTROLLER_NUM_BUFFERS * sizeof(AudioQueueBufferRef) );
	}
	return self;
}

-(void) dealloc
{
	[self stop];
	free( inputBuffers );
	free( availableOutputBuffers );
	free( outputBuffers );
	[super dealloc];
}

-(void) start
{
	if ( !running )
	{
		running = YES;
		
		recordBuffer = [[MMCircularBuffer alloc] init];

        audioFormat.mSampleRate = 8000.00;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mChannelsPerFrame = 1;
        audioFormat.mBitsPerChannel = 16;
        audioFormat.mBytesPerPacket = 2;
        audioFormat.mBytesPerFrame = 2;

		AudioQueueNewOutput(
			&audioFormat,
			playbackCallback, self,
			CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0,
			&outputQueue
			);
			
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_BUFFERS; ++i )
			AudioQueueAllocateBuffer( outputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &outputBuffers[i] );

		AudioQueueNewInput(
			&audioFormat,
			recordingCallback, self,
			CFRunLoopGetCurrent(), kCFRunLoopCommonModes,	0,
			&inputQueue
			);

		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_BUFFERS; ++i )
			AudioQueueAllocateBuffer( inputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &inputBuffers[i] );

		AudioSessionSetActive( TRUE );
		
		for ( numAvailableOutputBuffers=0; numAvailableOutputBuffers<MM_AUDIO_CONTROLLER_NUM_BUFFERS-MM_AUDIO_CONTROLLER_NUM_BUFFERS_TO_PUSH; ++numAvailableOutputBuffers )
			availableOutputBuffers[numAvailableOutputBuffers] = outputBuffers[numAvailableOutputBuffers];
		AudioQueueStart( outputQueue, NULL );
		for ( int i=numAvailableOutputBuffers; i<MM_AUDIO_CONTROLLER_NUM_BUFFERS; ++i )
		{
			outputBuffers[i]->mAudioDataByteSize = outputBuffers[i]->mAudioDataBytesCapacity;
			memset( outputBuffers[i]->mAudioData, 0, outputBuffers[i]->mAudioDataByteSize );
			AudioQueueEnqueueBuffer( outputQueue, outputBuffers[i], 0, NULL );
		}

		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_BUFFERS; ++i )
			AudioQueueEnqueueBuffer( inputQueue, inputBuffers[i], 0, NULL );
		AudioQueueStart( inputQueue, NULL );
	}
}

-(void) stop
{
	if ( running )
	{
		running = NO;

		AudioQueueStop( inputQueue, FALSE );
		AudioQueueStop( outputQueue, FALSE );
		
		AudioSessionSetActive( FALSE );

		AudioQueueDispose( inputQueue, TRUE );
		AudioQueueDispose( outputQueue, TRUE );
		
		[recordBuffer release];
	}
}

-(void) playbackFromBuffer:(MMCircularBuffer *)buffer;
{
	while ( numAvailableOutputBuffers > 0 )
	{
		AudioQueueBufferRef queueBuffer = availableOutputBuffers[--numAvailableOutputBuffers];
		if ( ![buffer getData:queueBuffer->mAudioData ofSize:queueBuffer->mAudioDataBytesCapacity] )
		{
			availableOutputBuffers[numAvailableOutputBuffers++] = queueBuffer;
			break;
		}
		queueBuffer->mAudioDataByteSize = queueBuffer->mAudioDataBytesCapacity;
		//NSLog( @"MMAudioController: playing back %d bytes", queueBuffer->mAudioDataByteSize );
		AudioQueueEnqueueBuffer( outputQueue, queueBuffer, 0, NULL );
	}
}

-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription
{
	if ( numPackets > 0 )
	{
		[recordBuffer putData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize];
		[delegate audioController:self recordedToBuffer:recordBuffer];
	}
	
	if ( running )
		AudioQueueEnqueueBuffer( queue, buffer, 0, NULL );
}

-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
{
	availableOutputBuffers[numAvailableOutputBuffers++] = buffer;
}

@synthesize delegate;

@dynamic frameSize;
-(unsigned) frameSize
{
	return MM_AUDIO_CONTROLLER_BUFFER_SIZE;
}

@end
