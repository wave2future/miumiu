//
//  MMIAX.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMCircularBuffer.h"
#include <iax-client.h>

@class MMIAX;

@protocol MMIAXDelegate <NSObject>

@required

-(void) iax:(MMIAX *)iax recordedAudioToBufer:(MMCircularBuffer *)buffer;

@end


@interface MMIAX : NSObject
{
@private
	id <MMIAXDelegate> delegate;
	NSString *hostname, *username, *password, *cidName, *cidNumber;
	struct iax_session *regSession, *callSession;
	CFSocketContext socketContext;
	MMCircularBuffer *recordedAudioBuffer;
	BOOL connected;
}

-(void) beginCall:(NSString *)number;
-(void) endCall;

-(void) playbackFromBuffer:(MMCircularBuffer *)buffer;

-(void) socketCallbackCalled;

@property ( nonatomic, assign ) id <MMIAXDelegate> delegate;

@end
