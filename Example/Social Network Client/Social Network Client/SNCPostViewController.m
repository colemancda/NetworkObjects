//
//  SNCPostViewController.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 3/6/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCPostViewController.h"
#import "SNCStore.h"
#import "Post.h"
#import "NSError+presentError.h"

static void *KVOContext;

@interface SNCPostViewController ()

@property NSURLSession *urlSession;

@end

@implementation SNCPostViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // KVO
    [self addObserver:self
           forKeyPath:@"post"
              options:NSKeyValueObservingOptionNew
              context:KVOContext];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"post"];
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == KVOContext) {
        
        if ([keyPath isEqualToString:@"post"]) {
            
            // update UI
            self.textView.text = self.post.text;
            
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
