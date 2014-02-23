//
//  SNCLoginViewController.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SNCKeyboardViewController.h"

@interface SNCLoginViewController : SNCKeyboardViewController

#pragma mark - IB UI Outlets

@property (weak, nonatomic) IBOutlet UITextField *serverURLTextField;

@property (weak, nonatomic) IBOutlet UITextField *clientIDTextField;

@property (weak, nonatomic) IBOutlet UITextField *clientSecretTextField;

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

#pragma mark

- (IBAction)login:(id)sender;

- (IBAction)register:(id)sender;


@end
