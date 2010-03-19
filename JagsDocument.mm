//
//  JagsDocument.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-08.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsDocument.h"
#import "ResultsDocument.h"
#import "RDataParser.h"

NSString * const JagsDocument_DocumentDeactivateNotification = @"JagsDocumentDeactivated";
NSString * const JagsDocument_DocumentActivateNotification = @"JagsDocumentActivated";

@implementation JagsDocument
@synthesize variables, monitors, burnInNumber, samplesNumber;

- (id)init
{
    self = [super init];
    if (self) {
		// Init the JAGS console-related stuff
		console = [[JagsConsole alloc] init];
		
		// Load the default modules
		if ([JagsConsole loadModule:@"basemod"])
			[self logStringValue:@"Loaded module 'basemod'"];
		else
			[self logStringValue:@"Could not load module 'basemod'"];
		
		if ([JagsConsole loadModule:@"bugs"])
			[self logStringValue:@"Loaded module 'bugs'"];
		else
			[self logStringValue:@"Could not load module 'bugs'"];
		
		[self setVariables:[[NSArray alloc] init]];
		
		// Init the text editing-related stuff
		modelText  = [[NSAttributedString alloc] init];
		dataText   = [[NSAttributedString alloc] init];
		paramsText = [[NSAttributedString alloc] init];
		burnInNumber  = [[NSNumber alloc] init];
		samplesNumber = [[NSNumber alloc] init];
		
		// Init the file architecture
		NSFileWrapper *modelWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData data]];
		NSFileWrapper *dataWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData data]];
		NSFileWrapper *paramsWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData data]];
		
		NSMutableDictionary *fileWrappers = 
		[NSMutableDictionary
		 dictionaryWithObjects:
		 [NSArray arrayWithObjects:modelWrapper,dataWrapper,paramsWrapper, nil] 
		forKeys:
		 [NSArray arrayWithObjects:@"model",@"data",@"params", nil]];
		
		documentWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:fileWrappers];
		
		[modelWrapper  release]; modelWrapper  = nil;
		[dataWrapper   release]; dataWrapper   = nil;
		[paramsWrapper release]; paramsWrapper = nil;
    }
    return self;
}

- (void)dealloc
{
	[console release];
	
	[documentWrapper release];
	
	[modelText release];
	[dataText release];
	[paramsText release];
	
	[variables release];
	[monitors release];
	[burnInNumber release];
	[samplesNumber release];
	
	[super dealloc];
}

- (void)setVariables:(NSArray *)newVariables
{
	if (variables != newVariables) {
		[variables release];
		variables = [newVariables retain];
	}
	
	[monitors release];
	monitors = [[NSMutableArray alloc] init];
	for (NSString *varName in variables)
		[monitors addObject:[NSNumber numberWithBool:NO]];
}

- (NSString *)windowNibName
{
    return @"JagsDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
	[self logStringValue:@"Document ready"];
	[self reloadTextViews];
}

// Returns file as an NSTextWrapper
- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError
{
	NSAssert([typeName isEqual:@"MacJags Document"], @"File must be of type Jags");
	
	if (!documentWrapper) {
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
		return nil;
	}
	
	NSFileWrapper *modelWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:[[[modelTextView textStorage] string] UTF8String] length:[[[modelTextView textStorage] string] length]]];
	NSFileWrapper *dataWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:[[[dataTextView textStorage] string] UTF8String] length:[[[dataTextView textStorage] string] length]]];
	NSFileWrapper *paramsWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:[[[paramsTextView textStorage] string] UTF8String] length:[[[paramsTextView textStorage] string] length]]];
	
	NSMutableDictionary *wrappers = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 modelWrapper, @"model",
									 dataWrapper, @"data",
									 paramsWrapper, @"params",
									 nil];
	[documentWrapper release];
	documentWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers];
	
	return documentWrapper;
}

// Loads file from an NSTextWrapper
- (BOOL)readFromFileWrapper:(NSFileWrapper *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSAssert([typeName isEqual:@"MacJags Document"], @"File must be of type Jags");
	
	if (documentWrapper != data) {
		[documentWrapper release];
		documentWrapper = [data retain];
	}
	
	[modelText release];
	[dataText release];
	[paramsText release];
	
	modelText  = [[NSAttributedString alloc] initWithString:[self stringForKey:@"model"] attributes:nil];
	dataText   = [[NSAttributedString alloc] initWithString:[self stringForKey:@"data"] attributes:nil];
	paramsText = [[NSAttributedString alloc] initWithString:[self stringForKey:@"params"] attributes:nil];
	
	[self reloadTextViews];
	
	[statusTextField setStringValue:@"Loaded"];

    return YES;
}

// Checks the model definition
- (IBAction)saveAndCheckModel:(id)sender
{
	NSURL *modelFile  = [self urlForKey:@"model"];
	
	NSError *error = nil;
	NSString *message;

	if ([console checkModel:modelFile error:&error]) {
		message = @"Valid model";
		[self setVariables:[console variableNames]];
		[checkModelButton setState:NSOnState];
		[checkModelButton setTitle:@"Valid"];
	} else {
		message = [NSString stringWithFormat:@"Invalid model: %@", [error localizedDescription]];
		[self setVariables:[NSArray array]];
		[checkModelButton setState:NSOffState];
		[checkModelButton setTitle:@"Check"];
	}
	
	[statusTextField setStringValue:message];
	[self logStringValue:message];

	[self postNotification:JagsDocument_DocumentActivateNotification];
}

