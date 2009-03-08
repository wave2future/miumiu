//
//  MMCall.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MMCall;

@protocol MMCallDelegate <NSObject>

@required

-(void) callDidBegin:(id <MMCall>)call;
-(void) callDidBeginRinging:(id <MMCall>)call;
-(void) callDidAnswer:(id <MMCall>)call;
-(void) callDidFail:(id <MMCall>)call;
-(void) callDidReturnBusy:(id <MMCall>)call;
-(void) callDidEnd:(id <MMCall>)call;

@end
