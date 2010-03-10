//
//  JagsDocument.m
//  MacJags
//
//  Created by Aidan Findlater on 10-03-08.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//

#import "JagsDocument.h"
#import "RDataParser.h"

NSString * const JagsDocument_DocumentDeactivateNotification = @"JagsDocumentDeactivated";
NSString * const JagsDocument_DocumentActivateNotification = @"JagsDocumentActivated";

@implementation JagsDocument
@synthesize variables, burnInNumber, samplesNumber;

- (id)init
{
    self = [super init];
    if (self) {
		modelText = [[NSAttributedString alloc] init];
		dataText = [[NSAttributedString alloc] init];
		paramsText = [[NSAttributedString alloc] init];
		console = [[JagsConsole alloc] init];
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
	
	[super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple 
	// NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"JagsDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
	[statusTextField setStringValue:@"Ready"];
	[self reloadTextViews];
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError
{
	NSAssert([typeName isEqual:@"MacJags Document"], @"File must be of type Jags");
	
	if (!documentWrapper) {
		// If the given outError != NULL, ensure that you set *outError when returning nil.
		if (outError != NULL)
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
		return nil;
	}
	
	return documentWrapper;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSAssert([typeName isEqual:@"MacJags Document"], @"File must be of type Jags");
	
	[data retain];
    [documentWrapper release];
    documentWrapper = data;
	
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

- (IBAction)saveAndCheckModel:(id)sender
{
	NSURL *modelFile  = [self urlForKey:@"model"];
	
	NSError *error = nil;
	NSString *message = @"";

	if ([console checkModel:modelFile error:&error]) {
		[statusTextField setStringValue:@"Valid model"];
		[self setVariables:[console variableNames]];
	} else {
		NSString *message = [NSString stringWithFormat:@"Invalid model: %@", [error localizedDescription]];
		[statusTextField setStringValue:message];
		[self logStringValue:message];
	}
	
	[error release];
	[message release];
	
	[self postNotification:JagsDocument_DocumentActivateNotification];
}

- (IBAction)saveAndRun:(id)sender
{
	[self saveAndCheckModel:sender];
	
	NSURL *dataFile   = [self urlForKey:@"data"];
	NSURL *paramsFile = [self urlForKey:@"params"];
	
	// Load the data
	RDataParser *dataParser = [[RDataParser alloc] initWithURL:dataFile];
	NSDictionary *data = [dataParser parseData];
	[dataParser release];
	
	if (!data)
		[self logStringValue:@"Invalid data"];
	else if ([data count] == 0)
		[self logStringValue:@"Missing data"];
	else
		[self logStringValue:@"Valid data"];
	
	// Load the params
	RDataParser *paramsParser = [[RDataParser alloc] initWithURL:paramsFile];
	NSDictionary *params = [paramsParser parseData];
	[paramsParser release];
	
	if (!params)
		[self logStringValue:@"Invalid parameters"];
	else if ([params count] == 0)
		[self logStringValue:@"Missing parameters"];
	else
		[self logStringValue:@"Valid parameters"];
	
	if ([console compileWithData:data chainNumber:[NSNumber numberWithInt:1] genData:NO]) {
		[statusTextField setStringValue:@"Compile succeeded"];
		[self logStringValue:@"Compile succeeded"];
	} else {
		[statusTextField setStringValue:@"Compile failed"];
		[self logStringValue:@"Compile failed"];
	}

}

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
	NSLog(@"%@", message);
}

- (void)postNotification:(NSString *)notificationName
{
    NSNotificationCenter *center;
    center = [NSNotificationCenter defaultCenter];
    
    [center postNotificationName: notificationName
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
