//
//  Server.swift
//  NetworkObjects
//
//  Created by Alsey Coleman Miller on 9/10/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData

/** This class that will broadcast a managed object context for the network. */

public class Server {
    
    // MARK: Properties
    
    /** The server's data source. */
    public let dataSource: ServerDataSource
    
    /** The server's delegate. */
    public let delegate: ServerDelegate?
    
    /** The string that will be used to generate a URL for search requests. 
    NOTE: Must not conflict with the resourcePath of entities.*/
    public let searchPath: String = "search"
    
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
    
    // MARK: Private Properties
    
    /** The underlying HTTP server. */
    private lazy var httpServer: HTTPServer = self.initHTTPServer();
    
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
        
        let entities = managedObjectModel.entities as [NSEntityDescription]
        
        for entity in entities {
            
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
        
        
        
        return httpServer;
    }
    
    // MARK: Server Control
    
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
    
    /*
    
    // MARK: Request Handlers
    private func responseForRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        
    }
    
    private func responseForSearchRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        return []
    }
    
    private func responseForCreateRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        return nil
    }
    
    private func responseForGetRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        return nil
    }
    
    private func responseForEditSearchRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        return nil
    }
    
    private func responseForDeleteRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        return nil
    }
    
    private func responseForFunctionRequest(request: ServerRequest) -> (ServerResponse, [String: AnyObject]) {
        
        return nil
    }
    
    */
    
    // MARK: Internal Methods
    
    private func jsonWritingOption() -> NSJSONWritingOptions {
        
        if self.prettyPrintJSON {
            
            return NSJSONWritingOptions.PrettyPrinted;
        }
        
        else {
            
            return NSJSONWritingOptions.allZeros;
        }
    }
    
    // MARK: Private Classes
    
    
}

// MARK: Supporting Classes

public class ServerRequest {
    
    
    
}

public class ServerResponse {
    
    
    
}

public class HTTPServer: RoutingHTTPServer {
    
    let server: Server;
    
    init(server: Server) {
        
        self.server = server;
    }
}

public class HTTPConnection: RoutingConnection {
    
    override public func isSecureServer() -> Bool {
        
        return !self.sslIdentityAndCertificates().isEmpty
    }
    
    
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
    
    func server(Server, didEncounterInternalError error: NSError, forRequest request: ServerRequest, userInfo: [ServerUserInfoKey: AnyObject])
    
    func server(Server, statusCodeForRequest request: ServerRequest, managedObject: NSManagedObject?) -> ServerPermission
    
    func server(Server, didPerformRequest request: ServerRequest, withResponse response: ServerResponse, userInfo: [ServerUserInfoKey: AnyObject])
}

// MARK: Enumerations

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

