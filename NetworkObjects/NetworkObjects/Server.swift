//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/10/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

// Constants

public let ServerFetchRequestKey: String = "NetworkObjects.ServerFetchRequestKey"

public let ServerResourceIDKey: String = "NetworkObjects.ServerResourceIDKey"

public let ServerManagedObjectKey: String = "NetworkObjects.ServerManagedObjectKey"

public let ServerManagedObjectContextKey: String = "NetworkObjects.ServerManagedObjectContextKey"

public let ServerNewValuesKey: String = "NetworkObjects.ServerNewValuesKey"

public let ServerFunctionNameKey: String = "NetworkObjects.ServerFunctionNameKey"

public let ServerFunctionJSONInputKey: String = "NetworkObjects.ServerFunctionJSONInputKey"

public let ServerFunctionJSONOutputKey: String = "NetworkObjects.ServerFunctionJSONOutputKey"

/** The class that will accept incoming connections 
*/

public class Server {
    
    // MARK: Properties
    
    /** The server's data source. */
    public let dataSource: ServerDataSource
    
    /** The server's delegate. */
    public let delegate: ServerDelegate?
    
    /** The string that will be used to generate a URL for search requests. 
    NOTE Must not conflict with the resourcePath of entities.*/
    public let searchPath: String = "search"
    
    /** Determines whether the exported JSON should have whitespace for easier readability. */
    public let prettyPrintJSON: Bool = false
    
    /** The name of the Integer attribute that will be used for identifying instances of entities. */
    public let resourceIDAttributeName: String = "resourceID"
    
    /** To enable HTTPS for all incoming connections set this value to an array appropriate for use in kCFStreamSSLCertificates SSL Settings. It should be an array of SecCertificateRefs except for the first element in the array, which is a SecIdentityRef.  */
    public let sslIdentityAndCertificates: [AnyObject]?
    
    /** Boolean that caches whether permissions (dynamic access control) is enabled. */
    public let permissionsEnabled: Bool = false;
    
    /** The managed object model */
    public let managedObjectModel: NSManagedObjectModel
    
    // TODO: Fix lazy initializers
    /** Resource path strings mapped to entity descriptions. */
    //public lazy var entitiesByResourcePath: [String: NSEntityDescription] = initEntitiesByResourcePath();
    
    // MARK: Private Properties
    
    /** The underlying HTTP server. */
    private let httpServer: HTTPServer = HTTPServer();
    
    // MARK: Initialization
    
    public init(dataSource: ServerDataSource, delegate: ServerDelegate?, managedObjectModel: NSManagedObjectModel, searchPath:String?, resourceIDAttributeName:String?, prettyPrintJSON:Bool, sslIdentityAndCertificates: [AnyObject]?, permissionsEnabled: Bool?) {
        
        // set required values
        self.dataSource = dataSource;
        self.managedObjectModel = managedObjectModel;
        
        // optional values
        if (delegate? != nil) {
            self.delegate = delegate!;
        }
        if (searchPath?  != nil){
            self.searchPath = searchPath!;
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
    }
    
    /** Lazily initializes self.entitiesByResourcePath. */
    private func initEntitiesByResourcePath() -> [String: NSEntityDescription] {
        
        var entitiesByResourcePathDictionary = [String: NSEntityDescription]();
        
        var entities = managedObjectModel.entities as [NSEntityDescription]
        
        for entity in entities {
            
            if !entity.abstract {
                
                let path = self.dataSource.server(self, resourcePathForEntity: entity)
                
                entitiesByResourcePathDictionary[path] = entity
            }
        }
        
        return entitiesByResourcePathDictionary
    }
    
    // MARK: Server Control
    public func start(onPort port: UInt) -> NSError? {
        
        
    }
    
    public func stop() {
        
        
    }
    
    // MARK: Request Handlers
    private func responseForRequest(forRequest request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        func responseForSearchRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
            
            
        }
        
        func responseForCreateRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
            
            
        }
        
        func responseForGetRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
            
            
        }
        
        func responseForEditSearchRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
            
            
        }
        
        func responseForDeleteRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
            
            
        }
        
        func responseForFunctionRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
            
            
        }
        
    }
    
    // MARK: Private Classes
    
    
}

// MARK: Protocols

/** Data Source protocol */
public protocol ServerDataSource {
    
    func server(Server, resourcePathForEntity entity: NSEntityDescription) -> String;
    
    func server(Server, managedObjectContextForRequest request: ServerRequest) -> NSManagedObjectContext
    
    func server(Server, newResourceIDForEntity entity: NSEntityDescription) -> Int
    
    func server(Server, functionsForEntity entity: NSEntityDescription) -> [String]
}

/**  */
public protocol ServerDelegate {
    
    func server(Server, didEncounterInternalError error: NSError, forRequest request: ServerRequest, userInfo: Dictionary<String, AnyObject>)
    
    func server(Server, statusCodeForRequest request: ServerRequest, managedObject: NSManagedObject?) -> ServerPermission
}

// MARK: Supporting Classes

public class ServerRequest {
    
    
    
}

public class ServerResponse {
    
    
    
}

// TODO: Delete temporary class

public class RoutingHTTPServer {
    
    
    
}

public class HTTPServer: RoutingHTTPServer {
    
    
}

// MARK: Enumerations

public enum SearchParameter: Int {
    
    case SearchParameterPredicateKey = 1
    case SearchParameterPredicateValue = 2
    case SearchParameterPredicateOperator = 3
    case SearchParameterPredicateOption = 4
    case SearchParameterPredicateModifier = 5
    case SearchParameterFetchLimit = 6
    case SearchParameterFetchOffset = 7
    case SearchParameterIncludesSubentities = 8
    case SearchParameterSortDescriptors = 9
    
};

/** These are HTTP status codes used with NOServer instances. */
public enum ServerStatusCode: Int {
    
    /** OK status code. */
    case ServerStatusCodeOK = 200
    
    /** Bad request status code. */
    case ServerStatusCodeBadRequest = 400
    
    /** Unauthorized status code. e.g. Used when authentication is required. */
    case ServerStatusCodeUnauthorized = 401 // not logged in
    
    case ServerStatusCodePaymentRequired = 402
    
    /** Forbidden status code. e.g. Used when permission is denied. */
    case ServerStatusCodeForbidden = 403 // item is invisible to user or api app
    
    /** Not Found status code. e.g. Used when a Resource instance cannot be found. */
    case ServerStatusCodeNotFound = 404 // item doesnt exist
    
    /** Method Not Allowed status code. e.g. Used for invalid requests. */
    case ServerStatusCodeMethodNotAllowed = 405
    
    /** Conflict status code. e.g. Used when a user with the specified username already exists. */
    case ServerStatusCodeConflict = 409 // user already exists
    
    /** Internal Server Error status code. e.g. Used when a JSON cannot be converted to NSData for a HTTP response. */
    case ServerStatusCodeInternalServerError = 500
    
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
};

/** Defines the connection protocols used communicate with the server. */
public enum ServerConnectionProtocol {
    
    /** The connection to the server was made via the HTTP protocol. */
    case HTTP
    
    /** The connection to the server was made via the WebSockets protocol. */
    case WebSocket
}

