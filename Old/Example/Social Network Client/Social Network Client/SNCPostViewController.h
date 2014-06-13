//
//  SNCPostViewController.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 3/6/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Post;

@interface SNCPostViewController : UIViewController

@property Post *post;

@property (readonly) NSURLSession *urlSession;

#pragma mark - IB UI

@property IBOutlet UITextView *textView;

@end
