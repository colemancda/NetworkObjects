//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/10/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import RoutingHTTPServer

/** This class that will broadcast a managed object context for the network. */

public class Server {
    
    // MARK: - Properties
    
    /** The server's data source. */
    public let dataSource: ServerDataSource
    
    /** The server's delegate. */
    public let delegate: ServerDelegate?
    
    /** The string that will be used to generate a URL for search requests. 
    NOTE: Must not conflict with the resourcePath of entities.*/
    public let searchPath: String?;
    
    /** Determines whether the exported JSON should have whitespace for easier readability. */
    public let prettyPrintJSON: Bool = false
    
    /** The name of the Integer attribute that will be used for identifying instances of entities. */
    public let resourceIDAttributeName: String = "ID"
    
    /** To enable HTTPS for all incoming connections set this value to an array appropriate for use in kCFStreamSSLCertificates SSL Settings. It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.  */
    public let sslIdentityAndCertificates: [AnyObject]?
    
    /** Boolean that caches whether permissions (dynamic access control) is enabled. */
    public let permissionsEnabled: Bool = false;
    
    /** The managed object model */
    public let managedObjectModel: NSManagedObjectModel
    
    /** Resource path strings mapped to entity descriptions. */
    public lazy var entitiesByResourcePath: [String: NSEntityDescription] = self.initEntitiesByResourcePath();
    
    // MARK: - Private Properties
    
    /** The underlying HTTP server. */
    private lazy var httpServer: HTTPServer = self.initHTTPServer();
    
    // MARK: - Initialization
    
    public init(dataSource: ServerDataSource, delegate: ServerDelegate?, managedObjectModel: NSManagedObjectModel, searchPath:String?, resourceIDAttributeName:String?, prettyPrintJSON:Bool, sslIdentityAndCertificates: [AnyObject]?, permissionsEnabled: Bool?) {
        
        // set required values
        self.dataSource = dataSource;
        self.managedObjectModel = managedObjectModel;
        
        // optional values
        if (delegate? != nil) {
            self.delegate = delegate!;
        }
        if (sslIdentityAndCertificates != nil) {
            self.sslIdentityAndCertificates = sslIdentityAndCertificates;
        }
        if (resourceIDAttributeName != nil) {
            self.resourceIDAttributeName = resourceIDAttributeName!;
        }
        if (permissionsEnabled != nil) {
            self.permissionsEnabled = permissionsEnabled!;
        }
        if (searchPath != nil) {
            self.searchPath = searchPath!
        }
    }
    
    /** Lazily initializes self.entitiesByResourcePath. */
    private func initEntitiesByResourcePath() -> [String: NSEntityDescription] {
        
        var entitiesByResourcePathDictionary = [String: NSEntityDescription]();
        
        for entity in managedObjectModel.entities as [NSEntityDescription] {
            
            if !entity.abstract {
                
                let path = self.dataSource.server(self, resourcePathForEntity: entity)
                
                entitiesByResourcePathDictionary[path] = entity
            }
        }
        
        return entitiesByResourcePathDictionary
    }
    
    // ** Configures the underlying HTTP server. */
    private func initHTTPServer() -> HTTPServer {
        
        let httpServer = HTTPServer(server: self);
        
        httpServer.setConnectionClass(HTTPConnection);
        
        // add HTTP REST handlers...
        
        for (path, entity) in self.entitiesByResourcePath {
            
            // MARK: HTTP Search Request Handler Block
            
            if (self.searchPath != nil) {
                
                let searchPathExpression = "/" + self.searchPath! + "/" + path
                
                let searchRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                    
                    let jsonErrorPointer = NSErrorPointer();
                    
                    let searchParameters = NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions.AllowFragments, error: jsonErrorPointer) as? [String: AnyObject]
                    
                    if ((jsonErrorPointer.memory != nil) || (searchParameters == nil)) {
                        
                        response.statusCode = ServerStatusCode.BadRequest.toRaw();
                        
                        return
                    }
                    
                    // create server request
                    
                    let serverRequest = ServerRequest(requestType: ServerRequestType.Search, connectionType: ServerConnectionType.HTTP, entity: entity, underlyingRequest: request, resourceID: nil, JSONObject: searchParameters, functionName: nil);
                    
                    
                    let (serverResponse, userInfo) = self.responseForSearchRequest(serverRequest)
                    
                    if serverResponse.statusCode != ServerStatusCode.OK {
                        
                        response.statusCode = serverResponse.statusCode.toRaw()
                    }
                    else {
                        
                        // respond with data
                        
                        let jsonSerializationError = NSErrorPointer()
                        
                        let jsonData = NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption(), error: jsonErrorPointer)
                        
                        if (jsonData == nil) {
                            
                            // tell the delegate about the error
                            self.delegate!.server(self, didEncounterInternalError: jsonErrorPointer.memory!, forRequest: serverRequest, userInfo: userInfo)
                            
                            response.statusCode = ServerStatusCode.InternalServerError.toRaw()
                            
                            return
                        }
                        
                        response.respondWithData(jsonData)
                    }
                    
                    // tell the delegate
                    
                    self.delegate!.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                httpServer.post(searchPathExpression, withBlock: searchRequestHandler)
            }
            
