#import "MMApplicationDelegate.h"
#import "MMPhoneController.h"

@implementation MMApplicationDelegate

-(void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSRect contentRect = NSMakeRect( 10, 40, 320, 480 );
	window = [[NSWindow alloc] initWithContentRect:contentRect
		styleMask:(NSTitledWindowMask|NSClosableWindowMask)
		backing:NSBackingStoreBuffered
		defer:YES];
	[window makeKeyAndOrderFront:nil];
	
	phoneController = [[MMPhoneController alloc] init];

	[phoneController start];
	[NSThread setThreadPriority:0];
}

-(void) dealloc
{
	[window release];
	[super dealloc];
}

@end
