//
//  ConnectViewController.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "ConnectViewController.h"
#import "AppDelegate.h"
#import <NetworkObjects/NetworkObjects.h>
#import <NetworkObjects/NOAPI.h>
#import "ClientStore.h"
#import "Post.h"
#import "User.h"
#import "NSError+presentError.h"

// UI Restoration Keys
#define kServerURLTextField @"ServerURLTextField"
#define kClientIDTextField @"ClientIDTextField"
#define kClientSecretTextField @"ClientSecretTextField"
#define kUsernameTextField @"UsernameTextField"
#define kPasswordTextField @"PasswordTextField"

@interface ConnectViewController ()

@end

@implementation ConnectViewController

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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // reset cache
    [[ClientStore sharedStore].store.context reset];
}

#pragma mark - Actions

- (IBAction)login:(UIButton *)sender
{
    // set API values
    [ClientStore sharedStore].store.api.serverURL = [NSURL URLWithString:self.urlTextField.text];
    
    [ClientStore sharedStore].store.api.clientSecret = self.clientSecretTextField.text;
    
    NSNumber *clientResourceID = [NSNumber numberWithInteger:self.clientIDTextField.text.integerValue];
    
    [ClientStore sharedStore].store.api.clientResourceID = clientResourceID;
    
    // login
    
    [[ClientStore sharedStore] loginWithUsername:self.usernameTextField.text password:self.passwordTextField.text completion:^(NSError *error) {
        
        if (error) {
            
            [error presentError];
            
            return;
        }
       
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self performSegueWithIdentifier:@"pushSessionVC"
                                      sender:self];
            
        }];
    }];
}

-(void)registerNewUser:(UIButton *)sender
{
    // set API values
    [ClientStore sharedStore].store.api.serverURL = [NSURL URLWithString:self.urlTextField.text];
    
    [ClientStore sharedStore].store.api.clientSecret = self.clientSecretTextField.text;
    
    NSNumber *clientResourceID = [NSNumber numberWithInteger:self.clientIDTextField.text.integerValue];
    
    [ClientStore sharedStore].store.api.clientResourceID = clientResourceID;
    
    // register
    
    [[ClientStore sharedStore] registerWithUsername:self.usernameTextField.text password:self.passwordTextField.text completion:^(NSError *error) {
        
        if (error) {
            
            [error presentError];
            
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self performSegueWithIdentifier:@"pushSessionVC"
                                      sender:self];
            
        }];
    }];
}

#pragma mark - State Restoration and Preservation

-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.urlTextField.text
                 forKey:kServerURLTextField];
    
    [coder encodeObject:self.clientIDTextField.text
                 forKey:kClientIDTextField];
    
    [coder encodeObject:self.clientSecretTextField.text
                 forKey:kClientSecretTextField];
    
    [coder encodeObject:self.usernameTextField.text
                 forKey:kUsernameTextField];
    
    [coder encodeObject:self.passwordTextField.text
                 forKey:kPasswordTextField];
    
    
}

-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.urlTextField.text = [coder decodeObjectForKey:kServerURLTextField];
    
    self.clientIDTextField.text = [coder decodeObjectForKey:kClientIDTextField];
    
    self.clientSecretTextField.text = [coder decodeObjectForKey:kClientSecretTextField];
    
    self.usernameTextField.text = [coder decodeObjectForKey:kUsernameTextField];
    
    self.passwordTextField.text = [coder decodeObjectForKey:kPasswordTextField];
}


@end
