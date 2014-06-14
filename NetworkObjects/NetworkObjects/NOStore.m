//
//  NOStore.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/13/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOStore.h"
#import "NetworkObjectsConstants.h"

@interface NOStore (Cache)

// call these inside -performWithBlock:

-(NSManagedObjectID *)findEntityWithName:(NSString *)entityName
                          withResourceID:(NSNumber *)resourceID
                                 context:(NSManagedObjectContext *)context;

// Must save context after calling these

-(NSManagedObject *)findOrCreateEntityWithName:(NSString *)entityName
                                withResourceID:(NSNumber *)resourceID
                                       context:(NSManagedObjectContext *)context;

-(NSManagedObject *)setJSONObject:(NSDictionary *)jsonObject
                 forManagedObject:(NSManagedObject *)managedObject;

@end

@interface NSEntityDescription (Convert)

-(NSDictionary *)jsonObjectFromCoreDataValues:(NSDictionary *)values;

@end

@interface NOStore (DateCached)

-(void)setupDateCachedAttributeWithAttributeName:(NSString *)dateCachedAttributeName;

-(void)didCacheManagedObject:(NSManagedObject *)managedObject;

@end

@interface NOStore (ManagedObjectContexts)

-(void)setupManagedObjectContextsWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc;

-(void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification;

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

-(NSURLSessionDataTask *)searchForResource:(NSString *)resourceName
                            withParameters:(NSDictionary *)parameters
                                URLSession:(NSURLSession *)urlSession
                                completion:(void (^)(NSError *error, NSArray *results))completionBlock;

-(NSURLSessionDataTask *)getResource:(NSString *)resourceName
                              withID:(NSUInteger)resourceID
                          URLSession:(NSURLSession *)urlSession
                          completion:(void (^)(NSError *error, NSDictionary *resource))completionBlock;

-(NSURLSessionDataTask *)editResource:(NSString *)resourceName
                               withID:(NSUInteger)resourceID
                              changes:(NSDictionary *)changes
                           URLSession:(NSURLSession *)urlSession
                           completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)deleteResource:(NSString *)resourceName
                                 withID:(NSUInteger)resourceID
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *error))completionBlock;

-(NSURLSessionDataTask *)createResource:(NSString *)resourceName
                      withInitialValues:(NSDictionary *)initialValues
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *error, NSNumber *resourceID))completionBlock;

-(NSURLSessionDataTask *)performFunction:(NSString *)functionName
                              onResource:(NSString *)resourceName
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

@property (nonatomic) NSDictionary *resourcePaths;

@property (nonatomic) NSManagedObjectModel *model;

@end

@implementation NOStore

#pragma mark - Initialization

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc
                                         serverURL:(NSURL *)serverURL
                                     resourcePaths:(NSDictionary *)resourcePaths
                                   prettyPrintJSON:(BOOL)prettyPrintJSON
                           resourceIDAttributeName:(NSString *)resourceIDAttributeName
                           dateCachedAttributeName:(NSString *)dateCachedAttributeName
{
    self = [super init];
    
    if (self) {
        
        [self setupManagedObjectContextsWithPersistentStoreCoordinator:psc];
        
        self.serverURL = serverURL;
        
        self.resourcePaths = resourcePaths;
        
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
        
        id jsonValue = [fetchRequest.entity jsonObjectFromCoreDataValues:@{predicate.leftExpression.keyPath: predicate.rightExpression.constantValue}].allValues.firstObject;
        
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
    
    return [self searchForResource:entity.name withParameters:jsonObject URLSession:urlSession completion:^(NSError *error, NSArray *results) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // get results as cached resources
        
        NSMutableArray *cachedResults = [[NSMutableArray alloc] init];
        
        [self.context performBlockAndWait:^{
            
            for (NSNumber *resourceID in results) {
                
                NSManagedObject *resource = [self findOrCreateResource:entity.name
                                                        withResourceID:resourceID
                                                               context:self.context];
                
                [cachedResults addObject:resource];
            }
            
            // save
            
            NSError *saveError;
            
            if (![self.context save:&saveError]) {
                
                [NSException raise:NSInternalInconsistencyException
                            format:@"%@", saveError.localizedDescription];
            }
            
        }];
        
        completionBlock(nil, cachedResults);
        
    }];
}

@end

@implementation NOStore (DateCached)

