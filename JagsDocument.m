//
//  JagsDocument.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-08.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsDocument.h"
#import "JagsLogPanelController.h"
#import "ResultsDocument.h"
#import "RDataParser.h"

NSString * const Jags_DocumentDeactivateNotification = @"JagsDocumentDeactivated";
NSString * const Jags_DocumentActivateNotification = @"JagsDocumentActivated";

@implementation JagsDocument
@synthesize variables, monitors, numberOfChains, burnInNumber, samplesNumber;

- (id)init
{
    self = [super init];
    if (self) {
		// Init the JAGS console-related stuff
		console = [[JagsConsole alloc] init];
		
		valid = NO;
		
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
		modelText  = [[NSAttributedString alloc] initWithString:@""];
		dataText   = [[NSAttributedString alloc] initWithString:@""];
		paramsText = [[NSAttributedString alloc] initWithString:@""];
		
		// Init the settings
		numberOfChains	= 1;
		burnInNumber	= 1000;
		samplesNumber	= 10000;

	}
    return self;
}

- (void)dealloc
{
	[console release];
		
	[modelText release];
	[dataText release];
	[paramsText release];
	
	[variables release];
	[monitors release];
	
	[super dealloc];
}

/**
 * Setter method for the NSArray of variables named in the model.
 * @param	newVariables	The new NSArray of variable names
 */
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
	
	// Connect the text views to the text storages
	[[modelTextView textStorage] setAttributedString:modelText];
	[[dataTextView textStorage] setAttributedString:dataText];
	[[paramsTextView textStorage] setAttributedString:paramsText];
	
	// Set the default font to Monaco 10pt
	[modelTextView  setFont:[NSFont fontWithName:@"Monaco" size:10]];
	[dataTextView   setFont:[NSFont fontWithName:@"Monaco" size:10]];
	[paramsTextView setFont:[NSFont fontWithName:@"Monaco" size:10]];
	
	[self logStringValue:@"Document ready"];
}

/**
 * Returns the MacJags file as an NSTextWrapper
 * @param	typeName	The type of document to return as (must be "MacJags Document")
 * @param	outError	If unsuccessful, a pointer to an error object
 * @return	A new NSFileWrapper object that refers to the current document
 */
- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError
{
	NSAssert([typeName isEqual:@"MacJags Document"], @"File must be of type Jags");
		
	NSFileWrapper *modelWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:[[[modelTextView textStorage] string] UTF8String] length:[[[modelTextView textStorage] string] length]]];
	NSFileWrapper *dataWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:[[[dataTextView textStorage] string] UTF8String] length:[[[dataTextView textStorage] string] length]]];
	NSFileWrapper *paramsWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSData dataWithBytes:[[[paramsTextView textStorage] string] UTF8String] length:[[[paramsTextView textStorage] string] length]]];
	
	NSMutableDictionary *wrappers = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 modelWrapper, @"model",
									 dataWrapper, @"data",
									 paramsWrapper, @"params",
									 nil];
	
	return [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers] autorelease];
}

/**
 * Loads a MacJags file from an NSTextWrapper
 * @param	data		An NSFileWrapper to load
 * @param	typeName	The type of file to load (must be "MacJags Document")
 * @param	error		If unsuccessful, a pointer to an error object
 * @return	TRUE on success, FALSE on failure
 */
- (BOOL)readFromFileWrapper:(NSFileWrapper *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSAssert([typeName isEqual:@"MacJags Document"], @"File must be of type Jags");
	
	[modelText release];
	[dataText release];
	[paramsText release];
	
	modelText  = [[NSAttributedString alloc] initWithString:[self stringForKey:@"model"] attributes:nil];
	dataText   = [[NSAttributedString alloc] initWithString:[self stringForKey:@"data"] attributes:nil];
	paramsText = [[NSAttributedString alloc] initWithString:[self stringForKey:@"params"] attributes:nil];
	
	[statusTextField setStringValue:@"Loaded"];

    return YES;
}

/**
 * Saves the current file and checks the model definition
 */