// Runs the model with data and parameters
- (IBAction)saveAndRun:(id)sender
{
	// Load the files
	NSURL *dataFile   = [self urlForKey:@"data"];
	NSURL *paramsFile = [self urlForKey:@"params"];
	
	
	[self logStringValue:@"Clearing the model..."];
	[console clearModel];
	
	
	[self logStringValue:@"Loading data from file..."];
	RDataParser *dataParser = [[RDataParser alloc] init];
	NSDictionary *data = [dataParser parseURL:dataFile];
	[dataParser release];
	
	if (!data) {
		[self logStringValue:@"Invalid data."];
		return;
	} else if ([data count] == 0) {
		[self logStringValue:@"Missing data."];
		return;
	} else {
		[self logStringValue:@"Valid data."];
	}
	
	
	[self logStringValue:@"Loading parameters from file..."];
	RDataParser *paramsParser = [[RDataParser alloc] init];
	NSDictionary *params = [paramsParser parseURL:paramsFile];
	[paramsParser release];
	
	if (!params) {
		[self logStringValue:@"Invalid parameters."];
	} else if ([params count] == 0) {
		[self logStringValue:@"Missing parameters."];
	} else {
		[self logStringValue:@"Valid parameters."];
	}
	
	if ([console compileWithData:data chainNumber:1 genData:YES]) {
		[self logStringValue:@"Compiled model."];
	} else {
		[self logStringValue:@"Could not compile model."];
		return;
	}
	
	
	[self logStringValue:@"Initializing model..."];
	if ([console initialize]) {
		[self logStringValue:@"Initialized model."];
	} else {
		[self logStringValue:@"Could not initialize model."];
		return;
	}
	
	
	[self logStringValue:@"Running burn-in..."];
	if ([console update:2000]) {
		[self logStringValue:@"Burn-in complete."];
	} else {
		[self logStringValue:@"Could not run burn-in."];
		return;
	}
	
	
	[self logStringValue:@"Setting monitors..."];
	for (NSUInteger i=0; i<[variables count]; i++) {
		if ([[monitors objectAtIndex:i] isEqual:[NSNumber numberWithInt:1]]) {
			[console setMonitor:[variables objectAtIndex:i]
			   thinningInterval:1
					monitorType:@"trace"];
			[self logStringValue:[NSString stringWithFormat:@"Added monitor for %@",[variables objectAtIndex:i]]];
		}
	}
	
	
	[self logStringValue:@"Running model..."];
	if ([console update:20000]) {
		[self logStringValue:@"Model run complete."];
	} else {
		[self logStringValue:@"Could not run model."];
		return;
	}
	
	
	[self logStringValue:@"Loading results..."];
	NSDictionary *results = [console dumpMonitors];
	if (results) {
		NSLog(@"Results loaded.");
	} else {
		[self logStringValue:@"Could not load results."];
	}
	
	NSError *err;
	ResultsDocument *resDoc = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"MacJags Results" error:&err];
	if (err)
		NSLog(@"Couldn't make results window: %@", err);
	[resDoc makeWindowControllers];
	[resDoc showWindows];
	[resDoc setResults:results];
	[resDoc retain];
}

// Allows JagsDocument to act as delegate to the NSTextViews
// Resets the "Check" buttons on edit
- (void)textDidChange:(NSNotification *)aNotification
{
	[checkModelButton setState:NSOffState];
	[checkModelButton setTitle:@"Check"];
	[checkDataButton setState:NSOffState];
	[checkDataButton setTitle:@"Check"];
	[checkParamsButton setState:NSOffState];
	[checkParamsButton setTitle:@"Check"];
}


// Helper methods for dealing with reading and writing files

- (NSString *)filenameForKey:(NSString *)key
{
	return [[[documentWrapper fileWrappers] objectForKey:key] filename];
}

- (NSURL *)urlForKey:(NSString *)key
{
	return [[self fileURL] URLByAppendingPathComponent:[self filenameForKey:key]];
}

- (NSData *)dataForKey:(NSString *)key
{
	return [[[documentWrapper fileWrappers] objectForKey:key] regularFileContents];
}

- (NSString *)stringForKey:(NSString *)key
{
	return [[NSString alloc] initWithData:[self dataForKey:key] encoding:NSASCIIStringEncoding];
}

- (void)reloadTextViews
{
	if (modelTextView)
		[[modelTextView textStorage] setAttributedString:modelText];
	if (dataTextView)
		[[dataTextView textStorage] setAttributedString:dataText];
	if (paramsTextView)
		[[paramsTextView textStorage] setAttributedString:paramsText];
}

- (void)logStringValue:(NSString *)message
{
	[statusTextField setStringValue:message];
	NSLog(@"%@", message);
}

- (void)postNotification:(NSString *)notificationName
{
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: notificationName
	 object: self];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [self postNotification:JagsDocument_DocumentActivateNotification];
	
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [self postNotification:JagsDocument_DocumentDeactivateNotification];
}


- (void)windowWillClose:(NSNotification *)notification
{
    [self postNotification:JagsDocument_DocumentDeactivateNotification];
}


@end
