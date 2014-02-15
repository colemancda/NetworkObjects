//
//  NSString+RandomString.m
//  ColemanServer
//
//  Created by Alsey Coleman Miller on 5/10/13.
//  Copyright (c) 2013 ColemanCDA. All rights reserved.
//

#import "NSString+RandomString.h"

@implementation NSString (RandomString)

+(NSString *)randomStringWithLength:(NSUInteger)length
{
    // got code from http://stackoverflow.com/questions/2633801/generate-a-random-alphanumeric-string-in-cocoa
    
    int charNumStart = (int) '0';
    int charNumEnd = (int) '9';
    int charCapitalStart = (int) 'A';
    int charCapitalEnd = (int) 'Z';
    int charLowerStart = (int) 'a';
    int charLowerEnd = (int) 'z';
    
    int amountOfChars = (charNumEnd - charNumStart) + (charCapitalEnd - charCapitalStart) + (charLowerEnd - charLowerStart); // amount of the characters we want.
    int firstGap = charCapitalStart - charNumEnd; // there are gaps of random characters between numbers and uppercase letters, so this allows us to skip those.
    int secondGap = charLowerStart - charCapitalEnd; // similar to above, but between uppercase and lowercase letters.
    
    // START generates a log to show us which characters we are considering for our UID.
    NSMutableString *chars = [NSMutableString stringWithCapacity:amountOfChars];
    for (int i = charNumStart; i <= charLowerEnd; i++) {
        if ((i >= charNumStart && i <= charNumEnd) || (i >= charCapitalStart && i <= charCapitalEnd) || (i >= charLowerStart && i <= charLowerEnd)) {
            [chars appendFormat:@"\n%c", (char) i];
        }
    }
    
    NSMutableString *uid = [NSMutableString stringWithCapacity:length];
    for (int i = 0; i < length; i++) {
        // Generate a random number within our character range.
        int randomNum = arc4random() % amountOfChars;
        // Add the lowest value number to line this up with a desirable character.
        randomNum += charNumStart;
        // if the number is in the letter range, skip over the characters between the numbers and letters.
        if (randomNum > charNumEnd) {
            randomNum += firstGap;
        }
        // if the number is in the lowercase letter range, skip over the characters between the uppercase and lowercase letters.
        if (randomNum > charCapitalEnd) {
            randomNum += secondGap;
        }
        // append the chosen character.
        [uid appendFormat:@"%c", (char) randomNum];
    }
    
    return (NSString *)uid;
}

@end
