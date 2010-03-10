//
//  JagsConsole.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-05.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define id Id
#import <JAGS/Console.h>
#undef id

@interface JagsConsole : NSObject {
	Console *console;
}

- (BOOL)checkModel:(NSURL *)fileName
			 error:(NSError **)outError;

- (BOOL)compileWithData:(NSDictionary *)dataTable
			chainNumber:(NSNumber *)nChain
				genData:(BOOL)genData;

- (NSArray *)variableNames;
- (void)clearModel;

@end
