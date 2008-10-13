//
//  MMCircularBuffer.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MMCircularBuffer : NSObject
{
@private
	unsigned capacity;
	char *buffer;
	unsigned head, used;
}

-(id) initWithCapacity:(unsigned)capacity;

-(BOOL) putData:(const void *)buffer ofSize:(unsigned)size;
-(BOOL) getData:(void *)buffer ofSize:(unsigned)size;
-(void) zap;

@property ( nonatomic, readonly ) unsigned capacity;
@property ( nonatomic, readonly ) unsigned used;

@end
