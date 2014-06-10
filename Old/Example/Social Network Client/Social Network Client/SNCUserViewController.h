//
//  SNCUserViewController.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/25/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <UIKit/UIKit.h>
@class User, SNCPostsTableViewController;

@interface SNCUserViewController : UIViewController
{
    NSDateFormatter *_dateFormatter;
}

#pragma mark - IB UI Outlets

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@property (weak, nonatomic) IBOutlet UILabel *dateCreatedLabel;

@property (weak, nonatomic) IBOutlet UILabel *numberOfPostsLabel;


@end
