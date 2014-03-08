//
//  NOAPI.m
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 10/21/13.
//  Copyright (c) 2013 CDA. All rights reserved.
//

#import "NOAPI.h"
#import "NOResourceProtocol.h"
#import "NOUserProtocol.h"
#import "NOSessionProtocol.h"
#import "NOClientProtocol.h"
#import "NetworkObjectsConstants.h"
#import <NetworkObjects/NOServerConstants.h>

@implementation NOAPI (NSJSONWritingOption)

-(NSJSONWritingOptions)jsonWritingOption
{
    if (self.prettyPrintJSON) {
        return NSJSONWritingPrettyPrinted;
    }
    
    return 0;
}

@end

@implementation NOAPI (Errors)

-(NSError *)invalidServerResponse
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"The server returned a invalid response",
                                                  @"The server returned a invalid response");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPIInvalidServerResponseErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

-(NSError *)badRequestError
{
    static NSError *error;
    
    if (!error) {
        
        NSString *description = NSLocalizedString(@"Invalid request",
                                                  @"Invalid request");
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPIBadRequestErrorCode
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
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPIServerInternalErrorCode
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
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPIUnauthorizedErrorCode
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
        
        error = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                    code:NOAPINotFoundErrorCode
                                userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    
    return error;
}

@end

@implementation NOAPI (Common)

-(Class)entityWithResourceName:(NSString *)resourceName
{
    NSEntityDescription *entity = self.model.entitiesByName[resourceName];
    
    if (!entity) {
        
        [NSException raise:NSInvalidArgumentException
                    format:@"No entity in the model matches '%@'", resourceName];
    }
    
    Class entityClass = NSClassFromString(entity.managedObjectClassName);
    
    return entityClass;
}

@end

@interface NOAPI ()

@property NSManagedObjectModel *model;

@property NSString *sessionEntityName;

@property NSString *userEntityName;

@property NSString *clientEntityName;

@property NSString *loginPath;

@end

@implementation NOAPI

- (id)initWithModel:(NSManagedObjectModel *)model
  sessionEntityName:(NSString *)sessionEntityName
     userEntityName:(NSString *)userEntityName
   clientEntityName:(NSString *)clientEntityName
          loginPath:(NSString *)loginPath
{
    self = [super init];
    if (self) {
        
        // set immutable values
        self.model = model;
        self.sessionEntityName = sessionEntityName;
        self.userEntityName = userEntityName;
        self.clientEntityName = clientEntityName;
        self.loginPath = loginPath;
        
    }
    return self;
}

- (id)init
{
    [NSException raise:@"Wrong initialization method"
                format:@"You cannot use %@ with '-%@', you have to use '-%@'",
     self,
     NSStringFromSelector(_cmd),
     NSStringFromSelector(@selector(initWithModel:sessionEntityName:userEntityName:clientEntityName:loginPath:))];
    return nil;
}

#pragma mark - Requests

-(NSURLSessionDataTask *)loginWithURLSession:(NSURLSession *)urlSession
                                  completion:(void (^)(NSError *))completionBlock
{
    if (!self.clientResourceID ||
        !self.clientSecret) {
        
        [NSException raise:NSInternalInconsistencyException
                    format:@"clientResourceID and clientSecret are required for authentication"];
        
        return nil;
    }
    
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build login URL
    
    NSURL *loginUrl = [self.serverURL URLByAppendingPathComponent:self.loginPath];
    
    // put togeather POST body...
    
    NSEntityDescription *sessionEntity = _model.entitiesByName[self.sessionEntityName];
    
    Class sessionEntityClass = NSClassFromString(sessionEntity.managedObjectClassName);
    
    NSString *sessionTokenKey = [sessionEntityClass sessionTokenKey];
    
    NSString *sessionUserKey = [sessionEntityClass sessionUserKey];
    
    NSString *sessionClientKey = [sessionEntityClass sessionClientKey];
    
    NSEntityDescription *clientEntity = _model.entitiesByName[self.clientEntityName];
    
    Class clientEntityClass = NSClassFromString(clientEntity.managedObjectClassName);
    
    NSString *clientResourceIDKey = [clientEntityClass resourceIDKey];
    
    NSString *clientSecretKey = [clientEntityClass clientSecretKey];
    
    NSEntityDescription *userEntity = _model.entitiesByName[self.userEntityName];
    
    Class userEntityClass = NSClassFromString(userEntity.managedObjectClassName);
    
    NSString *usernameKey = [userEntityClass usernameKey];
    
    NSString *userPasswordKey = [userEntityClass userPasswordKey];
    
    NSMutableDictionary *loginJSONObject = [[NSMutableDictionary alloc] init];
    
    // need at least client info to login
    [loginJSONObject addEntriesFromDictionary:@{sessionClientKey:
                                                    @{clientResourceIDKey: self.clientResourceID,
                                                           clientSecretKey : self.clientSecret}}];
    
    // add user to authentication if available
    
    if (self.username && self.userPassword) {
        
        [loginJSONObject addEntriesFromDictionary:@{sessionUserKey: @{usernameKey: self.username, userPasswordKey : self.userPassword}}];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginUrl];
    
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:loginJSONObject
                                                       options:self.jsonWritingOption
                                                         error:nil];
    
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error) {
            
            completionBlock(error);
            
            return;
        }
        
        // error status codes
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode != 200) {
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"The login failed",
                                                               @"The login failed");
                
                NSError *loginFailedError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                                code:NOAPILoginFailedErrorCode
                                                            userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                completionBlock(loginFailedError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponse);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponse);
            
            return;
        }
        
        // get session token key
        
        NSString *token = jsonResponse[sessionTokenKey];
        
        if (!token) {
            
            completionBlock(self.invalidServerResponse);
            
            return;
        }
        
        // get user ID if availible
        
        NSNumber *userResourceID = jsonResponse[sessionUserKey];
        
        if (userResourceID) {
            
            self.userResourceID = userResourceID;
        }
        
        self.sessionToken = token;
        
        completionBlock(nil);
        
    }];
    
    [task resume];
    
    return task;
}