            // MARK: HTTP POST Request Handler Block
            
            let createInstancePathExpression = "/" + path
            
            let createInstanceRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                
                // get initial values
                
                let jsonObject = NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String: AnyObject]
                
                if (jsonObject == nil) {
                    
                    response.statusCode = ServerStatusCode.BadRequest.toRaw()
                    
                    return
                }
                
                // convert to server request
                let serverRequest = ServerRequest(requestType: ServerRequestType.POST, connectionType: ServerConnectionType.HTTP, entity: entity, underlyingRequest: request, resourceID: nil, JSONObject: jsonObject, functionName: nil)
                
                // process request and return a response
                let (serverResponse, userInfo) = self.responseForCreateRequest(serverRequest)
                
                if serverResponse.statusCode != ServerStatusCode.OK {
                    
                    response.statusCode = serverResponse.statusCode.toRaw()
                    
                    return
                }
                
                // write to socket
                
                let errorPointer = NSErrorPointer()
                
                let jsonData = NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption(), error: errorPointer)
                
                // could not serialize json response, internal error
                if (jsonData == nil) {
                    
                    self.delegate!.server(self, didEncounterInternalError: errorPointer.memory!, forRequest: serverRequest, userInfo: userInfo)
                    
                    response.statusCode = ServerStatusCode.InternalServerError.toRaw()
                    
                    return
                }
                
                // respond with serialized json
                response.respondWithData(jsonData);
                
                // tell the delegate
                self.delegate!.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
            }
            
            httpServer.post(createInstancePathExpression, withBlock: createInstanceRequestHandler)
            
            // setup routes for resource instances...
            
            // MARK: HTTP GET, PUT, DELETE Request Handler Block
            
            let instancePathExpression = "{^/" + path + "(\\d+)}"
            
            let instanceRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                
                let parameters = request.params
                
                let captures: AnyObject? = parameters["captures"]
                
                // had to do this in more lines of code becuase the compiler would complain
                let capturesArray = captures as [String]
                
                let resourceIDInt = capturesArray.first?.toInt()
                
                let resourceID = UInt(resourceIDInt!)
                
                // get json body
                
                let jsonBody: AnyObject? = NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions.AllowFragments, error: nil)
                
                let jsonObject = jsonBody as? [String: AnyObject]
                
                // JSON recieved is not a dictionary
                if (jsonBody != nil) && (jsonObject == nil) {
                    
                    response.statusCode = ServerStatusCode.BadRequest.toRaw()
                    
                    return
                }
                
                // GET
                if request.method() == "GET" {
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.GET, connectionType: ServerConnectionType.HTTP, entity: entity, underlyingRequest: request, resourceID: resourceID, JSONObject: jsonObject, functionName: nil)
                    
                    // should not have a body
                    
                    if (jsonBody != nil) {
                        
                        response.statusCode = ServerStatusCode.BadRequest.toRaw()
                        
                        return
                    }
                    
                    // get response
                    let (serverResponse, userInfo) = self.responseForGetRequest(serverRequest)
                    
                    // serialize json data
                    
                    let error = NSErrorPointer()
                    
                    let jsonData = NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption(), error: error);
                    
                    // could not serialize json response, internal error
                    if (jsonData == nil) {
                        
                        self.delegate!.server(self, didEncounterInternalError: error.memory!, forRequest: serverRequest, userInfo: userInfo)
                        
                        response.statusCode = ServerStatusCode.InternalServerError.toRaw()
                        
                        return
                    }
                    
                    // respond with serialized json
                    response.respondWithData(jsonData);
                    
                    // tell the delegate
                    self.delegate!.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                // PUT
                if request.method() == "PUT" {
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.PUT, connectionType: ServerConnectionType.HTTP, entity: entity, underlyingRequest: request, resourceID: resourceID, JSONObject: jsonObject, functionName: nil)
                    
                    // should have a body
                    
                    if (jsonBody == nil) {
                        
                        response.statusCode = ServerStatusCode.BadRequest.toRaw()
                        
                        return
                    }
                    
                    // get response
                    let (serverResponse, userInfo) = self.responseForEditRequest(serverRequest)
                    
                    // serialize json data
                    
                    let error = NSErrorPointer()
                    
                    let jsonData = NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption(), error: error);
                    
                    // could not serialize json response, internal error
                    if (jsonData == nil) {
                        
                        self.delegate!.server(self, didEncounterInternalError: error.memory!, forRequest: serverRequest, userInfo: userInfo)
                        
                        response.statusCode = ServerStatusCode.InternalServerError.toRaw()
                        
                        return
                    }
                    
                    // respond with serialized json
                    response.respondWithData(jsonData);
                    
                    // tell the delegate
                    self.delegate!.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                // DELETE
                if request.method() == "DELETE" {
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.DELETE, connectionType: ServerConnectionType.HTTP, entity: entity, underlyingRequest: request, resourceID: resourceID, JSONObject: jsonObject, functionName: nil)
                    
                    // should not have a body
                    
                    if (jsonBody != nil) {
                        
                        response.statusCode = ServerStatusCode.BadRequest.toRaw()
                        
                        return
                    }
                    
                    // get response
                    let (serverResponse, userInfo) = self.responseForDeleteRequest(serverRequest)
                    
                    // respond with status code
                    response.statusCode = serverResponse.statusCode.toRaw()
                    
                    // tell the delegate
                    self.delegate!.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
            }
            
            // GET (read resource)
            httpServer.get(instancePathExpression, withBlock: instanceRequestHandler);
            
            // PUT (edit resource)
            httpServer.put(instancePathExpression, withBlock: instanceRequestHandler);
            
            // DELETE (delete resource)
            httpServer.delete(instancePathExpression, withBlock: instanceRequestHandler);
            
            // Add function routes...
            
            let functions = self.dataSource.server(self, functionsForEntity: entity)
            
            for functionName in functions {
                
                // MARK: HTTP Function Request Handler Block
                
                let functionExpressionPath = "{^/" + path + "/(\\d+)/" + functionName + "}"
                
                let functionRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                    
                    let parameters = request.params
                    
                    let captures: AnyObject? = parameters["captures"]
                    
                    // had to do this in more lines of code becuase the compiler would complain
                    let capturesArray = captures as [String]
                    
                    let resourceIDInt = capturesArray.first?.toInt()
                    
                    let resourceID = UInt(resourceIDInt!)
                    
                    // get json body
                    
                    let jsonBody: AnyObject? = NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions.AllowFragments, error: nil)
                    
                    let jsonObject = jsonBody as? [String: AnyObject]
                    
                    // JSON recieved is not a dictionary
                    if (jsonBody != nil) && (jsonObject == nil) {
                        
                        response.statusCode = ServerStatusCode.BadRequest.toRaw()
                        
                        return
                    }
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.Function, connectionType: ServerConnectionType.HTTP, entity: entity, underlyingRequest: request, resourceID: resourceID, JSONObject: jsonObject, functionName: functionName)
                    
                    // get response
                    let (serverResponse, userInfo) = self.responseForFunctionRequest(serverRequest)
                    
                    // respond with JSON if availible
                    if serverResponse.JSONResponse != nil  {
                        
                        // write to socket
                        
                        let errorPointer = NSErrorPointer()
                        
                        let jsonData = NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption(), error: errorPointer)
                        
                        // could not serialize json response, internal error
                        if (jsonData == nil) {
                            
                            self.delegate!.server(self, didEncounterInternalError: errorPointer.memory!, forRequest: serverRequest, userInfo: userInfo)
                            
                            response.statusCode = ServerStatusCode.InternalServerError.toRaw()
                            
                            return
                        }
                        
                        // respond with serialized json
                        response.respondWithData(jsonData);
                    }
                    
                    // set function status code
                    response.statusCode = serverResponse.statusCode.toRaw()
                    
                    // tell the delegate
                    self.delegate!.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                httpServer.post(functionExpressionPath, withBlock: functionRequestHandler)
            }
        }
        
        return httpServer;
    }
    
    // MARK: - Server Control
    
    /** Starts broadcasting the server. */
    public func start(onPort port: UInt) -> NSError? {
        
        let errorPointer: NSErrorPointer = NSErrorPointer()
        
        let success: Bool = self.httpServer.start(errorPointer);
        
        if !success {
            
            return errorPointer.memory
        }
        else {
            
            return nil
        }
    }
    
    /** Stops broadcasting the server. */
    public func stop() {
        
        self.httpServer.stop();
    }
    
    // MARK: - Request Handlers
    
    private func responseForSearchRequest(request: ServerRequest) -> (ServerResponse, [ServerUserInfoKey: AnyObject]) {
        
        var userInfo = [ServerUserInfoKey: AnyObject]()
        
        // get search parameters
        
        /** The JSON-formatted dictionary */
        let searchParameters = request.JSONObject
        
        let entity = request.entity
        
        // get the context this request will use
        
        let context = self.dataSource.server(self, managedObjectContextForRequest: request)
        
        userInfo[ServerUserInfoKey.ManagedObjectContext] = context
        
        // Put togeather fetch request
        
        let fetchRequest = NSFetchRequest(entityName: entity.name)
        
        // add search parameters...
        
        // MARK: Predicate
        
        let predicateKeyObject: AnyObject? = searchParameters![SearchParameter.PredicateKey.toRaw()]
        
        let predicateKey = predicateKeyObject as? String
        
        let jsonPredicateValue: AnyObject? = searchParameters![SearchParameter.PredicateValue.toRaw()]
        
        let predicateOperatorObject: AnyObject? = searchParameters![SearchParameter.PredicateOperator.toRaw()]
        
        let predicateOperatorNumber = predicateOperatorObject as? UInt
        
        let predicateOperator = NSPredicateOperatorType.fromRaw(predicateOperatorNumber!)
        
        if (predicateKey != nil) && (predicateOperator != nil) && (jsonPredicateValue != nil) {
            
            // validate operator
            
            if predicateOperatorNumber == NSPredicateOperatorType.CustomSelectorPredicateOperatorType.toRaw() {
                
                let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                
                return (response, userInfo)
            }
            
            // convert to Core Data value...
            var value: AnyObject?
            
            // one of these will be nil
            let relationshipDescription: NSRelationshipDescription? = entity.relationshipsByName[predicateKey!] as? NSRelationshipDescription
            
            let attributeDescription: NSRelationshipDescription? = entity.attributesByName[predicateKey!] as? NSRelationshipDescription
            
            // validate that key is attribute or relationship
            if (relationshipDescription == nil) && (attributeDescription == nil) {
                
                let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                
                return (response, userInfo)
            }
            
            // attribute value
            if attributeDescription != nil {
                
                // set value
                value = entity.attributeValueForJSONCompatibleValue(JSONCompatibleValue: jsonPredicateValue!, forAttribute: predicateKey!)!
            }
            
            // relationship value
            if relationshipDescription != nil {
                
                // to-one
                if !relationshipDescription!.toMany {
                    
                    let resourceID = jsonPredicateValue as? UInt
                    
                    // verify
                    if resourceID == nil {
                        
                        let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                        
                        return (response, userInfo)
                    }
                    
                    let (fetchedResource, error) = self.fetchEntity(entity, withResourceID: resourceID!, usingContext: context, shouldPrefetch: false)
                    
                    // error fetching
                    if error != nil {
                        
                        // tell delegate
                        self.delegate?.server(self, didEncounterInternalError: error!, forRequest: request, userInfo: userInfo)
                        
                        let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
                        
                        return (response, userInfo)
                    }
                    
                    // not found
                    if fetchedResource == nil {
                        
                        let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                        
                        return (response, userInfo)
                    }
                    
                    // set value
                    value = fetchedResource!
                }
                
                // to-many relationships
                else {
                    
                    let resourceIDs = jsonPredicateValue as? [UInt]
                    
                    // verify
                    
                    if resourceIDs == nil {
                        
                        let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                        
                        return (response, userInfo)
                    }
                    
                    let (fetchResult, error) = self.fetchEntity(entity, withResourceIDs: resourceIDs!, usingContext: context, shouldPrefetch: false)
                    
                    // error fetching
                    if error != nil {
                        
                        // tell delegate
                        self.delegate?.server(self, didEncounterInternalError: error!, forRequest: request, userInfo: userInfo)
                        
                        let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
                        
                        return (response, userInfo)
                    }
                    
                    // not found
                    if fetchResult.count != jsonPredicateValue?.count {
                        
                        let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                        
                        return (response, userInfo)
                    }
                    
                    // set value
                    value = fetchResult
                }
            }
            
            // add optional parameters...
            
            // MARK: Predicate Options
            
            var option = NSComparisonPredicateOptions.NormalizedPredicateOption // default value
            
            let optionNumberObject: AnyObject? = searchParameters![SearchParameter.PredicateOption.toRaw()]
            
            if optionNumberObject != nil {
                
                let optionNumber = optionNumberObject as? UInt
                
                // validate NSUInteger bitmask
                
                if optionNumber == nil || optionNumber != NSComparisonPredicateOptions.NormalizedPredicateOption.toRaw() || optionNumber != NSComparisonPredicateOptions.DiacriticInsensitivePredicateOption.toRaw() || optionNumber != NSComparisonPredicateOptions.CaseInsensitivePredicateOption.toRaw() {
                    
                    let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                    
                    return (response, userInfo)
                }
                
                option = NSComparisonPredicateOptions.fromRaw(optionNumber!)!
            }
            
            // MARK: Predicate Modifier
            
            var modifier: NSComparisonPredicateModifier? = NSComparisonPredicateModifier.DirectPredicateModifier // default value
            
            let modifierNumberObject: AnyObject? = searchParameters![SearchParameter.PredicateModifier.toRaw()]
            
            if modifierNumberObject != nil {
                
                let modifierNumber = modifierNumberObject as? UInt
                
                modifier = NSComparisonPredicateModifier.fromRaw(modifierNumber!)!
                
                // validate
                
                if modifier == nil {
                    
                    let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                    
                    return (response, userInfo)
                }
            }
            
            // create predicate...
            
            let leftPredicateExpression = NSExpression(forKeyPath: predicateKey!)
            
            let rightPredicateExpression = NSExpression(forConstantValue: value!)
            
            fetchRequest.predicate = NSComparisonPredicate(leftExpression: leftPredicateExpression, rightExpression: rightPredicateExpression, modifier: modifier!, type: predicateOperator!, options: option)
        }
        
        // MARK: Sort Descriptors
        
        let sortDescriptorsJSONArrayObject: AnyObject? = searchParameters![SearchParameter.SortDescriptors.toRaw()]
        
        let sortDescriptorsJSONArray = sortDescriptorsJSONArrayObject as? [[String: Bool]]
        
        if sortDescriptorsJSONArrayObject != nil {
            
            // empty mutable array
            var sortDescriptors = [NSSortDescriptor]()
            
            // validate
            if (sortDescriptorsJSONArray == nil || sortDescriptorsJSONArray?.isEmpty != nil) {
                
                let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                
                return (response, userInfo)
            }
            
            for sortDescriptorJSON:[String: Bool] in sortDescriptorsJSONArray! {
                
                // validate JSON
                
                if sortDescriptorJSON.keys.array.count != 1 {
                    
                    let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                    
                    return (response, userInfo)
                }
                
                let key = sortDescriptorJSON.keys.first
                
                let ascending = sortDescriptorJSON.values.first
                
                let sort = NSSortDescriptor(key: key!, ascending: ascending!)
                
                sortDescriptors.append(sort)
            }
            
            fetchRequest.sortDescriptors = sortDescriptors
        }
        
        // default Sort Descriptor
        else {
            
            let defaultSortDescriptor = NSSortDescriptor(key: self.resourceIDAttributeName, ascending: true)
            
            fetchRequest.sortDescriptors = [defaultSortDescriptor]
        }
        
        // MARK: Fetch Limit
        
        let fetchLimitObject: AnyObject? = searchParameters![SearchParameter.FetchLimit.toRaw()]
        
        let fetchLimitNumber = fetchLimitObject as? Int
        
        if fetchLimitObject != nil {
            
            // validate
            if fetchLimitNumber == nil {
                
                let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                
                return (response, userInfo)
            }
            
            fetchRequest.fetchLimit = fetchLimitNumber!
        }
        
        // MARK: Fetch Offset
        
        let fetchOffsetObject: AnyObject? = searchParameters![SearchParameter.FetchLimit.toRaw()]
        
        let fetchOffsetNumber = fetchOffsetObject as? Int
        
        if fetchOffsetObject != nil {
            
            // validate
            if fetchOffsetNumber == nil {
                
                let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                
                return (response, userInfo)
            }
            
            fetchRequest.fetchOffset = fetchOffsetNumber!
        }
        
        // MARK: Includes Subentities
        
        let includesSubentitiesObject: AnyObject? = searchParameters![SearchParameter.IncludesSubentities.toRaw()]
        
        let includesSubentities = includesSubentitiesObject as? Bool
        
        if includesSubentitiesObject != nil {
            
            // validate
            if includesSubentities == nil {
                
                let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
                
                return (response, userInfo)
            }
            
            fetchRequest.includesSubentities = includesSubentities!
        }
        
        // prefetch resourceID
        
        fetchRequest.returnsObjectsAsFaults = false
        
        fetchRequest.includesPropertyValues = true
        
        // add fully parsed fetch request to userInfo
        
        userInfo[ServerUserInfoKey.FetchRequest] = fetchRequest
        
        // check for permission (now that we have fully parsed the request)
        
        if self.delegate != nil {
            
            let statusCode = self.delegate?.server(self, statusCodeForRequest: request, managedObject: nil)
            
            if statusCode != ServerStatusCode.OK {
                
                let response = ServerResponse(statusCode: statusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // execute fetch request...
        
        let fetchError = NSErrorPointer()
        
        var results: [NSManagedObject]?
        
        context.performBlockAndWait { () -> Void in
            
            results = context.executeFetchRequest(fetchRequest, error: fetchError) as? [NSManagedObject]
        }
        
        // invalid fetch
        if fetchError.memory != nil {
            
            let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // optionally filter results
        if self.permissionsEnabled {
            
            var filteredResults = [NSManagedObject]()
            
            for managedObject in results! {
                
                var resourceID: Int?
                
                context.performBlockAndWait({ () -> Void in
                    
                    resourceID = managedObject.valueForKey(self.resourceIDAttributeName) as? Int
                })
                
                // permission to view resource
                
                
            }
        }
        
        return (ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: ""), [ServerUserInfoKey.ResourceID:0])
    }
    
    private func responseForCreateRequest(request: ServerRequest) -> (ServerResponse, [ServerUserInfoKey: AnyObject]) {
        
        return (ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: ""), [ServerUserInfoKey.ResourceID:0])
    }
    
    private func responseForGetRequest(request: ServerRequest) -> (ServerResponse, [ServerUserInfoKey: AnyObject]) {
        
        return (ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: ""), [ServerUserInfoKey.ResourceID:0])
    }
    
    private func responseForEditRequest(request: ServerRequest) -> (ServerResponse, [ServerUserInfoKey: AnyObject]) {
        
        return (ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: ""), [ServerUserInfoKey.ResourceID:0])
    }
    
    private func responseForDeleteRequest(request: ServerRequest) -> (ServerResponse, [ServerUserInfoKey: AnyObject]) {
        
        return (ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: ""), [ServerUserInfoKey.ResourceID:0])
    }
    
    private func responseForFunctionRequest(request: ServerRequest) -> (ServerResponse, [ServerUserInfoKey: AnyObject]) {
        
        return (ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: ""), [ServerUserInfoKey.ResourceID:0])
    }
    
    // MARK: - Internal Methods
    
    private func jsonWritingOption() -> NSJSONWritingOptions {
        
        if self.prettyPrintJSON {
            
            return NSJSONWritingOptions.PrettyPrinted;
        }
        
        else {
            
            return NSJSONWritingOptions.allZeros;
        }
    }
    
    private func fetchEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, usingContext context: NSManagedObjectContext, shouldPrefetch: Bool) -> (NSManagedObject?, NSError?) {
        
        let fetchRequest = NSFetchRequest(entityName: entity.name)
        
        fetchRequest.fetchLimit = 1
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        if shouldPrefetch {
            
            fetchRequest.returnsObjectsAsFaults = false
        }
        else {
            
            fetchRequest.includesPropertyValues = false
        }
        
        let error = NSErrorPointer()
        
        var result: [NSManagedObject]?
        
        context.performBlockAndWait { () -> Void in
            
            result = context.executeFetchRequest(fetchRequest, error: error) as? [NSManagedObject]
        }
        
        return (result!.first, error.memory)
    }
    
    private func fetchEntity(entity: NSEntityDescription, withResourceIDs resourceIDs: [UInt], usingContext context: NSManagedObjectContext, shouldPrefetch: Bool) -> ([NSManagedObject], NSError?) {
        
        let fetchRequest = NSFetchRequest(entityName: entity.name)
        
        fetchRequest.fetchLimit = 1
        
        fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: self.resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceIDs), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.InPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
        
        if shouldPrefetch {
            
            fetchRequest.returnsObjectsAsFaults = false
        }
        else {
            
            fetchRequest.includesPropertyValues = false
        }
        
        let error = NSErrorPointer()
        
        var result: [NSManagedObject]?
        
        context.performBlockAndWait { () -> Void in
            
            result = context.executeFetchRequest(fetchRequest, error: error) as? [NSManagedObject]
        }
        
        return (result!, error.memory)
        
    }
    
    private func JSONRepresentationOfManagedObject(managedObject: NSManagedObject) -> [String: AnyObject] {
        
        return ["":0]
    }
    
    private func verifyEditResource(resource: NSManagedObject, forRequest request:ServerRequest, context: NSManagedObjectContext, newValues: [String: AnyObject]) -> (ServerStatusCode, [String: AnyObject], NSError?) {
        
        return (ServerStatusCode.MethodNotAllowed, ["":0], nil)
    }
    
    // MARK: - Private Classes
    
    private class HTTPConnection: RoutingConnection {
        
        override func isSecureServer() -> Bool {
            
            return (self.sslIdentityAndCertificates() != nil)
        }
        
        override func sslIdentityAndCertificates() -> [AnyObject]! {
            
            let cocoaHTTPServer: CocoaHTTPServer.HTTPServer = self.config().server;
            
            let httpServer: HTTPServer = cocoaHTTPServer as HTTPServer;
            
            let server = httpServer.server;
            
            return server.sslIdentityAndCertificates;
        }
    }
}

