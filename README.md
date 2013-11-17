NetworkObjects
==============

NetworkObjects is a distributed object graph inspired by WebObjects. Its purpose is to broadcast Core Data entities over the network through REST URLs, serialize them to JSON and use HTTP verbs to manipulate the object graph.

Your Core Data entities must be subclasses and conform to the NOResourceProtocol. You are also required to has exactly one entity for each of the special NOResourceProtocols. These are NOUserProtocol, NOClientProtocol and NOSessionProtocol. Your entities must not have transformable or undefined attributes. On the client side you can have the exact same .xcdatamodel file you used in your server, but the NSManagedObjects subclasses must adopt to NOResourceKeysProtocol and not to NOResourceProtocol. The reason is becuase NOResourceProtocol defines how a enetity behaves on the server side. The schema for conditions when a entity is unavailible must be built into the client app itself.

The rest of framework's classes are sorted in two sections: Server & Client

To broadcast a Core Data context you must initialize a NOStore first.

By default, the NOStore's Core Data context does not have a persistent store coordinator, so you must initliaze one and add a persistent store to it.

Then initialize NOServer with 

-(id)initWithStore:(NOStore *)store
    userEntityName:(NSString *)userEntityName
 sessionEntityName:(NSString *)sessionEntityName
  clientEntityName:(NSString *)clientEntityName
         loginPath:(NSString *)loginPath;

NetworkObjects provides convenient controller and store client classes so that you don't have to know how NOServer's URLs and authentication work. With these classes you dont have to write code to connect to the server.

NOAPI is a controller that connects to a NetworkObjects server and returns JSON NSDictionaries. You must make sure to the the necesary properties such as the 'model' and 'serverURL' properties are set to a valid value for it to work.

NOAPICachedStore is store that takes a NOAPI instance as a property and uses it to connect to the server and cache the remote object graph using Core Data. You must initialize a persistent store coordinator and add a persistent store to the 'context' property so it can function.

This framework requires OS X 10.9 and iOS 7

If you have any questions you can contact me at @colemancda

