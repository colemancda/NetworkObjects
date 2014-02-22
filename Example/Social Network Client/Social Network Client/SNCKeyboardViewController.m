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
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
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
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
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
            
            [self didFinishForm];
            
            return YES;
        }
        
        // other text field
        
        [self.activeTextField resignFirstResponder];
        
        self.activeTextField = nil;
        
        // get next text field
        
        NSInteger index = [self.textFields indexOfObject:textField];
        
        UITextField *nextTextField = self.textFields[index + 1];
        
        self.activeTextField = nextTextField;
        
        [self.activeTextField becomeFirstResponder];
        
        return NO;
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
    
    
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    
    
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
