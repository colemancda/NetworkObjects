NetworkObjects
==============

NetworkObjects is a distributed object graph inspired by Apple's WebObjects. This framework compiles for OS X and iOS and serves as the foundation for building powerful Swift servers as well as serving as a cross-platform alternative to Cocoa's Distributed Objects. Powered by Core Data and Grand Central Dispatch, the framework comes with server and client classes which abstract away advanced networking code so the developer can focus on distributing Core Data entities over a network.

# Auto-Generated REST Server

The Server class, as its name implies, broadcasts a Core Data managed object context over the network (via HTTP) in way that it can be incrementally accessed and modified. The Server class will ask its data source for a path mapped to each entity. It will also ask the data source to keep track of unique identifiers (unsigned integer) assined to an instance of an entity. This will create a schema as follows:

|Method  |URL							|
|--------|----------------|
|POST    |/entityPath			|
|GET     |/entityPath/id	|
|PUT     |/entityPath/id	|
|DELETE  |/entityPath/id	|

Optionally the Server can create function and search URLs for special requests

|Method  |URL				 									|
|--------|----------------------------|
|POST    |/search/entityPath					|
|POST    |/entityPath/id/functionName	|

By default the server provides no authentication, but the Server can use SSL and the can ask its delegate for access control based on HTTP headers, making authentication completely customizeable. In addition to HTTP, the Server's data source and delegate protocols are built to be agnostic to connection protocols, making it open to other protocols in the future (WebSockets support is planned).

# Client-side caching

The Store class is what clients will use to communicate with the server. A dateCached attribute can be optionally added at runtime for cache validation.

# Deployment

The NetworkObjects framework is built as a dynamically linked framework for both OS X and iOS.  

# Support and Documentation

If you have any questions you can contact me on Twitter at @colemancda