// MARK: - Supporting Classes

public class ServerRequest {
    
    let requestType: ServerRequestType
    
    let connectionType: ServerConnectionType
    
    let entity: NSEntityDescription
    
    let underlyingRequest: AnyObject
    
    /** The resourceID of the requested instance. Will be nil for @c POST (search or create instance) requests. */
    
    let resourceID: UInt?
    
    let JSONObject: [String: AnyObject]?
    
    let functionName: String?
    
    init(requestType: ServerRequestType, connectionType: ServerConnectionType, entity: NSEntityDescription, underlyingRequest: AnyObject, resourceID: UInt?, JSONObject: [String: AnyObject]?, functionName: String?) {
        
        self.requestType = requestType
        self.connectionType = connectionType
        self.entity = entity
        self.underlyingRequest = underlyingRequest
        
        if (resourceID != nil) {
            self.resourceID = resourceID
        }
        if (JSONObject != nil) {
            self.JSONObject = JSONObject
        }
        if (functionName != nil) {
            self.functionName = functionName
        }
    }
}

public class ServerResponse {
    
    let statusCode: ServerStatusCode
    
    /** A JSON-compatible array or dictionary that will be sent as a response. */
    
    let JSONResponse: AnyObject?
    
    init(statusCode: ServerStatusCode, JSONResponse: AnyObject?) {
        
        self.statusCode = statusCode
        
        self.JSONResponse = JSONResponse
    }
}

