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
			chainNumber:(NSUInteger)nChain
				genData:(BOOL)genData;

- (BOOL)setMonitor:(NSString *)name
			 range:(NSRange)range
  thinningInterval:(NSUInteger)thin
	   monitorType:(NSString *)type;

- (BOOL)clearMonitor:(NSString *)name
			   range:(NSRange)range
		 monitorType:(NSString *)type;

- (NSArray *)variableNames;
- (void)clearModel;

+ (void)loadDLLs;
+ (BOOL)loadModule:(NSString *)moduleName;
+ (BOOL)unloadModule:(NSString *)moduleName;
+ (NSArray *)loadedModules;

@end
