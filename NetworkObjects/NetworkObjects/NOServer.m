//
//  NOServer.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 6/12/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "NOServer.h"
#import "NSManagedObject+CoreDataJSONCompatibility.h"

NSString const* NOServerFetchRequestKey = @"NOServerFetchRequestKey";

NSString const* NOServerResourceIDKey = @"NOServerResourceIDKey";

NSString const* NOServerManagedObjectKey = @"NOServerManagedObjectKey";

NSString const* NOServerManagedObjectContextKey = @"NOServerManagedObjectContextKey";

NSString const* NOServerNewValuesKey = @"NOServerNewValuesKey";

NSString const* NOServerFunctionNameKey = @"NOServerFunctionNameKey";

NSString const* NOServerFunctionJSONInputKey = @"NOServerFunctionJSONInputKey";

NSString const* NOServerFunctionJSONOutputKey = @"NOServerFunctionJSONOutputKey";

#pragma mark - Category and Externsions Declarations

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

-(NSDictionary *)JSONRepresentationOfManagedObject:(NSManagedObject *)managedObject;

-(NOServerStatusCode)verifyEditResource:(NSManagedObject *)resource
                             forRequest:(RouteRequest *)request
                            requestType:(NOServerRequestType)requestType
                     recievedJsonObject:(NSDictionary *)recievedJsonObject
                                context:(NSManagedObjectContext *)context
                                  error:(NSError **)error
                        convertedValues:(NSDictionary **)convertedValues;

@end

@interface NOServer (Permissions)

-(void)checkForDelegatePermissions;

-(NSDictionary *)filteredJSONRepresentationOfManagedObject:(NSManagedObject *)managedObject
                                                   context:(NSManagedObjectContext *)context
                                                   request:(RouteRequest *)request
                                               requestType:(NOServerRequestType)requestType;

@end

@interface NOServer ()

{
    BOOL _permissionsEnabled;
}


@end

#pragma mark - NOServer Implementation

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
        
        [self checkForDelegatePermissions];
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


#pragma mark - Caches

-(NSDictionary *)entitiesByResourcePath
{
    if (!_entitiesByResourcePath) {
        
        NSMutableDictionary *entitiesByResourcePath = [[NSMutableDictionary alloc] init];
        
        for (NSEntityDescription *entity in _managedObjectModel) {
            
            if (!entity.isAbstract) {
                
                NSString *path = [self.dataSource server:self
                                   resourcePathForEntity:entity];
                
                entitiesByResourcePath[path] = entity;
            }
        }
        
        _entitiesByResourcePath = [NSDictionary dictionaryWithDictionary:entitiesByResourcePath];
    }
    
    return _entitiesByResourcePath;
}

#pragma mark - Request Handlers

