//
//  SNCKeyboardViewController.h
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SNCKeyboardViewController : UIViewController <UITextFieldDelegate>

@property IBOutletCollection(UITextField) NSArray *textFields;

@property IBOutlet UIScrollView *scrollView;

@property (readonly) UITextField *activeTextField;

@property (readonly) BOOL keyboardVisible;

@property NSUInteger keyboardTextFieldSpacing;

#pragma mark

-(void)didFinishForm;

#pragma mark - Tap Gesture

-(void)scrollViewWasTapped:(UIGestureRecognizer *)gesture;

#pragma mark - Keyboard notifications

-(void)keyboardWillShow:(NSNotification *)notification;

-(void)keyboardWillHide:(NSNotification *)notification;

-(void)keyboardDidShow:(NSNotification *)notification;

-(void)keyboardDidHide:(NSNotification *)notification;

@end
