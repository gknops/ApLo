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
}
@property (assign) IBOutlet	WebView		*aploWebView;
@property (copy)				NSString	*identifier;

//*****************************************************************************
// Factory methods
//*****************************************************************************init
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
// @synthesize aploWebView;
// @synthesize identifier;

@end
