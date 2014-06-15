//
//  NOStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOStore.h"
#import "NODefines.h"
#import "NOError.h"
#import "NSManagedObject+CoreDataJSONCompatibility.h"

#pragma mark - Category Declarations

@interface NOStore (Cache)

// call these inside -performWithBlock:

-(NSManagedObjectID *)findEntity:(NSEntityDescription *)entity
                  withResourceID:(NSNumber *)resourceID
                         context:(NSManagedObjectContext *)context;

// Must save context after calling these

-(NSManagedObject *)findOrCreateEntity:(NSEntityDescription *)entity
                        withResourceID:(NSNumber *)resourceID
                               context:(NSManagedObjectContext *)context;

-(NSManagedObject *)setJSONObject:(NSDictionary *)jsonObject
                 forManagedObject:(NSManagedObject *)managedObject;

@end

@interface NSEntityDescription (Convert)

-(NSDictionary *)jsonObjectFromCoreDataValues:(NSDictionary *)values
                 usingResourceIDAttributeName:(NSString *)resourceIDAttributeName;

@end

@interface NOStore (DateCached)

-(void)setupDateCachedAttributeWithAttributeName:(NSString *)dateCachedAttributeName;

-(void)didCacheManagedObject:(NSManagedObject *)managedObject;

@end

@interface NOStore (ManagedObjectContexts)

-(void)setupManagedObjectContextsWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc managedObjectContextConcurrencyType:(NSManagedObjectContextConcurrencyType)managedObjectContextConcurrencyType;

-(void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification;

@end

@interface NOStore (CommonErrors)

-(NSError *)invalidServerResponseError;

-(NSError *)badRequestError;

-(NSError *)serverError;

-(NSError *)unauthorizedError;

-(NSError *)notFoundError;

@end

@implementation NOStore (NSJSONWritingOption)

-(NSJSONWritingOptions)jsonWritingOption
{
    if (self.prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

@end

@interface NOStore (API)

-(NSURLSessionDataTask *)searchForResource:(NSEntityDescription *)enitity
                            withParameters:(NSDictionary *)parameters
                                URLSession:(NSURLSession *)urlSession
                                completion:(void (^)(NSError *error, NSArray *results))completionBlock;

-(NSURLSessionDataTask *)getResource:(NSEntityDescription *)entity
                              withID:(NSUInteger)resourceID
                          URLSession:(NSURLSession *)urlSession
                          completion:(void (^)(NSError *error, NSDictionary *resource))completionBlock;

-(NSURLSessionDataTask *)editResource:(NSEntityDescription *)entity
                               withID:(NSUInteger)resourceID
                              changes:(NSDictionary *)changes
                           URLSession:(NSURLSession *)urlSession
                           completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)deleteResource:(NSEntityDescription *)entity
                                 withID:(NSUInteger)resourceID
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)createResource:(NSEntityDescription *)entity
                      withInitialValues:(NSDictionary *)initialValues
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *error, NSNumber *resourceID))completionBlock;

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                              onResource:(NSEntityDescription *)entity
                                  withID:(NSUInteger)resourceID
                          withJSONObject:(NSDictionary *)jsonObject
                              URLSession:(NSURLSession *)urlSession
                              completion:(void (^)(NSError *error, NSNumber *statusCode, NSDictionary *response))completionBlock;

@end

@interface NOStore ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic) NSManagedObjectContext *privateQueueManagedObjectContext;

@property (nonatomic) NSString *dateCachedAttributeName;

@property (nonatomic) NSString *resourceIDAttributeName;

@property (nonatomic) NSString *searchPath;

@property (nonatomic) BOOL prettyPrintJSON;

@property (nonatomic) NSURL *serverURL;

@property (nonatomic) NSDictionary *entitiesByResourcePath;

@property (nonatomic) NSManagedObjectModel *model;

@end

@implementation NOStore

#pragma mark - Initialization

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc
               managedObjectContextConcurrencyType:(NSManagedObjectContextConcurrencyType)managedObjectContextConcurrencyType
                                         serverURL:(NSURL *)serverURL
                            entitiesByResourcePath:(NSDictionary *)entitiesByResourcePath
                                   prettyPrintJSON:(BOOL)prettyPrintJSON
                           resourceIDAttributeName:(NSString *)resourceIDAttributeName
                           dateCachedAttributeName:(NSString *)dateCachedAttributeName
{
    self = [super init];
    
    if (self) {
        
        [self setupManagedObjectContextsWithPersistentStoreCoordinator:psc
                                   managedObjectContextConcurrencyType:managedObjectContextConcurrencyType];
        
        self.serverURL = serverURL;
        
        self.entitiesByResourcePath = entitiesByResourcePath;
        
        self.prettyPrintJSON = prettyPrintJSON;
        
        self.resourceIDAttributeName = resourceIDAttributeName;
        
        self.dateCachedAttributeName = dateCachedAttributeName;
        
        // modify the managedObjectModel
        
        if (self.dateCachedAttributeName) {
            
            [self setupDateCachedAttributeWithAttributeName:self.dateCachedAttributeName];
        }
        
    }
    
    return self;
}

