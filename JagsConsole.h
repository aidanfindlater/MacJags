//
//  JagsConsole.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-05.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
class Console;
#endif

#ifdef __OBJC__
#ifndef __cplusplus
typedef void Console;
#endif
#endif

/**
 * The JagsConsole class is a thin wrapper for the JAGS Console class.
 */
@interface JagsConsole : NSObject {
	Console *console;
}

- (BOOL)checkModel:(NSURL *)fileName
			 error:(NSError **)outError;

- (BOOL)compileWithData:(NSDictionary *)dataTable
			chainNumber:(NSUInteger)nChain
				genData:(BOOL)genData;

- (BOOL)setParameters:(NSDictionary *)paramTable
				chain:(NSUInteger)chainNumber;

- (BOOL)setRNGName:(NSString *)name
			 chain:(NSUInteger)chainNumber;

- (BOOL)initialize;
- (BOOL)update:(NSUInteger)numIterations;

- (BOOL)setMonitor:(NSString *)name
  thinningInterval:(NSUInteger)thin
	   monitorType:(NSString *)type;

- (BOOL)clearMonitor:(NSString *)name
		 monitorType:(NSString *)type;

- (void)clearAllMonitors;

- (BOOL)dumpState:(NSDictionary **)dataTable
		  rngName:(NSString **)name
			chain:(NSUInteger)chainNumber;

- (NSUInteger)iterationNumber;
- (NSArray *)variableNames;

- (NSUInteger)numChains;

- (NSDictionary *)dumpMonitors;

- (BOOL)dumpSamplers:(NSArray **)samplerList;
- (BOOL)setAdaptive:(BOOL)isAdaptive;
- (BOOL)adaptive;

- (void)clearModel;

+ (void)loadDLLs;
+ (BOOL)loadModule:(NSString *)moduleName;
+ (BOOL)unloadModule:(NSString *)moduleName;
+ (NSArray *)listModules;

@end
