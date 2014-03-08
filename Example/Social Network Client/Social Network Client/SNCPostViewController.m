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

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        
        // KVO
        [self addObserver:self
               forKeyPath:@"post"
                  options:NSKeyValueObservingOptionNew
                  context:KVOContext];
        
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
            
            if (self.view) {
                
                // update UI
                self.textView.text = self.post.text;
            }
            
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
