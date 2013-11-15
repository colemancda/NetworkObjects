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

- (IBAction)login:(UIButton *)sender {
    
    // set values for connection
    
    [ClientStore sharedStore].api.serverURL = [NSURL URLWithString:self.urlTextField.text];
    
    NSNumber *clientResourceID = [NSNumber numberWithInteger:self.clientIDTextField.text.integerValue];
    
    [ClientStore sharedStore].api.clientResourceID = clientResourceID;
    
    [ClientStore sharedStore].api.clientSecret = self.clientSecretTextField.text;
    
    [ClientStore sharedStore].api.username = self.usernameTextField.text;
    
    [ClientStore sharedStore].api.userPassword = self.passwordTextField.text;
    
    // login
    
    [[ClientStore sharedStore].api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                
                [alertView show];
                
            }];
            
            return;
        }
        
        NSLog(@"Got '%@' token", [ClientStore sharedStore].api.sessionToken);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            // push VC
            
            [self pushPostsVCWithUserPosts];
            
        }];
    }];
    
}

-(void)registerNewUser:(id)sender
{
    // set values for connection (login only as app and not as user & app)
    
    [ClientStore sharedStore].api.serverURL = [NSURL URLWithString:self.urlTextField.text];
    
    NSNumber *clientResourceID = [NSNumber numberWithInteger:self.clientIDTextField.text.integerValue];
    
    [ClientStore sharedStore].api.clientResourceID = clientResourceID;
    
    [ClientStore sharedStore].api.clientSecret = self.clientSecretTextField.text;
    
    [ClientStore sharedStore].api.username = nil;
    
    [ClientStore sharedStore].api.userPassword = nil;
    
    // login
    
    [[ClientStore sharedStore].api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            [error presentError];
            
            return;
        }
        
        NSLog(@"Got '%@' token", [ClientStore sharedStore].api.sessionToken);
        
        NSDictionary *initialValues = @{@"username": self.usernameTextField.text,
                                        @"password": self.passwordTextField.text};
        
        [[ClientStore sharedStore].api createResource:@"User" withInitialValues:initialValues completion:^(NSError *error, NSNumber *resourceID) {
            
            if (error) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                    
                    [alertView show];
                    
                }];
                
                return;
            }
            
            NSLog(@"Created new user with resource ID %@", resourceID);
            
            // login as new user
            
            //...
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                [self pushPostsVCWithUserPosts];
            }];
            
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

#pragma mark

-(void)pushPostsVCWithUserPosts
{
    // push VC
    
    // get user's post IDs...
    
    NSLog(@"Downloading user profile...");
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.resultType = NSDictionaryResultType;
    
    request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"resourceID", [ClientStore sharedStore].api.userResourceID];
    
     [[ClientStore sharedStore].context performBlock:^{
         
         NSError *error;
         
         NSArray *results = [[ClientStore sharedStore].context executeFetchRequest:request
                                                                             error:&error];
         
         if (error) {
             
             [error presentError];
             
             return;
         }
         
         // get user
         
         NSDictionary *userDict = results.firstObject;
         
         if (!userDict) {
             
             NSLog(@"Could not download user profile");
             
             NSError *error = [NSError errorWithDomain:@"domain"
                                                  code:100
                                              userInfo:@{NSLocalizedDescriptionKey: @"Could not fetch user profile"}];
             
             [error presentError];
             
             return;
         }
         
         _postIDs = userDict[@"posts"];
         
         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
             [self performSegueWithIdentifier:@"pushPostsVC"
                                       sender:self];
             
         }];
     }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue
                sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushPostsVC"]) {
        
        
        
    }
}

@end
