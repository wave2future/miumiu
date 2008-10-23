#import <Cocoa/Cocoa.h>

@class MMPhoneController;

@interface MMApplicationDelegate : NSObject
{
@private
	NSWindow *window;
	MMPhoneController *phoneController;
}

@end
