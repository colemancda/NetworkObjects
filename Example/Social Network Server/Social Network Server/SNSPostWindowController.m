//
//  SNSPostWindowController.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/16/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSPostWindowController.h"
#import "Post.h"

@interface SNSPostWindowController ()

@end

@implementation SNSPostWindowController

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
    
    [self addObserver:self
           forKeyPath:@"representedObject.text"
              options:NSKeyValueObservingOptionOld
              context:nil];
}

-(void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"representedObject.text"];
    
    
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    // Network edit
    if ([keyPath isEqualToString:@"representedObject.text"]) {
        
        Post *post = (Post *)self.representedObject;
        
        self.textView.string = post.text;
        
    }
    
}

@end
