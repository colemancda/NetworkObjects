//
//  Client.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/13/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Session, User;

@interface Client : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSNumber * isNotThirdParty;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * resourceID;
@property (nonatomic, retain) NSString * secret;
@property (nonatomic, retain) NSSet *authorizedUsers;
@property (nonatomic, retain) NSSet *sessions;
@property (nonatomic, retain) User *creator;
@end

@interface Client (CoreDataGeneratedAccessors)

- (void)addAuthorizedUsersObject:(User *)value;
- (void)removeAuthorizedUsersObject:(User *)value;
- (void)addAuthorizedUsers:(NSSet *)values;
- (void)removeAuthorizedUsers:(NSSet *)values;

- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

@end