-(NOServerResponse *)responseForSearchRequest:(NOServerRequest *)request
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    
    NOServerResponse *response = [[NOServerResponse alloc] init];
    
    // get search parameters
    
    NSDictionary *searchParameters = request.jsonObject;
    
    NSEntityDescription *entity = request.entity;
    
    // get the context this request will use
    
    NSManagedObjectContext *context = [_dataSource server:self managedObjectContextForRequest:request];
    
    userInfo[NOServerManagedObjectContextKey] = context;
    
    // Put togeather fetch request
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
    
    NSSortDescriptor *defaultSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:_resourceIDAttributeName
                                                                            ascending:YES];
    
    fetchRequest.sortDescriptors = @[defaultSortDescriptor];
    
    // add search parameters...
    
    // predicate...
    
    NSString *predicateKey = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateKey]];
    
    id jsonPredicateValue = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateValue]];
    
    NSNumber *predicateOperator = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateOperator]];
    
    if ([predicateKey isKindOfClass:[NSString class]] &&
        [predicateOperator isKindOfClass:[NSNumber class]] &&
        jsonPredicateValue) {
        
        // validate comparator
        
        if (predicateOperator.integerValue == NSCustomSelectorPredicateOperatorType) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return response;
        }
        
        // convert to Core Data value...
        
        id value;
        
        // one of these will be nil
        
        NSRelationshipDescription *relationshipDescription = entity.relationshipsByName[predicateKey];
        
        NSAttributeDescription *attributeDescription = entity.attributesByName[predicateKey];
        
        // validate that key is attribute or relationship
        if (!relationshipDescription && !attributeDescription) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return response;
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
                    
                    return response;
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
                        
                        [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
                    }
                    
                    response.statusCode = NOServerStatusCodeInternalServerError;
                    
                    return response;
                }
                
                if (!fetchedResource) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return response;
                }
                
            }
            
            // to-many
            
            else {
                
                // verify
                
                if (![jsonPredicateValue isKindOfClass:[NSArray class]]) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return response;
                }
                
                for (NSNumber *resourceID in jsonPredicateValue) {
                    
                    if (![resourceID isKindOfClass:[NSNumber class]]) {
                        
                        response.statusCode = NOServerStatusCodeBadRequest;
                        
                        return response;
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
                        
                        [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
                    }
                    
                    response.statusCode = NOServerStatusCodeInternalServerError;
                    
                    return response;
                }
                
                if (fetchResult.count != [jsonPredicateValue count]) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return response;
                }
                
                value = fetchResult;
            }
        }
        
        // create predicate
        
        NSExpression *leftExp = [NSExpression expressionForKeyPath:predicateKey];
        
        NSExpression *rightExp = [NSExpression expressionForConstantValue:value];
        
        NSPredicateOperatorType operator = predicateOperator.integerValue;
        
        // add optional parameters...
        
        NSNumber *optionNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateOption]];
        
        NSComparisonPredicateOptions options;
        
        if ([optionNumber isKindOfClass:[NSNumber class]]) {
            
            options = optionNumber.integerValue;
            
        }
        else {
            
            options = NSNormalizedPredicateOption;
        }
        
        NSNumber *modifierNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterPredicateModifier]];
        
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
            
            return response;
        }
        
        fetchRequest.predicate = predicate;
        
    }
    
    // sort descriptors
    
    NSArray *sortDescriptorsJSONArray = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterSortDescriptors]];
    
    NSMutableArray *sortDescriptors;
    
    if (sortDescriptorsJSONArray) {
        
        if (![sortDescriptorsJSONArray isKindOfClass:[NSArray class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return response;
        }
        
        if (!sortDescriptorsJSONArray.count) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return response;
        }
        
        sortDescriptors = [[NSMutableArray alloc] init];
        
        for (NSDictionary *sortDescriptorJSON in sortDescriptorsJSONArray) {
            
            // validate JSON
            
            if (![sortDescriptorJSON isKindOfClass:[NSDictionary class]]) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return response;
            }
            
            if (sortDescriptorJSON.allKeys.count != 1) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return response;
            }
            
            NSString *key = sortDescriptorJSON.allKeys.firstObject;
            
            NSNumber *ascending = sortDescriptorJSON.allValues.firstObject;
            
            // more validation
            
            if (![key isKindOfClass:[NSString class]] ||
                ![ascending isKindOfClass:[NSNumber class]]) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return response;
            }
            
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:key
                                                                   ascending:ascending.boolValue];
            
            [sortDescriptors addObject:sort];
            
        }
        
        fetchRequest.sortDescriptors = sortDescriptors;
        
    }
    
    // fetch limit
    
    NSNumber *fetchLimitNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterFetchLimit]];
    
    if (fetchLimitNumber) {
        
        if (![fetchLimitNumber isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return response;
        }
        
        fetchRequest.fetchLimit = fetchLimitNumber.integerValue;
    }
    
    // fetch offset
    
    NSNumber *fetchOffsetNumber = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterFetchOffset]];
    
    if (fetchOffsetNumber) {
        
        if (![fetchOffsetNumber isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return response;
        }
        
        
        fetchRequest.fetchOffset = fetchOffsetNumber.integerValue;
    }
    
    NSNumber *includeSubEntitites = searchParameters[[NSString stringWithFormat:@"%lu", (unsigned long)NOSearchParameterIncludesSubentities]];
    
    if (includeSubEntitites) {
        
        if (![includeSubEntitites isKindOfClass:[NSNumber class]]) {
            
            response.statusCode = NOServerStatusCodeBadRequest;
            
            return response;
        }
        
        fetchRequest.includesSubentities = includeSubEntitites.boolValue;
    }
    
    // prefetch resourceID
    
    fetchRequest.returnsObjectsAsFaults = NO;
    
    fetchRequest.includesPropertyValues = YES;
    
    // check for permission
    
    userInfo[NOServerFetchRequestKey] = fetchRequest;
    
    if (self.delegate) {
        
        NOServerStatusCode statusCode = [_delegate server:self statusCodeForRequest:request userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return response;
        }
    }
    
    // execute fetch request...
    
    // execute fetch request...
    
    __block NSError *fetchError;
    
    __block NSArray *results;
    
    [context performBlockAndWait:^{
        
        results = [context executeFetchRequest:fetchRequest
                                        error:&fetchError];
        
    }];
    
    // invalid fetch
    
    if (fetchError) {
        
        response.statusCode = NOServerStatusCodeBadRequest;
        
        return response;
    }
    
    // optionally filter results
    
    if (_permissionsEnabled) {
        
        NSMutableArray *filteredResults = [[NSMutableArray alloc] init];
        
        for (NSManagedObject *managedObject in results) {
            
            __block NSNumber *resourceID;
            
            [context performBlockAndWait:^{
                
                resourceID = [managedObject valueForKey:_resourceIDAttributeName];
                
            }];
            
            // permission to view resource
            
            if ([_delegate server:self permissionForRequest:request managedObject:managedObject context:context key:nil] >= NOServerPermissionReadOnly) {
                
                // must have permission for keys accessed
                
                if (predicateKey) {
                    
                    if ([_delegate server:self permissionForRequest:request managedObject:managedObject context:context key:predicateKey] < NOServerPermissionReadOnly) {
                        
                        break;
                    }
                    
                }
                
                // must have read only permission for keys in sort descriptor
                
                if (sortDescriptors) {
                    
                    for (NSSortDescriptor *sort in sortDescriptors) {
                        
                        if ([_delegate server:self permissionForRequest:request managedObject:managedObject context:context key:sort.key] >= NOServerPermissionReadOnly) {
                            
                            [filteredResults addObject:managedObject];
                        }
                    }
                }
                
                else {
                    
                    [filteredResults addObject:managedObject];
                }
            }
        }
        
        results = [NSArray arrayWithArray:filteredResults];
    }
    
    // return the resource IDs of objects mapped to their resource path
    
    NSMutableArray *jsonResponse = [[NSMutableArray alloc] init];
    
    [context performBlockAndWait:^{
        
        for (NSManagedObject *managedObject in results) {
            
            // get the resourcePath for the entity
            
            NSString *resourcePath = [self.entitiesByResourcePath allKeysForObject:managedObject.entity].firstObject;
            
            NSNumber *resourceID = [managedObject valueForKey:_resourceIDAttributeName];
            
            [jsonResponse addObject:@{[NSString stringWithFormat:@"%@", resourceID] : resourcePath}];
        }
        
    }];
    
    response.JSONResponse = jsonResponse;
    
    return response;
}

-(NOServerResponse *)responseForCreateNewInstanceRequest:(NOServerRequest *)request
{
    NOServerResponse *response = [[NOServerResponse alloc] init];
    
    NSEntityDescription *entity = request.entity;
    
    NSDictionary *jsonObject = request.JSONDictionary;
    
    // get context
    
    NSManagedObjectContext *context = [_dataSource server:self managedObjectContextForRequest:request];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{NOServerManagedObjectContextKey : context}];
    
    // ask delegate
    
    if (_delegate) {
        
        NOServerStatusCode statusCode = [_delegate server:self statusCodeForRequest:request userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return response;
        }
    }
    
    // check for permissions
    
    if (_permissionsEnabled) {
        
        if ([_delegate server:self permissionForRequest:request managedObject:nil context:context key:nil] < NOServerPermissionEditPermission) {
            
            response.statusCode = NOServerStatusCodeForbidden;
            
            return response;
        };
    }
    
    // create new instance
    
    NSNumber *resourceID = [_dataSource server:self newResourceIDForEntity:entity];
    
    __block NSManagedObject *managedObject;
    
    [context performBlockAndWait:^{
       
        managedObject = [NSEntityDescription insertNewObjectForEntityForName:entity.name
                                                      inManagedObjectContext:context];
        
        // set resourceID
        
        [managedObject setValue:resourceID
                         forKey:_resourceIDAttributeName];
        
    }];
    
    if (jsonObject) {
        
        // convert to core data values
        
        __block NOServerStatusCode editStatusCode;
        
        __block NSDictionary *newValues;
        
        __block NSError *error;
        
        [context performBlockAndWait:^{
            
            editStatusCode = [self verifyEditResource:managedObject
                                           forRequest:request
                                          requestType:NOServerRequestTypePOST
                                   recievedJsonObject:jsonObject
                                              context:context
                                                error:&error
                                      convertedValues:&newValues];
        }];
        
        if (editStatusCode != NOServerStatusCodeOK) {
            
            if (editStatusCode == NOServerStatusCodeInternalServerError) {
                
                if (_delegate) {
                    
                    [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
                }
            }
            
            response.statusCode = editStatusCode;
            
            return response;
        }
        
        userInfo[NOServerNewValuesKey] = newValues;
        
        // set new values from dictionary
        
        [context performBlockAndWait:^{
            
            [managedObject setValuesForKeysWithDictionary:newValues];
            
        }];
        
    }
    
    // respond
    
    NSDictionary *jsonResponse = @{_resourceIDAttributeName: resourceID};
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonResponse
                                                       options:self.jsonWritingOption
                                                         error:&error];
    
    if (!jsonData) {
        
        if (_delegate) {
            
            [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
        }
        
        response.statusCode = NOServerStatusCodeInternalServerError;
        
        return response;
    }
    
    return response;
}

