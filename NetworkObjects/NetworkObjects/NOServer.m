//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOServer.h"
#import "NOHTTPServer.h"
#import "NOHTTPConnection.h"
#import "NSManagedObject+CoreDataJSONCompatibility.h"

@interface NOServer (Internal)

@property (nonatomic, readonly) NSJSONWritingOptions jsonWritingOption;

-(void)setupHTTPServer;

-(NSManagedObject *)fetchEntity:(NSEntityDescription *)entity
                 withResourceID:(NSNumber *)resourceID
                   usingContext:(NSManagedObjectContext *)context
                 shouldPrefetch:(BOOL)shouldPrefetch
                          error:(NSError **)error;

-(NSArray *)fetchEntity:(NSEntityDescription *)entity
        withResourceIDs:(NSArray *)resourceIDs
           usingContext:(NSManagedObjectContext *)context
         shouldPrefetch:(BOOL)shouldPrefetch
                  error:(NSError **)error;

@end

@implementation NOServer

#pragma mark - Initializer

-(instancetype)initWithDataSource:(id<NOServerDataSource>)dataSource
                         delegate:(id<NOServerDelegate>)delegate
               managedObjectModel:(NSManagedObjectModel *)managedObjectModel
                       searchPath:(NSString *)searchPath
          resourceIDAttributeName:(NSString *)resourceIDAttributeName
                  prettyPrintJSON:(BOOL)prettyPrintJSON
       sslIdentityAndCertificates:(NSArray *)sslIdentityAndCertificates
{
    self = [super init];
    
    if (self) {
        
        if (!dataSource || !managedObjectModel || !resourceIDAttributeName) {
            
            return nil;
        }
        
        _dataSource = dataSource;
        
        _delegate = delegate;
        
        _managedObjectModel = managedObjectModel;
        
        _searchPath = searchPath;
        
        _resourceIDAttributeName = resourceIDAttributeName;
        
        _prettyPrintJSON = prettyPrintJSON;
        
        _sslIdentityAndCertificates = sslIdentityAndCertificates;
        
        [self setupHTTPServer];
    }
    
    return self;
}

#pragma mark - Server Control

-(BOOL)startOnPort:(NSUInteger)port
             error:(NSError *__autoreleasing *)error
{
    NSError *startServerError;
    
    BOOL success = [_httpServer start:&startServerError];
    
    if (*error) {
        
        *error = startServerError;
    }
    
    return success;
}

-(void)stop
{
    [_httpServer stop];
}


#pragma mark - Internal Methods

-(NSDictionary *)resourcePaths
{
    if (!_resourcePaths) {
        
        NSMutableDictionary *resourcePaths = [[NSMutableDictionary alloc] init];
        
        for (NSEntityDescription *entity in _managedObjectModel) {
            
            if (!entity.isAbstract) {
                
                NSString *path = [self.dataSource server:self
                                   resourcePathForEntity:entity];
                
                resourcePaths[path] = entity;
            }
        }
        
        _resourcePaths = [NSDictionary dictionaryWithDictionary:resourcePaths];
    }
    
    return _resourcePaths;
}

