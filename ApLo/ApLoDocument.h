// 
// ApLoDocument.h
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/03/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//

@class WebFrame, WebView;

@interface ApLoDocument: NSDocument
{
	NSTask							*logParser;
	NSFileHandle					*logParserFH;
	
	PROP(assign,IBOutlet) WebView	*aploWebView;
	PROP(copy) NSString				*identifier;
	
	PROP(copy,nonatomic) NSString	*searchString;
	PROP(assign) NSInteger			numMatches;
	
	//VPROP(assign) BOOL			searchButtonsEnabled;
}
@property (assign) IBOutlet	WebView		*aploWebView;
@property (copy)				NSString	*identifier;
@property (copy,nonatomic)		NSString	*searchString;
@property (assign)				NSInteger	numMatches;
@property (assign)				BOOL		searchButtonsEnabled;

//*****************************************************************************
// Factory methods
//*****************************************************************************
- (id)init;
- (void)dealloc;

//*****************************************************************************
// NSDocument implementation
//*****************************************************************************
- (NSString *)windowNibName;
- (void)windowControllerDidLoadNib:(NSWindowController *)aController;
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError;
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError;
+ (BOOL)autosavesInPlace;

//*****************************************************************************
// Action methods
//*****************************************************************************
- (IBAction)clear:sender;

//*****************************************************************************
// Search support
//*****************************************************************************
- (void)setSearchString:(NSString *)newSearchString;
- (IBAction)findNext:sender;
- (IBAction)findPrevious:sender;
- (IBAction)findButtonClicked:sender;
- (void)findWithJS:(NSString *)javascript;
- (BOOL)searchButtonsEnabled;
+ (NSSet *)keyPathsForValuesAffectingSearchButtonsEnabled;

//*****************************************************************************
// Implementation
//*****************************************************************************
- (void)startMonitoring:sender;
- (void)appendHTML:(NSString *)html;

//*****************************************************************************
// WebFrameLoadDelegate Protocol
//*****************************************************************************
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

//*****************************************************************************
// Parser related methods
//*****************************************************************************
- (void)startParser;
- (void)readFromParser:(NSNotification *)notification;

//*****************************************************************************
// Synthesized Accessors
//*****************************************************************************
// @synthesize searchString;
// @synthesize numMatches;
// @dynamic searchButtonsEnabled;
// @synthesize aploWebView;
// @synthesize identifier;

@end