-(NOServerResponse *)responseForGetInstanceRequest:(NOServerRequest *)request
{
    NSNumber *resourceID = request.resourceID;
    
    NSEntityDescription *entity = request.entity;
    
    // create response
    
    NOServerResponse *response = [[NOServerResponse alloc] init];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{NOServerResourceIDKey : resourceID}];
    
    // get context
    
    NSManagedObjectContext *context = [_dataSource server:self managedObjectContextForRequest:request];
    
    userInfo[NOServerManagedObjectContextKey] = context;
    
    // fetch managedObject
    
    NSError *error;
    
    NSManagedObject *managedObject = [self fetchEntity:entity
                                        withResourceID:resourceID
                                          usingContext:context
                                        shouldPrefetch:YES
                                                 error:&error];
    
    // internal error
    
    if (error) {
        
        if (_delegate) {
            
            [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
        }
        
        response.statusCode = NOServerStatusCodeInternalServerError;
        
        return response;
    }
    
    // object doesnt exist
    
    if (!managedObject && !error) {
        
        response.statusCode = NOServerStatusCodeNotFound;
        
        return response;
    }
    
    // add managedObject to userInfo
    
    userInfo[NOServerManagedObjectKey] = managedObject;
    
    // ask delegate
    
    if (_delegate) {
        
        NOServerStatusCode statusCode = [_delegate server:self statusCodeForRequest:request userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return response;
        }
    }
    
    // check for permissions
    
    if (_permissionsEnabled) {
        
        if ([_delegate server:self permissionForRequest:request managedObject:managedObject context:context key:nil] < NOServerPermissionReadOnly) {
            
            response.statusCode = NOServerStatusCodeForbidden;
            
            return response;
        };
    }
    
    // build json object
    __block NSDictionary *jsonObject;
    
    [context performBlockAndWait:^{
        
        if (_permissionsEnabled) {
            
            jsonObject = [self filteredJSONRepresentationOfManagedObject:managedObject
                                                                 context:context
                                                                 request:request
                                                             requestType:NOServerRequestTypeGET];
        }
        
        else {
            
            jsonObject = [self JSONRepresentationOfManagedObject:managedObject];
        }
        
    }];
    
    response.JSONResponse = jsonObject;
    
    return response;
}

-(void)handleEditInstanceRequest:(RouteRequest *)request forEntity:(NSEntityDescription *)entity resourceID:(NSNumber *)resourceID response:(RouteResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{NOServerResourceIDKey : resourceID}];
    
    // get JSON object
    
    __block NSError *error;
    
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                               options:NSJSONReadingAllowFragments
                                                                 error:&error];
    
    if (!jsonObject || [jsonObject isKindOfClass:[NSDictionary class]]) {
        
        response.statusCode = NOServerStatusCodeBadRequest;
        
        return;
    }
    
    // get context
    
    NSManagedObjectContext *context = [_dataSource server:self managedObjectContextForRequest:request withType:NOServerRequestTypePUT];
    
    userInfo[NOServerManagedObjectContextKey] = context;
    
    // fetch managedObject
    
    NSManagedObject *managedObject = [self fetchEntity:entity withResourceID:resourceID usingContext:context shouldPrefetch:NO error:&error];
    
    // internal error
    
    if (error) {
        
        if (_delegate) {
            
            [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
        }
        
        response.statusCode = NOServerStatusCodeInternalServerError;
        
        return;
    }
    
    // object doesnt exist
    
    if (!managedObject && !error) {
        
        response.statusCode = NOServerStatusCodeNotFound;
        
        return;
    }
    
    // add managedObject to userInfo
    
    userInfo[NOServerManagedObjectKey] = managedObject;
    
    // ask delegate
    
    if (_delegate) {
        
        NOServerStatusCode statusCode = [_delegate server:self statusCodeForRequest:request withType:NOServerRequestTypePUT entity:entity userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return;
        }
    }
    
    // check for permissions
    
    if (_permissionsEnabled) {
        
        if ([_delegate server:self permissionForRequest:request withType:NOServerRequestTypePUT entity:entity managedObject:managedObject context:context key:nil] < NOServerPermissionEditPermission) {
            
            response.statusCode = NOServerStatusCodeForbidden;
            
            return;
        };
    }
    
    // validate
    
    __block NOServerStatusCode editStatusCode;
    
    __block NSDictionary *newValues;
    
    [context performBlockAndWait:^{
        
        editStatusCode = [self verifyEditResource:managedObject
                                       forRequest:request
                                      requestType:NOServerRequestTypePUT
                               recievedJsonObject:jsonObject
                                          context:context
                                            error:&error
                                  convertedValues:&newValues];
    }];
    
    if (editStatusCode != NOServerStatusCodeOK) {
        
        if (editStatusCode == NOServerStatusCodeInternalServerError) {
            
            if (_delegate) {
                
                [_delegate server:self didEncounterInternalError:error forRequest:request withType:NOServerRequestTypePUT entity:entity userInfo:userInfo];
            }
        }
        
        response.statusCode = editStatusCode;
        
        return;
    }
    
    userInfo[NOServerNewValuesKey] = newValues;
    
    // set new values from dictionary
    
    [context performBlockAndWait:^{
       
        [managedObject setValuesForKeysWithDictionary:newValues];
        
    }];
    
    // return 200
    response.statusCode = NOServerStatusCodeOK;
    
    // tell delegate
    
    if (_delegate) {
        
        [_delegate server:self didPerformRequest:request withType:NOServerRequestTypePUT userInfo:userInfo];
    }
}

