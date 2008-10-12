//
//  MMViewController.h
//  MiuMiu
//
//  Created by Peter Zion on 08/10/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMView.h"
#import "MMPhoneController.h"

@interface MMViewController : UIViewController <MMViewDelegate, MMPhoneControllerDelegate>
{
@private
	MMView *view;
	MMPhoneController *phoneController;
}

@end

