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

static NSString *kUrlPreferenceKey = @"url";

static NSString *kClientIDPreferenceKey = @"clientID";

static NSString *kClientSecretPreferenceKey = @"clientSecret";

static NSString *kUsernamePreferenceKey = @"username";

static NSString *kPasswordPreferenceKey = @"password";

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
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    // set values for connection
    
    appDelegate.api.serverURL = [NSURL URLWithString:self.urlTextField.text];
    
    NSNumber *clientResourceID = [NSNumber numberWithInteger:self.clientIDTextField.text.integerValue];
    
    appDelegate.api.clientResourceID = clientResourceID;
    
    appDelegate.api.clientSecret = self.clientSecretTextField.text;
    
    appDelegate.api.username = self.usernameTextField.text;
    
    appDelegate.api.userPassword = self.passwordTextField.text;
    
    // login
    
    [appDelegate.api loginWithCompletion:^(NSError *error) {
        
        if (error) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
                
                [alertView show];
                
            }];
            
            return;
        }
       
        NSLog(@"Got '%@' token", appDelegate.api.sessionToken);
        
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


@end