-(void)handleSearchRequest:(RouteRequest *)request forEntity:(NSEntityDescription *)entity response:(RouteResponse *)response
{
    NSDictionary *userInfo;
    
    // get search parameters
    
    NSError *jsonError;
    
    NSDictionary *searchParameters = [NSJSONSerialization JSONObjectWithData:request.body options:NSJSONReadingAllowFragments error:&jsonError];
    
    if (jsonError || ![searchParameters isKindOfClass:[NSDictionary class]]) {
        
        response.statusCode = NOServerStatusCodeBadRequest;
        
        return;
    }
    
    // get the context this request will use
    
    NSManagedObjectContext *context = [_dataSource server:self managedObjectContextForRequest:request withType:NOServerRequestTypeSearch];
    
    // Put togeather fetch request
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    NSSortDescriptor *defaultSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:_resourceIDAttributeName
                                                                            ascending:YES];
    
    fetchRequest.sortDescriptors = @[defaultSortDescriptor];
    
    // add search parameters...
    
    // predicate...
    
    NSString *predicateKey = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateKeyParameter]];
    
    id jsonPredicateValue = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateValueParameter]];
    
    NSNumber *predicateOperator = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateOperatorParameter]];
    
    if ([predicateKey isKindOfClass:[NSString class]] &&
        [predicateOperator isKindOfClass:[NSNumber class]] &&
        jsonPredicateValue) {
        
        // validate comparator
        
        if (predicateOperator.integerValue == NSCustomSelectorPredicateOperatorType) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        // convert to Core Data value...
        
        id value;
        
        // one of these will be nil
        
        NSRelationshipDescription *relationshipDescription = entity.relationshipsByName[predicateKey];
        
        NSAttributeDescription *attributeDescription = entity.attributesByName[predicateKey];
        
        // validate that key is attribute or relationship
        if (!relationshipDescription && !attributeDescription) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        // attribute value
        
        if (attributeDescription) {
            
            value = [entity attributeValueForJSONCompatibleValue:jsonPredicateValue
                                                    forAttribute:predicateKey];
        }
        
        // relationship value
        
        if (relationshipDescription) {
            
            // to-one
            
            if (!relationshipDescription.isToMany) {
                
                // verify
                if (![jsonPredicateValue isKindOfClass:[NSNumber class]]) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                NSNumber *resourceID = jsonPredicateValue;
                
                NSError *error;
                
                NSManagedObject *fetchedResource = [self fetchEntity:entity
                                                      withResourceID:resourceID
                                                        usingContext:context
                                                      shouldPrefetch:NO
                                                               error:&error];
                
                if (error) {
                    
                    if (_delegate) {
                        
                        [_delegate server:self didEncounterInternalError:error forRequest:request withType:NOServerRequestTypeSearch entity:entity userInfo:userInfo];
                    }
                    
                    response.statusCode = NOServerStatusCodeInternalServerError;
                    
                    return;
                }
                
                if (!fetchedResource) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
            }
            
            // to-many
            
            else {
                
                // verify
                
                if (![jsonPredicateValue isKindOfClass:[NSArray class]]) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                for (NSNumber *resourceID in jsonPredicateValue) {
                    
                    if (![resourceID isKindOfClass:[NSNumber class]]) {
                        
                        response.statusCode = NOServerStatusCodeBadRequest;
                        
                        return;
                    }
                }
                
                NSError *error;
                
                NSArray *fetchResult = [self fetchEntity:entity
                                         withResourceIDs:jsonPredicateValue
                                            usingContext:context
                                          shouldPrefetch:NO
                                                   error:&error];
                
                if (error) {
                    
                    if (_delegate) {
                        
                        [_delegate server:self didEncounterInternalError:error forRequest:request withType:NOServerRequestTypeSearch entity:entity userInfo:userInfo];
                    }
                    
                    response.statusCode = NOServerStatusCodeInternalServerError;
                    
                    return;
                }
                
                if (fetchResult.count != [jsonPredicateValue count]) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                value = fetchResult;
            }
        }
        
        // create predicate
        
        NSExpression *leftExp = [NSExpression expressionForKeyPath:predicateKey];
        
        NSExpression *rightExp = [NSExpression expressionForConstantValue:value];
        
        NSPredicateOperatorType operator = predicateOperator.integerValue;
        
        // add optional parameters...
        
        NSNumber *optionNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateOptionParameter]];
        
        NSComparisonPredicateOptions options;
        
        if ([optionNumber isKindOfClass:[NSNumber class]]) {
            
            options = optionNumber.integerValue;
            
        }
        else {
            
            options = NSNormalizedPredicateOption;
        }
        
        NSNumber *modifierNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchPredicateModifierParameter]];
        
        NSComparisonPredicateModifier modifier;
        
        if ([modifierNumber isKindOfClass:[NSNumber class]]) {
            
            modifier = modifierNumber.integerValue;
        }
        
        else {
            
            modifier = NSDirectPredicateModifier;
        }
        
        NSComparisonPredicate *predicate = [[NSComparisonPredicate alloc] initWithLeftExpression:leftExp
                                                                                 rightExpression:rightExp
                                                                                        modifier:modifier
                                                                                            type:operator
                                                                                         options:options];
        
        if (!predicate) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        fetchRequest.predicate = predicate;
        
    }
    
    // sort descriptors
    
    NSArray *sortDescriptorsJSONArray = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchSortDescriptorsParameter]];
    
    NSMutableArray *sortDescriptors;
    
    if (sortDescriptorsJSONArray) {
        
        if (![sortDescriptorsJSONArray isKindOfClass:[NSArray class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        if (!sortDescriptorsJSONArray.count) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        sortDescriptors = [[NSMutableArray alloc] init];
        
        for (NSDictionary *sortDescriptorJSON in sortDescriptorsJSONArray) {
            
            // validate JSON
            
            if (![sortDescriptorJSON isKindOfClass:[NSDictionary class]]) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return;
            }
            
            if (sortDescriptorJSON.allKeys.count != 1) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return;
            }
            
            NSString *key = sortDescriptorJSON.allKeys.firstObject;
            
            NSNumber *ascending = sortDescriptorJSON.allValues.firstObject;
            
            // more validation
            
            if (![key isKindOfClass:[NSString class]] ||
                ![ascending isKindOfClass:[NSNumber class]]) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return;
            }
            
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:key
                                                                   ascending:ascending.boolValue];
            
            [sortDescriptors addObject:sort];
            
        }
        
        fetchRequest.sortDescriptors = sortDescriptors;
        
    }
    
    // fetch limit
    
    NSNumber *fetchLimitNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchFetchLimitParameter]];
    
    if (fetchLimitNumber) {
        
        if (![fetchLimitNumber isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        fetchRequest.fetchLimit = fetchLimitNumber.integerValue;
    }
    
    // fetch offset
    
    NSNumber *fetchOffsetNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchFetchOffsetParameter]];
    
    if (fetchOffsetNumber) {
        
        if (![fetchOffsetNumber isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        
        fetchRequest.fetchOffset = fetchOffsetNumber.integerValue;
    }
    
    NSNumber *includeSubEntitites = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchIncludesSubentitiesParameter]];
    
    if (includeSubEntitites) {
        
        if (![includeSubEntitites isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return;
        }
        
        fetchRequest.includesSubentities = includeSubEntitites.boolValue;
    }
    
    // check for permission
    
    if (self.delegate) {
        
        NOServerStatusCode statusCode = [_delegate server:self statusCodeForRequest:request withType:NOServerRequestTypeSearch entity:entity userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return;
        }
    }
    
    // execute fetch request...
    
    // prefetch resourceID
    
    fetchRequest.returnsObjectsAsFaults = NO;
    
    fetchRequest.includesPropertyValues = YES;
    
    // execute fetch request...
    
    __block NSError *fetchError;
    
    __block NSArray *result;
    
    [context performBlockAndWait:^{
        
        result = [context executeFetchRequest:fetchRequest
                                        error:&fetchError];
        
    }];
    
    // invalid fetch
    
    if (fetchError) {
        
        response.statusCode = NOServerStatusCodeBadRequest;
        
        return;
    }
    
    // return the resource IDs of filtered objects
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result
                                                       options:self.jsonWritingOption
                                                         error:&error];
    
    if (!jsonData) {
        
        if (_delegate) {
            
            [_delegate server:self didEncounterInternalError:error forRequest:request withType:NOServerRequestTypeSearch entity:entity userInfo:userInfo];
        }
        
        response.statusCode = NOServerStatusCodeInternalServerError;
        
        return;
    }
    
    [response respondWithData:jsonData];
    
    // tell delegate
    
    if (_delegate) {
        
        [_delegate server:self didPerformRequest:request withType:NOServerRequestTypeSearch userInfo:userInfo];
    }
}

