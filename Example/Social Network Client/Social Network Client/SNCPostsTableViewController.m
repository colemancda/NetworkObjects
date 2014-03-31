//
//  SNCPostsTableViewController.m
//  Social Network Client
//
//  Created by Alsey Coleman Miller on 2/25/14.
//  Copyright (c) 2014 ColemanCDA. All rights reserved.
//

#import "SNCPostsTableViewController.h"
#import "SNCStore.h"
#import "Post.h"
#import "User.h"
#import "NSError+presentError.h"
#import "SNCPostViewController.h"

static void *KVOContext = &KVOContext;

@interface SNCPostsTableViewController (Notifications)

-(void)setupNotifications;

-(void)didFinishFetchRequest:(NSNotification *)notification;

-(void)didGetNewValues:(NSNotification *)notification;

@end

@interface SNCPostsTableViewController ()

@property NSDate *dateLastFetched;

@end

@interface SNCPostsTableViewController (ConfigureCell)

-(void)configureCell:(UITableViewCell *)cell
             forPost:(Post *)post;

@end

@implementation SNCPostsTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // KVO
    [self addObserver:self
           forKeyPath:NSStringFromSelector(@selector(predicate))
              options:NSKeyValueObservingOptionNew
              context:KVOContext];
    
    // notifications
    
    [self setupNotifications];
    
    // default predicate
    
    self.predicate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(predicate))];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == KVOContext) {
        
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(predicate))]) {
            
            // create fetch request
            
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
            
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"resourceID"
                                                                           ascending:NO]];
            fetchRequest.predicate = self.predicate;
            
            // make nsfetchedresultscontroller
            _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[SNCStore sharedStore].context sectionNameKeyPath:nil cacheName:nil];
            
            _fetchedResultsController.delegate = self;
            
            // fetch
            [self fetchData:nil];
            
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Fetch data

-(void)fetchData:(id)sender
{
    // refetch all of the fetch results
    
    self.dateLastFetched = [NSDate date];
    
    _errorDownloadingPost = nil;
    
    [[SNCStore sharedStore].context performBlock:^{
        
        NSError *fetchError;
        
        [_fetchedResultsController performFetch:&fetchError];
        
        if (fetchError) {
            
            [NSException raise:NSInternalInconsistencyException
                        format:@"Error executing fetch request. (%@)", fetchError.localizedDescription];
        }
    }];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    return _fetchedResultsController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SNCPostCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // get model object
    Post *post = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    [self configureCell:cell forPost:post];
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get model object
    Post *post = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [[SNCStore sharedStore].incrementalStore.cachedStore deleteCachedResource:(id)post URLSession:nil completion:^(NSError *error) {
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
        }];
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"selectedPost"]) {
        
        // set post object
        SNCPostViewController *postVC = segue.destinationViewController;
        
        postVC.post = _fetchedResultsController.fetchedObjects[self.tableView.indexPathForSelectedRow.row];
        
    }
    
}

-(void)savedPost:(UIStoryboardSegue *)segue
{
    SNCPostViewController *postVC = segue.sourceViewController;
    
    // create new post
    if (!postVC.post) {
        
        [[SNCStore sharedStore].incrementalStore.cachedStore createCachedResource:@"Post" initialValues:@{@"text": postVC.textView.text} URLSession:postVC.urlSession completion:^(NSError *error, NSManagedObject<NOResourceKeysProtocol> *resource) {
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
            // configure new post
            
            Post *post = (Post *)resource;
            
            post.creator = [SNCStore sharedStore].user;
            
            post.created = [NSDate date];
            
        }];
        
    }
    
    // edit existing post
    else {
        
        [[SNCStore sharedStore].incrementalStore.cachedStore editCachedResource:(id)postVC.post changes:@{@"text": postVC.textView.text} URLSession:postVC.urlSession completion:^(NSError *error) {
            
            if (error) {
                
                [error presentError];
                
                return;
            }
            
        }];
    }
     
}

#pragma mark - Fetched Results Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [self.tableView beginUpdates];

    }];
    
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        UITableView *tableView = self.tableView;
        
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[newIndexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                
                // setup cell without reloading it...
                
                [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath]
                            forPost:anObject];
                
                break;
                
            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                
                [tableView insertRowsAtIndexPaths:@[newIndexPath]
                                 withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
        
    }];
    
}


- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id )sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
        
    }];
    
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        [self.tableView endUpdates];

    }];
}

    
@end

@implementation SNCPostsTableViewController (ConfigureCell)

-(void)configureCell:(UITableViewCell *)cell forPost:(Post *)post
{
    // blocks
    
    void (^configureCell)() = ^void() {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            // Configure the cell...
            cell.textLabel.text = post.text;
            
            if (!_dateFormatter) {
                
                _dateFormatter = [[NSDateFormatter alloc] init];
                _dateFormatter.dateStyle = NSDateFormatterShortStyle;
            }
            
            cell.detailTextLabel.text = [_dateFormatter stringFromDate:post.created];
            
        }];
    };
    
    void (^configurePlaceholderCell)() = ^void() {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            // Configure the cell...
            cell.textLabel.text = NSLocalizedString(@"Loading...",
                                                    @"Loading...");
            
            cell.detailTextLabel.text = @"";
            
        }];
    };
    
    // not downloaded from server
    
    __block BOOL isFault;
    
    [[SNCStore sharedStore].context performBlockAndWait:^{
        
        isFault = post.isFault;
        
        if (isFault) {
            
            // fires fault
            
            [post text];
            
            configurePlaceholderCell();
        }
        
    }];
    
    // not fault
    
    if (!isFault) {
        
        NSDate *dateCached = [[SNCStore sharedStore].incrementalStore.cachedStore dateCachedForResource:@"Post"
                                                                                             resourceID:post.resourceID.integerValue];
        
        // cached object was fetched before we started loading this table view
        if ([dateCached compare:_dateLastFetched] == NSOrderedAscending) {
            
            [[SNCStore sharedStore].context performBlock:^{
                
                [[SNCStore sharedStore].context refreshObject:post
                                                 mergeChanges:YES];
                
            }];
        }
        
        configureCell();
    }
    
}

@end

@implementation SNCPostsTableViewController (Notifications)

-(void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFinishFetchRequest:)
                                                 name:NOIncrementalStoreFinishedFetchRequestNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didGetNewValues:)
                                                 name:NOIncrementalStoreDidGetNewValuesNotification
                                               object:nil];
}

-(void)didFinishFetchRequest:(NSNotification *)notification
{
    // make sure this notification was intended for us
    if (_fetchedResultsController.fetchRequest == notification.userInfo[NOIncrementalStoreRequestKey]) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            [self.refreshControl endRefreshing];
            
        }];
        
        
        NSError *error = notification.userInfo[NOIncrementalStoreErrorKey];
        
        if (error) {
            
            [error presentError];
            
            return;
        }
        
        // nothing needed, fetch result controller should detect the new changes from context
    }
}

-(void)didGetNewValues:(NSNotification *)notification
{
    // make sure its values we requested
    
    NSManagedObjectID *objectID = notification.userInfo[NOIncrementalStoreObjectIDKey];
    
    for (Post *post in _fetchedResultsController.fetchedObjects) {
        
        if (post.objectID == objectID) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                // setup cell without reloading it...
                
                [self configureCell:[self.tableView cellForRowAtIndexPath:[_fetchedResultsController indexPathForObject:post]]
                            forPost:post];
                
            }];
            
            break;
        }
    }
    
}

@end

