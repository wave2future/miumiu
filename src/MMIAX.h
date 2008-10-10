//
//  MMIAX.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMDataProducer.h"
#import "MMDataConsumer.h"

#include <iax-client.h>

@class MMIAX;
@class MMCall;
@class MMIAXCall;

@protocol MMIAXDelegate <NSObject>

@required

@end

#define MAX_NUM_CALLS 8

@interface MMIAX : NSObject
{
@private
	id <MMIAXDelegate> delegate;
	NSString *hostname, *username, *password, *cidName, *cidNumber;
	unsigned numCalls;
	struct
	{
		struct iax_session *session;
		MMIAXCall *iaxCall;
	} calls[MAX_NUM_CALLS];
	struct iax_session *session;
	CFSocketContext socketContext;
}

-(MMCall *) beginCall:(NSString *)number;

-(void) registerIAXCall:(MMIAXCall *)call withSession:(struct iax_session *)callSession;
-(void) unregisterIAXCall:(MMIAXCall *)call withSession:(struct iax_session *)callSession;

-(void) socketCallbackCalled;

@property ( nonatomic, assign ) id <MMIAXDelegate> delegate;
@property ( nonatomic, readonly ) NSString *hostname;
@property ( nonatomic, readonly ) NSString *username;
@property ( nonatomic, readonly ) NSString *password;
@property ( nonatomic, readonly ) NSString *cidName;
@property ( nonatomic, readonly ) NSString *cidNumber;

@end
