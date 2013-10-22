//
//  ConnectViewController.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "ConnectViewController.h"
#import "AppDelegate.h"
#import "NOAPI.h"

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
            
            
            
            return;
        }
       
        NSLog(@"Got '%@' token", appDelegate.api.sessionToken);
        
    }];
}


@end
