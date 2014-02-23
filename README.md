NetworkObjects
==============

NetworkObjects is a distributed object graph inspired by Apple's WebObjects. This framework compiles for OS X and iOS and serves as the foundation for building powerful Objective-C servers as well as serving as a cross-platform alternative to Cocoa's Distributed Objects. Powered by Core Data and Grand Central Dispatch, the framework comes with server and client classes which abstract away advanced networking code so the developer can focus on distributing Core Data entities over a network.

## Installation

This framework compiles for OS X 10.9 and iOS 7. It cannot be ported to older versions since it uses NSURLSession and the new Base64 categories.

### OS X

1. Drag the NetworkObjects project into your project to add it.
2. In your project go to **General -> Linked Frameworks and Libraries** and add the NetworkObjects framework. Make sure it's *NetworkObjects.framework* and not *libNetworkObjects.a*.
3. In **Build Phases -> Target Dependencies** add the OS X framework.
4. In **Build Phases -> Copy Files** add the OS X framework and set *Destination* to *Frameworks*.

### iOS

1. Drag the NetworkObjects project into your project to add it.
2. In your project go to **General -> Linked Frameworks and Libraries** and add the NetworkObjects framework. Make sure it's *libNetworkObjects.a* and not *NetworkObjects.framework*.
3. In **Build Phases -> Target Dependencies** add the iOS framework.
4. In **Build Settings** add *-all_load* to **Other Linker Flags**.

##Usage

If you plan on building seperate server and client apps, as opposed to a single app with server and client capabilities, make sure that they both use the same **.xcdatamodel** but different implementations. The entities will be exacly the same but their ```NSManagedObject``` subclass implementations should be different.

### Server

To broadcast a Core Data context over the network with NetworkObjects, a ```NOStore``` instance must first be initialized.

For initialization of ```NOStore```, the default ```-init``` method should only be used if the ```NOStore``` will be in-memory only. Else, use 

	-(id)initWithManagedObjectModel:(NSManagedObjectModel *)model
		             lastIDsURL:(NSURL *)lastIDsURL
		             
The *lastIDsURL* argument specifies where a PLIST should be saved. This parameter must be set to a valid value for the store to work. Make sure to add a ```NSPersistentStore``` to ```NOStore```'s ```self.context.persistentStoreCoordinator``` property.

For example

    // get paths
    
    NSString *sqliteFilePath = [self.appSupportFolderPath stringByAppendingPathComponent:@"NOExample.sqlite"];
    
    NSURL *sqlURL = [NSURL fileURLWithPath:sqliteFilePath];
    
    NSString *lastIDsPath = [self.appSupportFolderPath stringByAppendingPathComponent:@"lastIDs.plist"];
    
    NSURL *lastIDsURL = [NSURL fileURLWithPath:lastIDsPath];
    
    // setup store
    
    _store = [[NOStore alloc] initWithManagedObjectModel:nil
                                              lastIDsURL:lastIDsURL];
    
    
    // add persistance
    
    NSError *addPersistentStoreError;
    [_store.context.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                            configuration:nil
                                                                      URL:sqlURL
                                                                  options:nil
                                                                    error:&addPersistentStoreError];

Next, initialize an instance of ```NOServer``` with 

	-(id)initWithStore:(NOStore *)store
	    userEntityName:(NSString *)userEntityName
	 sessionEntityName:(NSString *)sessionEntityName
	  clientEntityName:(NSString *)clientEntityName
	         loginPath:(NSString *)loginPath;

For example

	_server = [[NOServer alloc] initWithStore:_store
	                              userEntityName:@"User"
	                            sessionEntityName:@"Session"
	                            clientEntityName:@"Client"
	                                   loginPath:@"login"];
                                    
Once those two instances are initialized you can start broadcasting by sending ```-(NSError *)startOnPort:(NSUInteger)port``` to the ```NOStore``` instance.

### Client

To implement client functionality, initalize a ```NOAPI```followed by a ```NOAPICachedStore```.

For example



#Example



Your Core Data entities must be subclasses of NSManagedObject and conform to NOResourceProtocol. You are also required to have exactly one entity for each of the special NOResourceProtocols: NOUserProtocol, NOClientProtocol, and NOSessionProtocol. Your entities must not have transformable or undefined attributes. On the client side, should use the exact same .xcdatamodel file you use in your server, but the NSManagedObject subclasses must adopt to NOResourceKeysProtocol and not to NOResourceProtocol. The reason is becuase NOResourceProtocol defines how a entity behaves on the server side. NOResourceKeys only defines the basic keys needed for the client classes to function properly.

The rest of this framework's classes are sorted in two sections: Server & Client.

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

