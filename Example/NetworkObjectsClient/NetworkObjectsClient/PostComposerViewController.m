//
//  PostComposerViewController.m
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "PostComposerViewController.h"
#import "ClientStore.h"
#import <NetworkObjects/NOAPICachedStore.h>
#import "NSError+presentError.h"
#import "User.h"
#import "Post.h"

@interface PostComposerViewController ()

@end

@implementation PostComposerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.post) {
        
        self.textView.text = self.post.text;
    }
}

#pragma mark - Actions

-(void)done:(id)sender
{
    // create new post
    if (!self.post) {
        
        NSLog(@"Uploading post...");
        
        [[ClientStore sharedStore].store createResource:@"Post" initialValues:@{@"text": self.textView.text} completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
           
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
               
                if (error) {
                    
                    [error presentError];
                    
                    return;
                }
                
                Post *post = (Post *)resource;
                
                post.creator = [ClientStore sharedStore].user;
                
                NSLog(@"Successfully created new post");
                
                [self performSegueWithIdentifier:@"postComposerVCDone"
                                          sender:self];
            }];
        }];
        
        return;
    }
    
    // edit post
    
    NSLog(@"Editing post...");
    
    [[ClientStore sharedStore].store editResource:(NSManagedObject<NOResourceKeysProtocol> *)self.post changes:@{@"text": self.textView.text} completion:^(NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
            NSLog(@"Successfully edited post");
            
            [self performSegueWithIdentifier:@"postComposerVCDone"
                                      sender:self];
        }];
    }];
}

@end