#pragma mark - Requests

-(NSURLSessionDataTask *)performSearchWithFetchRequest:(NSFetchRequest *)fetchRequest
                                            URLSession:(NSURLSession *)urlSession
                                            completion:(void (^)(NSError *, NSArray *))completionBlock
{
    // build JSON request from fetch request
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // Optional comparison predicate
    
    NSComparisonPredicate *predicate = (NSComparisonPredicate *)fetchRequest.predicate;
    
    if (predicate) {
        
        if (![predicate isKindOfClass:[NSComparisonPredicate class]]) {
            
            [NSException raise:NSInvalidArgumentException
                        format:@"The fetch request's predicate must be of type NSComparisonPredicate"];
            
            return nil;
        }
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateKey]] = predicate.leftExpression.keyPath;
        
        // convert value to from Core Data to JSON
        
        id jsonValue = [fetchRequest.entity jsonObjectFromCoreDataValues:@{predicate.leftExpression.keyPath: predicate.rightExpression.constantValue} usingResourceIDAttributeName:_resourceIDAttributeName].allValues.firstObject;
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateValue]] = jsonValue;
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateOperator]] = [NSNumber numberWithInteger:predicate.predicateOperatorType];
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateOption]] = [NSNumber numberWithInteger:predicate.options];
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateModifier]] = [NSNumber numberWithInteger:predicate.comparisonPredicateModifier];
    }
    
    // other fetch parameters
    
    if (fetchRequest.fetchLimit) {
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterFetchLimit]] = [NSNumber numberWithInteger: fetchRequest.fetchLimit];
    }
    
    if (fetchRequest.fetchOffset) {
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterFetchOffset]] = [NSNumber numberWithInteger:fetchRequest.fetchOffset];
    }
    
    if (fetchRequest.includesSubentities) {
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterIncludesSubentities]] = [NSNumber numberWithInteger:fetchRequest.includesSubentities];
    }
    
    // sort descriptors
    
    if (fetchRequest.sortDescriptors.count) {
        
        NSMutableArray *jsonSortDescriptors = [[NSMutableArray alloc] init];
        
        for (NSSortDescriptor *sort in fetchRequest.sortDescriptors) {
            
            [jsonSortDescriptors addObject:@{sort.key: @(sort.ascending)}];
        }
        
        jsonObject[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterSortDescriptors]] = jsonSortDescriptors;
    }
    
    // get entity
    
    NSEntityDescription *entity = self.model.entitiesByName[fetchRequest.entityName];
    
    return [self searchForResource:entity withParameters:jsonObject URLSession:urlSession completion:^(NSError *error, NSArray *results) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // get results as cached resources
        
        NSMutableArray *cachedResults = [[NSMutableArray alloc] init];
        
        [_privateQueueManagedObjectContext performBlockAndWait:^{
            
            for (NSDictionary *resourcePathByResourceID in results) {
                
                NSString *resourcePath = resourcePathByResourceID.allValues.firstObject;
                
                NSString *resourceID = resourcePathByResourceID.allKeys.firstObject;
                
                // get the entity
                
                NSEntityDescription *entity = self.entitiesByResourcePath[resourcePath];
                
                NSManagedObject *resource = [self findOrCreateEntity:entity
                                                      withResourceID:[NSNumber numberWithInteger:resourceID.integerValue]
                                                             context:_privateQueueManagedObjectContext];
                
                [cachedResults addObject:resource];
                
                // save
                
                NSError *saveError;
                
                if (![_privateQueueManagedObjectContext save:&saveError]) {
                    
                    [NSException raise:NSInternalInconsistencyException
                                format:@"%@", saveError.localizedDescription];
                }
            }
            
        }];
        
        // get the corresponding managed objects that belongs to the main queue context
        
        NSMutableArray *mainContextResults = [[NSMutableArray alloc] init];
        
        [_managedObjectContext performBlockAndWait:^{
            
            for (NSManagedObject *managedObject in cachedResults) {
                
                NSManagedObject *mainContextManagedObject = [_managedObjectContext objectWithID:managedObject.objectID];
                
                [mainContextResults addObject:mainContextManagedObject];
            }
            
        }];
        
        completionBlock(nil, mainContextResults);
        
    }];
}

