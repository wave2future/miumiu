//
//  MMIAX.h
//  MiuMiu
//
//  Created by Peter Zion on 09/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMProtocol;

@protocol MMProtocolDelegate <NSObject>

@required

-(void) protocol:(MMProtocol *)protocol isReceivingCallFrom:(NSString *)cidInfo;

@end
