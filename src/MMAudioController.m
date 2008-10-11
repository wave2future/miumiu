//
//  MMAudioController.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMAudioController.h"
#import "MMToneGenerator.h"

#ifndef SIMULATE_AUDIO
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
#endif

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
	}
	return self;
}

-(void) dealloc
{
	[self stop];
	[super dealloc];
}

-(void) start
{
	if ( !running )
	{
		running = YES;
		
#ifdef SIMULATE_AUDIO
		unsigned numTones = 1;
		float amplitudes[] = { 16384 };
		float frequencies[] = { 440 };
		toneGenerator = [[MMToneGenerator alloc] initWithNumTones:numTones amplitudes:amplitudes frequencies:frequencies samplingFrequency:8000];
		toneGeneratorOffset = 0;
		recordTimer = [[NSTimer scheduledTimerWithTimeInterval:MM_AUDIO_CONTROLLER_BUFFER_SIZE/8000.00 target:self selector:@selector(recordTimerCallback:) userInfo:nil repeats:YES] retain];
#else
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
#endif
	}
}

-(void) stop
{
	if ( running )
	{
		running = NO;

#ifdef SIMULATE_AUDIO
		[recordTimer invalidate];
		[recordTimer release];
		[toneGenerator release];
#else
		AudioQueueStop( inputQueue, FALSE );
		AudioQueueStop( outputQueue, FALSE );
		
		AudioSessionSetActive( FALSE );

		AudioQueueDispose( inputQueue, TRUE );
		AudioQueueDispose( outputQueue, TRUE );
#endif
	}
}

-(void) consumeData:(void *)_data ofSize:(unsigned)size
{
#ifndef SIMULATE_AUDIO
	const char *data = (char *)_data;
	while ( size > 0 && numAvailableOutputBuffers > 0 )
	{
		AudioQueueBufferRef queueBuffer = availableOutputBuffers[--numAvailableOutputBuffers];
		queueBuffer->mAudioDataByteSize = size;
		if ( queueBuffer->mAudioDataByteSize > queueBuffer->mAudioDataBytesCapacity )
			queueBuffer->mAudioDataByteSize = queueBuffer->mAudioDataBytesCapacity;
		memcpy( queueBuffer->mAudioData, data, queueBuffer->mAudioDataByteSize );
		data += queueBuffer->mAudioDataByteSize;
		size -= queueBuffer->mAudioDataByteSize;
		AudioQueueEnqueueBuffer( outputQueue, queueBuffer, 0, NULL );
	}
#endif
}

#ifdef SIMULATE_AUDIO
-(void) recordTimerCallback:(id)_
{
	short samples[160];
	[toneGenerator generateSamples:samples count:160 offset:toneGeneratorOffset];
	toneGeneratorOffset += 160;
	[self produceData:samples ofSize:sizeof(samples)];
}
#else
-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription
{
	if ( numPackets > 0 )
		[self produceData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize];

	if ( running )
		AudioQueueEnqueueBuffer( queue, buffer, 0, NULL );
}

-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
{
	if ( running && numAvailableOutputBuffers == MM_AUDIO_CONTROLLER_NUM_BUFFERS - MM_AUDIO_CONTROLLER_NUM_BUFFERS_TO_PUSH )
	{
		buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
		memset( buffer->mAudioData, 0, buffer->mAudioDataByteSize );
		AudioQueueEnqueueBuffer( queue, buffer, 0, NULL );
	}
	else
		availableOutputBuffers[numAvailableOutputBuffers++] = buffer;
}
#endif

@end