-(NSURLSessionDataTask *)fetchEntityWithName:(NSString *)entityName
                                  resourceID:(NSNumber *)resourceID
                                  URLSession:(NSURLSession *)urlSession
                                  completion:(void (^)(NSError *, NSManagedObject *))completionBlock
{
    NSEntityDescription *entity = self.model.entitiesByName[entityName];
    
    return [self getResource:entity withID:resourceID.integerValue URLSession:urlSession completion:^(NSError *error, NSDictionary *resourceDict) {
        
        if (error) {
            
            // not found, delete object from our cache
            
            if (error.code == NOServerStatusCodeNotFound) {
                
                // delete object on private thread
                
                [self.privateQueueManagedObjectContext performBlockAndWait:^{
                    
                    NSManagedObjectID *objectID = [self findEntity:entity
                                                    withResourceID:resourceID
                                                           context:_privateQueueManagedObjectContext];
                    
                    if (objectID) {
                        
                        [_privateQueueManagedObjectContext deleteObject:[_privateQueueManagedObjectContext objectWithID:objectID]];
                        
                        NSError *saveError;
                        
                        // save
                        
                        if (![_privateQueueManagedObjectContext save:&saveError]) {
                            
                            [NSException raise:NSInternalInconsistencyException
                                        format:@"%@", saveError];
                        }
                    }
                    
                }];
            }
            
            completionBlock(error, nil);
            
            return;
        }
        
        __block NSManagedObject *resource;
        
        [self.privateQueueManagedObjectContext performBlockAndWait:^{
            
            // get cached resource
            
            resource = [self findOrCreateEntity:entity
                                 withResourceID:resourceID
                                        context:_privateQueueManagedObjectContext];
            
            // set values
            
            [self setJSONObject:resourceDict
               forManagedObject:resource];
            
            
            // set date cached
            
            [self didCacheManagedObject:resource];
            
            // save
            
            NSError *saveError;
            
            if (![_privateQueueManagedObjectContext save:&saveError]) {
                
                [NSException raise:NSInternalInconsistencyException
                            format:@"%@", saveError.localizedDescription];
            }
            
        }];
        
        // get the corresponding managed object that belongs to the main queue context
        
        __block NSManagedObject *mainContextManagedObject;
        
        [self.managedObjectContext performBlockAndWait:^{
            
            mainContextManagedObject = [_managedObjectContext objectWithID:resource.objectID];
            
        }];
        
        completionBlock(nil, mainContextManagedObject);
    }];
}

-(NSURLSessionDataTask *)createEntityWithName:(NSString *)entityName
                                initialValues:(NSDictionary *)initialValues
                                   URLSession:(NSURLSession *)urlSession
                                   completion:(void (^)(NSError *, NSManagedObject *))completionBlock
{
    NSEntityDescription *entity = self.model.entitiesByName[entityName];
    
    // convert those Core Data values to JSON
    NSDictionary *jsonValues = [entity jsonObjectFromCoreDataValues:initialValues usingResourceIDAttributeName:_resourceIDAttributeName];
    
    return [self createResource:entity withInitialValues:jsonValues URLSession:urlSession completion:^(NSError *error, NSNumber *resourceID) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        __block NSManagedObject *resource;
        
        [self.privateQueueManagedObjectContext performBlockAndWait:^{
            
            // create new entity
            
            resource = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                     inManagedObjectContext:_privateQueueManagedObjectContext];
            
            // set resource ID
            
            [resource setValue:resourceID
                        forKey:_resourceIDAttributeName];
            
            // set values
            for (NSString *key in initialValues) {
                
                id value = initialValues[key];
                
                // Core Data cannot hold NSNull
                
                if (value == [NSNull null]) {
                    
                    value = nil;
                }
                
                [resource setValue:value
                            forKey:key];
            }
            
            // set date cached
            
            [self didCacheManagedObject:resource];
            
            // save
            
            NSError *saveError;
            
            if (![_privateQueueManagedObjectContext save:&saveError]) {
                
                [NSException raise:NSInternalInconsistencyException
                            format:@"%@", saveError.localizedDescription];
            }
            
        }];
        
        // get the corresponding managed object that belongs to the main queue context
        
        __block NSManagedObject *mainContextManagedObject;
        
        [self.managedObjectContext performBlockAndWait:^{
            
            mainContextManagedObject = [_managedObjectContext objectWithID:resource.objectID];
            
        }];
        
        completionBlock(nil, resource);
    }];
}

