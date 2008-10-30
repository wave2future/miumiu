//
//  MMIAX.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MMProtocolDelegate;
@class MMCall;
@protocol MMCallDelegate;

@interface MMProtocol : NSObject
{
@protected
	id <MMProtocolDelegate> delegate;
	NSString *hostname, *username, *password, *cidName, *cidNumber;
}

-(id) initWithProtocolDelegate:(id <MMProtocolDelegate>)_delegate;

-(MMCall *) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate;
-(MMCall *) answerCallWithCallDelegate:(id <MMCallDelegate>)callDelegate;
-(void) ignoreCall;

@property ( nonatomic, readonly ) NSString *hostname;
@property ( nonatomic, readonly ) NSString *username;
@property ( nonatomic, readonly ) NSString *password;
@property ( nonatomic, readonly ) NSString *cidName;
@property ( nonatomic, readonly ) NSString *cidNumber;

@end
