//
//  JagsConsole.mm
//  MacJags
//
//  Created by Aidan Findlater on 10-03-05.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsConsole.h"
#import <dlfcn.h>

#define id Id
#import <JAGS/compiler/ParseTree.h>
#import <JAGS/Module.h>
#import <JAGS/model/BUGSModel.h>
#import <JAGS/model/Monitor.h>
#import <JAGS/Console.h>
#import <string>
#import <sstream>
#undef id

using std::map;
using std::string;
using std::vector;
using std::pair;
using std::list;

@implementation JagsConsole

- (id)init
{
	self = [super init];
	if (self) {
		console = new Console(std::cout, std::cerr);
		[JagsConsole loadDLLs];
	}
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


- (BOOL)initialize
{
	return (BOOL)console->initialize();
}

- (BOOL)update:(NSUInteger)numIterations
{
	return (BOOL)console->update(numIterations);
}

- (BOOL)setMonitor:(NSString *)name
  thinningInterval:(NSUInteger)thin
	   monitorType:(NSString *)type
{
	return (BOOL)console->setMonitor([name UTF8String], Range(), thin, [type UTF8String]);
}

- (BOOL)clearMonitor:(NSString *)name
		 monitorType:(NSString *)type;
{
	string c_name = [name UTF8String];
	string c_type = [type UTF8String];
	
	return (BOOL)console->clearMonitor(c_name, Range(), c_type);
}

- (void)clearAllMonitors
{
	const BUGSModel *model = console->model();
	const list<MonitorControl> monitors = model->monitors();
	for (list<MonitorControl>::const_iterator p = monitors.begin(); p != monitors.end(); ++p) {
		console->clearMonitor(p->monitor()->name(), Range(), "trace");
	}
}

- (NSDictionary *)dumpMonitors
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	for (list<MonitorControl>::const_iterator p = console->model()->monitors().begin();
		 p != console->model()->monitors().end(); ++p) {
		vector<double> const &v = p->monitor()->dump().value();
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:v.size()];
		for (vector<double>::const_iterator i = v.begin(); i != v.end(); ++i) {
			[arr addObject:[NSNumber numberWithDouble:*i]];
		}
		[dict setObject:arr forKey:[NSString stringWithUTF8String:p->monitor()->name().c_str()]];
	}
	return dict;
}

- (BOOL)dumpState:(NSDictionary **)dataTable
		  rngName:(NSString **)name
		 dumpType:(DumpType)type
			chain:(NSUInteger)chainNumber
{
	map<string,SArray> c_dataTable;
	string c_name;
	
	if (!console->dumpState(c_dataTable, c_name, type, chainNumber))
		return NO;
	
	NSMutableDictionary *newDataTable = [NSMutableDictionary dictionary];
	
	for (map<string,SArray>::iterator p = c_dataTable.begin(); p !=c_dataTable.end(); ++p) {
		vector<double> c_data = (*p).second.value();
		NSMutableArray *data = [NSMutableArray arrayWithCapacity:c_data.size()];
		for (vector<double>::iterator i = c_data.begin(); i != c_data.end(); ++i) {
			[data addObject:[NSNumber numberWithDouble:(*i)]];
		}
		[newDataTable
		 setObject:data forKey:[NSString stringWithUTF8String:(*p).first.c_str()]];
	}
	
	*dataTable = [NSDictionary dictionaryWithDictionary:newDataTable];
	*name = [NSString stringWithUTF8String:c_name.c_str()];
	
	return YES;
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

- (BOOL)adaptive
{
	return (BOOL)console->isAdapting();
}


- (void)clearModel
{
	console->clearModel();
}

+ (BOOL)loadModule:(NSString *)moduleName
{
	[JagsConsole unloadModule:moduleName];
	return (BOOL)Console::loadModule([moduleName UTF8String]);
}

+ (BOOL)unloadModule:(NSString *)moduleName
{
	return (BOOL)Console::unloadModule([moduleName UTF8String]);
}

+ (NSArray *)loadedModules
{
	std::list<Module *> c_modules = Console::loadedModules();
	NSMutableArray *modules = [[NSMutableArray alloc] init];
	
	list<Module *>::const_iterator p;
    for (p = c_modules.begin(); p != c_modules.end(); ++p) {
		[modules addObject:
		 [NSString stringWithUTF8String:(*p)->name().c_str()]];
	}
	
	return modules;
}

// Get the pluggable modules ready for loading
static BOOL loadedDLLs;
+ (void)loadDLLs
{
	if (loadedDLLs) return;
	
	NSString *modulesPath = @"/usr/local/lib/JAGS/modules-2.0.0/";
	NSDirectoryEnumerator *modEnumerator = [[NSFileManager defaultManager]
											enumeratorAtPath:modulesPath];
	for (NSString *mod in modEnumerator) {
		if ([[mod pathExtension] isEqualToString:@"so"]) {
			dlopen([[NSString stringWithFormat:@"%@%@",modulesPath,mod] UTF8String], RTLD_LAZY);
		}
	}
	
	loadedDLLs = NO;
}

@end