-(NSURLSessionDataTask *)editManagedObject:(NSManagedObject *)resource
                                   changes:(NSDictionary *)values
                                URLSession:(NSURLSession *)urlSession
                                completion:(void (^)(NSError *))completionBlock
{
    // convert those Core Data values to JSON
    NSDictionary *jsonValues = [resource.entity jsonObjectFromCoreDataValues:values usingResourceIDAttributeName:_resourceIDAttributeName];
    
    // get resourceID
    
    NSNumber *resourceID = [resource valueForKey:_resourceIDAttributeName];
    
    return [self editResource:resource.entity withID:resourceID.integerValue changes:jsonValues URLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        [self.privateQueueManagedObjectContext performBlockAndWait:^{
            
            // get object on this context
            
            NSManagedObject *contextResource = [_privateQueueManagedObjectContext objectWithID:resource.objectID];
            
            // set values
            for (NSString *key in values) {
                
                id value = values[key];
                
                // Core Data cannot hold NSNull
                
                if (value == [NSNull null]) {
                    
                    value = nil;
                }
                
                [contextResource setValue:value
                                   forKey:key];
            }
            
            // save
            
            NSError *saveError;
            
            if (![_privateQueueManagedObjectContext save:&saveError]) {
                
                [NSException raise:NSInternalInconsistencyException
                            format:@"%@", saveError.localizedDescription];
            }
            
        }];
        
        completionBlock(nil);
        
    }];
}

-(NSURLSessionDataTask *)deleteManagedObject:(NSManagedObject *)resource
                                  URLSession:(NSURLSession *)urlSession
                                  completion:(void (^)(NSError *))completionBlock
{
    // get resourceID
    
    NSNumber *resourceID = [resource valueForKey:_resourceIDAttributeName];
    
    return [self deleteResource:resource.entity withID:resourceID.integerValue URLSession:urlSession completion:^(NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // delete...
        
        [self.privateQueueManagedObjectContext performBlock:^{
            
            // get object on this context
            
            NSManagedObject *contextResource = [_privateQueueManagedObjectContext objectWithID:resource.objectID];
            
            [_privateQueueManagedObjectContext deleteObject:contextResource];
            
            // save
            
            NSError *saveError;
            
            if (![_privateQueueManagedObjectContext save:&saveError]) {
                
                [NSException raise:NSInternalInconsistencyException
                            format:@"%@", saveError.localizedDescription];
            }
            
            completionBlock(nil);
        }];
    }];
}

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                        forManagedObject:(NSManagedObject *)managedObject
                          withJSONObject:(NSDictionary *)jsonObject
                              URLSession:(NSURLSession *)urlSession
                              completion:(void (^)(NSError *, NSNumber *, NSDictionary *))completionBlock
{
    // get resourceID
    
    NSNumber *resourceID = [managedObject valueForKey:_resourceIDAttributeName];
    
    return [self performFunction:functionName
                      onResource:managedObject.entity
                          withID:resourceID.integerValue
                  withJSONObject:jsonObject
                      URLSession:urlSession
                      completion:completionBlock];
}

@end

#pragma mark - Category Implementations

@implementation NOStore (API)

