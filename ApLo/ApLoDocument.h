// 
// ApLoDocument.h
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/03/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//

@class WebFrame, WebView;

@interface ApLoDocument: NSDocument <NSWindowDelegate>
{
	NSTask								*logParser;
	NSFileHandle						*logParserFH;
	NSFileHandle						*logParserErrorFH;
	
	NSMutableData						*readBuffer;
	
	
	PROP(assign,IBOutlet) NSSearchField	*searchField;
	PROP(assign,IBOutlet) WebView		*aploWebView;
	PROP(copy) NSString					*identifier;
	
	PROP(copy,nonatomic) NSString		*searchString;
	PROP(assign) NSInteger				numMatches;
	
	//VPROP(assign) BOOL				searchButtonsEnabled;
	
	PROP(retain) NSDictionary			*taskEnvironment;
	
	PROP(copy) NSString					*previewPath;
}
@property (assign) IBOutlet	NSSearchField	*searchField;
@property (assign) IBOutlet	WebView			*aploWebView;
@property (copy)				NSString		*identifier;
@property (copy,nonatomic)		NSString		*searchString;
@property (assign)				NSInteger		numMatches;
@property (assign)				BOOL			searchButtonsEnabled;
@property (retain)				NSDictionary	*taskEnvironment;
@property (copy)				NSString		*previewPath;

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
- (BOOL)isDocumentEdited;

//*****************************************************************************
// Action methods
//*****************************************************************************
- (IBAction)clear:sender;

//*****************************************************************************
// Find Panel support
//*****************************************************************************
- (void)performApLoFindPanelAction:(id)sender;
- (void)setSearchStringFromSelection;

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
- (void)forceWebViewRedraw;
- (void)checkFindPasteboard;

//*****************************************************************************
// Implementation
//*****************************************************************************
- (void)startMonitoring:sender;
- (NSString *)readFromParser:(NSString *)parserPath withFlag:(NSString *)flag;
- (void)appendHTML:(NSString *)html;
- (void)processNewData;
- (NSString *)getLineFromBuffer;
- (void)deleteApLoFileIfRequested:(NSString *)path;
- (BOOL)relaunchWithEnvironment:(NSDictionary *)newEnv filename:(NSString *)filename;
- (BOOL)showPreview:(BOOL)isReload;
- (void)showWebInspector:(BOOL)isReload;

//*****************************************************************************
// WebFrameLoadDelegate Protocol
//*****************************************************************************
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

//*****************************************************************************
// Parser related methods
//*****************************************************************************
- (NSString *)parserPath;
- (void)startParser;
- (void)readFromParser:(NSNotification *)notification;
- (void)readErrorFromParser:(NSNotification *)notification;
- (void)terminateParser;

//*****************************************************************************
// Observers
//*****************************************************************************
- (void)defaultsChanged:(NSNotification *)aNotification;

//*****************************************************************************
// NSWindowDelegate Protocol
//*****************************************************************************
- (void)windowWillClose:(NSNotification *)notification;

//*****************************************************************************
// Synthesized Accessors
//*****************************************************************************
// @synthesize previewPath;
// @synthesize taskEnvironment;
// @synthesize searchField;
// @synthesize searchString;
// @synthesize numMatches;
// @dynamic searchButtonsEnabled;
// @synthesize aploWebView;
// @synthesize identifier;

@end
