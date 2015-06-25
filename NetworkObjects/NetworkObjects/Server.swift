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

/** This class will broadcast a managed object context over the network. */

public class Server {
    
    // MARK: - Properties
    
    /** The server's data source. */
    public let dataSource: ServerDataSource
    
    /** The server's delegate. */
    public let delegate: ServerDelegate?
    
    /** The string that will be used to generate a URL for search requests. 
    NOTE: Must not conflict with the resourcePath of entities.*/
    public let searchPath: String?
    
    /** Determines whether the exported JSON should have whitespace for easier readability. */
    public let prettyPrintJSON: Bool
    
    /** The name of the Integer attribute that will be used for identifying instances of entities. */
    public let resourceIDAttributeName: String
    
    /** To enable HTTPS for all incoming connections set this value to an array appropriate for use in kCFStreamSSLCertificates SSL Settings. It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.  */
    public let sslIdentityAndCertificates: [AnyObject]?
    
    /** Boolean that caches whether permissions (dynamic access control) is enabled. */
    public let permissionsEnabled: Bool
    
    /** The managed object model */
    public let managedObjectModel: NSManagedObjectModel
    
    /** The underlying HTTP server. */
    public lazy var httpServer: ServerHTTPServer = self.initHTTPServer()
    
    // MARK: - Initialization
    
    public init(dataSource: ServerDataSource,
        delegate: ServerDelegate? = nil,
        managedObjectModel: NSManagedObjectModel,
        searchPath: String? = "search",
        resourceIDAttributeName: String = "id",
        prettyPrintJSON: Bool = false,
        sslIdentityAndCertificates: [AnyObject]? = nil,
        permissionsEnabled: Bool = false) {
            
            self.dataSource = dataSource
            self.managedObjectModel = managedObjectModel.copy() as! NSManagedObjectModel
            self.delegate = delegate
            self.sslIdentityAndCertificates = sslIdentityAndCertificates
            self.resourceIDAttributeName = resourceIDAttributeName
            self.permissionsEnabled = permissionsEnabled
            self.searchPath = searchPath
            self.prettyPrintJSON = prettyPrintJSON
            
            // add resource ID programatically
            self.managedObjectModel.addResourceIDAttribute(resourceIDAttributeName)
    }
    
    // ** Configures the underlying HTTP server. */
    private func initHTTPServer() -> ServerHTTPServer {
        
        let httpServer = ServerHTTPServer(server: self)
        
        httpServer.setConnectionClass(ServerHTTPConnection)
        
        // set default header
        
        httpServer.setDefaultHeaders(["Server": "NetworkObjects/\(NetworkObjectsVersionNumber)"])
        
        // add HTTP REST handlers...
        
        for (path, entity) in self.managedObjectModel.entitiesByName as [String: NSEntityDescription] {
            
            // MARK: HTTP Search Request Handler Block
            
            if (self.searchPath != nil) {
                
                let searchPathExpression = "/" + self.searchPath! + "/" + path
                
                let searchRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                    
                    let searchParameters = NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions()) as? [String: AnyObject]
                    
                    let serverRequest = ServerRequest(requestType: ServerRequestType.Search,
                        connectionType: ServerConnectionType.HTTP,
                        entity: entity,
                        underlyingRequest: request,
                        resourceID: nil,
                        JSONObject: searchParameters,
                        functionName: nil,
                        headers: request.headers as! [String: String])
                    
                    // seach requests require HTTP body
                    if searchParameters == nil {
                        
                        // return BadRequest
                        response.statusCode = ServerStatusCode.BadRequest.rawValue
                        
                        // tell delegate
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil), userInfo: [String : AnyObject]())
                        
                        return
                    }
                    
                    // create server request
                    
                    let (serverResponse, userInfo) = self.responseForSearchRequest(serverRequest)
                    
                    // return error
                    if serverResponse.statusCode != ServerStatusCode.OK {
                        
                        // return error status code
                        response.statusCode = serverResponse.statusCode.rawValue
                        
                        // tell delegate
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                        
                        return
                    }
                    
                    // respond with data
                    
