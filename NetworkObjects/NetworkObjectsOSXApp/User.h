//
//  User.h
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/13/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Client, Post, Session;

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * resourceID;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSSet *authorizedClients;
@property (nonatomic, retain) NSSet *likedPosts;
@property (nonatomic, retain) Post *posts;
@property (nonatomic, retain) NSSet *sessions;
@property (nonatomic, retain) Client *createdClients;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addAuthorizedClientsObject:(Client *)value;
- (void)removeAuthorizedClientsObject:(Client *)value;
- (void)addAuthorizedClients:(NSSet *)values;
- (void)removeAuthorizedClients:(NSSet *)values;

- (void)addLikedPostsObject:(Post *)value;
- (void)removeLikedPostsObject:(Post *)value;
- (void)addLikedPosts:(NSSet *)values;
- (void)removeLikedPosts:(NSSet *)values;

- (void)addSessionsObject:(Session *)value;
- (void)removeSessionsObject:(Session *)value;
- (void)addSessions:(NSSet *)values;
- (void)removeSessions:(NSSet *)values;

@end
