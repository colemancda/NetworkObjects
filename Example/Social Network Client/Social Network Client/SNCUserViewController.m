//
//  SNCUserViewController.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/25/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCUserViewController.h"
#import "User.h"
#import "SNCStore.h"
#import "SNCPostsTableViewController.h"

@interface SNCUserViewController ()

@end

@implementation SNCUserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateStyle = NSDateFormatterShortStyle;
    _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    // by defualt load the current user
    
    self.usernameLabel.text = [SNCStore sharedStore].user.username;
    
    self.dateCreatedLabel.text = [_dateFormatter stringFromDate:[SNCStore sharedStore].user.created];
    
    // update count label
    self.numberOfPostsLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)[SNCStore sharedStore].user.posts.count];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
