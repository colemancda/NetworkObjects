//
//  AppDelegate.m
//  NetworkObjectsOSXApp
//
//  Created by Alsey Coleman Miller on 10/5/13.
//
//

#import "AppDelegate.h"
#import "NOServer.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    // setup store (just a memory store for now)
    _store = [[NOStore alloc] init];
    
    _server = [[NOServer alloc] initWithStore:_store];
}

- (IBAction)startStop:(id)sender {
    
    NSButton *button = (NSButton *)sender;
    
    if (button.state == NSOnState) {
        
        [self.server stop];
        
    }
    
    else {
        
        NSUInteger port = self.portTextField.integerValue;
        
        NSError *startError = [self.server startOnPort:port];
        
        if (startError) {
            
            button.state = NSOffState;
            
            [NSApp presentError:startError];
            
        }
    }
}


@end
