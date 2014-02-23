//
//  NSError+presentError.m
//  NetworkObjectsClient
//
//  Created by Alsey Coleman Miller on 11/11/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NSError+presentError.h"

@implementation NSError (presentError)

-(void)presentError
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                            message:self.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                                  otherButtonTitles:nil];
        
        [alertView show];
        
    }];
}

@end
