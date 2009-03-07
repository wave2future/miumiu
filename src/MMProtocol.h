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

-(BOOL) loginWithServer:(NSString *)_server
	username:(NSString *)_username
	password:(NSString *)_password
	cidName:(NSString *)_cidName
	cidNumber:(NSString *)_cidNumber
	withResultingError:(NSError **)error;
-(void) beginCallWithNumber:(NSString *)number callDelegate:(id <MMCallDelegate>)callDelegate;
-(void) answerCallWithCallDelegate:(id <MMCallDelegate>)callDelegate;
-(void) ignoreCall;

@property ( nonatomic, readonly ) NSString *hostname;
@property ( nonatomic, readonly ) NSString *username;
@property ( nonatomic, readonly ) NSString *password;
@property ( nonatomic, readonly ) NSString *cidName;
@property ( nonatomic, readonly ) NSString *cidNumber;

@end
