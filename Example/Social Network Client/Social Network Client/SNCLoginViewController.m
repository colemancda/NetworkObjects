//
//  SNCLoginViewController.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCLoginViewController.h"
#import "SNCStore.h"
#import "NSError+presentError.h"

@interface SNCLoginViewController ()

@end

@implementation SNCLoginViewController

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

#pragma mark

-(void)didFinishForm
{
    [self login:nil];
}

- (IBAction)login:(id)sender {
    
    [[SNCStore sharedStore] loginWithUsername:self.usernameTextField.text password:self.passwordTextField.text serverURL:[NSURL URLWithString:self.serverURLTextField.text] clientID:self.clientIDTextField.text.integerValue clientSecret:self.clientSecretTextField.text URLSession:nil
                                   completion:^(NSError *error) {
        
        if (error) {
            
            [error presentError];
            
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self performSegueWithIdentifier:@"loginSegue" sender:self];

        }];
    }];
}

- (IBAction)register:(id)sender {
    
    [[SNCStore sharedStore] registerWithUsername:self.usernameTextField.text password:self.passwordTextField.text serverURL:[NSURL URLWithString:self.serverURLTextField.text] clientID:self.clientIDTextField.text.integerValue clientSecret:self.clientSecretTextField.text URLSession:nil completion:^(NSError *error) {
        
        if (error) {
            
            [error presentError];
            
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self performSegueWithIdentifier:@"loginSegue" sender:self];
            
        }];
    }];
    
}

@end