-(NSURLSessionDataTask *)getResource:(NSString *)resourceName
                              withID:(NSUInteger)resourceID
                          URLSession:(NSURLSession *)urlSession
                          completion:(void (^)(NSError *, NSDictionary *))completionBlock
{
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityWithResourceName:resourceName];
    
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
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Access to resource is denied",
                                                               @"Access to resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == NotFoundStatusCode) {
                
                completionBlock([self notFoundError], nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponse, nil);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponse, nil);
            
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
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL...
    
    Class entityClass = [self entityWithResourceName:resourceName];
    
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
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError, nil);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to create new resource is denied",
                                                               @"Permission to create new resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError, nil);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError, nil);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponse, nil);
            
            return;
        }
        
        // parse response
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:nil];
        
        if (!jsonResponse ||
            ![jsonResponse isKindOfClass:[NSDictionary class]]) {
            
            completionBlock(self.invalidServerResponse, nil);
            
            return;
        }
        
        // get new resource id
        
        NSEntityDescription *entity = _model.entitiesByName[resourceName];
        
        Class entityClass = NSClassFromString(entity.managedObjectClassName);
        
        NSString *resourceIDKey = [entityClass resourceIDKey];
        
        NSNumber *resourceID = jsonResponse[resourceIDKey];
        
        if (!resourceID) {
            
            completionBlock(self.invalidServerResponse, nil);
            
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
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityWithResourceName:resourceName];
    
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
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to edit resource is denied",
                                                               @"Permission to edit resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponse);
            
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
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityWithResourceName:resourceName];
    
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
            
            if (httpResponse.statusCode == UnauthorizedStatusCode) {
                
                completionBlock(self.unauthorizedError);
                return;
            }
            
            if (httpResponse.statusCode == ForbiddenStatusCode) {
                
                NSString *errorDescription = NSLocalizedString(@"Permission to delete resource is denied",
                                                               @"Permission to delete resource is denied");
                
                NSError *forbiddenError = [NSError errorWithDomain:NetworkObjectsErrorDomain
                                                              code:NOAPIForbiddenErrorCode
                                                          userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                
                completionBlock(forbiddenError);
                
                return;
            }
            
            if (httpResponse.statusCode == InternalServerErrorStatusCode) {
                
                completionBlock(self.serverError);
                
                return;
            }
            
            if (httpResponse.statusCode == BadRequestStatusCode) {
                
                completionBlock(self.badRequestError);
                
                return;
            }
            
            // else
            
            completionBlock(self.invalidServerResponse);
            
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
    // determine URL session
    if (!urlSession) {
        
        urlSession = [NSURLSession sharedSession];
    }
    
    // build URL
    
    Class entityClass = [self entityWithResourceName:resourceName];
    
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
                        format:@"Invalid JSON NSDicitionary"];
            
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
