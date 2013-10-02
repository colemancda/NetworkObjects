//
//  NOResource.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/1/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, NOResourcePermissions) {
    
    NOResourcePermissionsNoAccess,
    NOResourcePermissionsReadOnly,
    NOResourcePermissionsWrite,
    
};

@interface NOResource : NSManagedObject

// name of the attribute to use for resource IDs, must be a integer
+(NSString *)resourceIDKey;

@end
