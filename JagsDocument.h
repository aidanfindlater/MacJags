//
//  JagsDocument.h
//  MacJags
//
//  Created by Aidan Findlater on 10-03-08.
//  Copyright 2010 Aidan Findlater. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "JagsConsole.h"

extern NSString * const Jags_DocumentDeactivateNotification;
extern NSString * const Jags_DocumentActivateNotification;

/**
 * The JagsDocument class manages and displays the files that make up a .jags file.
 * 
 * JagsDocument objects contain three separate files:
 *
 *     - model: the JAGS model definition
 *     - data: the observed data, as R variables
 *     - params: the parameters/initial values to use
 *
 * The files are stored on the hard drive as a directory with a .jags extension.
 */
@interface JagsDocument : NSDocument
{
	JagsConsole *console;		/**< Pointer to the JAGS Console class wrapper		*/
	BOOL valid;					/**< Flag for the validity of the model and data	*/
	
	NSArray *variables;			/**< The names of the variables in the model	*/
	NSMutableArray *monitors;	/**< Boolean flags of variables to monitor		*/
	NSNumber *burnInNumber;		/**< Number of reps for burn-in					*/
	NSNumber *samplesNumber;	/**< Number of reps for sampling				*/
		
	NSAttributedString *modelText;	/**< Text of the model file			*/
	NSAttributedString *dataText;	/**< Text of the data file			*/
	NSAttributedString *paramsText; /**< Text of the parameters file	*/
	
	IBOutlet NSTextView *modelTextView;
	IBOutlet NSTextView *dataTextView;
	IBOutlet NSTextView *paramsTextView;
	
	IBOutlet NSButton *checkModelButton;
	IBOutlet NSButton *checkDataButton;
	IBOutlet NSButton *checkParamsButton;
	
	IBOutlet NSTextField *statusTextField;
}

@property (retain,readwrite) NSArray *variables;
@property (retain,readwrite) NSMutableArray *monitors;
@property (retain,readwrite) NSNumber *burnInNumber;
@property (retain,readwrite) NSNumber *samplesNumber;

// Saves then checks that the model is valid
- (IBAction)saveAndCheckModel:(id)sender;

// Saves then compiles and runs the model
- (IBAction)saveAndRun:(id)sender;

// Helper methods
- (void)reloadTextViews;
- (void)logStringValue:(NSString *)message;
- (void)postNotification:(NSString *)notificationName;
- (void)textDidChange:(NSNotification *)aNotification;

// Methods for working with the NSFileWrapper
- (NSURL *)urlForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

@end
