#import <Foundation/Foundation.h>

@interface NSObject (NSDictionaryRepresentation)

/**
 Returns an NSDictionary containing the properties of an object that are not nil.
 */
- (NSDictionary *)dictionaryRepresentation;

@end