-(void)handleDeleteInstanceRequest:(RouteRequest *)request forEntity:(NSEntityDescription *)entity resourceID:(NSNumber *)resourceID response:(RouteResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{NOServerResourceIDKey : resourceID}];
    
    // get context
    
    NSManagedObjectContext *context = [_dataSource server:self managedObjectContextForRequest:request withType:NOServerRequestTypeDELETE];
    
    userInfo[NOServerManagedObjectContextKey] = context;
    
    // fetch managedObject
    
    NSError *error;
    
    NSManagedObject *managedObject = [self fetchEntity:entity withResourceID:resourceID usingContext:context shouldPrefetch:NO error:&error];
    
    // internal error
    
    if (error) {
        
        if (_delegate) {
            
            [_delegate server:self didEncounterInternalError:error forRequest:request withType:NOServerRequestTypeDELETE entity:entity userInfo:userInfo];
        }
        
        response.statusCode = NOServerStatusCodeInternalServerError;
        
        return;
    }
    
    // object doesnt exist
    
    if (!managedObject && !error) {
        
        response.statusCode = NOServerStatusCodeNotFound;
        
        return;
    }
    
    // add managedObject to userInfo
    
    userInfo[NOServerManagedObjectKey] = managedObject;
    
    // ask delegate
    
    if (_delegate) {
        
        NOServerStatusCode statusCode = [_delegate server:self statusCodeForRequest:request withType:NOServerRequestTypeDELETE entity:entity userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return;
        }
    }
    
    // check for permissions
    
    if (_permissionsEnabled) {
        
        if ([_delegate server:self permissionForRequest:request withType:NOServerRequestTypeDELETE entity:entity managedObject:managedObject context:context key:nil] < NOServerPermissionEditPermission) {
            
            response.statusCode = NOServerStatusCodeForbidden;
            
            return;
        };
    }
    
    // delete object
    
    [context performBlockAndWait:^{
        
        [context deleteObject:managedObject];
        
    }];
    
    response.statusCode = NOServerStatusCodeOK;
    
    // tell delegate
    
    if (_delegate) {
        
        [_delegate server:self didPerformRequest:request withType:NOServerRequestTypeDELETE userInfo:userInfo];
    }
}

-(void)handleFunctionInstanceRequest:(RouteRequest *)request forEntity:(NSEntityDescription *)entity resourceID:(NSNumber *)resourceID functionName:(NSString *)functionName response:(RouteResponse *)response
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{NOServerResourceIDKey : resourceID}];
    
    // get context
    
    NSManagedObjectContext *context = [_dataSource server:self managedObjectContextForRequest:request withType:NOServerRequestTypeFunction];
    
    userInfo[NOServerManagedObjectContextKey] = context;
    
    // fetch managedObject
    
    NSError *error;
    
    NSManagedObject *managedObject = [self fetchEntity:entity withResourceID:resourceID usingContext:context shouldPrefetch:NO error:&error];
    
    // internal error
    
    if (error) {
        
        if (_delegate) {
            
            [_delegate server:self didEncounterInternalError:error forRequest:request withType:NOServerRequestTypeFunction entity:entity userInfo:userInfo];
        }
        
        response.statusCode = NOServerStatusCodeInternalServerError;
        
        return;
    }
    
    // object doesnt exist
    
    if (!managedObject && !error) {
        
        response.statusCode = NOServerStatusCodeNotFound;
        
        return;
    }
    
    // add managedObject to userInfo
    
    userInfo[NOServerManagedObjectKey] = managedObject;
    
    // get recieved JSON object
    
    NSDictionary *recievedJSONObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                                      options:NSJSONReadingAllowFragments
                                                                        error:nil];
    
    if (recievedJSONObject && ![recievedJSONObject isKindOfClass:[NSDictionary class]]) {
        
        response.statusCode = NOServerStatusCodeBadRequest;
        
        return;
    }
    
    if (recievedJSONObject) {
        
        userInfo[NOServerFunctionJSONInputKey] = recievedJSONObject;
    }
    
    // ask delegate
    
    if (_delegate) {
        
        NOServerStatusCode statusCode = [_delegate server:self statusCodeForRequest:request withType:NOServerRequestTypeFunction entity:entity userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return;
        }
    }
    
    // check for permissions
    
    if (_permissionsEnabled) {
        
        if ([_delegate server:self permissionForRequest:request withType:NOServerRequestTypeFunction entity:entity managedObject:managedObject context:context key:nil] < NOServerPermissionEditPermission) {
            
            response.statusCode = NOServerStatusCodeForbidden;
            
            return;
        };
    }
    
    NSDictionary *jsonObject;
    
    // perform function
    
    NOServerFunctionCode statusCode = [_dataSource server:self
                                        performFunction:functionName
                                       forManagedObject:managedObject
                                                context:context
                                     recievedJsonObject:recievedJSONObject
                                               response:&jsonObject];
    
    response.statusCode = statusCode;
    
    if (jsonObject) {
        
        // add to userInfo
        
        userInfo[NOServerFunctionJSONOutputKey] = jsonObject;
        
        // add to response
        
        response.jsonObject = jsonObject;
    }
    
    return response;
}

@end

#pragma mark - Category Implementations

@implementation NOServer (Internal)

