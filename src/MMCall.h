//
//  MMCall.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMDataPipe.h"

@protocol MMCallDelegate;
@class MMCodec;

@interface MMCall : MMDataPipe
{
@protected
	id <MMCallDelegate> delegate;
}

-(id) initWithCallDelegate:(id <MMCallDelegate>)_delegate;

-(void) sendDTMF:(NSString *)dtmf;
-(void) end;

@property ( nonatomic, assign ) id <MMCallDelegate> delegate;

@end
