//
//  JagsConsole.mm
//  MacJags
//
//  Created by Aidan Findlater on 10-03-05.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsConsole.h"

#define id Id
#import <JAGS/compiler/ParseTree.h>
#import <JAGS/Console.h>
#import <string>
#import <sstream>
#undef id

using std::map;
using std::string;
using std::vector;
using std::pair;

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
	if (![fileName isFileURL]) {
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:nil];
		return NO;
	}
	
	std::FILE *file = fopen([[fileName path] UTF8String], "r");
	if (file == NULL || ferror(file)) {
		NSLog(@"Error opening file");
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:nil];
		return NO;
	}
	
	bool ret = console->checkModel(file);
	
	if (fclose(file) == EOF) {
		NSLog(@"Error closing file");
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:EBADF userInfo:nil];
		return NO;
	}
	
	return (BOOL)ret;
}

- (BOOL)compileWithData:(NSDictionary *)dataTable
			chainNumber:(NSUInteger)nChain
				genData:(BOOL)genData
{
	// Convert data to C++ structure
	map<string, SArray> c_dataTable;
	for (NSString *varName in dataTable) {
		NSArray *array = [dataTable objectForKey:varName];
		unsigned int arraySize = [array count];
		
		string c_varName = [varName UTF8String];
		SArray sarray(vector<unsigned int>(1, arraySize)); // one-dimensional ONLY
		
		vector<double> v;
		for (NSNumber *num in array)
			v.push_back([num floatValue]);
		
		sarray.setValue(v);
		
		c_dataTable.insert(pair<string,SArray>(c_varName, sarray));
	}
	
	// Compile the model with the data
	bool ret = console->compile(c_dataTable, nChain, (bool)genData);
		
	return (BOOL)ret;
}

- (BOOL)setMonitor:(NSString *)name
			 range:(NSRange)range
  thinningInterval:(NSUInteger)thin
	   monitorType:(NSString *)type
{
	string c_name = [name UTF8String];
	Range c_range;
	string c_type = [type UTF8String];
	
	bool ret = console->setMonitor(c_name, c_range, thin, c_type);
	
	return (BOOL)ret;
}

- (BOOL)clearMonitor:(NSString *)name
			   range:(NSRange)range
		 monitorType:(NSString *)type;
{
	string c_name = [name UTF8String];
	Range c_range;
	string c_type = [type UTF8String];
	
	bool ret = console->clearMonitor(c_name, c_range, c_type);
	
	return (BOOL)ret;
}

- (NSArray *)variableNames
{
	vector<string> c_varNames = console->variableNames();
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
