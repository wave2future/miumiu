//
//  MMCall.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMCall;
@class MMCodec;

@protocol MMCallDelegate <NSObject>

@required

-(void) callDidBegin:(MMCall *)call;
-(void) callDidBeginRinging:(MMCall *)call;
-(void) call:(MMCall *)call didAnswerWithEncoder:(MMCodec *)encoder decoder:(MMCodec *)decoder;
-(void) callDidFail:(MMCall *)call;
-(void) callDidReturnBusy:(MMCall *)call;
-(void) callDidEnd:(MMCall *)call;

@end
