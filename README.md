NetworkObjects
==============

A Objective-C framework inspired by WebObjects

NetworkObjects is a networked object graph inspired by WebObjects. Its purpose is to broadcast Core Data entities over the network through REST style URLs, serialize them to JSON data and use HTTP verbs to manipulate the object graph.

The NO classes are sorted in two sections: Server & Client

Server
==============

To broadcast a Core Data context you must initialize a NOStore first.

By default the NOStore's Core Data context does not have a persistent store coordinator, so you must initliaze one and add a persistent store to it.

Then initialize a NOServer with 

-(id)initWithStore:(NOStore *)store
    userEntityName:(NSString *)userEntityName
 sessionEntityName:(NSString *)sessionEntityName
  clientEntityName:(NSString *)clientEntityName
         loginPath:(NSString *)loginPath;

You must subclass the Core Data entities you want to broadcast and they must conform to NOResourceProtocol. You must have exactly one entity that conforms to each of the following protocols: NOUserProtocol, NOSessionProtocol and NOClientProtocol.

For all other entities use NOResourceProtocol.

Client
==============

NetworkObjects provides a convient controller and store class so that you dont have to know how NOServer's URLs and authentication work and so you dont have to write code to connect to the server. There are two classes availible for a client.

NOAPI is a controller that connects to a NetworkObjects server and return JSON NSDictionaries. You must make sure to the the necesary properties such as the 'model' and 'serverURL' property for it to work.

NOAPICachedStore is store that has a NOAPI property which you must initialize and setup so it can use it to initialize a Core Data context. It is important to initialize a persistent store cooridnator and add a persistent store to the 'context' property so it can function.

The server and client can share the same xcdatamodel file but not the same NSManagedObject subclass for each entity. Your server's NSManagedObject subclasses must conform to NOResourceProtocol for proper functionality. The client Core Data NSManagedObject subclasses only has to conform to NOResourceProtocolKeys.

This framework is OS X 10.9+ and iOS 7+

If you have any questions you can contact me at @colemancda

