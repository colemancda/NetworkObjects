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

@interface NOServer (Internal)

@property (nonatomic, readonly) NSJSONWritingOptions jsonWritingOption;

-(void)setupHTTPServer;

-(NSManagedObject *)fetchEntity:(NSEntityDescription *)entity
                 withResourceID:(NSNumber *)resourceID;

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
    
    if (jsonError) {
        
        if (self.delegate) {
            
            [self.delegate server:self didEncounterInternalError:jsonError forRequest:request withType:NOServerRequestTypeSearch entity:entity userInfo:userInfo];
        }
        
        response.statusCode = NOServerStatusCodeBadRequest;
        
        return;
    }
    
    if (![searchParameters isKindOfClass:[NSDictionary class]]) {
        
        response.statusCode = NOServerStatusCodeBadRequest;
        
        return;
    }
    
    // check for permission
    
    if (self.delegate) {
        
        NOServerStatusCode statusCode = [self.delegate server:self statusCodeForRequest:request withType:NOServerRequestTypeSearch entity:entity userInfo:userInfo];
        
        if (statusCode != NOServerStatusCodeOK) {
            
            response.statusCode = statusCode;
            
            return;
        }
    }
    
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
        
        NSRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[predicateKey];
        
        NSAttributeDescription *attributeDescription = entityDescription.attributesByName[predicateKey];
        
        // validate that key is attribute or relationship
        if (!relationshipDescription && !attributeDescription) {
            
            response.statusCode = NOServerBadRequestStatusCode;
            
            return;
        }
        
        // attribute value
        
        if (attributeDescription) {
            
            value = [entityDescription attributeValueForJSONCompatibleValue:jsonPredicateValue
                                                               forAttribute:predicateKey];
        }
        
        // relationship value
        
        
    
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

@end
