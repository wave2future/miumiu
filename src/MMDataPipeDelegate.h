/*
 *  MMDataPipeDelegate.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 28/10/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@class MMDataPipe;

@protocol MMDataPipeDelegate <NSObject>

@optional

-(void) dataPipe:(MMDataPipe *)dataPipe didConnectToSource:(MMDataPipe *)newSource;
-(void) dataPipe:(MMDataPipe *)dataPipe willDisconnectFromSource:(MMDataPipe *)oldSource;
-(void) dataPipe:(MMDataPipe *)dataPipe didConnectToTarget:(MMDataPipe *)newTarget;
-(void) dataPipe:(MMDataPipe *)dataPipe willDisconnectFromTarget:(MMDataPipe *)oldTarget;

@end