public class HTTPServer: RoutingHTTPServer {
    
    let server: Server;
    
    init(server: Server) {
        
        self.server = server;
    }
}

// MARK: - Protocols

/** Server Data Source Protocol */
public protocol ServerDataSource {
    
    /** Data Source should return a unique string will represent the entity when broadcasting the managed object context.
    */
    func server(Server, resourcePathForEntity entity: NSEntityDescription) -> String;
    
    /** Asks the data source for a managed object context to access. In simple setups the data source can always return the same context, but for higly concurrent servers, the data source create a separate context for each request (configured with the same backing store). */
    func server(Server, managedObjectContextForRequest request: ServerRequest) -> NSManagedObjectContext
    
    /** Asks the data source for a numerical identifier for a newly create object. It is the data source's responsibility to keep track of the resource IDs of instances of an entity. This method should return 0 the for the first instance of an entity and increment by 1 for each newly created instance. */
    func server(Server, newResourceIDForEntity entity: NSEntityDescription) -> UInt
    
    /** Should return an array of string specifing the names of functions an entity declares. */
    func server(Server, functionsForEntity entity: NSEntityDescription) -> [String]
    
    /** Asks the data source to perform a function on a managed object. 
    
    Returns a tuple containing a ServerFunctionCode and JSON-compatible dictionary.
    */
    func server(Server, performFunction functionName:String, forManagedObject managedObject: NSManagedObject,
        context: NSManagedObjectContext, recievedJsonObject: [String: AnyObject]?) -> (ServerFunctionCode, [String: AnyObject]?)
}

