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

@interface SNCUserViewController ()

@property SNCPostsTableViewController *postsTableVC;

@end

@implementation SNCUserViewController

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
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    
    // KVO
    [self addObserver:self forKeyPath:@"user" options:NSKeyValueObservingOptionNew context:nil];
    
    // by defualt load the user profile
    self.user = [SNCStore sharedStore].user;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"user"];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:@"user"]) {
        
        if (self.user) {
            
            self.usernameLabel.text = self.user.username;
            
            self.dateCreatedLabel.text = [_dateFormatter stringFromDate:self.user.created];
            
            self.numberOfPostsLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.user.posts.count];
            
            self.postsTableVC;
        }
    }
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embedPostsTableVC"]) {
        
        self.postsTableVC = segue.destinationViewController;
    }
    
}

@end
