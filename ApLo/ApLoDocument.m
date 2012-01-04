// 
// ApLoDocument.m
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/03/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//
#import "ApLoDocument.h"

@implementation ApLoDocument

//*****************************************************************************
// Factory methods
//*****************************************************************************init
- (id)init {
	
	if((self=[super init]))
	{
	    [[NSNotificationCenter defaultCenter]addObserver:self
	        selector:@selector(readFromParser:)
	        name:NSFileHandleReadCompletionNotification
	        object:nil
		];
	}
	
	return self;
}
- (void)dealloc {
	
	//
	// Deallocates the receiver.
	// 
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	
	[super dealloc];
}

//*****************************************************************************
// NSDocument implementation
//*****************************************************************************
- (NSString *)windowNibName {
	
	DLog(@"%@  (%@)",_CMD,self);
	
	return @"ApLoDocument";
}
- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	
	DLog(@"%@  aController: %@  (%@)",_CMD,aController,self);
	
	// [aController setShouldCascadeWindows:NO];
	
	[super windowControllerDidLoadNib:aController];
	
	// [[aploWebView window]setFrameAutosaveName:@"xxx"];
	
	[aploWebView setFrameLoadDelegate:self];
	
	[self startMonitoring:self];
}
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	
	/*
	 Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
	You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
	*/
	NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
	@throw exception;
	return nil;
}
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	
	/*
	Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
	You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
	If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
	*/
	NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
	@throw exception;
	return YES;
}
+ (BOOL)autosavesInPlace {
	
    return YES;
}

//*****************************************************************************
// Action methods
//*****************************************************************************
- (IBAction)clear:sender {
	
	[self startMonitoring:self];
}

//*****************************************************************************
// Implementation
//*****************************************************************************
- (void)startMonitoring:sender {
	
	DLog(@"%@  sender: %@  (%@)",_CMD,sender,self);
	
	NSURL	*templateURL=[[NSBundle bundleForClass:[self class]]
		URLForResource:@"Template"
		withExtension:@"html"
	];
	
	ASSERT(templateURL,@"Could not locate Template.html!");
	
	[[aploWebView mainFrame]
		loadRequest:[NSURLRequest requestWithURL:templateURL]
	];
}
- (void)appendHTML:(NSString *)html {
	
	// Gets a list of all <body></body> nodes.
	// DOMDocument		*doc=[[aploWebView mainFrame]DOMDocument];
	// DOMNodeList		*bodyNodeList=[doc getElementsByTagName:@"body"];
	// 
	// // There should be just one in valid HTML, so get the first DOMElement.
	// DOMHTMLElement	*bodyNode=(DOMHTMLElement *)[bodyNodeList item:0];
	
	DOMDocument			*doc=[[aploWebView mainFrame]DOMDocument];
	DOMHTMLBodyElement	*bodyNode=(DOMHTMLBodyElement *)[doc body];
	
	DOMHTMLElement		*newNode=(DOMHTMLElement *)[doc createElement:@"div"];
	
	[newNode setInnerHTML:html];
	
	NSView				*docView=[[[aploWebView mainFrame]frameView]documentView];
	NSRect				docViewBunds=[docView bounds];
	NSScrollView 		*scrollView=[docView enclosingScrollView];
	NSRect 				scrollViewBounds=[[scrollView contentView]bounds];
	
	BOOL				shouldScroll=((scrollViewBounds.origin.y+scrollViewBounds.size.height)==docViewBunds.size.height);
	
	
	// DLog(@"scrollViewBounds: %@",NSStringFromRect(scrollViewBounds));
	// DLog(@"docViewBunds: %@",NSStringFromRect(docViewBunds));
	// DLog(@"shouldScroll: %d",shouldScroll);
	
	// Add the new element to the bodyNode as the last child.
	[bodyNode appendChild:newNode];
	
	if(shouldScroll)
	{
		[bodyNode setValue:[bodyNode valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
	}
}

//*****************************************************************************
// WebFrameLoadDelegate Protocol
//*****************************************************************************
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	
	dispatch_async(dispatch_get_main_queue(),^{
		[self startParser];
	});
}

//*****************************************************************************
// Parser related methods
//*****************************************************************************
- (void)startParser {
	
	if(logParser)
	{
		logParserFH=nil;
		[logParser terminate];
		[logParser release];
		logParser=nil;
	}
	
	NSString	*logParserPath=[[NSBundle bundleForClass:[self class]]
		pathForResource:@"logParser"
		ofType:nil
	];
	NSPipe		*myPipe=[NSPipe pipe];
	
	ASSERT(logParserPath,@"Could not locate logParser!");
	
	logParser=[[NSTask alloc]init];
	
	[logParser setLaunchPath:logParserPath];
	[logParser setArguments:[NSArray arrayWithObjects:
		@"Forge",
		@"/Users/gerti/Clients/Harte-Hanks/Projects/AnvilSuite2",
		nil
	]];
	
	[logParser setStandardOutput:myPipe];
	
	logParserFH=[myPipe fileHandleForReading];
	[logParserFH readInBackgroundAndNotify];
	
	[logParser launch];
}
- (void)readFromParser:(NSNotification *)notification {
	
    if([notification object]!=logParserFH) return;
	
    NSData		*data=[[notification userInfo]objectForKey:NSFileHandleNotificationDataItem];
    NSString	*html=[[NSString alloc]
		initWithData:data
		encoding:NSUTF8StringEncoding
	];
	
	[self appendHTML:html];
	
	[html release];
	
	if(logParser) [logParserFH readInBackgroundAndNotify];
}

//*****************************************************************************
// Synthesized Accessors
//*****************************************************************************
@synthesize aploWebView;
@synthesize identifier;

@end