-(NSURLSessionDataTask *)searchForResource:(NSEntityDescription *)entity
                            withParameters:(NSDictionary *)parameters
                                URLSession:(NSURLSession *)urlSession
                                completion:(void (^)(NSError *, NSArray *))completionBlock
{
    if (!self.searchPath) {
        
        [NSException raise:NSInternalInconsistencyException
                    format:@"searchPath must be set to a valid value"];
    }
    
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // Build URL
    
    NSString *resourcePath = [self.entitiesByResourcePath allKeysForObject:entity].firstObject;
    
    NSURL *searchURL = [self.serverURL URLByAppendingPathComponent:self.searchPath];
    
    searchURL = [searchURL URLByAppendingPathComponent:resourcePath];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:searchURL];
    
    urlRequest.HTTPMethod = @"POST";
    
    // add JSON data
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:self.jsonWritingOption
                                                         error:nil];
    if (!jsonData) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"Invalid parameters NSDictionary argument. Not valid JSON."];
        
        return nil;
    }
    
    urlRequest.HTTPBody = jsonData;
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // error codes
        
        if (httpResponse.statusCode != NOServerStatusCodeOK) {
            
            if (httpResponse.statusCode == NOServerStatusCodeUnauthorized) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeForbidden) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to perform search is denied",
                                                               @"Permission to perform search is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                                              code:NOErrorCodeServerStatusCodeForbidden
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeInternalServerError) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeBadRequest) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // parse response
        
        NSArray *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                options:NSJSONReadingAllowFragments
                                                                  error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSArray class]]) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // verify that values are string
        
        for (NSDictionary *resultResourcePathByResourceID in jsonResponse) {
            
            if (![resultResourcePathByResourceID isKindOfClass:[NSDictionary class]]) {
                
                completionBlock(self.invalidServerResponseError, nil);
                
                return;
            }
            
            NSString *resourcePath = resultResourcePathByResourceID.allValues.firstObject;
            
            NSString *resourceID = resultResourcePathByResourceID.allKeys.firstObject;
            
            if (![resourcePath isKindOfClass:[NSString class]] ||
                ![resourceID isKindOfClass:[NSString class]] ||
                resultResourcePathByResourceID.allKeys.count != 1 ||
                resultResourcePathByResourceID.allValues.count != 1) {
                
                completionBlock(self.invalidServerResponseError, nil);
                
                return;
            }
        }
        
        completionBlock(nil, jsonResponse);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)getResource:(NSEntityDescription *)entity
                              withID:(NSUInteger)resourceID
                          URLSession:(NSURLSession *)urlSession
                          completion:(void (^)(NSError *, NSDictionary *))completionBlock
{
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    NSString *resourcePath = [self.entitiesByResourcePath allKeysForObject:entity].firstObject;
    
    NSURL *getResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    getResourceURL = [getResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:getResourceURL];
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != NOServerStatusCodeOK) {
            
            if (httpResponse.statusCode == NOServerStatusCodeUnauthorized) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeForbidden) {
                
                NSString *errorDescription = NSLocalizedString(@"Access to resource is denied",
                                                               @"Access to resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                                              code:NOErrorCodeServerStatusCodeForbidden
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeInternalServerError) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeBadRequest) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeNotFound) {
                
                completionBlock([self notFoundError], nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        completionBlock(nil, jsonResponse);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)createResource:(NSEntityDescription *)entity
                      withInitialValues:(NSDictionary *)initialValues
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *, NSNumber *))completionBlock
{
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL...
    
    NSString *resourcePath = [self.entitiesByResourcePath allKeysForObject:entity].firstObject;
    
    NSURL *createResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:createResourceURL];
    
    // add the initial values to request
    if (initialValues) {
        
        NSData *postData = [NSJSONSerialization dataWithJSONObject:initialValues
                                                           options:self.jsonWritingOption
                                                             error:nil];
        
        if (!postData) {
            
            completionBlock(self.badRequestError, nil);
            
            return nil;
        }
        
        request.HTTPBody = postData;
    }
    
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != NOServerStatusCodeOK) {
            
            if (httpResponse.statusCode == NOServerStatusCodeUnauthorized) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeForbidden) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to create new resource is denied",
                                                               @"Permission to create new resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                                              code:NOErrorCodeServerStatusCodeForbidden
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeInternalServerError) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeBadRequest) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // get new resource id
        
        NSNumber *resourceID = jsonResponse[_resourceIDAttributeName];
        
        if (!resourceID) {
            
            completionBlock(self.invalidServerResponseError, nil);
            
            return;
        }
        
        // got it!
        completionBlock(nil, resourceID);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)editResource:(NSEntityDescription *)entity
                               withID:(NSUInteger)resourceID
                              changes:(NSDictionary *)changes
                           URLSession:(NSURLSession *)urlSession
                           completion:(void (^)(NSError *))completionBlock
{
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    NSString *resourcePath = [self.entitiesByResourcePath allKeysForObject:entity].firstObject;
    
    NSURL *editResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    editResourceURL = [editResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:editResourceURL];
    
    request.HTTPMethod = @"PUT";
    
    // add HTTP body
    
    NSData *httpBody = [NSJSONSerialization dataWithJSONObject:changes
                                                       options:self.jsonWritingOption
                                                         error:nil];
    
    if (!httpBody) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"The 'changes' dictionary must be a valid JSON object"];
        
        return nil;
    }
    
    request.HTTPBody = httpBody;
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != NOServerStatusCodeOK) {
            
            if (httpResponse.statusCode == NOServerStatusCodeUnauthorized) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeForbidden) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to edit resource is denied",
                                                               @"Permission to edit resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                                              code:NOServerStatusCodeForbidden
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeInternalServerError) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeBadRequest) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        completionBlock(nil);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)deleteResource:(NSEntityDescription *)entity
                                 withID:(NSUInteger)resourceID
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *))completionBlock
{
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    NSString *resourcePath = [self.entitiesByResourcePath allKeysForObject:entity].firstObject;
    
    NSURL *deleteResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    deleteResourceURL = [deleteResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deleteResourceURL];
    
    request.HTTPMethod = @"DELETE";
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != NOServerStatusCodeOK) {
            
            if (httpResponse.statusCode == NOServerStatusCodeNotFound) {
                
                completionBlock(self.notFoundError);
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeUnauthorized) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeForbidden) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to delete resource is denied",
                                                               @"Permission to delete resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                                              code:NOServerStatusCodeForbidden
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeInternalServerError) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerStatusCodeBadRequest) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        completionBlock(nil);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                              onResource:(NSEntityDescription *)entity
                                  withID:(NSUInteger)resourceID
                          withJSONObject:(NSDictionary *)jsonObject
                              URLSession:(NSURLSession *)urlSession
                              completion:(void (^)(NSError *, NSNumber *, NSDictionary *))completionBlock
{
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    NSString *resourcePath = [self.entitiesByResourcePath allKeysForObject:entity].firstObject;
    
    NSURL *deleteResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    deleteResourceURL = [deleteResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deleteResourceURL];
    
    request.HTTPMethod = @"POST";
    
    // add HTTP body
    if (jsonObject) {
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:self.jsonWritingOption
                                                             error:nil];
        
        if (!jsonData) {
            
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid 'withJSONObject:' NSDictionary argument. Not valid JSON."];
            
            return nil;
        }
        
        request.HTTPBody = jsonData;
    }
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil, nil);
            
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        NSNumber *statusCode = @(httpResponse.statusCode);
        
        // get response body
        
        NSDictionary *jsonResponse;
        
        if (data) {
            
            jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                           options:NSJSONReadingAllowFragments
                                                             error:nil];
            
            if (![jsonResponse isKindOfClass:[NSDictionary class]]) {
                
                jsonResponse = nil;
            }
        }
        
        completionBlock(nil, statusCode, jsonResponse);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