-(void)setupHTTPServer
{
    _httpServer = [[NOHTTPServer alloc] init];
    
    _httpServer.connectionClass = [NOHTTPConnection class];
    
    _httpServer.server = self;
        
    // setup routes
    
    for (NSString *path in self.entitiesByResourcePath) {
        
        NSEntityDescription *entity = self.entitiesByResourcePath[path];
        
        // add search handler
        
        if (self.searchPath) {
            
            NSString *searchPathExpression = [NSString stringWithFormat:@"/%@/%@", _searchPath, path];
            
            void (^searchRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *request, RouteResponse *response) {
                
                NSError *jsonError;
                
                NSDictionary *searchParameters = [NSJSONSerialization JSONObjectWithData:request.body options:NSJSONReadingAllowFragments error:&jsonError];
                
                if (jsonError || ![searchParameters isKindOfClass:[NSDictionary class]]) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                // convert to server request
                
                NOServerRequest *serverRequest = [[NOServerRequest alloc] init];
                
                serverRequest.requestType = NOServerRequestTypeSearch;
                serverRequest.connectionType = NOServerConnectionTypeHTTP;
                serverRequest.entity = entity;
                serverRequest.JSONDictionary = searchParameters;
                serverRequest.originalRequest = request;
                
                // process request and return a response
                
                NOServerResponse *serverResponse = [self responseForSearchRequest:request];
                
                if (response.statusCode == NOServerStatusCodeOK) {
                    
                    // write to socket
                    
                    NSError *error;
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:serverResponse.JSONResponse
                                                                       options:self.jsonWritingOption
                                                                         error:&error];
                    
                    if (!jsonData) {
                        
                        if (_delegate) {
                            
                            [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
                        }
                        
                        response.statusCode = NOServerStatusCodeInternalServerError;
                        
                        return response;
                    }
                    
                    [response respondWithData:jsonData];
                }
                else {
                    
                    response.statusCode = serverResponse.statusCode;
                }
                
                // tell delegate
                
                if (_delegate) {
                    
                    [_delegate server:self didPerformRequest:serverRequest withResponse:serverResponse userInfo:userInfo];
                }
                
            };
            
            [_httpServer post:searchPathExpression
                    withBlock:searchRequestHandler];
        }
        
        // setup routes for resources...
        
        NSString *allInstancesPathExpression = [NSString stringWithFormat:@"/%@", path];
        
        void (^allInstancesRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *routeRequest, RouteResponse *routeResponse) {
            
            // get initial values
            
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:request.body
                                                                       options:NSJSONReadingAllowFragments
                                                                         error:nil];
            
            if (jsonObject && ![jsonObject isKindOfClass:[NSDictionary class]]) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return;
            }
            
            // convert to server request
            
            NOServerRequest *serverRequest = [[NOServerRequest alloc] init];
            
            serverRequest.requestType = NOServerRequestTypeSearch;
            serverRequest.connectionType = NOServerConnectionTypeHTTP;
            serverRequest.entity = entity;
            serverRequest.JSONDictionary = searchParameters;
            serverRequest.originalRequest = request;
            
            // process request and return a response
            
            NOServerResponse *serverResponse = [self responseForCreateNewInstanceRequest:request];
            
            if (serverResponse != NOServerStatusCodeOK) {
                
                response.statusCode = serverResponse.statusCode;
                
                return;
            }
            
            // write to socket
            
            NSError *error;
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:serverResponse.JSONResponse
                                                               options:self.jsonWritingOption
                                                                 error:&error];
            
            if (!jsonData) {
                
                if (_delegate) {
                    
                    [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
                }
                
                response.statusCode = NOServerStatusCodeInternalServerError;
                
                return response;
            }
            
            [response respondWithData:jsonData];
            
            response.statusCode = NOServerStatusCodeOK;
            
            // tell delegate
            
            if (_delegate) {
                
                [_delegate server:self didPerformRequest:serverRequest withResponse:serverResponse userInfo:userInfo];
            }
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
            
            // get initial values
            
            NSDictionary *jsonObject  = [NSJSONSerialization JSONObjectWithData:request.body
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:nil];
            
            if (jsonObject && ![jsonObject isKindOfClass:[NSDictionary class]]) {
                
                response.statusCode = NOServerStatusCodeBadRequest;
                
                return;
            }
            
            // convert to server request
            
            NOServerRequest *serverRequest = [[NOServerRequest alloc] init];
            
            serverRequest.connectionType = NOServerConnectionTypeHTTP;
            serverRequest.entity = entity;
            serverRequest.resourceID = resourceID;
            serverRequest.JSONDictionary = searchParameters;
            serverRequest.originalRequest = request;
            
            NOServerResponse *serverResponse;
            
            if ([request.method isEqualToString:@"GET"]) {
                
                serverRequest.requestType = NOServerRequestTypeGET;
                
                // should not have a body
                
                if (jsonObject) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                serverResponse = [self responseForGetInstanceRequest:serverRequest];
                
                // serialize JSON data
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                   options:self.jsonWritingOption
                                                                     error:&error];
                if (!jsonData) {
                    
                    if (_delegate) {
                        
                        [_delegate server:self didEncounterInternalError:error forRequest:request userInfo:userInfo];
                    }
                    
                    response.statusCode = NOServerStatusCodeInternalServerError;
                    
                    return;
                }
                
                // return JSON representation of resource
                [response respondWithData:jsonData];
                
            }
            
            if ([request.method isEqualToString:@"PUT"]) {
                
                serverRequest.requestType = NOServerRequestTypePUT;
                
                // body required
                
                if (!jsonObject) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                serverResponse = [self responseForEditInstanceRequest:serverRequest];
                
            }
            
            if ([request.method isEqualToString:@"DELETE"]) {
                
                serverRequest.requestType = NOServerRequestTypeDELETE;
                
                // should not have a body
                
                if (jsonObject) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                serverResponse = [self responseForDeleteInstanceRequest:serverRequest];
                
            }
            
            // tell delegate
            
            if (_delegate) {
                
                [_delegate server:self didPerformRequest:request withResponse:serverResponse userInfo:userInfo];
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
            
            void (^instanceFunctionRequestHandler) (RouteRequest *, RouteResponse *) = ^(RouteRequest *routeRequest, RouteResponse *routeResponse) {
                
                NSArray *captures = request.params[@"captures"];
                
                NSString *capturedResourceID = captures[0];
                
                NSNumber *resourceID = [NSNumber numberWithInteger:capturedResourceID.integerValue];
                
                // get initial values
                
                NSDictionary *jsonObject  = [NSJSONSerialization JSONObjectWithData:request.body
                                                                            options:NSJSONReadingAllowFragments
                                                                              error:nil];
                
                if (jsonObject && ![jsonObject isKindOfClass:[NSDictionary class]]) {
                    
                    response.statusCode = NOServerStatusCodeBadRequest;
                    
                    return;
                }
                
                // convert to server request
                
                NOServerRequest *serverRequest = [[NOServerRequest alloc] init];
                
                serverRequest.requestType = NOServerRequestTypeFunction;
                serverRequest.connectionType = NOServerConnectionTypeHTTP;
                serverRequest.entity = entity;
                serverRequest.resourceID = resourceID;
                serverRequest.JSONDictionary = jsonObject;
                serverRequest.originalRequest = request;
                
                NOServerResponse *serverResponse = [self responseForFunctionInstanceRequest:request];
                
                if (serverResponse.JSONResponse) {
                    
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                                       options:self.jsonWritingOption
                                                                         error:&error];
                    
                    if (!jsonData) {
                        
                        if (_delegate) {
                            
                            [_delegate server:self didEncounterInternalError:error forRequest:request withType:NOServerRequestTypeFunction entity:entity userInfo:userInfo];
                        }
                        
                        response.statusCode = NOServerStatusCodeInternalServerError;
                        
                        return;
                    }
                    
                    [response respondWithData:jsonData];
                }
                
                response.statusCode = statusCode;
                
                // tell delegate
                
                if (_delegate) {
                    
                    [_delegate server:self didPerformRequest:request withType:NOServerRequestTypeFunction userInfo:userInfo];
                }
            };
            
            // functions use POST
            [_httpServer post:functionExpression
                    withBlock:instanceFunctionRequestHandler];
            
        }
    }
    
    // setup WebSocket routes
    
    for (NSString *path in self.entitiesByResourcePath) {
        
        NSEntityDescription *entity = self.entitiesByResourcePath[path];
        
        // add search handler
        
        if (self.searchPath) {
            
            NSString *searchPathExpression = [NSString stringWithFormat:@"{^POST /%@/%@$^(\\.+)}", _searchPath, path];
            
            [_httpServer addWebSocketCommandForExpression:searchPathExpression block:^(NSDictionary *parameters, NOWebSocket *webSocket) {
                
                // parse JSON
                
                NSString *JSONString = parameters[@"captures"].firstObject;
                
                NSData *JSONData = [[NSString alloc] initWithData:JSONData
                                                         encoding:NSUTF8StringEncoding];
                
                NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:nil];
                
                if (![JSONDictionary isKindOfClass:[NSDictionary class]]) {
                    
                    [webSocket sendMessage:[NSString stringWithFormat:@"%d", NOServerStatusCodeBadRequest]];
                    
                    return;
                }
               
                // make request
                
                NOWebSocketRequest *webSocketRequest = [[NOWebSocketRequest alloc] initWithWebSocket:webSocket
                                                                                     recievedMessage:mess]
                
                NOServerRequest *request = [[NOServerRequest alloc] initWithRequestType:NOServerRequestTypeSearch
                                                                         connectionType:NOServerConnectionTypeWebSocket
                                                                                 entity:entity
                                                                             resourceID:nil
                                                                         JSONDictionary:JSONDictionary
                                                                        originalRequest:[NOWebSocketRequest]]
                
            }];
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
                
                NSNumber *resourceID = [NSNumber numberWithInteger:capturedResourceID.integerValue];
                
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

-(NSDictionary *)JSONRepresentationOfManagedObject:(NSManagedObject *)managedObject
{
    // build JSON object...
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // first the attributes
    
    for (NSString *attributeName in managedObject.entity.attributesByName) {
        
        // get attribute
        NSAttributeDescription *attribute = managedObject.entity.attributesByName[attributeName];
        
        // make sure the attribute is not transformable or undefined
        if (attribute.attributeType != NSTransformableAttributeType ||
            attribute.attributeType != NSUndefinedAttributeType) {
            
            // add to JSON representation
            jsonObject[attributeName] = [managedObject JSONCompatibleValueForAttribute:attributeName];
            
        }
    }
    
    // then the relationships
    for (NSString *relationshipName in managedObject.entity.relationshipsByName) {
        
        NSRelationshipDescription *relationshipDescription = managedObject.entity.relationshipsByName[relationshipName];
        
        // to-one relationship
        if (!relationshipDescription.isToMany) {
            
            // get destination resource
            NSManagedObject *destinationResource = [managedObject valueForKey:relationshipName];
            
            // get resourceID
            NSNumber *destinationResourceID = [destinationResource valueForKey:_resourceIDAttributeName];
            
            // add to json object
            [jsonObject setValue:destinationResourceID
                          forKey:relationshipName];
        }
        
        // to-many relationship
        else {
            
            // get destination collection
            NSArray *toManyRelationship = [managedObject valueForKey:relationshipName];
            
            // only add resources that are visible
            NSMutableArray *visibleRelationship = [[NSMutableArray alloc] init];
            
            for (NSManagedObject *destinationResource in toManyRelationship) {
                
                // get destination resource ID
                
                NSNumber *destinationResourceID = [destinationResource valueForKey:_resourceIDAttributeName];
                
                [visibleRelationship addObject:destinationResourceID];
            }
            
            // add to jsonObject
            [jsonObject setValue:visibleRelationship
                          forKey:relationshipName];
        }
    }
    
    return jsonObject;
}

-(NOServerStatusCode)verifyEditResource:(NSManagedObject *)resource
                             forRequest:(RouteRequest *)request
                            requestType:(NOServerRequestType)requestType
                     recievedJsonObject:(NSDictionary *)recievedJsonObject
                                context:(NSManagedObjectContext *)context
                                  error:(NSError **)error
                        convertedValues:(NSDictionary **)convertedValues
{
    NSMutableDictionary *newConvertedValues = [[NSMutableDictionary alloc] initWithCapacity:recievedJsonObject.count];
    
    for (NSString *key in recievedJsonObject) {
        
        // validate the recieved JSON object
        
        if (![NSJSONSerialization isValidJSONObject:recievedJsonObject]) {
            
            return NOServerStatusCodeBadRequest;
        }
        
        id jsonValue = recievedJsonObject[key];
        
        BOOL isAttribute = NO;
        BOOL isRelationship = NO;
        
        for (NSString *attributeName in resource.entity.attributesByName) {
            
            // found attribute with same name
            if ([key isEqualToString:attributeName]) {
                
                isAttribute = YES;
                
                // resourceID cannot be edited by anyone
                if ([key isEqualToString:_resourceIDAttributeName]) {
                    
                    return NOServerStatusCodeForbidden;
                }
                
                // check permissions
                
                if (_permissionsEnabled) {
                    
                    if ([_delegate server:self permissionForRequest:request withType:requestType entity:resource.entity managedObject:resource context:context key:attributeName] < NOServerPermissionEditPermission) {
                        
                        return NOServerStatusCodeForbidden;
                    }
                }
                
                NSAttributeDescription *attribute = resource.entity.attributesByName[attributeName];
                
                // make sure the attribute to edit is not transformable or undefined
                if (attribute.attributeType == NSTransformableAttributeType ||
                    attribute.attributeType == NSUndefinedAttributeType) {
                    
                    return NOServerStatusCodeBadRequest;
                }
                
                // get pre-edit value
                id newValue = [resource attributeValueForJSONCompatibleValue:jsonValue
                                                                       forAttribute:key];
                
                // validate that the pre-edit value is of the same class as the attribute it will be given
                
                if (![resource isValidConvertedValue:newValue
                                        forAttribute:attributeName]) {
                    
                    return NOServerStatusCodeBadRequest;
                }
                
                // let NOResource verify that the new attribute value is a valid new value
                if (![resource validateValue:&newValue
                                      forKey:attributeName
                                       error:nil]) {
                    
                    return NOServerStatusCodeBadRequest;
                }
                
                newConvertedValues[attributeName] = newValue;
            }
        }
        
        for (NSString *relationshipName in resource.entity.relationshipsByName) {
            
            // found relationship with that name...
            if ([key isEqualToString:relationshipName] ) {
                
                isRelationship = YES;
                
                // check permissions of relationship
                
                if (_permissionsEnabled) {
                    
                    if ([_delegate server:self permissionForRequest:request withType:requestType entity:resource.entity managedObject:resource context:context key:relationshipName] < NOServerPermissionEditPermission) {
                        
                        return NOServerStatusCodeForbidden;
                    }
                }
                
                NSRelationshipDescription *relationshipDescription = resource.entity.relationshipsByName[key];
                
                // to-one relationship
                if (!relationshipDescription.isToMany) {
                    
                    // must be number
                    if (![jsonValue isKindOfClass:[NSNumber class]]) {
                        
                        return NOServerStatusCodeBadRequest;
                    }
                    
                    NSNumber *destinationResourceID = jsonValue;
                    
                    NSManagedObject *newValue = [self fetchEntity:relationshipDescription.destinationEntity
                                                   withResourceID:destinationResourceID
                                                     usingContext:context
                                                   shouldPrefetch:NO
                                                            error:error];
                    
                    if (*error) {
                        
                        return NOServerStatusCodeInternalServerError;
                    }
                    
                    if (!newValue) {
                        
                        return NOServerStatusCodeBadRequest;
                    }
                    
                    // destination resource must be visible
                    
                    if (_permissionsEnabled) {
                        
                        if ([_delegate server:self permissionForRequest:request withType:requestType entity:relationshipDescription.destinationEntity managedObject:newValue context:context key:nil] < NOServerPermissionReadOnly) {
                            
                            return NOServerStatusCodeForbidden;
                        }
                    }
                    
                    // must be valid value
                    
                    if (![resource validateValue:&newValue
                                          forKey:key
                                           error:nil]) {
                        
                        return NOServerStatusCodeBadRequest;
                    }
                    
                    newConvertedValues[relationshipName] = newValue;
                }
                
                // to-many relationship
                else {
                    
                    // must be array
                    if (![jsonValue isKindOfClass:[NSArray class]]) {
                        
                        return NOServerStatusCodeBadRequest;
                    }
                    
                    // verify that the array contains numbers
                    
                    for (NSNumber *resourceID in jsonValue) {
                        
                        if (![resourceID isKindOfClass:[NSNumber class]]) {
                            
                            return NOServerStatusCodeBadRequest;
                        }
                    }
                    
                    NSArray *jsonReplacementCollection = jsonValue;
                    
                    // fetch new value
                    NSArray *newValue = [self fetchEntity:relationshipDescription.destinationEntity
                                          withResourceIDs:jsonReplacementCollection
                                             usingContext:context
                                           shouldPrefetch:NO
                                                    error:error];
                    
                    if (*error) {
                        
                        return NOServerStatusCodeInternalServerError;
                    }
                    
                    // make sure all the values are present and have the correct permissions...
                    
                    if (jsonReplacementCollection.count != newValue.count) {
                        
                        return NOServerStatusCodeBadRequest;
                    }
                    
                    for (NSNumber *destinationResourceID in jsonReplacementCollection) {
                        
                        NSManagedObject *destinationResource = newValue[[jsonReplacementCollection indexOfObject:destinationResourceID]];
                        
                        // destination resource must be visible
                        
                        if (_permissionsEnabled) {
                            
                            if ([_delegate server:self permissionForRequest:request withType:requestType entity:relationshipDescription.destinationEntity managedObject:destinationResource context:context key:nil] < NOServerPermissionReadOnly) {
                                
                                return NOServerStatusCodeForbidden;
                            }
                        }
                    }
                    
                    // must be valid new value
                    if (![resource validateValue:&newValue
                                          forKey:key
                                           error:nil]) {
                        
                        return NOServerStatusCodeBadRequest;
                    }
                    
                    newConvertedValues[relationshipName] = newValue;
                }
            }
        }
        
        // no attribute or relationship with that name found
        if (!isAttribute && !isRelationship) {
            
            return NOServerStatusCodeBadRequest;
        }
    }
    
    *convertedValues = newConvertedValues;
    
    return NOServerStatusCodeOK;
}

@end


@implementation NOServer (Permissions)

-(void)checkForDelegatePermissions
{
    _permissionsEnabled = (_delegate && [_delegate respondsToSelector:@selector(server:permissionForRequest:withType:entity:managedObject:context:key:)]);
}

-(NSDictionary *)filteredJSONRepresentationOfManagedObject:(NSManagedObject *)managedObject
                                                   context:(NSManagedObjectContext *)context
                                                   request:(RouteRequest *)request
                                               requestType:(NOServerRequestType)requestType
{
    // build JSON object...
    
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    // first the attributes
    
    for (NSString *attributeName in managedObject.entity.attributesByName) {
        
        // check access permissions (unless its the resourceID, thats always visible)
        if ([_delegate server:self permissionForRequest:request withType:requestType entity:managedObject.entity managedObject:managedObject context:context key:attributeName] >= NOServerPermissionReadOnly ||
            [attributeName isEqualToString:_resourceIDAttributeName]) {
            
            // get attribute
            NSAttributeDescription *attribute = managedObject.entity.attributesByName[attributeName];
            
            // make sure the attribute is not undefined
            if (attribute.attributeType != NSUndefinedAttributeType) {
                
                // add to JSON representation
                jsonObject[attributeName] = [managedObject JSONCompatibleValueForAttribute:attributeName];
                
            }
        }
    }
    
    // then the relationships
    for (NSString *relationshipName in managedObject.entity.relationshipsByName) {
        
        NSRelationshipDescription *relationshipDescription = managedObject.entity.relationshipsByName[relationshipName];
        
        NSEntityDescription *destinationEntity = relationshipDescription.destinationEntity;
        
        // make sure relationship is visible
        if ([_delegate server:self permissionForRequest:request withType:requestType entity:managedObject.entity managedObject:managedObject context:context key:relationshipName] >= NOServerPermissionReadOnly) {
            
            // to-one relationship
            if (!relationshipDescription.isToMany) {
                
                // get destination resource
                NSManagedObject *destinationResource = [managedObject valueForKey:relationshipName];
                
                // check access permissions (the relationship & the single distination object must be visible)
                if ([_delegate server:self permissionForRequest:request withType:requestType entity:destinationEntity managedObject:destinationResource context:context key:nil] >= NOServerPermissionReadOnly) {
                    
                    NSNumber *destinationResourceID = [destinationResource valueForKey:_resourceIDAttributeName];
                    
                    // add to json object
                    jsonObject[destinationResourceID] = relationshipName;
                }
            }
            
            // to-many relationship
            else {
                
                // get destination collection
                NSArray *toManyRelationship = [managedObject valueForKey:relationshipName];
                
                // only add resources that are visible
                NSMutableArray *visibleRelationship = [[NSMutableArray alloc] init];
                
                for (NSManagedObject *destinationResource in toManyRelationship) {
                    
                    if ([_delegate server:self permissionForRequest:request withType:requestType entity:destinationEntity managedObject:destinationResource context:context key:nil] >= NOServerPermissionReadOnly) {
                        
                        // get destination resource ID
                        
                        NSNumber *destinationResourceID = [destinationResource valueForKey:_resourceIDAttributeName];
                        
                        [visibleRelationship addObject:destinationResourceID];
                    }
                }
                
                // add to jsonObject
                jsonObject[relationshipName] = visibleRelationship;
            }
        }
    }
    
    return jsonObject;
}

@end

#pragma mark - Private Classes Implementation

@implementation NOHTTPConnection

-(BOOL)isSecureServer
{
    return (BOOL)self.sslIdentityAndCertificates;
}

-(NSArray *)sslIdentityAndCertificates
{
    NOHTTPServer *httpServer = (NOHTTPServer *)config.server;
    
    NOServer *server = httpServer.server;
    
    return server.sslIdentityAndCertificates;
}

-(WebSocket *)webSocketForURI:(NSString *)path
{
    if ([path isEqualToString:@"/"]) {
        
        NOWebSocket *webSocket = [[NOWebSocket alloc] initWithRequest:request socket:asyncSocket];
        
        webSocket.server = config.server;
        
        return webSocket;
    }
    
    return [super webSocketForURI:path];
}

@end

@implementation NOHTTPServer

-(void)addWebSocketCommandForExpression:(NSString *)expressionString block:(void (^)())block
{
    NOWebSocketCommand *command = [[NOWebSocketCommand alloc] init];
    
    NSMutableArray *keys = [NSMutableArray array];
    
    NSString *path = expressionString;
    
    if ([path length] > 2 && [path characterAtIndex:0] == '{') {
        // This is a custom regular expression, just remove the {}
        path = [path substringWithRange:NSMakeRange(1, [path length] - 2)];
    } else {
        NSRegularExpression *regex = nil;
        
        // Escape regex characters
        regex = [NSRegularExpression regularExpressionWithPattern:@"[.+()]" options:0 error:nil];
        path = [regex stringByReplacingMatchesInString:path options:0 range:NSMakeRange(0, path.length) withTemplate:@"\\\\$0"];
        
        // Parse any :parameters and * in the path
        regex = [NSRegularExpression regularExpressionWithPattern:@"(:(\\w+)|\\*)"
                                                          options:0
                                                            error:nil];
        NSMutableString *regexPath = [NSMutableString stringWithString:path];
        __block NSInteger diff = 0;
        [regex enumerateMatchesInString:path options:0 range:NSMakeRange(0, path.length)
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSRange replacementRange = NSMakeRange(diff + result.range.location, result.range.length);
                                 NSString *replacementString;
                                 
                                 NSString *capturedString = [path substringWithRange:result.range];
                                 if ([capturedString isEqualToString:@"*"]) {
                                     [keys addObject:@"wildcards"];
                                     replacementString = @"(.*?)";
                                 } else {
                                     NSString *keyString = [path substringWithRange:[result rangeAtIndex:2]];
                                     [keys addObject:keyString];
                                     replacementString = @"([^/]+)";
                                 }
                                 
                                 [regexPath replaceCharactersInRange:replacementRange withString:replacementString];
                                 diff += replacementString.length - result.range.length;
                             }];
        
        path = [NSString stringWithFormat:@"^%@$", regexPath];
    }
    
    command.regularExpression = [NSRegularExpression regularExpressionWithPattern:path options:NSRegularExpressionCaseInsensitive error:nil];
    
    if ([keys count] > 0) {
        
        command.keys = keys;
    }
    
    command.block = block;
    
    if (!_webSocketCommands) {
        
        _webSocketCommands = [[NSMutableArray alloc] init];
    }
    
    [_webSocketCommands addObject:command];
}

