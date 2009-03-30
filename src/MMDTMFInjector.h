//
//  MMDTMFInjector.h
//  MiuMiu
//
//  Created by Peter Zion on 11/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSimpleSamplePipe.h"

@interface MMDTMFInjector : MMSimpleSamplePipe
{
@private
	NSArray *rowCols;
	NSDictionary *digitToRow;
	NSDictionary *digitToCol;
	unsigned offset;
}

-(id) initWithSamplingFrequency:(float)samplingFrequency;

-(void) digitPressed:(NSString *)digit;
-(void) digitReleased:(NSString *)digit;

@end