-(void)setupDateCachedAttributeWithAttributeName:(NSString *)dateCachedAttributeName
{
    // add a date attribute to
    for (NSString *entityName in self.model.entitiesByName) {
        
        NSEntityDescription *entity = self.model.entitiesByName[entityName];
        
        if (!entity.isAbstract || !entity.superentity) {
            
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

@implementation NOStore (API)

-(NSURLSessionDataTask *)searchForResource:(NSString *)resourceName
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
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *searchURL = [self.serverURL URLByAppendingPathComponent:self.searchPath];
    
    searchURL = [searchURL URLByAppendingPathComponent:resourcePath];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:searchURL];
    
    urlRequest.HTTPMethod = @"POST";
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [urlRequest addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
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
        
        if (httpResponse.statusCode != NOServerOKStatusCode) {
            
            if (httpResponse.statusCode == NOServerUnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == NOServerForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to perform search is denied",
                                                               @"Permission to perform search is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerInternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerBadRequestStatusCode) {
                
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
        
        // verify that values are numbers
        
        for (NSNumber *resultResourceID in jsonResponse) {
            
            if (![resultResourceID isKindOfClass:[NSNumber class]]) {
                
                completionBlock(self.invalidServerResponseError, nil);
                
                return;
            }
        }
        
        completionBlock(nil, jsonResponse);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask *)getResource:(NSString *)resourceName
                              withID:(NSUInteger)resourceID
                          URLSession:(NSURLSession *)urlSession
                          completion:(void (^)(NSError *, NSDictionary *))completionBlock
{
    NOAPICheckForServerURL
    
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *getResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    getResourceURL = [getResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:getResourceURL];
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == NOServerUnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == NOServerForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Access to resource is denied",
                                                               @"Access to resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerInternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerBadRequestStatusCode) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerNotFoundStatusCode) {
                
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

-(NSURLSessionDataTask *)createResource:(NSString *)resourceName
                      withInitialValues:(NSDictionary *)initialValues
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *, NSNumber *))completionBlock
{
    NOAPICheckForServerURL
    
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL...
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
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
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error, nil);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == NOServerUnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == NOServerForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to create new resource is denied",
                                                               @"Permission to create new resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerInternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerBadRequestStatusCode) {
                
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
        
        NSEntityDescription *entity = _model.entitiesByName[resourceName];
        
        Class entityClass = NSClassFromString(entity.managedObjectClassName);
        
        NSString *resourceIDKey = [entityClass resourceIDKey];
        
        NSNumber *resourceID = jsonResponse[resourceIDKey];
        
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

-(NSURLSessionDataTask *)editResource:(NSString *)resourceName
                               withID:(NSUInteger)resourceID
                              changes:(NSDictionary *)changes
                           URLSession:(NSURLSession *)urlSession
                           completion:(void (^)(NSError *))completionBlock
{
    NOAPICheckForServerURL
    
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
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
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == NOServerUnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == NOServerForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to edit resource is denied",
                                                               @"Permission to edit resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerInternalServerErrorStatusCode) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerBadRequestStatusCode) {
                
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

-(NSURLSessionDataTask *)deleteResource:(NSString *)resourceName
                                 withID:(NSUInteger)resourceID
                             URLSession:(NSURLSession *)urlSession
                             completion:(void (^)(NSError *))completionBlock
{
    NOAPICheckForServerURL
    
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *deleteResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    deleteResourceURL = [deleteResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deleteResourceURL];
    
    request.HTTPMethod = @"DELETE";
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == NOServerNotFoundStatusCode) {
                
                completionBlock(self.notFoundError);
                return;
            }
            
            if (httpResponse.statusCode == NOServerUnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == NOServerForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to delete resource is denied",
                                                               @"Permission to delete resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerInternalServerErrorStatusCode) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == NOServerBadRequestStatusCode) {
                
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
                              onResource:(NSString *)resourceName
                                  withID:(NSUInteger)resourceID
                          withJSONObject:(NSDictionary *)jsonObject
                              URLSession:(NSURLSession *)urlSession
                              completion:(void (^)(NSError *, NSNumber *, NSDictionary *))completionBlock
{
    NOAPICheckForServerURL
    
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityClassWithResourceName:resourceName];
    
    NSString *resourcePath = [entityClass resourcePath];
    
    NSURL *deleteResourceURL = [self.serverURL URLByAppendingPathComponent:resourcePath];
    
    NSString *resourceIDString = [NSString stringWithFormat:@"%ld", (unsigned long)resourceID];
    
    deleteResourceURL = [deleteResourceURL URLByAppendingPathComponent:resourceIDString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:deleteResourceURL];
    
    request.HTTPMethod = @"POST";
    
    // add authentication header if availible
    
    if (self.sessionToken) {
        
        [request addValue:self.sessionToken forHTTPHeaderField:@"Authorization"];
    }
    
    // add HTTP body
    if (jsonObject) {
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:self.jsonWritingOption
                                                             error:nil];
        
        if (!jsonData) {
            
            [NSException raise:NSInvalidArgumentException
                        format:@"Invalid jsonObject NSDictionary argument. Not valid JSON."];
            
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

@implementation NOStore (ManagedObjectContexts)

-(void)setupManagedObjectContextsWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc
{
    // setup contexts
    
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    
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
                
                // destination entity
                NSEntityDescription *destinationEntity = relationship.destinationEntity;
                
                Class entityClass = NSClassFromString(destinationEntity.managedObjectClassName);
                
                NSString *destinationResourceIDKey = [entityClass resourceIDKey];
                
                // to-one relationship
                if (!relationship.isToMany) {
                    
                    // get resource ID of object
                    
                    NSManagedObject<NOResourceKeysProtocol> *destinationResource = values[key];
                    
                    NSNumber *destinationResourceID = [destinationResource valueForKey:destinationResourceIDKey];
                    
                    jsonObject[key] = destinationResourceID;
                    
                }
                
                // to-many relationship
                else {
                    
                    NSSet *destinationResources = [values valueForKey:relationshipName];
                    
                    NSMutableArray *destinationResourceIDs = [[NSMutableArray alloc] init];
                    
                    for (NSManagedObject *destinationResource in destinationResources) {
                        
                        NSNumber *destinationResourceID = [destinationResource valueForKey:destinationResourceIDKey];
                        
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
