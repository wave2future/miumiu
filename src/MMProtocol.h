//
//  MMIAX.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMCall;

@protocol MMProtocolDelegate <NSObject>

@required

@end

@interface MMProtocol : NSObject
{
@protected
	id <MMProtocolDelegate> delegate;
	NSString *hostname, *username, *password, *cidName, *cidNumber;
}

-(MMCall *) beginCall:(NSString *)number;

@property ( nonatomic, assign ) id <MMProtocolDelegate> delegate;
@property ( nonatomic, readonly ) NSString *hostname;
@property ( nonatomic, readonly ) NSString *username;
@property ( nonatomic, readonly ) NSString *password;
@property ( nonatomic, readonly ) NSString *cidName;
@property ( nonatomic, readonly ) NSString *cidNumber;

@end
