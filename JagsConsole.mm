//
//  JagsConsole.mm
//  MacJags
//
//  Created by Aidan Findlater on 10-03-05.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsConsole.h"

#define id Id
#import <JAGS/Compiler/ParseTree.h>
#import <JAGS/Console.h>
#import <string>
#import <sstream>
#undef id

@implementation JagsConsole

- (id)init
{
	self = [super init];
	console = new Console(std::cout, std::cerr);
	return self;
}

- (void)dealloc
{
	delete console;
    [super dealloc];
}

- (BOOL)checkModel:(NSURL *)fileName error:(NSError **)outError
{
	NSAssert([fileName isFileURL], @"fileName must be a local file");
	
	std::FILE *file = fopen([[fileName path] UTF8String], "r");
	if (file == NULL) {
		NSLog(@"couldn't open");
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:nil];
		return NO;
	} else if (ferror(file)) {
		NSLog(@"error");
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:EBADF userInfo:nil];
		return NO;
	}
	
	bool ret = console->checkModel(file);
	
	if (fclose(file) == EOF) {
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:EBADF userInfo:nil];
		return NO;
	}
	
	return (BOOL)ret;
}

- (BOOL)compileWithData:(NSDictionary *)dataTable
			chainNumber:(NSNumber *)nChain
				genData:(BOOL)genData
{
	// Convert data to C++ structure
	std::map<std::string, SArray> *c_dataTable = new std::map<std::string, SArray>;
	for (NSString *varName in dataTable) {
		NSArray *array = [dataTable objectForKey:varName];
		unsigned int arraySize = [array count];
		
		std::string c_varName = [varName UTF8String];
		std::vector<unsigned int> *c_dim = new std::vector<unsigned int>();
		c_dim->push_back(arraySize);
		SArray *c_array = new SArray(*c_dim);
		for (unsigned int i=0; i<arraySize; i++)
			c_array->setValue([[array objectAtIndex:i] floatValue], i);
		c_dataTable->insert(make_pair(c_varName, *c_array));
		delete c_array;
	}
	
	bool ret = console->compile(*c_dataTable, [nChain unsignedIntValue], (bool)genData);
	
	delete c_dataTable;
	
	return (BOOL)ret;
}

- (NSArray *)variableNames
{
	std::vector<std::string> c_varNames = console->variableNames();
	NSMutableArray *varNames = [[NSMutableArray alloc] initWithCapacity:c_varNames.size()];
	
	for (int i=0; i<c_varNames.size(); i++) {
		NSString *nextVar = [[NSString alloc] initWithCString:c_varNames[i].c_str()];
		[varNames insertObject:nextVar atIndex:i];
	}
	
	return varNames;
}

- (void)clearModel
{
	console->clearModel();
}


@end
