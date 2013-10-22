//
//  ConnectViewController.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/22/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConnectViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *urlTextField;

@property (weak, nonatomic) IBOutlet UITextField *clientIDTextField;

@property (weak, nonatomic) IBOutlet UITextField *clientSecretTextField;

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)login:(UIButton *)sender;

@end
