NetworkObjects
==============

NetworkObjects is a distributed object graph inspired by Apple's WebObjects. This framework compiles for OS X and iOS and serves as the foundation for building powerful Swift servers as well as serving as a cross-platform alternative to Cocoa's Distributed Objects. Powered by Core Data and Grand Central Dispatch, the framework comes with server and client classes which abstract away advanced networking code so the developer can focus on distributing Core Data entities over a network.

# Auto-Generated REST Server

The Server class, as its name implies, broadcasts a Core Data managed object context over the network (via HTTP) in way that it can be incrementally accessed and modified. It will also ask the data source to keep track of unique identifiers (unsigned integer) assigned to an instance of an entity. This will create a schema as follows:

|Method  |URL				|JSON Request Body|JSON Response Body   |
|--------|------------------|-----------------|---------------------|
|POST    |/entityName		|Yes (Optional)   |Yes (ResourceID Only)|
|GET     |/entityName/id	|No               |Yes                  |
|PUT     |/entityName/id	|Yes              |No                   |
|DELETE  |/entityName/id	|No               |No                   |

The JSON recieved from or sent to the server follows the following schema:

```
{
    "attributeName": attributeValue,
    "toOneRelationshipName": {"DestinationEntityName": resourceID}
    "toManyRelationshipName": [{"DestinationEntityName": resourceID1}, {"DestinationEntityName": resourceID2}, ...]
}
```

Nil values are ommited from the JSON Body in GET responses. In PUT or POST requests it is represented by the JSON null type.

Attribute Values are converted in the following way:

|CoreData Value|JSON Value    |
|--------------|--------------|
|String        |String        |
|Number        |Number        |
|Date          |ISO8601 String|
|Data          |Base64 String |
|Transformable |Base64 String |
|Nil           |Null (PUT, POST), Ommited from JSON body in GET|

Optionally the Server can create function and search URLs for special requests

|Method  |URL				 									|
|--------|----------------------------|
|POST    |/search/entityName					|
|POST    |/entityName/id/functionName	|

# Server Permissions / Access Control

By default the server provides no authentication, but the Server can use SSL and the can ask its delegate for access control based on HTTP headers, making authentication completely customizeable. In addition to HTTP, the Server's data source and delegate protocols are built to be agnostic to connection protocols, making it open to other protocols in the future (WebSockets support is planned).

There are two delegate protocol methods for access control:

    func server(Server, statusCodeForRequest request: ServerRequest, managedObject: NSManagedObject?, context: NSManagedObjectContext?) -> ServerStatusCode
    func server(Server, permissionForRequest request: ServerRequest, managedObject: NSManagedObject?, context: NSManagedObjectContext?, key: String?) -> ServerPermission

# Client-side caching

The Store class is what clients will use to communicate with the server. A dateCached attribute can be optionally added at runtime for cache validation.

# Deployment

The NetworkObjects framework is built as a dynamically linked framework for both OS X and iOS. It requires Xcode 6.1 and a minimum operating system of iOS 8 or OS X 10.10.

# Support and Documentation

If you have any questions you can contact me on Twitter at @colemancda

