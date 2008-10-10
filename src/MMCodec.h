//
//  MMCodec.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMCircularBuffer.h"

@interface MMCodec : NSObject
{
@private
}

-(void) start;
-(void) fromBuffer:(MMCircularBuffer *)src toBuffer:(MMCircularBuffer *)dst;
-(void) stop;

@end

