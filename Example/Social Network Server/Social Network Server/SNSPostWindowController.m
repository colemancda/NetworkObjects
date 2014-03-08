//
//  SNSPostWindowController.m
//  Social Network Server
//
//  Created by Alsey Coleman Miller on 2/16/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNSPostWindowController.h"
#import "Post.h"

static void *KVOContext;

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
    
    // initially load text
    
    Post *post = (Post *)self.representedObject;
    
    self.textView.string = post.text;
    
    // text view changes
    
    self.textView.textStorage.delegate = self;
    
    // KVO
    [self addObserver:self
           forKeyPath:@"representedObject"
              options:NSKeyValueObservingOptionNew
              context:KVOContext];
}

-(void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"representedObject"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == KVOContext) {
        
        if ([keyPath isEqualToString:@"representedObject"]) {
            
            // update UI
            
            Post *post = (Post *)self.representedObject;
            
            self.textView.string = post.text;
            
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Text Storage Delegate

-(void)textStorageDidProcessEditing:(NSNotification *)notification
{
    // update model object
    
    Post *post = (Post *)self.representedObject;
    
    post.text = self.textView.string;
    
}

@end