/** Server Delegate Protocol */
public protocol ServerDelegate {
    
    /** Notifies the delegate that an internal error ocurred (e.g. could not serialize a JSON object). */
    func server(Server, didEncounterInternalError error: NSError, forRequest request: ServerRequest, userInfo: [ServerUserInfoKey: AnyObject])
    
    /** Asks the delegate for a status code for a request. Any response that is not ServerStatusCode.OK, will be forwarded to the client and the request will end. This can be used to implement authentication or access control. */
    func server(Server, statusCodeForRequest request: ServerRequest, managedObject: NSManagedObject?) -> ServerStatusCode
    
    /** Notifies the delegate that a request was performed successfully. */
    func server(Server, didPerformRequest request: ServerRequest, withResponse response: ServerResponse, userInfo: [ServerUserInfoKey: AnyObject])
    
    /** Asks the delegate for access control for a request. Server must have its permissions enabled for this method to be called. */
    func server(Server, permissionForRequest request: ServerRequest, managedObject: NSManagedObject?, context: NSManagedObjectContext?, key: String?)
}

// MARK: - Enumerations

/** Keys used in userInfo dictionaries. */
public enum ServerUserInfoKey: String {
    
    case FetchRequest = "FetchRequest"
    
    case ResourceID = "ResourceID"
    