@end

@implementation NOStore (DateCached)

-(void)setupDateCachedAttributeWithAttributeName:(NSString *)dateCachedAttributeName
{
    // add a date attribute to
    for (NSString *entityName in self.model.entitiesByName) {
        
        NSEntityDescription *entity = self.model.entitiesByName[entityName];
        
        if (!entity.superentity) {
            
            // create new (runtime) attribute
            
            NSAttributeDescription *dateAttribute = [[NSAttributeDescription alloc] init];
            
            dateAttribute.attributeType = NSDateAttributeType;
            
            dateAttribute.name = dateCachedAttributeName;
            
            // add to entity
            
            entity.properties = [entity.properties arrayByAddingObject:dateAttribute];
        }
    }
}

-(void)didCacheManagedObject:(NSManagedObject *)managedObject;
{
    if (_dateCachedAttributeName) {
        
        [managedObject setValue:[NSDate date]
                         forKey:self.dateCachedAttributeName];
    }
}

@end

@implementation NOStore (ManagedObjectContexts)

-(void)setupManagedObjectContextsWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc managedObjectContextConcurrencyType:(NSManagedObjectContextConcurrencyType)managedObjectContextConcurrencyType
{
    // setup contexts
    
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:managedObjectContextConcurrencyType];
    
    self.managedObjectContext.undoManager = nil;
    
    self.managedObjectContext.persistentStoreCoordinator = psc;
    
    self.model = psc.managedObjectModel;
    
    self.privateQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    self.privateQueueManagedObjectContext.undoManager = nil;
    
    self.privateQueueManagedObjectContext.persistentStoreCoordinator = psc;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChangesFromContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.privateQueueManagedObjectContext];
    
}

