//
//  SNSClientWindowController.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSClientWindowController.h"

static void *KVOContext;

@interface SNSClientWindowController ()

@end

@implementation SNSClientWindowController

-(id)init
{
    self = [self initWithWindowNibName:NSStringFromClass(self.class)
                                 owner:self];
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        
        
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    // self.representedObject changed
    if ([keyPath isEqualToString:@"representedObject"] &&
        context == KVOContext) {
        
        
        
    }
}

@end