    case ManagedObject = "ManagedObject"
    
    case ManagedObjectContext = "ManagedObjectContext"
    
    case NewValues = "NewValues"
    
    case FunctionName = "FunctionName"
    
    case FunctionJSONInput = "FunctionJSONInput"
    
    case FunctionJSONOutput = "FunctionJSONOutput"
}

/** Defines the different search parameters */
public enum SearchParameter: String {
    
    case PredicateKey = "Predicate"
    case PredicateValue = "PredicateValue"
    case PredicateOperator = "PredicateOperator"
    case PredicateOption = "PredicateOption"
    case PredicateModifier = "PredicateModifier"
    case FetchLimit = "FetchLimit"
    case FetchOffset = "FetchOffset"
    case IncludesSubentities = "IncludesSubentities"
    case SortDescriptors = "SortDescriptors"
    
};

/** These are HTTP status codes used with NOServer instances. */
public enum ServerStatusCode: Int {
    
    /** OK status code. */
    case OK = 200
    
    /** Bad request status code. */
    case BadRequest = 400
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    case Unauthorized = 401 // not logged in
    
    case PaymentRequired = 402
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    case Forbidden = 403 // item is invisible to user or api app
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    case NotFound = 404 // item doesnt exist
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    case MethodNotAllowed = 405
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    case Conflict = 409 // user already exists
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    case InternalServerError = 500
    
};

