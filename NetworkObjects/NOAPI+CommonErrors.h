//
//  NOAPI+CommonErrors.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 3/26/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import <NetworkObjects/NetworkObjects.h>

@interface NOAPI (CommonErrors)

-(NSError *)invalidServerResponseError;

-(NSError *)badRequestError;

-(NSError *)serverError;

-(NSError *)unauthorizedError;

-(NSError *)notFoundError;

@end
