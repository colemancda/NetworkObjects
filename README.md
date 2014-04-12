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

## Implementation

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

Next, initialize an instance of ```NOServer``` 

	_server = [[NOServer alloc] initWithStore:_store
	                              userEntityName:@"User"
	                            sessionEntityName:@"Session"
	                            clientEntityName:@"Client"
	                                   loginPath:@"login"];
                                    
Once those two instances are initialized you can start broadcasting by sending ```-(NSError *)startOnPort:(NSUInteger)port``` to the ```NOServer``` instance.

### Client

NetworkObjects provides convenient controller and store client classes so that you don't have to know how NOServer's URLs and authentication work. With these classes you dont have to write code to connect to the server.

```NOAPI``` is a controller that connects to a NetworkObjects server and returns JSON NSDictionaries. You must make sure to the the necesary properties such as the 'model' and 'serverURL' properties are set to a valid value for it to work.

```NOAPICachedStore``` is a subclass of ```NOAPI``` thats additionally caches the remote object graph using Core Data. You must initialize a persistent store coordinator and add a persistent store to the ```self.context``` property so it can function properly.

To implement client functionality, initialize an instance of ```NOAPICachedStore```.

#Example

NetworkObjects includes example client and server apps. The server runs on OS X and the client on iOS. In order to test the functionality compile and run both. Make sure to create a new client entity in the server app since the app is empty upon first launch. To do this, click on the ```Browser``` button the the server's OS X GUI. In the drop-down box, select the Client entity and press the ```New``` button. Select the newly created entity to edit its settings (Double click the ```0``` row). In the Client Window, enable the ```First Party``` checkbox and set the name and token to whatever values you want.

On the iOS client, set fill out the session variables (0 for Client ID and the token you previously entered for Client Secret, along with the desired username and password) in the login screen to login or register a new user.

Here's a video of the example working - https://vimeo.com/91811333

If you have any questions you can contact me at @colemancda