-(void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
{
    [_managedObjectContext performBlock:^{
       
        [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        
    }];
}

@end

@implementation NSEntityDescription (Convert)

-(NSDictionary *)jsonObjectFromCoreDataValues:(NSDictionary *)values
                 usingResourceIDAttributeName:(NSString *)resourceIDAttributeName
{
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // convert values...
    
    for (NSString *attributeName in self.attributesByName) {
        
        for (NSString *key in values) {
            
            // found matching key (will only run once because dictionaries dont have duplicates)
            if ([key isEqualToString:attributeName]) {
                
                id value = [values valueForKey:key];
                
                id jsonValue = [self JSONCompatibleValueForAttributeValue:value
                                                             forAttribute:key];
                
                jsonObject[key] = jsonValue;
                
                break;
            }
        }
    }
    
    for (NSString *relationshipName in self.relationshipsByName) {
        
        NSRelationshipDescription *relationship = self.relationshipsByName[relationshipName];
        
        for (NSString *key in values) {
            
            // found matching key (will only run once because dictionaries dont have duplicates)
            if ([key isEqualToString:relationshipName]) {
                
                // to-one relationship
                if (!relationship.isToMany) {
                    
                    // get resource ID of object
                    
                    NSManagedObject *destinationResource = values[key];
                    
                    NSNumber *destinationResourceID = [destinationResource valueForKey:resourceIDAttributeName];
                    
                    jsonObject[key] = destinationResourceID;
                    
                }
                
                // to-many relationship
                else {
                    
                    NSSet *destinationResources = [values valueForKey:relationshipName];
                    
                    NSMutableArray *destinationResourceIDs = [[NSMutableArray alloc] init];
                    
                    for (NSManagedObject *destinationResource in destinationResources) {
                        
                        NSNumber *destinationResourceID = [destinationResource valueForKey:resourceIDAttributeName];
                        
                        [destinationResourceIDs addObject:destinationResourceID];
                    }
                    
                    jsonObject[key] = destinationResourceIDs;
                    
                }
                
                break;
            }
        }
    }
    
    return jsonObject;
}

@end

@implementation NOStore (CommonErrors)

-(NSError *)invalidServerResponseError
{
    
    NSString *description = NSLocalizedString(@"The server returned a invalid response",
                                              @"The server returned a invalid response");
    
    NSError *error = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                         code:NOErrorCodeInvalidServerResponse
                                     userInfo:@{NSLocalizedDescriptionKey: description}];
    
    return error;
}

-(NSError *)badRequestError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Invalid request",
                                                  @"Invalid request");
        
        error = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                    code:NOErrorCodeServerStatusCodeBadRequest
                                userInfo:@{NSLocalizedDescriptionKey: description}];
        
    }
    
    return error;
}

-(NSError *)serverError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"The server suffered an internal error",
                                                  @"The server suffered an internal error");
        
        error = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                    code:NOErrorCodeServerStatusCodeInternalServerError
                                userInfo:@{NSLocalizedDescriptionKey: description}];
        
    }
    
    return error;
}

-(NSError *)unauthorizedError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Authentication is required",
                                                  @"Authentication is required");
        
        error = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                    code:NOErrorCodeServerStatusCodeUnauthorized
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

-(NSError *)notFoundError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Resource was not found",
                                                  @"Resource was not found");
        
        error = [NSError errorWithDomain:(NSString *)NOErrorDomain
                                    code:NOErrorCodeServerStatusCodeNotFound
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

@end

@implementation NOStore (Cache)

-(NSManagedObjectID *)findEntity:(NSEntityDescription *)entity
                  withResourceID:(NSNumber *)resourceID
                         context:(NSManagedObjectContext *)context
{
    // look for resource in cache
    
    NSManagedObjectID *objectID;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    fetchRequest.resultType = NSManagedObjectIDResultType;
    
    fetchRequest.fetchLimit = 1;
    
    // create predicate
    fetchRequest.predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:_resourceIDAttributeName]
                                                                rightExpression:[NSExpression expressionForConstantValue:resourceID]
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSEqualToPredicateOperatorType
                                                                        options:NSNormalizedPredicateOption];
    
    NSError *error;
    
    NSArray *results = [context executeFetchRequest:fetchRequest
                                              error:&error];
    
    if (error) {
        
        [NSException raise:@"Error executing NSFetchRequest"
                    format:@"%@", error.localizedDescription];
        
        return nil;
    }
    
    objectID = results.firstObject;
    
    return objectID;
}

-(NSManagedObject *)findOrCreateEntity:(NSEntityDescription *)entity
                        withResourceID:(NSNumber *)resourceID
                               context:(NSManagedObjectContext *)context
{
    // get cached resource...
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    fetchRequest.fetchLimit = 1;
    
    // create predicate
    
    fetchRequest.predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:_resourceIDAttributeName]
                                                                rightExpression:[NSExpression expressionForConstantValue:resourceID]
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSEqualToPredicateOperatorType
                                                                        options:NSNormalizedPredicateOption];
    
    fetchRequest.returnsObjectsAsFaults = NO;
    
    // fetch
    
    NSManagedObject *resource;
    
    NSError *error;
    
    NSArray *results = [context executeFetchRequest:fetchRequest
                                              error:&error];
    
    if (error) {
        
        [NSException raise:@"Error executing NSFetchRequest"
                    format:@"%@", error.localizedDescription];
        
        return nil;
    }
    
    resource = results.firstObject;
    
    // create cached resource if not found
    
    if (!resource) {
        
        // create new entity
        
        resource = [NSEntityDescription insertNewObjectForEntityForName:entity.name
                                                 inManagedObjectContext:context];
        
        // set resource ID
        
        [resource setValue:resourceID
                    forKey:_resourceIDAttributeName];
        
    }
    
    return resource;
}

