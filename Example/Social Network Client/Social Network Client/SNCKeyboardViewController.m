//
//  SNCKeyboardViewController.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/21/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCKeyboardViewController.h"

@interface SNCKeyboardViewController ()

@property UITextField *activeTextField;

@property BOOL keyboardIsVisible;

@end

@implementation SNCKeyboardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // defualt
        self.keyboardTextFieldSpacing = 8;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // just in case it was not setup in IB
    self.scrollView.frame = self.view.frame;
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    // add tap gesture detector
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(scrollViewWasTapped:)]];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

-(void)dealloc
{
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark

-(void)didFinishForm
{
    // do something
}

#pragma mark - Text Field Delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    // set active text field
    self.activeTextField = textField;
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([_textFields containsObject:textField]) {
        
        // final text field
        if (textField == _textFields.lastObject) {
            
            [_activeTextField resignFirstResponder];
            
            self.activeTextField = nil;
            
            [self didFinishForm];
            
            return NO;
        }
        
        // other text field
        
        [self.activeTextField resignFirstResponder];
        
        self.activeTextField = nil;
        
        // get next text field
        
        NSInteger index = [self.textFields indexOfObject:textField];
        
        UITextField *nextTextField = self.textFields[index + 1];
        
        self.activeTextField = nextTextField;
        
        [self.activeTextField becomeFirstResponder];
        
        return YES;
    }
    
    return YES;
}

#pragma mark - Tap Gesture

-(void)scrollViewWasTapped:(UIGestureRecognizer *)gesture
{
    // prevents sending -resignFirstResponder to _activeTextField after the keyboard has been dismissed
    if (self.activeTextField) {
        
        [_activeTextField resignFirstResponder];
        
        self.activeTextField = nil;
    }
}

#pragma mark - Keyboard notifications

-(void)keyboardWillShow:(NSNotification *)notification
{
    if (self.activeTextField) {
        
        // adjust edge insets
        
        NSValue *keyboardFrameValue = notification.userInfo[UIKeyboardFrameBeginUserInfoKey];
        
        UIEdgeInsets contentInsets;
        
        contentInsets.bottom = keyboardFrameValue.CGRectValue.size.height;
        
        self.scrollView.contentInset = contentInsets;
        
        self.scrollView.scrollIndicatorInsets = contentInsets;
        
        // if hidden
        
        CGRect visibleRect = self.view.frame;
        
        visibleRect.size.height -= keyboardFrameValue.CGRectValue.size.height;
        
        CGPoint hiddenPoint = self.activeTextField.frame.origin;
        
        hiddenPoint.y += self.activeTextField.frame.size.height;
        
        // if textfield is partially hidden, scroll to the bottem of it + spacing
        if (!CGRectContainsPoint(visibleRect, self.activeTextField.frame.origin)) {
            
            CGRect visibleRect = self.activeTextField.frame;
            
            visibleRect.origin.y += self.keyboardTextFieldSpacing;
            
            [self.scrollView scrollRectToVisible:self.activeTextField.frame
                                        animated:YES];
            
        }
    }
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    // restore original insets
        
    self.scrollView.contentInset = UIEdgeInsetsZero;
    
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

-(void)keyboardDidShow:(NSNotification *)notification
{
    self.keyboardIsVisible = YES;
    
}

-(void)keyboardDidHide:(NSNotification *)notification
{
    self.keyboardIsVisible = NO;
    
}

@end
