//
//  SNSRepresentedObjectWindowController.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/15/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSRepresentedObjectWindowController.h"

static void *SNSRepresentedObjectWindowControllerContext;

@interface SNSRepresentedObjectWindowController ()

@end

@implementation SNSRepresentedObjectWindowController

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
    
    // KVO
    
    [self addObserver:self
           forKeyPath:@"representedObject"
              options:NSKeyValueObservingOptionInitial
              context:SNSRepresentedObjectWindowControllerContext];
}

-(void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"representedObject"];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    // self.representedObject changed
    if ([keyPath isEqualToString:@"representedObject"] &&
        context == SNSRepresentedObjectWindowControllerContext) {
        
        
        
    }
}

@end
