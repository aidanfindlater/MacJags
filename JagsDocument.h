//
//  JagsDocument.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-08.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import "JagsConsole.h"

@interface JagsDocument : NSDocument
{
	JagsConsole *console;
	
	NSFileWrapper *documentWrapper;
	
	NSAttributedString *modelText;
	NSAttributedString *dataText;
	NSAttributedString *paramsText;
	
	IBOutlet NSTextView *modelTextView;
	IBOutlet NSTextView *dataTextView;
	IBOutlet NSTextView *paramsTextView;
	IBOutlet NSTextField *statusTextField;
}

// Saves then checks that the model is valid
- (IBAction)saveAndCheckModel:(id)sender;

// Saves then compiles and runs the model
- (IBAction)saveAndRun:(id)sender;

// Helper methods
- (void)reloadTextViews;
- (void)logStringValue:(NSString *)message;

// Methods for working with the NSFileWrapper
- (NSString *)filenameForKey:(NSString *)key;
- (NSURL *)urlForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

@end