@end

@implementation NOServer (Internal)

-(void)setupHTTPServer
{
    _httpServer = [[NOHTTPServer alloc] init];
    
    _httpServer.connectionClass = [NOHTTPConnection class];
    
    _httpServer.server = self;
    
    // setup routes
    
    for (NSString *path in self.resourcePaths) {
        
        NSEntityDescription *entity = self.resourcePaths[path];
        
        // add search handler
        
        if (self.searchPath) {
            
            NSString *searchPathExpression = [NSString stringWithFormat:@"/%@/%@", _searchPath, path];
            
            void (^searchRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
                
                [self handleSearchRequest:request forEntity:entity response:response];
            };
            
            [_httpServer post:searchPathExpression
                    withBlock:searchRequestHandler];
        }
        
        // setup routes for resources...
        
        NSString *allInstancesPathExpression = [NSString stringWithFormat:@"/%@", path];
        
        void (^allInstancesRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            [self handleCreateNewInstanceRequest:request forEntity:entity response:response];
        };
        
        // POST (create new resource)
        [_httpServer post:allInstancesPathExpression
                withBlock:allInstancesRequestHandler];
        
        // setup routes for resource instances
        
        NSString *instancePathExpression = [NSString stringWithFormat:@"{^/%@/(\\d+)}", path];
        
        void (^instanceRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
            
            NSArray *captures = request.params[@"captures"];
            
            NSString *capturedResourceID = captures[0];
            
            NSNumber *resourceID = [NSNumber numberWithInteger:capturedResourceID.integerValue];
            
            if ([request.method isEqualToString:@"GET"]) {
                
                [self handleGetInstanceRequest:request forEntity:entity resourceID:resourceID response:response];
            }
            
            if ([request.method isEqualToString:@"PUT"]) {
                
                [self handleEditInstanceRequest:request forEntity:entity resourceID:resourceID response:response];
            }
            
            if ([request.method isEqualToString:@"DELETE"]) {
                
                [self handleDeleteInstanceRequest:request forEntity:entity resourceID:resourceID response:response];
            }
        };
        
        // GET (read resource)
        [_httpServer get:instancePathExpression
               withBlock:instanceRequestHandler];
        
        // PUT (edit resource)
        [_httpServer put:instancePathExpression
               withBlock:instanceRequestHandler];
        
        // DELETE (delete resource)
        [_httpServer delete:instancePathExpression
                  withBlock:instanceRequestHandler];
        
        // add function routes
        
        NSSet *functions = [self.dataSource server:self functionsForEntity:entity];
        
        for (NSString *functionName in functions) {
            
            NSString *functionExpression = [NSString stringWithFormat:@"{^/%@/(\\d+)/%@}", path, functionName];
            
            void (^instanceFunctionRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
                
                NSArray *captures = request.params[@"captures"];
                
                NSString *capturedResourceID = captures[0];
                
                NSNumber *resourceID = @(capturedResourceID.integerValue);
                
                [self handleFunctionInstanceRequest:request
                                          forEntity:entity
                                         resourceID:resourceID
                                       functionName:functionName
                                           response:response];
            };
            
            // functions use POST
            [_httpServer post:functionExpression
                    withBlock:instanceFunctionRequestHandler];
            
        }
    }
    
}

