//
//  MMAudioController.m
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMAudioController.h"
#import "MMAudioControllerDelegate.h"
#import "MMToneGenerator.h"
#import "MMCircularBuffer.h"

#undef MM_AUDIO_CONTROLLER_STATUS

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

#pragma mark Private

#ifdef MM_AUDIO_CONTROLLER_STATUS
-(void) addStatus:(NSString *)ch
{
	[status appendString:ch];
	if ( [status length] > 100 )
	{
		NSLog( @"status: %@", status );
		[status setString:@""];
	}
}
#endif

#pragma mark Lifecycle

-(id) init
{
	if ( self = [super init] )
	{
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
			CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0,
			&outputQueue
			);
		
		UInt32 enableOutputLevelMetering = 1;
		AudioQueueSetProperty(
			outputQueue,
			kAudioQueueProperty_EnableLevelMetering,
			&enableOutputLevelMetering,
			sizeof(enableOutputLevelMetering)
			);
		
		[self setPlaybackLevelTo:1.0];

		outputLevelMeterCountdown = MM_AUDIO_CONTROLLER_BUFFERS_PER_LEVEL_METER;
		
		outputBuffer = [[MMCircularBuffer alloc] initWithCapacity:MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS*MM_AUDIO_CONTROLLER_BUFFER_SIZE];
			
		AudioQueueNewInput(
			&audioFormat,
			recordingCallback, self,
			CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 0,
			&inputQueue
			);
		
		UInt32 enableInputLevelMetering = 1;
		AudioQueueSetProperty(
			inputQueue,
			kAudioQueueProperty_EnableLevelMetering,
			&enableInputLevelMetering,
			sizeof(enableInputLevelMetering)
			);
		
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_INPUT_BUFFERS; ++i )
		{
			AudioQueueBufferRef buffer;
			AudioQueueAllocateBuffer( inputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &buffer );
			AudioQueueEnqueueBuffer( inputQueue, buffer, 0, NULL );
		}
		inputLevelMeterCountdown = MM_AUDIO_CONTROLLER_BUFFERS_PER_LEVEL_METER;
		
		AudioQueueStart( inputQueue, NULL );
		
		status = [[NSMutableString alloc] init];
	}
	return self;
}

-(void) dealloc
{
	[status release];

	[outputBuffer release];

	AudioQueueDispose( inputQueue, FALSE );
	
	AudioQueueDispose( outputQueue, FALSE );

#ifdef IPHONE	
	AudioSessionSetActive( FALSE );
#endif
	
	[super dealloc];
}

-(void) recordingCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
		startTime:(const AudioTimeStamp *)startTime
		numPackets:(UInt32)numPackets
		packetDescription:(const AudioStreamPacketDescription *)packetDescription
{
#ifdef MM_AUDIO_CONTROLLER_STATUS
	[self addStatus:@"R"];
#endif
	[super consumeSamples:(short *)buffer->mAudioData count:buffer->mAudioDataByteSize/sizeof(short)];
	if ( !outputStarted )
	{
		for ( int i=0; i<MM_AUDIO_CONTROLLER_NUM_OUTPUT_BUFFERS; ++i )
		{
			AudioQueueBufferRef buffer;
			AudioQueueAllocateBuffer( outputQueue, MM_AUDIO_CONTROLLER_BUFFER_SIZE, &buffer );
			buffer->mAudioDataByteSize = buffer->mAudioDataBytesCapacity;
			[outputBuffer getData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize];
			AudioQueueEnqueueBuffer( outputQueue, buffer, 0, NULL );
		}
				
		AudioQueueStart( outputQueue, NULL );
		
		outputStarted = YES;
	}
	AudioQueueEnqueueBuffer( queue, buffer, 0, NULL );
	if ( --inputLevelMeterCountdown == 0 )
	{
		AudioQueueLevelMeterState level;
		UInt32 levelSize = sizeof(level);
		AudioQueueGetProperty(
			inputQueue,
			kAudioQueueProperty_CurrentLevelMeter,
			&level,
			&levelSize );
		[delegate audioController:self inputLevelIs:level.mAveragePower];
		inputLevelMeterCountdown = MM_AUDIO_CONTROLLER_BUFFERS_PER_LEVEL_METER;
	}
}

-(void) playbackCallbackCalledWithQueue:(AudioQueueRef)queue
		buffer:(AudioQueueBufferRef)buffer
{
#ifdef MM_AUDIO_CONTROLLER_STATUS
	[self addStatus:@"P"];
#endif
	if ( ![outputBuffer getData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize] )
	{
#ifdef MM_AUDIO_CONTROLLER_STATUS
		[self addStatus:@"O"];
#endif
		char *zeroes = alloca( MM_AUDIO_CONTROLLER_BUFFER_SIZE );
		memset( zeroes, 0, MM_AUDIO_CONTROLLER_BUFFER_SIZE );
		for ( int i=0; i<2; ++i )
			[outputBuffer putData:zeroes ofSize:MM_AUDIO_CONTROLLER_BUFFER_SIZE];
		[outputBuffer getData:buffer->mAudioData ofSize:buffer->mAudioDataByteSize];
	}
	AudioQueueEnqueueBuffer( outputQueue, buffer, 0, NULL );
	if ( --outputLevelMeterCountdown == 0 )
	{
		AudioQueueLevelMeterState level;
		UInt32 levelSize = sizeof(level);
		AudioQueueGetProperty(
			outputQueue,
			kAudioQueueProperty_CurrentLevelMeter,
			&level,
			&levelSize );
		[delegate audioController:self outputLevelIs:level.mAveragePower];
		outputLevelMeterCountdown = MM_AUDIO_CONTROLLER_BUFFERS_PER_LEVEL_METER;
	}
}

-(void) setPlaybackLevelTo:(float)playbackLevel
{
	AudioQueueSetParameter(
		outputQueue,
		kAudioQueueParam_Volume,
		playbackLevel
		);
}

-(void) reset
{
	[outputBuffer zap];
}

-(void) consumeSamples:(short *)samples count:(unsigned)count
{
	[outputBuffer putData:samples ofSize:count*sizeof(short)];
}


@synthesize delegate;

@end
