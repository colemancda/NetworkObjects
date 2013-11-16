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
#import "NSObject+NSDictionaryRepresentation.h"
#import <NetworkObjects/NOAPI.h>
#import "ClientStore.h"
#import "Post.h"
#import "User.h"
#import "NSError+presentError.h"

@interface ConnectViewController ()

@end

@implementation ConnectViewController

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
    
    [self loadTextFromPreferences];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)login:(UIButton *)sender
{
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    
    NSError *error;
    
    delegate.clientStore = [[ClientStore alloc] initWithURL:url
                                                      error:&error];
    
    if (error) {
        
        [error presentError];
        
        return;
    }
    
    NSNumber *clientResourceID = [NSNumber numberWithInteger:self.clientIDTextField.text.integerValue];
    
    delegate.clientStore.apiStore.api.clientResourceID = clientResourceID;
    
    delegate.clientStore.apiStore.api.clientSecret = self.clientSecretTextField.text;
    
    // login
    
    [delegate.clientStore loginWithUsername:self.usernameTextField.text password:self.passwordTextField.text completion:^(NSError *error) {
        
        if (error) {
            
            [error presentError];
            
            return;
        }
       
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self performSegueWithIdentifier:@"pushPostsVC"
                                      sender:self];
            
        }];
    }];
}

-(void)registerNewUser:(UIButton *)sender
{
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    
    NSError *error;
    
    delegate.clientStore = [[ClientStore alloc] initWithURL:url
                                                      error:&error];
    
    if (error) {
        
        [error presentError];
        
        return;
    }
    
    NSNumber *clientResourceID = [NSNumber numberWithInteger:self.clientIDTextField.text.integerValue];
    
    delegate.clientStore.apiStore.api.clientResourceID = clientResourceID;
    
    delegate.clientStore.apiStore.api.clientSecret = self.clientSecretTextField.text;
    
    // login
    
    [delegate.clientStore registerWithUsername:self.usernameTextField.text password:self.passwordTextField.text completion:^(NSError *error) {
        
        if (error) {
            
            [error presentError];
            
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self performSegueWithIdentifier:@"pushPostsVC"
                                      sender:self];
            
        }];
    }];
}

#pragma mark - UITextField Delegate

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    // save the text of all textFields that are declared properties
    
    NSDictionary *dictRepresentation = self.dictionaryRepresentation;
    
    for (NSString *key in dictRepresentation) {
        
        id value = [dictRepresentation valueForKey:key];
        
        if (textField == value) {
            
            [[NSUserDefaults standardUserDefaults] setObject:textField.text
                                                      forKey:key];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    };
}

#pragma mark

-(void)loadTextFromPreferences
{
    NSDictionary *dictRepresentation = self.dictionaryRepresentation;
    
    for (NSString *key in dictRepresentation) {
        
        id value = [dictRepresentation valueForKey:key];
        
        if ([value isKindOfClass:[UITextField class]]) {
            
            UITextField *textField = (UITextField *)value;
            
            if (textField.delegate == self) {
                
                // restore text if it was saved
                NSString *text = [[NSUserDefaults standardUserDefaults] stringForKey:key];
                
                if (text) {
                    
                    textField.text = text;
                }
            }
        }
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue
                sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushPostsVC"]) {
        
        
        
    }
}

@end