- (IBAction)saveAndCheckModel:(id)sender
{
	valid = NO;
	
	[self saveDocument:sender];
	[self textDidChange:[NSNotification notificationWithName:@"changed" object:sender]];
	
	NSURL *modelFile  = [self urlForKey:@"model"];
	
	NSError *error = nil;
	NSString *message;

	if ([console checkModel:modelFile error:&error]) {
		message = @"Valid model";
		[self setVariables:[console variableNames]];
		[checkModelButton setState:NSOnState];
		[checkModelButton setTitle:@"Valid"];
		valid = YES;
	} else {
		message = [NSString stringWithFormat:@"Invalid model: %@", [error localizedDescription]];
		[self setVariables:[NSArray array]];
		[checkModelButton setState:NSOffState];
		[checkModelButton setTitle:@"Load"];
		valid = NO;
	}
	
	[statusTextField setStringValue:message];
	[self logStringValue:message];

	[self postNotification:Jags_DocumentActivateNotification];
}

/**
 * Saves the current file, checks the model definition, and runs the model with data and parameters
 * 
 * This is equivalent to doing the following in JAGS:
 *     MODEL IN modelFile
 *     DATA IN dataFile
 *     INITS IN paramsFile
 *     COMPILE, nchains(numberOfChains)
 *     INITIALIZE
 *     UPDATE burnInNumber
 *     MONITOR var1
 *     MONTIRO var2
 *     ...
 *     UPDATE samplesNumber
 */
- (IBAction)saveAndRun:(id)sender
{
	if (!valid)
		[self saveAndCheckModel:sender];
	
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
	
	if ([console compileWithData:data chainNumber:numberOfChains genData:YES]) {
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
	if ([console update:burnInNumber]) {
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
	if ([console update:samplesNumber]) {
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
	if (resDoc == nil) {
		NSLog(@"Couldn't make results window: %@", err);
		return;
	}
	
	[resDoc makeWindowControllers];
	[resDoc showWindows];
	[resDoc setResults:results];
	[resDoc retain];
}

/**
 * Allows JagsDocument to act as delegate to the NSTextViews, resetting the "Load" buttons on a change
 * @param	aNotification	An NSNotification with information on the change
 */
- (void)textDidChange:(NSNotification *)aNotification
{
	valid = NO;
	
	modelText = [modelTextView textStorage];
	dataText = [dataTextView textStorage];
	paramsText = [paramsTextView textStorage];
	
	[checkModelButton setState:NSOffState];
	[checkModelButton setTitle:@"Load"];
	[checkDataButton setState:NSOffState];
	[checkDataButton setTitle:@"Load"];
	[checkParamsButton setState:NSOffState];
	[checkParamsButton setTitle:@"Load"];
}


// Helper methods for dealing with reading and writing files

/**
 * @param	key		The specific file to return (model, data, or param)
 * @return	An NSURL referring to the requested file
 */
- (NSURL *)urlForKey:(NSString *)key
{
	return [[self fileURL] URLByAppendingPathComponent:key];
}

/**
 * @param	key		The specific file to return (model, data, or param)
 * @return	An NSData object referring to the requested file
 */
- (NSData *)dataForKey:(NSString *)key
{
	return [[NSFileManager defaultManager] contentsAtPath:[[self urlForKey:key] path]];
}

/**
 * @param	key		The specific file to return (model, data, or param)
 * @return	An NSString with the contents of the requested file
 */
- (NSString *)stringForKey:(NSString *)key
{
	return [[NSString alloc] initWithData:[self dataForKey:key] encoding:NSASCIIStringEncoding];
}

/**
 * Sends a string to the log window
 * @param	message		An NSString to append to the log window
 */
- (void)logStringValue:(NSString *)message
{
	[statusTextField setStringValue:message];
	NSLog(@"%@", message);
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: Jags_LogSentNotification
	 object: message];
}

/**
 * Helper method to post notifications to the defaultCenter
 * @param	notificationName	The name of the notification to post
 */
- (void)postNotification:(NSString *)notificationName
{
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: notificationName
	 object: self];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [self postNotification:Jags_DocumentActivateNotification];
	
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [self postNotification:Jags_DocumentDeactivateNotification];
}


- (void)windowWillClose:(NSNotification *)notification
{
    [self postNotification:Jags_DocumentDeactivateNotification];
}


@end
