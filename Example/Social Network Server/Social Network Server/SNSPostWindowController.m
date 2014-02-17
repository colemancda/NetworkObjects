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
    
    // initially load text
    
    Post *post = (Post *)self.representedObject;
    
    self.textView.string = post.text;
    
    // text view changes
    
    self.textView.textStorage.delegate = self;
}

#pragma mark - Text Storage Delegate

-(void)textStorageDidProcessEditing:(NSNotification *)notification
{
    // update model object
    
    Post *post = (Post *)self.representedObject;
    
    post.text = self.textView.string;
    
}

@end