                let jsonData: NSData?
                    do {
                        jsonData = try NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption())
                    } catch _ {
                        jsonData = nil
                    }
                    
                    response.respondWithData(jsonData)
                    
                    // tell the delegate
                    
                    self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                httpServer.post(searchPathExpression, withBlock: searchRequestHandler)
            }
            
            // only Search is supported for absract entities
            
            if entity.abstract {
                
                continue
            }
            
            // MARK: HTTP POST Request Handler Block
            
            let createInstancePathExpression = "/" + path
            
            let createInstanceRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                
                // get initial values
                
                let jsonObject = NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions()) as? [String: AnyObject]
                
                // convert to server request
                let serverRequest = ServerRequest(requestType: ServerRequestType.POST,
                    connectionType: ServerConnectionType.HTTP,
                    entity: entity,
                    underlyingRequest: request,
                    resourceID: nil,
                    JSONObject: jsonObject,
                    functionName: nil,
                    headers: request.headers as! [String: String])
                
                // process request and return a response
                let (serverResponse, userInfo) = self.responseForCreateRequest(serverRequest)
                
                if serverResponse.statusCode != ServerStatusCode.OK {
                    
                    response.statusCode = serverResponse.statusCode.rawValue
                    
                    self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                    
                    return
                }
                
                // write to socket
                
                let jsonData = try! NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption())
                
                // respond with serialized json
                response.respondWithData(jsonData)
                
                // tell the delegate
                self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
            }
            
            httpServer.post(createInstancePathExpression, withBlock: createInstanceRequestHandler)
            
            // setup routes for resource instances...
            
            // MARK: HTTP GET, PUT, DELETE Request Handler Block
            
            let instancePathExpression = "{^/" + path + "/(\\d+)}"
            
            let instanceRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                
                // get resource ID
                
                let parameters = request.params
                
                let captures = parameters["captures"] as! [String]
                
                let resourceID = UInt(Int(captures.first!)!)
                
                // get json body
                
                let jsonObject = NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions()) as? [String: AnyObject]
                
                // GET
                if request.method() == "GET" {
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.GET,
                        connectionType: ServerConnectionType.HTTP,
                        entity: entity,
                        underlyingRequest: request,
                        resourceID: resourceID,
                        JSONObject: jsonObject,
                        functionName: nil,
                        headers: request.headers as! [String: String])
                    
                    // should not have a body (also validate thate JSON is dictionary
                    
                    if jsonObject != nil {
                        
                        response.statusCode = ServerStatusCode.BadRequest.rawValue
                        
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil), userInfo: [String: AnyObject]())
                        
                        return
                    }
                    
                    // get response
                    let (serverResponse, userInfo) = self.responseForGetRequest(serverRequest)
                    
                    // check for error status code
                    if serverResponse.statusCode != ServerStatusCode.OK {
                        
                        response.statusCode = serverResponse.statusCode.rawValue
                        
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                        
                        return
                    }
                    
                    // serialize json data
                    
                    let jsonData = try! NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption())
                    
                    // respond with serialized json
                    response.respondWithData(jsonData)
                    
                    // tell the delegate
                    self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                // PUT
                if request.method() == "PUT" {
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.PUT,
                        connectionType: ServerConnectionType.HTTP,
                        entity: entity,
                        underlyingRequest: request,
                        resourceID: resourceID,
                        JSONObject: jsonObject,
                        functionName: nil,
                        headers: request.headers as! [String: String])
                    
                    // should have a body (and not a empty JSON dicitonary)
                    
                    if (jsonObject == nil || jsonObject?.count == 0) {
                        
                        response.statusCode = ServerStatusCode.BadRequest.rawValue
                        
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil), userInfo: [String: AnyObject]())
                        
                        return
                    }
                    
                    // get response
                    let (serverResponse, userInfo) = self.responseForEditRequest(serverRequest)
                    
                    // check for error status code
                    if serverResponse.statusCode != ServerStatusCode.OK {
                        
                        response.statusCode = serverResponse.statusCode.rawValue
                        
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                        
                        return
                    }
                    
                    // respond with status code
                    response.statusCode = ServerStatusCode.OK.rawValue
                    
                    // tell the delegate
                    self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                // DELETE
                if request.method() == "DELETE" {
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.DELETE,
                        connectionType: ServerConnectionType.HTTP,
                        entity: entity,
                        underlyingRequest: request,
                        resourceID: resourceID,
                        JSONObject: jsonObject,
                        functionName: nil,
                        headers: request.headers as! [String: String])
                    
                    // should not have a body
                    
                    if (jsonObject != nil) {
                        
                        response.statusCode = ServerStatusCode.BadRequest.rawValue
                        
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil), userInfo: [String: AnyObject]())
                        
                        return
                    }
                    
                    // get response
                    let (serverResponse, userInfo) = self.responseForDeleteRequest(serverRequest)
                    
                    // check for error status code
                    if serverResponse.statusCode != ServerStatusCode.OK {
                        
                        response.statusCode = serverResponse.statusCode.rawValue
                        
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                        
                        return
                    }
                    
                    // respond with status code
                    response.statusCode = ServerStatusCode.OK.rawValue
                    
                    // tell the delegate
                    self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
            }
            
            // GET (read resource)
            httpServer.get(instancePathExpression, withBlock: instanceRequestHandler)
            
            // PUT (edit resource)
            httpServer.put(instancePathExpression, withBlock: instanceRequestHandler)
            
            // DELETE (delete resource)
            httpServer.delete(instancePathExpression, withBlock: instanceRequestHandler)
            
            // Add function routes...
            
            let functions = self.dataSource.server(self, functionsForEntity: entity)
            
            for functionName in functions {
                
                // MARK: HTTP Function Request Handler Block
                
                let functionExpressionPath = "{^/" + path + "/(\\d+)/" + functionName + "}"
                
                let functionRequestHandler: RequestHandler = { (request: RouteRequest!, response: RouteResponse!) -> Void in
                    
                    // get resource ID
                    
                    let parameters = request.params
                    
                    let captures = parameters["captures"] as! [String]
                    
                    let resourceID = UInt(Int(captures.first!)!)
                    
                    // get json body
                    
                let jsonBody: AnyObject?
                    do {
                        jsonBody = try NSJSONSerialization.JSONObjectWithData(request.body(), options: NSJSONReadingOptions())
                    } catch _ {
                        jsonBody = nil
                    }
                    
                    let jsonObject = jsonBody as? [String: AnyObject]
                    
                    // convert to server request
                    let serverRequest = ServerRequest(requestType: ServerRequestType.Function,
                        connectionType: ServerConnectionType.HTTP,
                        entity: entity,
                        underlyingRequest: request,
                        resourceID: resourceID,
                        JSONObject: jsonObject,
                        functionName: functionName,
                        headers: request.headers as! [String: String])
                    
                    // invalid json body
                    if jsonObject == nil && jsonBody != nil {
                        
                        response.statusCode = ServerStatusCode.BadRequest.rawValue
                        
                        self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil), userInfo: [String: AnyObject]())
                        
                        return
                    }
                    
                    // get response
                    var (serverResponse, userInfo) = self.responseForFunctionRequest(serverRequest)
                    
                    // respond with JSON if availible
                    if serverResponse.JSONResponse != nil  {
                        
                        // write to socket
                        
                        var error: NSError?
                        
                        let jsonData: NSData?
                        do {
                            jsonData = try NSJSONSerialization.dataWithJSONObject(serverResponse.JSONResponse!, options: self.jsonWritingOption())
                        } catch var error1 as NSError {
                            error = error1
                            jsonData = nil
                        } catch {
                            fatalError()
                        }
                        
                        // could not serialize json response, internal error
                        if (jsonData == nil) {
                            
                            self.delegate?.server(self, didEncounterInternalError: error!, forRequest: serverRequest, userInfo: userInfo)
                            
                            response.statusCode = ServerStatusCode.InternalServerError.rawValue
                            
                            // tell the delegate
                            self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                            
                            return
                        }
                        
                        // respond with serialized json
                        response.respondWithData(jsonData)
                    }
                    
                    // set function status code
                    response.statusCode = serverResponse.statusCode.rawValue
                    
                    // tell the delegate
                    self.delegate?.server(self, didPerformRequest: serverRequest, withResponse: serverResponse, userInfo: userInfo)
                }
                
                httpServer.post(functionExpressionPath, withBlock: functionRequestHandler)
            }
        }
        
        return httpServer
    }
    
    // MARK: - Server Control
    
    /** Starts broadcasting the server. */
    public func start(onPort port: UInt) -> NSError? {
        
        var error: NSError?
        
        self.httpServer.setPort(UInt16(port))
        
        let success: Bool
        do {
            try self.httpServer.start()
            success = true
        } catch var error1 as NSError {
            error = error1
            success = false
        }
        
        if !success {
            
            return error
        }
        else {
            
            return nil
        }
    }
    
    /** Stops broadcasting the server. */
    public func stop() {
        
        self.httpServer.stop()
    }
    
    // MARK: - Request Handlers
    
    private func responseForSearchRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        var userInfo = [String: AnyObject]()
        
        // get search parameters
        
        /** The JSON-formatted dictionary */
        let searchParameters = request.JSONObject!
        
        let entity = request.entity
        
        // get the context this request will use
        
        let context = self.dataSource.server(self, managedObjectContextForRequest: request)
        
        userInfo[ServerUserInfoKey.ManagedObjectContext.rawValue] = context
        
        // create fetch request from JSON
        
        var parseFetchRequestError: NSError?
        
        let fetchRequest: NSFetchRequest?
        do {
            fetchRequest = try NSFetchRequest(JSONObject: searchParameters, entity: entity, managedObjectContext: context, resourceIDAttributeName: self.resourceIDAttributeName)
        } catch var error as NSError {
            parseFetchRequestError = error
            fetchRequest = nil
        }
        
        // if error parsing (e.g. fetching an embedded entity in a comaprison predicate)
        if parseFetchRequestError != nil {
            
            // tell delegate
            self.delegate?.server(self, didEncounterInternalError: parseFetchRequestError!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // no error but JSON was invalid
        if fetchRequest == nil {
            
            let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // prefetch resourceID
        
        fetchRequest!.returnsObjectsAsFaults = false
        
        fetchRequest!.includesPropertyValues = true
        
        // add fully parsed fetch request to userInfo
        
        userInfo[ServerUserInfoKey.FetchRequest.rawValue] = fetchRequest!
        
        // check for permission (now that we have fully parsed the request)
        
        if self.delegate != nil {
            
            let statusCode = self.delegate?.server(self, statusCodeForRequest: request, managedObject: nil, context: context, userInfo: &userInfo)
            
            if statusCode != ServerStatusCode.OK {
                
                let response = ServerResponse(statusCode: statusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // get all embedded comparison predicates (only if permissions are enabled)
        let comparisonPredicates: [NSComparisonPredicate]? = {
            
            if !self.permissionsEnabled {
                
                return nil
            }
           
            return fetchRequest!.predicate?.extractComparisonSubpredicates()
        }()
        
        // check for permission of fetch request's predicate (embedded entities must be visible)
        if self.delegate != nil && self.permissionsEnabled && fetchRequest!.predicate != nil {
            
            for comparisonPredicate in comparisonPredicates! {
                
                // get embedded entity
                if let managedObject = comparisonPredicate.rightExpression.constantValue as? NSManagedObject {
                    
                    // must have at least readonly permisson
                    if self.delegate!.server(self, permissionForRequest: request, managedObject: managedObject, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.ReadOnly.rawValue {
                        
                        let response = ServerResponse(statusCode: ServerStatusCode.Forbidden, JSONResponse: nil)
                        
                        return (response, userInfo)
                    }
                }
            }
        }
        
        // execute fetch request...
        let fetchError: NSError?
        
        var results: [NSManagedObject]?
        
        context.performBlockAndWait { () -> Void in
            
            results = context.executeFetchRequest(fetchRequest!) as? [NSManagedObject]
        }
        
        // invalid fetch
        if fetchError != nil {
            
            // tell delegate
            self.delegate?.server(self, didEncounterInternalError: fetchError!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // optionally filter results
        if self.permissionsEnabled && self.delegate != nil {
            
            var filteredResults = [NSManagedObject]()
            
            for managedObject in results! {
                
                let resourceID = managedObject.valueForKey(self.resourceIDAttributeName, managedObjectContext: context) as! UInt
                
                // permission to view resource (must have at least readonly access)
                if self.delegate!.server(self, permissionForRequest: request, managedObject: managedObject, context: context, key: nil, userInfo: &userInfo).rawValue >= ServerPermission.ReadOnly.rawValue {
                    
                    // must have permission for keys accessed
                    if comparisonPredicates != nil {
                        
                        var visible = true
                        
                        for comparisonPredicate in comparisonPredicates! {
                            
                            let key = comparisonPredicate.leftExpression.keyPath
                            
                            if self.delegate!.server(self, permissionForRequest: request, managedObject: managedObject, context: context, key: key, userInfo: &userInfo).rawValue < ServerPermission.ReadOnly.rawValue {
                                
                                visible = false
                                
                                break
                            }
                        }
                        
                        // at least one of the keys specified in the comparison predicate should not be visible
                        if !visible {
                            
                            // dont add to results
                            break
                        }
                    }
                    
                    // must have read only permission for keys in sort descriptor
                    if !fetchRequest!.sortDescriptors!.isEmpty {
                        
                        for sort in fetchRequest!.sortDescriptors! as [NSSortDescriptor] {
                            
                            if self.delegate?.server(self, permissionForRequest: request, managedObject: managedObject, context: context, key: sort.key!, userInfo: &userInfo).rawValue >= ServerPermission.ReadOnly.rawValue {
                                
                                filteredResults.append(managedObject)
                            }
                        }
                    }
                    else {
                        
                        filteredResults.append(managedObject)
                    }
                }
            }
            
            results = filteredResults
        }
        
        // return the resource IDs of objects mapped to their resource path
        
        var jsonResponse = [[String: UInt]]()
        
        context.performBlockAndWait { () -> Void in
            
            for managedObject in results! {
                
                // get the resourcePath for the entity
                
                let resourcePath = managedObject.entity.name!
                
                let resourceID = (managedObject.valueForKey(self.resourceIDAttributeName) as! UInt)
                
                jsonResponse.append([resourcePath: resourceID])
            }
        }
        
        let response = ServerResponse(statusCode: ServerStatusCode.OK, JSONResponse: jsonResponse)
        
        return (response, userInfo)
    }
    
    private func responseForCreateRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        let entity = request.entity
        
        // get context
        
        let context = self.dataSource.server(self, managedObjectContextForRequest: request)
        
        var userInfo: [String: AnyObject] = [ServerUserInfoKey.ManagedObjectContext.rawValue: context]
        
        // ask delegate
        if self.delegate != nil {
            
            let statusCode = self.delegate?.server(self, statusCodeForRequest: request, managedObject: nil, context: context, userInfo: &userInfo)
            
            if statusCode != ServerStatusCode.OK {
                
                let response = ServerResponse(statusCode: statusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // check for permissions
        if permissionsEnabled {
            
            if self.delegate?.server(self, permissionForRequest: request, managedObject: nil, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.EditPermission.rawValue {
                
                let response = ServerResponse(statusCode: ServerStatusCode.Forbidden, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // create new instance
        
        let resourceID = self.dataSource.server(self, newResourceIDForEntity: entity)
        
        var managedObject: NSManagedObject!
        
        context.performBlockAndWait { () -> Void in
            
            managedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as NSManagedObject
            
            // set resourceID
            
            managedObject.setValue(resourceID, forKey:self.resourceIDAttributeName)
        }
        
        if request.JSONObject != nil {
            
            // convert to Core Data values...
            
            var editStatusCode: ServerStatusCode?
            
            var newValues = [String: AnyObject]()
            
            var error: NSError?
            
            // validate and convert JSON
            context.performBlockAndWait({ () -> Void in
                
                editStatusCode = self.verifyEditResource(managedObject, forRequest: request, context: context, newValues: &newValues, userInfo: &userInfo, error: &error)
            })
            
            if editStatusCode != ServerStatusCode.OK {
                
                if editStatusCode == ServerStatusCode.InternalServerError {
                    
                    self.delegate?.server(self, didEncounterInternalError: error!, forRequest: request, userInfo: userInfo)
                }
                
                let response = ServerResponse(statusCode: editStatusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
            
            userInfo[ServerUserInfoKey.NewValues.rawValue] = newValues
            
            // set new values from dictionary
            context.performBlockAndWait({ () -> Void in
                
                managedObject.setValuesForKeysWithDictionary(newValues)
                
                return
            })
        }
        
        // tell delegate we just created a new resource (delegate may want to give more initial values)
        
        self.delegate?.server(self, didInsertManagedObject: managedObject!, context: context, userInfo: &userInfo)
        
        // perform Core Data validation (to make sure there will be no errors saving)
        
        var validCoreData: Bool = false
        
        context.performBlockAndWait({ () -> Void in
            
            validCoreData = managedObject!.validateForInsert()
        })
        
        // invalid (e.g. non-optional property is nil)
        if !validCoreData {
            
            let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // save
        var saveError: NSError?
        
        context.performBlockAndWait({ () -> Void in
            
            do {
                try context.save()
            } catch var error as NSError {
                saveError = error
            } catch {
                fatalError()
            }
            
            return
        })
        
        if saveError != nil {
            
            self.delegate?.server(self, didEncounterInternalError: saveError!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // respond
        
        let jsonResponse = [resourceIDAttributeName: resourceID]
        
        let response = ServerResponse(statusCode: ServerStatusCode.OK, JSONResponse: jsonResponse)
        
        return (response, userInfo)
    }
    
    private func responseForGetRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        let resourceID = request.resourceID
        
        let entity = request.entity
        
        // user info
        var userInfo: [String: AnyObject] = [ServerUserInfoKey.ResourceID.rawValue: resourceID!]
        
        // get context
        let context = self.dataSource.server(self, managedObjectContextForRequest: request)
        
        userInfo[ServerUserInfoKey.ManagedObjectContext.rawValue] = context
        
        // fetch managedObject
        let (managedObject, error) = FetchEntity(entity, withResourceID: resourceID!, usingContext: context,  resourceIDAttributeName: self.resourceIDAttributeName ,shouldPrefetch: true)
        
        // internal error
        if error != nil {
            
            self.delegate?.server(self, didEncounterInternalError: error!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // not found 
        if managedObject == nil {
            
            let response = ServerResponse(statusCode: ServerStatusCode.NotFound, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // add to userInfo
        userInfo[ServerUserInfoKey.ManagedObject.rawValue] = managedObject
        
        // ask delegate for access
        if delegate != nil {
            
            let statusCode = self.delegate?.server(self, statusCodeForRequest: request, managedObject: managedObject, context:context, userInfo: &userInfo)
            
            if statusCode != ServerStatusCode.OK {
                
                let response = ServerResponse(statusCode: statusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // check for permissions
        if permissionsEnabled {
            
            // must have at least read permission
            if self.delegate?.server(self, permissionForRequest: request, managedObject: nil, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.ReadOnly.rawValue {
                
                let response = ServerResponse(statusCode: ServerStatusCode.Forbidden, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // build json object
        var jsonObject: [String: AnyObject]?
        
        context.performBlockAndWait { () -> Void in
            
            if self.permissionsEnabled {
                
                jsonObject = self.filteredJSONRepresentationOfManagedObject(managedObject!, context: context, request: request, userInfo: &userInfo)
            }
            else {
                
                jsonObject = self.JSONRepresentationOfManagedObject(managedObject!)
            }
        }
        
        return (ServerResponse(statusCode: ServerStatusCode.OK, JSONResponse: jsonObject), userInfo)
    }
    
    private func responseForEditRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        let resourceID = request.resourceID
        
        let entity = request.entity
        
        // user info
        var userInfo: [String: AnyObject] = [ServerUserInfoKey.ResourceID.rawValue: resourceID!]
        
        // get context
        let context = self.dataSource.server(self, managedObjectContextForRequest: request)
        
        userInfo[ServerUserInfoKey.ManagedObjectContext.rawValue] = context
        
        // fetch managedObject
        let (managedObject, error) = FetchEntity(entity, withResourceID: resourceID!, usingContext: context, resourceIDAttributeName: self.resourceIDAttributeName, shouldPrefetch: true)
        
        // internal error
        if error != nil {
            
            self.delegate?.server(self, didEncounterInternalError: error!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // not found
        if managedObject == nil {
            
            let response = ServerResponse(statusCode: ServerStatusCode.NotFound, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // add to userInfo
        userInfo[ServerUserInfoKey.ManagedObject.rawValue] = managedObject
        
        // ask delegate for access
        if delegate != nil {
            
            let statusCode = self.delegate?.server(self, statusCodeForRequest: request, managedObject: managedObject, context: context, userInfo: &userInfo)
            
            if statusCode != ServerStatusCode.OK {
                
                let response = ServerResponse(statusCode: statusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // check for permissions
        if permissionsEnabled {
            
            if self.delegate?.server(self, permissionForRequest: request, managedObject: nil, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.EditPermission.rawValue {
                
                let response = ServerResponse(statusCode: ServerStatusCode.Forbidden, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // convert to Core Data values
        
        var editStatusCode: ServerStatusCode?
        
        var newValues = [String: AnyObject]()
        
        var editError: NSError?
        
        // validate and convert JSON
        context.performBlockAndWait({ () -> Void in
            
            editStatusCode = self.verifyEditResource(managedObject!, forRequest: request, context: context, newValues: &newValues, userInfo: &userInfo, error: &editError)
        })
        
        if editStatusCode != ServerStatusCode.OK {
            
            if editStatusCode == ServerStatusCode.InternalServerError {
                
                self.delegate?.server(self, didEncounterInternalError: editError!, forRequest: request, userInfo: userInfo)
            }
            
            let response = ServerResponse(statusCode: editStatusCode!, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        userInfo[ServerUserInfoKey.NewValues.rawValue] = newValues
        
        // set new values from dictionary
        context.performBlockAndWait({ () -> Void in
            
            managedObject!.setValuesForKeysWithDictionary(newValues)
        })
        
        // perform Core Data validation (to make sure there will be no errors saving)
        
        var validCoreData: Bool = false
        
        context.performBlockAndWait({ () -> Void in
            
            validCoreData = managedObject!.validateForUpdate()
        })
        
        // invalid (e.g. non-optional property is nil)
        if !validCoreData {
            
            let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // save
        var saveError: NSError?
        
        context.performBlockAndWait({ () -> Void in
            
            do {
                try context.save()
            } catch var error as NSError {
                saveError = error
            } catch {
                fatalError()
            }
            
            return
        })
        
        if saveError != nil {
            
            self.delegate?.server(self, didEncounterInternalError: saveError!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        let response = ServerResponse(statusCode: ServerStatusCode.OK, JSONResponse: nil)
        
        return (response, userInfo)
    }
    
    private func responseForDeleteRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        let resourceID = request.resourceID
        
        let entity = request.entity
        
        // user info
        var userInfo: [String: AnyObject] = [ServerUserInfoKey.ResourceID.rawValue: resourceID!]
        
        // get context
        let context = self.dataSource.server(self, managedObjectContextForRequest: request)
        
        userInfo[ServerUserInfoKey.ManagedObjectContext.rawValue] = context
        
        // fetch managedObject
        let (managedObject, error) = FetchEntity(entity, withResourceID: resourceID!, usingContext: context,  resourceIDAttributeName: self.resourceIDAttributeName, shouldPrefetch: true)
        
        // internal error
        if error != nil {
            
            self.delegate?.server(self, didEncounterInternalError: error!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // not found
        if managedObject == nil {
            
            let response = ServerResponse(statusCode: ServerStatusCode.NotFound, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // add to userInfo
        userInfo[ServerUserInfoKey.ManagedObject.rawValue] = managedObject
        
        // ask delegate for access
        if delegate != nil {
            
            let statusCode = self.delegate?.server(self, statusCodeForRequest: request, managedObject: managedObject, context: context, userInfo: &userInfo)
            
            if statusCode != ServerStatusCode.OK {
                
                let response = ServerResponse(statusCode: statusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // check for permissions
        if permissionsEnabled {
            
            if self.delegate?.server(self, permissionForRequest: request, managedObject: nil, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.EditPermission.rawValue {
                
                let response = ServerResponse(statusCode: ServerStatusCode.Forbidden, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        /* Not working #104
        
        // perform Core Data validation (to make sure there will be no errors saving)
        let (validCoreData: Bool, deletionError: NSError?) = {
            
            var validCoreData: Bool!
            
            var deletionError: NSError?
            
            context.performBlockAndWait({ () -> Void in
                
                validCoreData = managedObject!.validateForDelete(&deletionError)
            })
            
            return (validCoreData, deletionError)
        }()
        
        // invalid (e.g. non-optional property is nil)
        if !validCoreData {
            
            let response = ServerResponse(statusCode: ServerStatusCode.BadRequest, JSONResponse: nil)
            
            return (response, userInfo)
        }
        */
        
        // delete...
        
        // save
        var saveError: NSError?
        
        context.performBlockAndWait { () -> Void in
            
            context.deleteObject(managedObject!)
            
            do {
                try context.save()
            } catch var error as NSError {
                saveError = error
            } catch {
                fatalError()
            }
            
            return
        }
        
        if saveError != nil {
            
            self.delegate?.server(self, didEncounterInternalError: saveError!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        let response = ServerResponse(statusCode: ServerStatusCode.OK, JSONResponse: nil)
        
        return (response, userInfo)
    }
    
    private func responseForFunctionRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        let resourceID = request.resourceID
        
        let entity = request.entity
        
        // user info
        var userInfo: [String: AnyObject] = [ServerUserInfoKey.ResourceID.rawValue: resourceID!]
        
        // get context
        let context = self.dataSource.server(self, managedObjectContextForRequest: request)
        
        userInfo[ServerUserInfoKey.ManagedObjectContext.rawValue] = context
        
        // fetch managedObject
        let (managedObject, error) = FetchEntity(entity, withResourceID: resourceID!, usingContext: context, resourceIDAttributeName: self.resourceIDAttributeName, shouldPrefetch: true)
        
        // internal error
        if error != nil {
            
            self.delegate?.server(self, didEncounterInternalError: error!, forRequest: request, userInfo: userInfo)
            
            let response = ServerResponse(statusCode: ServerStatusCode.InternalServerError, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // not found
        if managedObject == nil {
            
            let response = ServerResponse(statusCode: ServerStatusCode.NotFound, JSONResponse: nil)
            
            return (response, userInfo)
        }
        
        // add to userInfo
        userInfo[ServerUserInfoKey.ManagedObject.rawValue] = managedObject
        
        // add jsonObject to userInfo
        let recievedJSONObject = request.JSONObject
        
        if recievedJSONObject != nil {
            
            userInfo[ServerUserInfoKey.FunctionJSONInput.rawValue] = recievedJSONObject
        }
        
        // ask delegate for access
        if delegate != nil {
            
            let statusCode = self.delegate?.server(self, statusCodeForRequest: request, managedObject: managedObject, context: context, userInfo: &userInfo)
            
            if statusCode != ServerStatusCode.OK {
                
                let response = ServerResponse(statusCode: statusCode!, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // check for permissions
        if permissionsEnabled {
            
            if self.delegate?.server(self, permissionForRequest: request, managedObject: nil, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.EditPermission.rawValue {
                
                let response = ServerResponse(statusCode: ServerStatusCode.Forbidden, JSONResponse: nil)
                
                return (response, userInfo)
            }
        }
        
        // perform function
        let (functionCode, jsonObject) = self.dataSource.server(self, performFunction: request.functionName!, forManagedObject: managedObject!, context: context, recievedJsonObject: recievedJSONObject, request: request, userInfo: &userInfo)
        
        if jsonObject != nil {
            
            // add to userInfo
            userInfo[ServerUserInfoKey.FunctionJSONOutput.rawValue] = jsonObject
        }
        
        let response = ServerResponse(statusCode: functionCode.toServerStatusCode(), JSONResponse: jsonObject)
        
        return (response, userInfo)
    }
    
    // MARK: - Internal Methods
    
    private func jsonWritingOption() -> NSJSONWritingOptions {
        
        if self.prettyPrintJSON {
            
            return NSJSONWritingOptions.PrettyPrinted
        }
        
        else {
            
            return NSJSONWritingOptions()
        }
    }
    
    private func JSONRepresentationOfManagedObject(managedObject: NSManagedObject) -> [String: AnyObject] {
        
        // build JSON object...
        
        var jsonObject = [String: AnyObject]()
        
        // first the attributes
        for (attributeName, attribute) in managedObject.entity.attributesByName as [String: NSAttributeDescription] {
            
            // make sure the attribute is not undefined
            if attribute.attributeType != NSAttributeType.UndefinedAttributeType {
                
                // add to JSON representation
                jsonObject[attributeName] = managedObject.JSONCompatibleValueForAttribute(attributeName)
            }
        }
        
        // then the relationships
        for (relationshipName, relationshipDescription) in managedObject.entity.relationshipsByName as [String: NSRelationshipDescription] {
            
            // to-one relationship
            if !relationshipDescription.toMany {
                
                // get destination resource
                if let destinationResource = managedObject.valueForKey(relationshipName) as? NSManagedObject {
                    
                    // get resource ID
                    let destinationResourceID = destinationResource.valueForKey(self.resourceIDAttributeName) as! UInt
                    
                    // add to JSON object
                    jsonObject[relationshipName] = [destinationResource.entity.name!: destinationResourceID]
                }
            }
            
            // to-many relationship
            else {
                
                if let arrayValue = managedObject.arrayValueForToManyRelationship(relationship: relationshipName) {
                    
                    // get resource IDs
                    var resourceIDs = [[String: UInt]]()
                    
                    for destinationResource in arrayValue {
                        
                        let destinationResourceID = destinationResource.valueForKey(self.resourceIDAttributeName) as! UInt
                        
                        resourceIDs.append([destinationResource.entity.name!: destinationResourceID])
                    }
                    
                    // add to jsonObject
                    jsonObject[relationshipName] = resourceIDs
                }
            }
        }
        
        return jsonObject
    }
    
    private func filteredJSONRepresentationOfManagedObject(managedObject: NSManagedObject, context: NSManagedObjectContext, request: ServerRequest, inout userInfo: [String: AnyObject]) -> [String: AnyObject] {
        
        // build JSON object...
        
        var jsonObject = [String: AnyObject]()
        
        // first the attributes
        for (attributeName, attribute) in managedObject.entity.attributesByName as [String: NSAttributeDescription] {
            
            // check access permissions (unless its the resourceID, thats always visible)
            if attributeName != self.resourceIDAttributeName {
                
                if self.delegate?.server(self, permissionForRequest: request, managedObject: managedObject, context: context, key: attributeName, userInfo: &userInfo).rawValue >= ServerPermission.ReadOnly.rawValue {
                    
                    // make sure the attribute is not undefined
                    if attribute.attributeType != NSAttributeType.UndefinedAttributeType {
                        
                        // add to JSON representation
                        jsonObject[attributeName] = managedObject.JSONCompatibleValueForAttribute(attributeName)
                    }
                }
            }
            
            // add resource ID attribute
            else {
                
                // add to JSON representation
                jsonObject[attributeName] = managedObject.JSONCompatibleValueForAttribute(attributeName)
            }
        }
        
        // then the relationships
        for (relationshipName, relationshipDescription) in managedObject.entity.relationshipsByName as [String: NSRelationshipDescription] {
            
            // make sure relationship is visible
            if self.delegate?.server(self, permissionForRequest: request, managedObject: managedObject, context: context, key: relationshipName, userInfo: &userInfo).rawValue >= ServerPermission.ReadOnly.rawValue {
                
                // to-one relationship
                if !relationshipDescription.toMany {
                    
                    // get destination resource
                    if let destinationResource = managedObject.valueForKey(relationshipName) as? NSManagedObject {
                        
                        // check access permissions (the relationship & the single distination object must be visible)
                        if self.delegate?.server(self, permissionForRequest: request, managedObject: destinationResource, context: context, key: nil, userInfo: &userInfo).rawValue >= ServerPermission.ReadOnly.rawValue {
                            
                            // get resource ID
                            let destinationResourceID = destinationResource.valueForKey(self.resourceIDAttributeName) as!
                            UInt
                            
                            // add to JSON object
                            jsonObject[relationshipName] = [destinationResource.entity.name!: destinationResourceID]
                        }
                    }
                }
                    
                // to-many relationship
                else {
                    
                    // only add if value is present
                    if let arrayValue = managedObject.arrayValueForToManyRelationship(relationship: relationshipName) {
                        
                        // only add resources that are visible
                        var resourceIDs = [[String: UInt]]()
                        
                        for destinationResource in arrayValue {
                            
                            if self.delegate?.server(self, permissionForRequest: request, managedObject: destinationResource, context: context, key: nil, userInfo: &userInfo).rawValue >= ServerPermission.ReadOnly.rawValue {
                                
                                // get destination resource ID
                                let destinationResourceID = destinationResource.valueForKey(self.resourceIDAttributeName) as! UInt
                                
                                resourceIDs.append([destinationResource.entity.name!: destinationResourceID])
                            }
                        }
                        
                        // add to jsonObject
                        jsonObject[relationshipName] = resourceIDs
                    
                    }
                }
            }
        }
        
        return jsonObject
    }
    
    /** Verifies the JSON values and converts them to Core Data equivalents. */
    private func verifyEditResource(resource: NSManagedObject, forRequest request:ServerRequest, context: NSManagedObjectContext, inout newValues: [String: AnyObject], inout userInfo: [String: AnyObject], error: NSErrorPointer) -> ServerStatusCode {
        
        let recievedJsonObject = request.JSONObject!
        
        for (key, jsonValue) in recievedJsonObject {
            
            let attribute = (resource.entity.attributesByName as [String: NSAttributeDescription])[key]
            
            let relationship = (resource.entity.relationshipsByName as [String: NSRelationshipDescription])[key]
            
            // not found
            
            if attribute == nil && relationship == nil {
                
                return ServerStatusCode.BadRequest
            }
            
            // attribute
            if attribute != nil {
                
                // resourceID cannot be edited by anyone
                if key == self.resourceIDAttributeName {
                    
                    return ServerStatusCode.Forbidden
                }
                
                // check for permissions
                if permissionsEnabled {
                    
                    if self.delegate?.server(self, permissionForRequest: request, managedObject: resource, context: context, key: key, userInfo: &userInfo).rawValue < ServerPermission.EditPermission.rawValue {
                        
                        return ServerStatusCode.Forbidden
                    }
                }
                
                // make sure the attribute to edit is not undefined
                if attribute!.attributeType == NSAttributeType.UndefinedAttributeType {
                    
                    return ServerStatusCode.BadRequest
                }
                
                // get pre-edit value
                let (newValue: AnyObject, valid) = resource.entity.attributeValueForJSONCompatibleValue(jsonValue, forAttribute: key)
                
                if !valid {
                    
                    return ServerStatusCode.BadRequest
                }
                
                // let the managed object verify that the new attribute value is a valid new value
                
                // pointer
                var newValuePointer: AnyObject? = newValue as AnyObject?
                
                do {
                    try resource.validateValue(&newValuePointer, forKey: key)
                } catch _ {
                    
                    return ServerStatusCode.BadRequest
                }
                
                newValues[key] = newValuePointer
            }
            
            // relationship
            if relationship != nil {
                
                // check permissions of relationship
                if permissionsEnabled {
                    
                    if self.delegate?.server(self, permissionForRequest: request, managedObject: resource, context: context, key: key, userInfo: &userInfo).rawValue < ServerPermission.EditPermission.rawValue {
                        
                        return ServerStatusCode.Forbidden
                    }
                }
                
                // to-one relationship
                if !relationship!.toMany {
                    
                    // must be dictionary
                    let destinationResourceDictionary = jsonValue as? [String: UInt]
                    
                    if destinationResourceDictionary == nil {
                        
                        return ServerStatusCode.BadRequest
                    }
                    
                    // resource dictionary must have 1 value-key pair
                    
                    if destinationResourceDictionary!.count != 1 {
                        
                        return ServerStatusCode.BadRequest
                    }
                    
                    // get key and value
                    
                    let destinationResourceEntityName = destinationResourceDictionary!.keys.first!
                    
                    let destinationResourceID = destinationResourceDictionary!.values.first!
                    
                    let destinationEntity = self.managedObjectModel.entitiesByName[destinationResourceEntityName] as? NSEntityDescription
                    
                    // verify that entity is subentity
                    if (destinationEntity == nil) || !(destinationEntity?.isKindOfEntity(relationship!.destinationEntity!) ?? true) {
                        
                        return ServerStatusCode.BadRequest
                    }
                    
                    let (newValue, error) = FetchEntity(destinationEntity!, withResourceID: destinationResourceID, usingContext: context, resourceIDAttributeName: self.resourceIDAttributeName, shouldPrefetch: false)
                    
                    if error != nil {
                        
                        return ServerStatusCode.InternalServerError
                    }
                    
                    if newValue == nil {
                        
                        return ServerStatusCode.BadRequest
                    }
                    
                    // destination resource must be visible
                    if self.permissionsEnabled {
                        
                        if self.delegate?.server(self, permissionForRequest: request, managedObject: newValue, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.ReadOnly.rawValue {
                            
                            return ServerStatusCode.Forbidden
                        }
                    }
                    
                    // pointer
                    var newValuePointer: AnyObject? = newValue as AnyObject?
                    
                    // must be a valid value
                    do {
                        try resource.validateValue(&newValuePointer, forKey: key)
                    } catch _ {
                        
                        return ServerStatusCode.BadRequest
                    }
                    
                    newValues[key] = newValue
                }
                
                // to-many relationship
                else {
                    
                    // must be array of dictionaries
                    let destinationResourceIDs = jsonValue as? [[String: UInt]]
                    
                    if destinationResourceIDs == nil {
                        
                        return ServerStatusCode.BadRequest
                    }
                    
                    // verify dictionaries in array and create new value array
                    
                    var newArrayValue = [NSManagedObject]()
                    
                    for destinationResourceDictionary in destinationResourceIDs! {
                        
                        // resource dictionary must have 1 value-key pair
                        if destinationResourceDictionary.count != 1 {
                            
                            return ServerStatusCode.BadRequest
                        }
                        
                        // get key and value
                        
                        let destinationResourceEntityName = destinationResourceDictionary.keys.first!
                        
                        let destinationResourceID = destinationResourceDictionary.values.first!
                        
                        let destinationEntity = self.managedObjectModel.entitiesByName[destinationResourceEntityName] as? NSEntityDescription
                        
                        // verify that entity is subentity
                        if (destinationEntity == nil) || !(destinationEntity?.isKindOfEntity(relationship!.destinationEntity!) ?? true) {
                            
                            return ServerStatusCode.BadRequest
                        }
                        
                        let (newValue, error) = FetchEntity(destinationEntity!, withResourceID: destinationResourceID, usingContext: context, resourceIDAttributeName: self.resourceIDAttributeName, shouldPrefetch: false)
                        
                        if error != nil {
                            
                            return ServerStatusCode.InternalServerError
                        }
                        
                        if newValue == nil {
                            
                            return ServerStatusCode.BadRequest
                        }
                        
                        // destination resource must be visible
                        if self.permissionsEnabled {
                            
                            if self.delegate?.server(self, permissionForRequest: request, managedObject: newValue, context: context, key: nil, userInfo: &userInfo).rawValue < ServerPermission.ReadOnly.rawValue {
                                
                                return ServerStatusCode.Forbidden
                            }
                        }
                        
                        // add to new value array
                        newArrayValue.append(newValue!)
                    }
                    
                    // convert back to NSSet or NSOrderedSet
                    
                    var newValue: AnyObject?
                    
                    if relationship!.ordered {
                        
                        newValue = NSOrderedSet(array: newArrayValue)
                    }
                    else {
                        
                        newValue = NSSet(array: newArrayValue)
                    }
                    
                    // must be a valid value
                    do {
                        try resource.validateValue(&newValue, forKey: key)
                    } catch _ {
                        
                        return ServerStatusCode.BadRequest
                    }
                    
                    newValues[key] = newValue
                }
            }
            
        }
        
        return ServerStatusCode.OK
    }
}

// MARK: - Supporting Classes

/** Encapsulates information about a server request. */
public class ServerRequest {
    
    public let requestType: ServerRequestType
    
    public let connectionType: ServerConnectionType
    
    public let entity: NSEntityDescription
    
    public let underlyingRequest: AnyObject
    
    /** The resourceID of the requested instance. Will be nil for POST (search or create instance) requests. */
    public let resourceID: UInt?
    
    public let JSONObject: [String: AnyObject]?
    
    public let functionName: String?
    
    public let headers: [String: String]
    
    public init(requestType: ServerRequestType,
        connectionType: ServerConnectionType,
        entity: NSEntityDescription,
        underlyingRequest: AnyObject,
        resourceID: UInt?,
        JSONObject: [String: AnyObject]?,
        functionName: String?,
        headers: [String: String]) {
            
            self.requestType = requestType
            self.connectionType = connectionType
            self.entity = entity
            self.underlyingRequest = underlyingRequest
            self.resourceID = resourceID
            self.JSONObject = JSONObject
            self.functionName = functionName
            self.headers = headers
    }
}

public class ServerResponse {
    
    public let statusCode: ServerStatusCode
    
    /** A JSON-compatible array or dictionary that will be sent as a response. */
    
    public let JSONResponse: AnyObject?
    
    public init(statusCode: ServerStatusCode, JSONResponse: AnyObject?) {
        
        self.statusCode = statusCode
        
        self.JSONResponse = JSONResponse
    }
}

public class ServerHTTPServer: RoutingHTTPServer {
    
    public let server: Server
    
    public init(server: Server) {
        
        self.server = server
    }
}

public class ServerHTTPConnection: RoutingConnection {
    
    override public func isSecureServer() -> Bool {
        
        return (self.sslIdentityAndCertificates() != nil)
    }
    
    override public func sslIdentityAndCertificates() -> [AnyObject]! {
        
        let cocoaHTTPServer: CocoaHTTPServer.HTTPServer = self.config().server
        
        let httpServer = cocoaHTTPServer as! ServerHTTPServer
        
        let server = httpServer.server
        
        return server.sslIdentityAndCertificates
    }
}

// MARK: - Protocols

/** Server Data Source Protocol */
public protocol ServerDataSource {
    
    /** Asks the data source for a managed object context to access. The data source should create a separate context for each request. */
    func server(server: Server, managedObjectContextForRequest request: ServerRequest) -> NSManagedObjectContext
    
    /** Asks the data source for a numerical identifier for a newly create object. It is the data source's responsibility to keep track of the resource IDs of instances of an entity. This method should return 0 the for the first instance of an entity and increment by 1 for each newly created instance. */
    func server(server: Server, newResourceIDForEntity entity: NSEntityDescription) -> UInt
    
    /** Should return an array of strings specifing the names of functions an entity declares. */
    func server(server: Server, functionsForEntity entity: NSEntityDescription) -> [String]
    
    /** Asks the data source to perform a function on a managed object. Returns a tuple containing a ServerFunctionCode and JSON-compatible dictionary. */
    func server(server: Server, performFunction functionName:String, forManagedObject managedObject: NSManagedObject,
        context: NSManagedObjectContext, recievedJsonObject: [String: AnyObject]?, request: ServerRequest, inout userInfo: [String: AnyObject]) -> (ServerFunctionCode, [String: AnyObject]?)
}

/** Server Delegate Protocol */
public protocol ServerDelegate {
    
    /** Asks the delegate for a status code for a request. Any response that is not ServerStatusCode.OK, will be forwarded to the client and the request will end. This can be used to implement authentication or access control. */
    func server(server: Server, statusCodeForRequest request: ServerRequest, managedObject: NSManagedObject?, context: NSManagedObjectContext, inout userInfo: [String: AnyObject]) -> ServerStatusCode
    
    /** Asks the delegate for access control for a request. Server must have its permissions enabled for this method to be called. */
    func server(server: Server, permissionForRequest request: ServerRequest, managedObject: NSManagedObject?, context: NSManagedObjectContext, key: String?, inout userInfo: [String: AnyObject]) -> ServerPermission
    
    /** Notifies the delegate that a new resource was created. Values are prevalidated. This is a good time to set initial values that cannot be set in -awakeFromInsert: or -awakeFromFetch:.  */
    func server(server: Server, didInsertManagedObject managedObject: NSManagedObject, context: NSManagedObjectContext, inout userInfo: [String: AnyObject])
    
    /** Notifies the delegate that a request was processed. */
    func server(server: Server, didPerformRequest request: ServerRequest, withResponse response: ServerResponse, userInfo: [String: AnyObject])
    
    /** Notifies the delegate that an internal error ocurred (e.g. could not serialize a JSON object). */
    func server(server: Server, didEncounterInternalError error: NSError, forRequest request: ServerRequest, userInfo: [String: AnyObject])
}

// MARK: - Internal Extensions

internal extension NSManagedObjectModel {
    
    func addResourceIDAttribute(resourceIDAttributeName: String) {
        
        // add a resourceID attribute to managed object model
        for (entityName, entity) in self.entitiesByName as [String: NSEntityDescription] {
            
            if entity.superentity == nil {
                
                // create new (runtime) attribute
                let resourceIDAttribute = NSAttributeDescription()
                resourceIDAttribute.attributeType = NSAttributeType.Integer64AttributeType
                resourceIDAttribute.name = resourceIDAttributeName
                resourceIDAttribute.optional = false
                
                // add to entity
                entity.properties.append(resourceIDAttribute)
            }
        }
    }
}

// MARK: - Internal Functions

internal func FetchEntity(entity: NSEntityDescription, withResourceID resourceID: UInt, usingContext context: NSManagedObjectContext, resourceIDAttributeName: String, shouldPrefetch: Bool) -> (NSManagedObject?, NSError?) {
    
    let fetchRequest = NSFetchRequest(entityName: entity.name!)
    
    fetchRequest.fetchLimit = 1
    
    fetchRequest.includesSubentities = false
    
    fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceID), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
    
    if shouldPrefetch {
        
        fetchRequest.returnsObjectsAsFaults = false
    }
    else {
        
        fetchRequest.includesPropertyValues = false
    }
    
    let error: NSError?
    
    var result: [NSManagedObject]?
    
    context.performBlockAndWait { () -> Void in
        
        result = context.executeFetchRequest(fetchRequest) as? [NSManagedObject]
    }
    
    return (result?.first, error)
}

internal func FetchEntity(entity: NSEntityDescription, withResourceIDs resourceIDs: [UInt], usingContext context: NSManagedObjectContext, resourceIDAttributeName: String, shouldPrefetch: Bool) -> ([NSManagedObject]?, NSError?) {
    
    let fetchRequest = NSFetchRequest(entityName: entity.name!)
    
    fetchRequest.fetchLimit = resourceIDs.count
    
    fetchRequest.predicate = NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: resourceIDAttributeName), rightExpression: NSExpression(forConstantValue: resourceIDs), modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.InPredicateOperatorType, options: NSComparisonPredicateOptions.NormalizedPredicateOption)
    
    if shouldPrefetch {
        
        fetchRequest.returnsObjectsAsFaults = false
    }
    else {
        
        fetchRequest.includesPropertyValues = false
    }
    
    let error: NSError?
    
    var result: [NSManagedObject]?
    
    context.performBlockAndWait { () -> Void in
        
        result = context.executeFetchRequest(fetchRequest) as? [NSManagedObject]
    }
    
    return (result, error)
}

