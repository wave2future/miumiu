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

        audioFormat.mSampleRate = 8000.00;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mChannelsPerFrame = 1;
        audioFormat.mBitsPerChannel = 16;
        audioFormat.mBytesPerPacket = 2;
        audioFormat.mBytesPerFrame = 2;

		AudioSessionSetActive( TRUE );
		
		AudioQueueNewOutput(
			&audioFormat,
			playbackCallback, self,
			CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0,
			&outputQueue
			);
			
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_BUFFERS; ++i )
		{
			AudioQueueAllocateBuffer( outputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &outputBuffers[i] );
			availableOutputBuffers[i] = outputBuffers[i];
		}
		numAvailableOutputBuffers = MM_AUDIO_CONTROLLER_NUM_BUFFERS;

#ifdef SIMULATE_AUDIO
		unsigned numTones = 1;
		float amplitudes[] = { 2048 };
		float frequencies[] = { 440 };
		toneGenerator = [[MMToneGenerator alloc] initWithNumTones:numTones amplitudes:amplitudes frequencies:frequencies samplingFrequency:8000];
		toneGeneratorOffset = 0;
#else
		AudioQueueNewInput(
			&audioFormat,
			recordingCallback, self,
			CFRunLoopGetCurrent(), kCFRunLoopCommonModes,	0,
			&inputQueue
			);
		NSLog( @"Created input queue" );
		
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_BUFFERS; ++i )
		{
			AudioQueueAllocateBuffer( inputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &inputBuffers[i] );
			availableInputBuffers[i] = inputBuffers[i];
		}
		numAvailableInputBuffers = MM_AUDIO_CONTROLLER_NUM_BUFFERS;
#endif
	}
	return self;
}

-(void) dealloc
{
	[self stopRecording];
	AudioQueueDispose( inputQueue, TRUE );
	
	AudioQueueStop( outputQueue, FALSE );
	AudioQueueDispose( outputQueue, TRUE );
	AudioSessionSetActive( FALSE );
	
	[super dealloc];
}

-(void) startRecording
{
	if ( !recording )
	{
		recording = YES;
		
#ifdef SIMULATE_AUDIO
		recordTimer = [[NSTimer scheduledTimerWithTimeInterval:MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER/8000.00 target:self selector:@selector(recordTimerCallback:) userInfo:nil repeats:YES] retain];
#else
		while ( numAvailableInputBuffers > 0 )
		{
			AudioQueueEnqueueBuffer( inputQueue, inputBuffers[--numAvailableInputBuffers], 0, NULL );
			//NSLog( @"Initially queued input buffer" );
		}
		
		AudioQueueStart( inputQueue, NULL );
		//NSLog( @"Started input queue" );
#endif
	}
}

-(void) stopRecording
{
	if ( recording )
	{
		recording = NO;

#ifdef SIMULATE_AUDIO
		[recordTimer invalidate];
		[recordTimer release];
		recordTimer = nil;
#else
		AudioQueueStop( inputQueue, FALSE );
		//NSLog( @"Stopped input queue" );
#endif
	}
}

-(void) consumeData:(void *)_data ofSize:(unsigned)size numSamples:(unsigned)numSamples
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

		if ( numAvailableOutputBuffers == MM_AUDIO_CONTROLLER_NUM_BUFFERS - 2 )
			AudioQueueStart( outputQueue, NULL );
	}
#endif
}

#ifdef SIMULATE_AUDIO
-(void) recordTimerCallback:(id)_
{
	short samples[MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER];
	[toneGenerator generateSamples:samples count:MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER offset:toneGeneratorOffset];
	toneGeneratorOffset += MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER;
	[self produceData:samples ofSize:sizeof(samples) numSamples:MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER];
}
#else
-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription
{
	[self produceData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize numSamples:numPackets];

	if ( recording )
	{
		AudioQueueEnqueueBuffer( queue, buffer, 0, NULL );
		//NSLog( @"Requeued input buffer" );
	}
	else
	{
		availableInputBuffers[numAvailableInputBuffers++] = buffer;
		//NSLog( @"Marked input buffer as available" );
	}
}

-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
{
	availableOutputBuffers[numAvailableOutputBuffers++] = buffer;
	if ( numAvailableOutputBuffers == MM_AUDIO_CONTROLLER_NUM_BUFFERS )
		AudioQueuePause( outputQueue );
}
#endif

@end