/** Server Permission Enumeration */

public enum ServerPermission {
    
    /**  No access permission */
    case NoAccess
    
    /**  Read Only permission */
    case ReadOnly
    
    /**  Read and Write permission */
    case EditPermission
}

/** Server Request Type */
public enum ServerRequestType {
    
    /** Undetermined request */
    case Undetermined
    
    /** GET request */
    case GET
    
    /** PUT (edit) request */
    case PUT
    
    /** DELETE request */
    case DELETE
    
    /** POST (create new) request */
    case POST
    
    /** Search request */
    case Search
    
    /** Function request */
    case Function
}

/** Resource Function constants */
public enum ServerFunctionCode: Int {
    
    /** The function performed successfully */
    case PerformedSuccesfully = 200
    
    /** The function recieved an invalid JSON object */
    case RecievedInvalidJSONObject = 400
    
    /** The function cannot be performed, possibly due to session permissions */
    case CannotPerformFunction = 403
    
    /** There was an internal error while performing the function */
    case InternalErrorPerformingFunction = 500
    
    func toServerStatusCode() -> ServerStatusCode {
        
        return ServerStatusCode.fromRaw(self.toRaw())!
    }
};

/** Defines the connection protocols used communicate with the server. */
public enum ServerConnectionType {
    
    /** The connection to the server was made via the HTTP protocol. */
    case HTTP
    
    /** The connection to the server was made via the WebSockets protocol. */
    case WebSocket
}

