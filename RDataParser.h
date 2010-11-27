//
//  RDataParser.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-07.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * The RDataParser class parses R-formatted files and strings using NSScanners.
 *
 * RDataParser only supports a subset of the R syntax. An example of acceptable
 * data is:
 *
 *     'x' <- c(1,2,3,4,5)
 *     'Y' <- c(1,3,3,3,5)
 *     'N' <- 5
 *
 */
@interface RDataParser : NSObject {
	NSString *rDataString;
	NSScanner *scanner;
	NSCharacterSet *endTextCharacterSet;
	NSCharacterSet *symbolCharacterSet;
}

- (NSDictionary *)parseString:(NSString *)aString;
- (NSDictionary *)parseURL:(NSURL *)aURL;

- (NSDictionary *)parseAssignmentExpression;
- (NSString *)parseVariableName;
- (NSString *)parseAssignmentToken;
- (NSArray *)parseArray;
- (NSNumber *)parseNumber;
- (NSObject *)parseExpression;
- (NSString *)parseWhitespace;
- (NSString *)parseArraySeparator;

@end