-(NSJSONWritingOptions)jsonWritingOption
{
    if (_prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}
    
-(NSManagedObject *)fetchEntity:(NSEntityDescription *)entity
                 withResourceID:(NSNumber *)resourceID
                   usingContext:(NSManagedObjectContext *)context
                 shouldPrefetch:(BOOL)shouldPrefetch
                          error:(NSError **)error
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    fetchRequest.fetchLimit = 1;
    
    fetchRequest.predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:_resourceIDAttributeName]
                                                                rightExpression:[NSExpression expressionForConstantValue:resourceID]
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSEqualToPredicateOperatorType
                                                                        options:NSNormalizedPredicateOption];
    
    if (shouldPrefetch) {
        
        fetchRequest.returnsObjectsAsFaults = NO;
    }
    else {
        
        fetchRequest.includesPropertyValues = NO;
    }
    
    __block NSArray *result;
    
    [context performBlockAndWait:^{
        
        result = [context executeFetchRequest:fetchRequest
                                        error:error];
        
    }];
    
    if (!result) {
        
        return nil;
    }
    
    NSManagedObject *resource = result.firstObject;
    
    return resource;
}

-(NSArray *)fetchEntity:(NSEntityDescription *)entity
        withResourceIDs:(NSArray *)resourceIDs
           usingContext:(NSManagedObjectContext *)context
         shouldPrefetch:(BOOL)shouldPrefetch
                  error:(NSError **)error
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    fetchRequest.fetchLimit = resourceIDs.count;
    
    fetchRequest.predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:_resourceIDAttributeName]
                                                                rightExpression:[NSExpression expressionForConstantValue:resourceIDs]
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSInPredicateOperatorType
                                                                        options:NSNormalizedPredicateOption];
    
    if (shouldPrefetch) {
        
        fetchRequest.returnsObjectsAsFaults = NO;
    }
    else {
        
        fetchRequest.includesPropertyValues = NO;
    }
    
    __block NSArray *result;
    
    [context performBlockAndWait:^{
        
        result = [context executeFetchRequest:fetchRequest
                                        error:error];
        
    }];
    
    return result;
}

@end
