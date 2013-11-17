//
//  PostComposerViewController.h
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Post;

@interface PostComposerViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextView *textView;

@property Post *post;

-(IBAction)done:(id)sender;


@end
