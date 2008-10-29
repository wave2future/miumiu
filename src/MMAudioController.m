//
//  MMAudioController.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMAudioController.h"
#import "MMToneGenerator.h"
#import "MMCircularBuffer.h"

#ifdef MM_AUDIO_CONTROLLER_LOG

#define LOG( format, ... ) \
	[self logWithFormatAndArgs:format, ## __VA_ARGS__]

#else

#define LOG( format, ... )

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
		recordTimer = [[NSTimer scheduledTimerWithTimeInterval:MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER/8000.00 target:self selector:@selector(recordTimerCallback:) userInfo:nil repeats:YES] retain];
#else
#ifdef IPHONE
		AudioSessionInitialize( NULL, NULL, interruptionCallback, self );

		UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
        AudioSessionSetProperty(
            kAudioSessionProperty_AudioCategory,
            sizeof(sessionCategory),
            &sessionCategory
			);
#endif

        audioFormat.mSampleRate = 8000.00;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mChannelsPerFrame = 1;
        audioFormat.mBitsPerChannel = 16;
        audioFormat.mBytesPerPacket = 2;
        audioFormat.mBytesPerFrame = 2;

#ifdef IPHONE
		AudioSessionSetActive( TRUE );
#endif
		
		AudioQueueNewOutput(
			&audioFormat,
			playbackCallback, self,
			CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0,
			&outputQueue
			);
		LOG( @"Created output queue" );
		
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS; ++i )
		{
			AudioQueueBufferRef buffer;
			AudioQueueAllocateBuffer( outputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &buffer );
			buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
			memset( buffer->mAudioData, 0, buffer->mAudioDataByteSize );
			AudioQueueEnqueueBuffer( outputQueue, buffer, 0, NULL );
		}
			
		
		AudioQueueNewInput(
			&audioFormat,
			recordingCallback, self,
			CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0,
			&inputQueue
			);
		LOG( @"Created input queue" );
		
		AudioQueueSetParameter(
			inputQueue,
			kAudioQueueParam_Volume,
			0.8
			);
		
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_INPUT_BUFFERS; ++i )
		{
			AudioQueueBufferRef buffer;
			AudioQueueAllocateBuffer( inputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &buffer );
			AudioQueueEnqueueBuffer( inputQueue, buffer, 0, NULL );
		}
		
		AudioQueueStart( outputQueue, NULL );
		AudioQueueStart( inputQueue, NULL );
#endif
	}
	return self;
}

-(void) dealloc
{
#ifdef SIMULATE_AUDIO
	[recordTimer invalidate];
	[recordTimer release];
	recordTimer = nil;
#else
	AudioQueueDispose( inputQueue, FALSE );
	
	AudioQueueDispose( outputQueue, FALSE );

#ifdef IPHONE	
	AudioSessionSetActive( FALSE );
#endif
#endif
	
#ifdef MM_AUDIO_CONTROLLER_LOG
	[logStream release];
#endif
	
	[super dealloc];
}

#ifdef SIMULATE_AUDIO
-(void) recordTimerCallback:(id)_
{
	short samples[MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER];
	memset( samples, 0, sizeof(samples) );
	[toneGenerator injectSamples:samples count:MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER offset:toneGeneratorOffset];
	toneGeneratorOffset += MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER;
	[self pushData:samples ofSize:sizeof(samples) numSamples:MM_AUDIO_CONTROLLER_SAMPLES_PER_BUFFER];
}
#else
-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription
{
	[self pushData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize numSamples:numPackets];
	AudioQueueEnqueueBuffer( queue, buffer, 0, NULL );
	LOG( @"Requeued input buffer" );
}

-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
{
	[self pullData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize];
	AudioQueueEnqueueBuffer( outputQueue, buffer, 0, NULL );
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

-(void) resetOutputDelay
{
}

@end