-(NSManagedObject *)setJSONObject:(NSDictionary *)resourceDict
                 forManagedObject:(NSManagedObject *)resource
{
    // set values...
    
    NSEntityDescription *entity = resource.entity;
    
    [self.privateQueueManagedObjectContext performBlockAndWait:^{
        
        for (NSString *attributeName in entity.attributesByName) {
            
            for (NSString *key in resourceDict) {
                
                // found matching key (will only run once because dictionaries dont have duplicates)
                if ([key isEqualToString:attributeName]) {
                    
                    id jsonValue = [resourceDict valueForKey:key];
                    
                    id newValue = [resource attributeValueForJSONCompatibleValue:jsonValue
                                                                    forAttribute:attributeName];
                    
                    id value = [resource valueForKey:key];
                    
                    NSAttributeDescription *attribute = entity.attributesByName[attributeName];
                    
                    // check if new values are different from current values...
                    
                    BOOL isNewValue = YES;
                    
                    // if both are nil
                    if (!value && !newValue) {
                        
                        isNewValue = NO;
                    }
                    
                    else {
                        
                        if (attribute.attributeType == NSStringAttributeType) {
                            
                            if ([value isEqualToString:newValue]) {
                                
                                isNewValue = NO;
                            }
                        }
                        
                        if (attribute.attributeType == NSDecimalAttributeType ||
                            attribute.attributeType == NSInteger16AttributeType ||
                            attribute.attributeType == NSInteger32AttributeType ||
                            attribute.attributeType == NSInteger64AttributeType ||
                            attribute.attributeType == NSDoubleAttributeType ||
                            attribute.attributeType == NSBooleanAttributeType ||
                            attribute.attributeType == NSFloatAttributeType) {
                            
                            if ([value isEqualToNumber:newValue]) {
                                
                                isNewValue = NO;
                            }
                        }
                        
                        if (attribute.attributeType == NSDateAttributeType) {
                            
                            if ([value isEqualToDate:newValue]) {
                                
                                isNewValue = NO;
                            }
                        }
                        
                        if (attribute.attributeType == NSBinaryDataAttributeType) {
                            
                            if ([value isEqualToData:newValue]) {
                                
                                isNewValue = NO;
                            }
                        }
                    }
                    
                    // only set newValue if its different from the current value
                    
                    if (isNewValue) {
                        
                        [resource setValue:newValue
                                    forKey:attributeName];
                    }
                    
                    break;
                }
            }
        }
        
        for (NSString *relationshipName in entity.relationshipsByName) {
            
            NSRelationshipDescription *relationship = entity.relationshipsByName[relationshipName];
            
            for (NSString *key in resourceDict) {
                
                // found matching key (will only run once because dictionaries dont have duplicates)
                if ([key isEqualToString:relationshipName]) {
                    
                    // destination entity
                    NSEntityDescription *destinationEntity = relationship.destinationEntity;
                    
                    // to-one relationship
                    if (!relationship.isToMany) {
                        
                        // get the resource ID
                        NSNumber *destinationResourceID = [resourceDict valueForKey:relationshipName];
                        
                        NSManagedObject *destinationResource = [self findOrCreateEntity:destinationEntity
                                                                         withResourceID:destinationResourceID
                                                                                context:resource.managedObjectContext];
                        
                        // dont set value if its the same as current value
                        
                        if (destinationResource != [resource valueForKey:relationshipName]) {
                            
                            [resource setValue:destinationResource
                                        forKey:key];
                        }
                    }
                    
                    // to-many relationship
                    else {
                        
                        // get the resourceIDs
                        NSArray *destinationResourceIDs = [resourceDict valueForKey:relationshipName];
                        
                        NSSet *currentValues = [resource valueForKey:relationshipName];
                        
                        NSMutableSet *destinationResources = [[NSMutableSet alloc] init];
                        
                        for (NSNumber *destinationResourceID in destinationResourceIDs) {
                            
                            NSManagedObject *destinationResource = [self findOrCreateEntity:destinationEntity withResourceID:destinationResourceID context:resource.managedObjectContext];
                            
                            [destinationResources addObject:destinationResource];
                        }
                        
                        // set new relationships if they are different from current values
                        if (![currentValues isEqualToSet:destinationResources]) {
                            
                            [resource setValue:destinationResources
                                        forKey:key];
                        }
                        
                    }
                    
                    break;
                    
                }
            }
        }
        
    }];
    
    return resource;
}

@end
