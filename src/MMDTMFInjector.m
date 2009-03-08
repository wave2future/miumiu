//
//  MMDTMFInjector.m
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMDTMFInjector.h"
#import "MMToneGenerator.h"

@interface MMDTMFRowCol : NSObject
{
@private
	MMToneGenerator *toneGenerator;
	unsigned pressCount;
}

-(id) initWithFrequency:(float)frequency samplingFrequency:(float)samplingFrequency;
+(id) rowColWithFrequency:(float)frequency samplingFrequency:(float)samplingFrequency;

-(void) pressed;
-(void) released;

-(unsigned) injectSamples:(short *)samples count:(unsigned)count offset:(unsigned)offset;

@end

@implementation MMDTMFRowCol

-(id) initWithFrequency:(float)frequency samplingFrequency:(float)samplingFrequency
{
	if ( self = [super init] )
	{
		float amplitude = 8192;
		toneGenerator = [[MMToneGenerator alloc] initWithNumTones:1 amplitudes:&amplitude frequencies:&frequency samplingFrequency:samplingFrequency];
	}
	return self;
}

+(id) rowColWithFrequency:(float)frequency samplingFrequency:(float)samplingFrequency
{
	return [[[self alloc] initWithFrequency:frequency samplingFrequency:samplingFrequency] autorelease];
}

-(void) dealloc
{
	[toneGenerator release];
	[super dealloc];
}

-(void) pressed
{
	++pressCount;
}

-(void) released
{
	--pressCount;
}

-(unsigned) injectSamples:(short *)samples count:(unsigned)count offset:(unsigned)offset
{
	if ( pressCount > 0 )
		[toneGenerator injectSamples:samples count:count offset:offset];
	return pressCount;
}

@end

@implementation MMDTMFInjector

-(id) initWithSamplingFrequency:(float)samplingFrequency
{
	if ( self = [super init] )
	{
		MMDTMFRowCol *rows[4];
		rows[0] = [MMDTMFRowCol rowColWithFrequency:697 samplingFrequency:samplingFrequency];
		rows[1] = [MMDTMFRowCol rowColWithFrequency:770 samplingFrequency:samplingFrequency];
		rows[2] = [MMDTMFRowCol rowColWithFrequency:852 samplingFrequency:samplingFrequency];
		rows[3] = [MMDTMFRowCol rowColWithFrequency:941 samplingFrequency:samplingFrequency];
	
		MMDTMFRowCol *cols[4];
		cols[0] = [MMDTMFRowCol rowColWithFrequency:1209 samplingFrequency:samplingFrequency];
		cols[1] = [MMDTMFRowCol rowColWithFrequency:1336 samplingFrequency:samplingFrequency];
		cols[2] = [MMDTMFRowCol rowColWithFrequency:1477 samplingFrequency:samplingFrequency];
		cols[3] = [MMDTMFRowCol rowColWithFrequency:1633 samplingFrequency:samplingFrequency];
	
		rowCols = [[NSArray alloc] initWithObjects:
			rows[0], rows[1], rows[2], rows[3],
			cols[0], cols[1], cols[2], cols[3],
			nil];
			
		digitToRow = [[NSDictionary alloc] initWithObjectsAndKeys:
			rows[0], @"1", rows[0], @"2", rows[0], @"3", rows[0], @"A", 
			rows[1], @"4", rows[1], @"5", rows[1], @"6", rows[1], @"B", 
			rows[2], @"7", rows[2], @"8", rows[2], @"9", rows[2], @"C", 
			rows[3], @"*", rows[3], @"0", rows[3], @"#", rows[3], @"D", 
			nil];
			
		digitToCol = [[NSDictionary alloc] initWithObjectsAndKeys:
			cols[0], @"1", cols[1], @"2", cols[2], @"3", cols[3], @"A", 
			cols[0], @"4", cols[1], @"5", cols[2], @"6", cols[3], @"B", 
			cols[0], @"7", cols[1], @"8", cols[2], @"9", cols[3], @"C", 
			cols[0], @"*", cols[1], @"0", cols[2], @"#", cols[3], @"D", 
			nil];
	}
	return self;
}

-(void) dealloc
{
	[digitToCol release];
	[digitToRow release];
	[rowCols release];
	[super dealloc];
}

#pragma mark Public

-(void) digitPressed:(NSString *)digit
{
	[[digitToRow valueForKey:digit] pressed];
	[[digitToCol valueForKey:digit] pressed];
}

-(void) digitReleased:(NSString *)digit
{
	[[digitToRow valueForKey:digit] released];
	[[digitToCol valueForKey:digit] released];
}

#pragma mark MMSampleConsumer

-(void) consumeSamples:(short *)data count:(unsigned)count
{
	unsigned totalPressCount = 0;
	for ( MMDTMFRowCol *rowCol in rowCols )
		totalPressCount += [rowCol injectSamples:data count:count offset:offset];
	if ( totalPressCount > 0 )
		offset += count;
	else
		offset = 0;
	[super consumeSamples:data count:count];
}

@end
