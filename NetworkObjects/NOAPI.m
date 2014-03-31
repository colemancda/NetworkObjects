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
#import "NOServerConstants.h"

@interface NOAPI ()


@end

@implementation NOAPI



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
            
            completionBlock(self.invalidServerResponseError);
            
            return;
        }
        
        completionBlock(nil);
        
    }];
    
    [dataTask resume];
    
    return dataTask;
}


@end
