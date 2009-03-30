//
//  MMIAX.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMProtocol;

@protocol MMProtocolDelegate <NSObject>

@required

-(void) protocolConnectSucceeded:(MMProtocol *)protocol;
-(void) protocol:(MMProtocol *)protocol connectFailedWithError:(NSError *)error;

-(void) protocol:(MMProtocol *)protocol beginCallDidFailWithError:(NSError *)error;

-(void) protocol:(MMProtocol *)protocol isReceivingCallFrom:(NSString *)cidInfo;

@end
