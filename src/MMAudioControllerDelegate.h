/*
 *  MMAudioControllerDelegate.h
 *  MiuMiu
 *
 *  Created by Peter Zion on 03/11/08.
 *  Copyright 2008 Peter Zion. All rights reserved.
 *
 */

#include <Foundation/Foundation.h>

@class MMAudioController;

@protocol MMAudioControllerDelegate <NSObject>

-(void) audioController:(MMAudioController *)audioController
	inputLevelIs:(float)level;
-(void) audioController:(MMAudioController *)audioController
	outputLevelIs:(float)level;

@end
