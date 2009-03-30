//
//  MMCall.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 Peter Zion. All rights reserved.
//

#import "MMSamplePipe.h"

@protocol MMCall <MMSamplePipe>

-(void) sendDTMF:(NSString *)dtmf;
-(void) end;

@end
