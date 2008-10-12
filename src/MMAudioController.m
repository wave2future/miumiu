//
//  MMAudioController.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMAudioController.h"
#import "MMToneGenerator.h"

#ifdef MM_AUDIO_CONTROLLER_LOG

#define LOG( format, ... ) \
	[self logWithFormatAndArgs:format, ## __VA_ARGS__]

#else

#define DebugLog( format, ... )

#endif


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

static void interruptionCallback(
   void *inClientData,
   UInt32 inInterruptionState
   )
{
}
#endif

@implementation MMAudioController

-(id) init
{
	if ( self = [super init] )
	{
#ifdef MM_AUDIO_CONTROLLER_LOG
		logStream = [[NSOutputStream outputStreamToFileAtPath:@"/tmp/MiuMiu.log" append:NO] retain];
		[logStream open];
#endif

#ifdef SIMULATE_AUDIO
		unsigned numTones = 1;
		float amplitudes[] = { 2048 };
		float frequencies[] = { 440 };
		toneGenerator = [[MMToneGenerator alloc] initWithNumTones:numTones amplitudes:amplitudes frequencies:frequencies samplingFrequency:8000];
		toneGeneratorOffset = 0;
#else
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
			NULL, 0, 0,
			&outputQueue
			);
		LOG( @"Created output queue" );
			
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_BUFFERS; ++i )
		{
			AudioQueueAllocateBuffer( outputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &outputBuffers[i] );
			availableOutputBuffers[i] = outputBuffers[i];
		}
		numAvailableOutputBuffers = MM_AUDIO_CONTROLLER_NUM_BUFFERS;

		AudioQueueNewInput(
			&audioFormat,
			recordingCallback, self,
			NULL, 0, 0,
			&inputQueue
			);
		LOG( @"Created input queue" );
		
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

#ifndef SIMULATE_AUDIO
	AudioQueueDispose( inputQueue, TRUE );
	
	AudioQueueStop( outputQueue, FALSE );
	AudioQueueDispose( outputQueue, TRUE );
	AudioSessionSetActive( FALSE );
#endif
	
#ifdef MM_AUDIO_CONTROLLER_LOG
	[logStream release];
#endif
	
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
			LOG( @"Initially queued input buffer" );
		}
		
		AudioQueueStart( inputQueue, NULL );
		LOG( @"Started input queue" );
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
		LOG( @"Stopped input queue" );
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
		LOG( @"Enqueued output buffer" );

		if ( numAvailableOutputBuffers == MM_AUDIO_CONTROLLER_NUM_BUFFERS - 2 )
		{
			AudioQueueStart( outputQueue, NULL );
			LOG( @"Started output queue" );
		}
	}
#endif
}

#ifdef SIMULATE_AUDIO
-(void) recordTimerCallback:(id)_
{
	short samples[MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER];
	memset( samples, 0, sizeof(samples) );
	[toneGenerator injectSamples:samples count:MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER offset:toneGeneratorOffset];
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
		LOG( @"Requeued input buffer" );
	}
	else
	{
		availableInputBuffers[numAvailableInputBuffers++] = buffer;
		LOG( @"Marked input buffer as available" );
	}
}

-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
{
	availableOutputBuffers[numAvailableOutputBuffers++] = buffer;
	LOG( @"Marked output buffer as available" );
	
	if ( numAvailableOutputBuffers == MM_AUDIO_CONTROLLER_NUM_BUFFERS )
	{
		AudioQueuePause( outputQueue );
		LOG( @"Paused output queue due to underrun" );
	}
}
#endif

#ifdef MM_AUDIO_CONTROLLER_LOG
-(void) logWithFormatAndArgs:format, ...
{
	va_list argList;
	va_start( argList, format );
	NSString *formattedString = [[[NSString alloc] initWithFormat:format arguments:argList] autorelease];
	va_end( argList );
	
	const void *utf8FormattedString = [formattedString UTF8String];
	[logStream write:utf8FormattedString maxLength:strlen(utf8FormattedString)];
	[logStream write:(const void *)"\n" maxLength:1];
}
#endif

@end