-(void)webSocket:(NOWebSocket *)webSocket didReceiveMessage:(NSString *)message
{
    // look for matching command
    
    for (NOWebSocketCommand *command in _webSocketCommands) {
        
        NSTextCheckingResult *result = [command.regularExpression firstMatchInString:path
                                                                             options:0
                                                                               range:NSMakeRange(0, path.length)];
        if (!result)
            continue;
        
        NSDictionary *params = [[NSMutableDictionary alloc] init];
        
        // The first range is all of the text matched by the regex.
        NSUInteger captureCount = [result numberOfRanges];
        
        if (command.keys) {
            // Add the route's parameters to the parameter dictionary, accounting for
            // the first range containing the matched text.
            if (captureCount == [command.keys count] + 1) {
                NSMutableDictionary *newParams = [params mutableCopy];
                NSUInteger index = 1;
                BOOL firstWildcard = YES;
                for (NSString *key in route.keys) {
                    NSString *capture = [path substringWithRange:[result rangeAtIndex:index]];
                    if ([key isEqualToString:@"wildcards"]) {
                        NSMutableArray *wildcards = [newParams objectForKey:key];
                        if (firstWildcard) {
                            // Create a new array and replace any existing object with the same key
                            wildcards = [NSMutableArray array];
                            [newParams setObject:wildcards forKey:key];
                            firstWildcard = NO;
                        }
                        [wildcards addObject:capture];
                    } else {
                        [newParams setObject:capture forKey:key];
                    }
                    index++;
                }
                params = newParams;
            }
        } else if (captureCount > 1) {
            // For custom regular expressions place the anonymous captures in the captures parameter
            NSMutableDictionary *newParams = [params mutableCopy];
            NSMutableArray *captures = [NSMutableArray array];
            for (NSUInteger i = 1; i < captureCount; i++) {
                [captures addObject:[path substringWithRange:[result rangeAtIndex:i]]];
            }
            [newParams setObject:captures forKey:@"captures"];
            params = newParams;
        }
        
        // execute command
        
        command.block(params);
        
        return;
    }
    
    // unknown command
    
    [webSocket sendMessage:[NSString stringWithFormat:@"%lu", NOServerStatusCodeMethodNotAllowed]];
}

@end

@implementation NOWebSocket

-(void)didReceiveMessage:(NSString *)msg
{    
    [_server webSocket:self didReceiveMessage:message];
}

@end

@implementation NOServerResponse

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.statusCode = NOServerStatusCodeOK;
        
    }
    return self;
}

@end


