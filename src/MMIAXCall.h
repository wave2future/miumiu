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

-(id) initWithSession:(struct iax_session *)session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax;
-(id) initWithFormat:(unsigned)_format session:(struct iax_session *)session callDelegate:(id <MMCallDelegate>)_delegate iax:(MMIAX *)_iax;

-(BOOL) handleEvent:(struct iax_event *)event;
-(void) end;

@end
