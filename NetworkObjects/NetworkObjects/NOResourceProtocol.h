//
//  NOResourceProtocol.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/29/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NOResourceProtocol <NSObject>

@property (readonly) resourceID;

@property (readonly) NSString *url;

-(void)setDefaultValues;

@end
