//
//  MMIAXCall.h
//  MiuMiu
//
//  Created by Peter Zion on 10/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MMCall.h"

#include <iax-client.h>

@class MMIAX;

@interface MMIAXCall : MMCall
{
@private
	MMIAX *iax;
	struct iax_session *session;
	unsigned format;
}

-(id) initWithNumber:(NSString *)number iax:(MMIAX *)_iax;

-(void) handleEvent:(struct iax_event *)event;

@end
