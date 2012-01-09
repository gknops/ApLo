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
		readBuffer=[[NSMutableData alloc]init];
	}
	
	return self;
}
- (void)dealloc {
	
	//
	// Deallocates the receiver.
	// 
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	
	[readBuffer release];
	
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
	
	[aploWebView setPreferencesIdentifier:@"ApLoWebViewPreferences"];
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
	
	DOMDocument			*doc=[[aploWebView mainFrame]DOMDocument];
	DOMHTMLBodyElement	*bodyNode=(DOMHTMLBodyElement *)[doc body];
	
	while(bodyNode.lastChild)
	{
		[bodyNode removeChild:bodyNode.lastChild];
	}
}

//*****************************************************************************
// Find Panel support
//*****************************************************************************
- (void)performApLoFindPanelAction:(id)sender {
	
	NSInteger	tag=[sender tag];
	
	switch(tag)
	{
		case NSTextFinderActionShowFindInterface:
	    	[searchField.window makeFirstResponder:searchField];
			break;
		case NSTextFinderActionNextMatch:
			[self findNext:sender];
			break;
		case NSTextFinderActionPreviousMatch:
			[self findPrevious:sender];
			break;
		case NSTextFinderActionSetSearchString:
			[self setSearchStringFromSelection];
			break;
		default:
			ERRLog(@"performApLoFindPanelAction: for sender tag %ld not supported!",(long)tag);
			NSBeep();
			break;
	}
}
- (void)setSearchStringFromSelection {
	
	DOMRange	*dr=[aploWebView selectedDOMRange];
	NSString	*s=dr.text;
	
	if(!s || [s length]==0)
	{
		NSBeep();
		
		return;
	}
	
	self.searchString=s;
}

//*****************************************************************************
// Search support
//*****************************************************************************
- (void)setSearchString:(NSString *)newSearchString {
	
	id old=searchString;
	searchString=[newSearchString copy];
	[old release];
	
    NSPasteboard	*pasteboard=[NSPasteboard pasteboardWithName:NSFindPboard];
	
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:searchString forType:NSStringPboardType];
	
	NSString		*escapedSearchString=[searchString
		stringByReplacingOccurrencesOfString:@"'"
		withString:@"\\'"
	];
	
	if(!escapedSearchString || [escapedSearchString length]==0)
	{
		[aploWebView stringByEvaluatingJavaScriptFromString:@"apLoRemoveHighlights()"];
		self.numMatches=0;
	}
	else if([searchString length]>2)
	{
	    NSString	*result=[aploWebView stringByEvaluatingJavaScriptFromString:
			[NSString stringWithFormat:@"apLoHighlightString('%@')",escapedSearchString]
		];
		
		self.numMatches=[result integerValue];
	}
	
	[self forceWebViewRedraw];
}
- (IBAction)findNext:sender {
	
	[self findWithJS:@"apLoFindNext()"];
}
- (IBAction)findPrevious:sender {
	
	[self findWithJS:@"apLoFindPrevious()"];
}
- (IBAction)findButtonClicked:sender {
	
	[self findWithJS:([sender selectedSegment])?@"apLoFindNext()":@"apLoFindPrevious()"];
}
- (void)findWithJS:(NSString *)javascript {
	
	if(self.numMatches<2)
	{
		NSBeep();
		
		return;
	}
	
	[aploWebView stringByEvaluatingJavaScriptFromString:javascript];
	[self forceWebViewRedraw];
}
- (BOOL)searchButtonsEnabled {
	
	return (self.numMatches>1);
}
+ (NSSet *)keyPathsForValuesAffectingSearchButtonsEnabled {
	
	return [NSSet setWithObjects:@"numMatches",nil];
}
- (void)forceWebViewRedraw {
	
	[aploWebView makeTextLarger:self];
	[aploWebView makeTextSmaller:self];
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
	
	NSString	*html=[NSString
		stringWithContentsOfURL:templateURL
		encoding:NSUTF8StringEncoding
		error:NULL
	];
	
	ASSERT(html,@"Could not load Template.html!");
	
	NSString	*parserPath=[self parserPath];
	NSString	*css=[self readFromParser:parserPath withFlag:@"-css"];
	NSString	*js=[self readFromParser:parserPath withFlag:@"-js"];
	
	html=[html stringByReplacingOccurrencesOfString:@"/*PARSER_CSS_HERE*/" withString:css];
	html=[html stringByReplacingOccurrencesOfString:@"/*PARSER_JAVASCRIPT_HERE*/" withString:js];
	
	DLog(@"html: %@",html);
	
	[[aploWebView mainFrame]loadHTMLString:html baseURL:[NSURL URLWithString:@"file:///"]];
	
	// [[aploWebView mainFrame]
	// 	loadRequest:[NSURLRequest requestWithURL:templateURL]
	// ];
}
- (NSString *)readFromParser:(NSString *)parserPath withFlag:(NSString *)flag {
	
	NSTask	*task=[[NSTask alloc]init];
	NSPipe	*pipe=[NSPipe pipe];
	
	[task setLaunchPath:parserPath];
	[task setArguments:[NSArray arrayWithObjects:flag,nil]];
	[task setStandardOutput:pipe];
	[task launch];
	
	NSData	*data=[[pipe fileHandleForReading]readDataToEndOfFile];
	
	[task waitUntilExit];
	[task release];
	
	return  [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]autorelease];
}
- (void)appendHTML:(NSString *)html {
	
	// Gets a list of all <body></body> nodes.
	// DOMDocument		*doc=[[aploWebView mainFrame]DOMDocument];
	// DOMNodeList		*bodyNodeList=[doc getElementsByTagName:@"body"];
	// 
	// // There should be just one in valid HTML, so get the first DOMElement.
	// DOMHTMLElement	*bodyNode=(DOMHTMLElement *)[bodyNodeList item:0];
	
	DLog(@"appendHTML: %@",html);
	
	
	DOMDocument			*doc=[[aploWebView mainFrame]DOMDocument];
	DOMHTMLBodyElement	*bodyNode=(DOMHTMLBodyElement *)[doc body];
	
	DOMHTMLElement		*newNode=(DOMHTMLElement *)[doc createElement:@"div"];
	
	[newNode setInnerHTML:html];
	
	NSView				*docView=[[[aploWebView mainFrame]frameView]documentView];
	NSRect				docViewBounds=[docView bounds];
	NSScrollView 		*scrollView=[docView enclosingScrollView];
	NSRect 				scrollViewBounds=[[scrollView contentView]bounds];
	
	BOOL				shouldScroll=((scrollViewBounds.origin.y+scrollViewBounds.size.height)==docViewBounds.size.height);
	
	
	// DLog(@"scrollViewBounds: %@",NSStringFromRect(scrollViewBounds));
	// DLog(@"docViewBounds: %@",NSStringFromRect(docViewBounds));
	// DLog(@"shouldScroll: %d",shouldScroll);
	
	// Add the new element to the bodyNode as the last child.
	[bodyNode appendChild:newNode];
	
	if(shouldScroll)
	{
		[bodyNode setValue:[bodyNode valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
	}
}
- (NSString *)parserPath {
	
	NSString	*parserName=@"xcodebuildParser";
	
	NSString	*parserPath=[[NSBundle bundleForClass:[self class]]
		pathForResource:parserName
		ofType:nil
	];
	
	ASSERT(parserPath,@"Could not find parser '%@'",parserName);
	
	return parserPath;
}
- (void)processNewData {
	
	NSString	*html=nil;
	
	while((html=[self getLineFromBuffer]))
	{
		// <script type="text/javascript">toggleVisibilityOfElementsNamed('levelID00007');</script>
		if([html hasPrefix:@"<script type=\"text/javascript\">"] && [html hasSuffix:@"</script>"])
		{
			NSString	*js=[html substringWithRange:NSMakeRange(31,[html length]-40)];
			
			[aploWebView stringByEvaluatingJavaScriptFromString:js];
		}
		else
		{
			[self appendHTML:html];
		}
	}
}
- (NSString *)getLineFromBuffer {
	
	NSString	*line=nil;
	
	@synchronized(readBuffer)
	{
		const void	*bytes=[readBuffer bytes];
		const void	*p=strnstr(bytes,"\n",[readBuffer length]);
		
		if(p)
		{
			line=[[[NSString alloc]
				initWithBytes:bytes
				length:p-bytes
				encoding:NSUTF8StringEncoding
			]autorelease];
			
			[readBuffer
				replaceBytesInRange:NSMakeRange(0,p-bytes+1)
				withBytes:NULL
				length:0
			];
		}
	}
	
	return line;
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
	
	[self terminateParser];
	
	NSString	*parserPath=[self parserPath];
	NSPipe		*myPipe=[NSPipe pipe];
	
	ASSERT(parserPath,@"Could not locate logParser!");
	
	logParser=[[NSTask alloc]init];
	
	[logParser setLaunchPath:parserPath];
	[logParser setArguments:[NSArray arrayWithObjects:
		@"Forge",
		@"/Users/gerti/Clients/Harte-Hanks/Projects/AnvilSuite2",
		nil
	]];
	
	[logParser setStandardOutput:myPipe];
	
	logParserFH=[myPipe fileHandleForReading];
	
    [[NSNotificationCenter defaultCenter]addObserver:self
        selector:@selector(readFromParser:)
        name:NSFileHandleReadCompletionNotification
        object:logParserFH
	];
	
	[logParserFH readInBackgroundAndNotify];
	
	[logParser launch];
}
- (void)readFromParser:(NSNotification *)notification {
	
    if([notification object]!=logParserFH) return;
	
    NSData		*data=[[notification userInfo]objectForKey:NSFileHandleNotificationDataItem];
	
	if(!data || [data length]==0)
	{
		[self terminateParser];
		
		return;
	}
	
	@synchronized(readBuffer)
	{
		[readBuffer appendData:data];
	}
	
	[self processNewData];
	
	if(logParser) [logParserFH readInBackgroundAndNotify];
}
- (void)terminateParser {
	
	if(!logParser) return;
	
    [[NSNotificationCenter defaultCenter]removeObserver:self
        name:NSFileHandleReadCompletionNotification
        object:logParserFH
	];
	
	logParserFH=nil;
	[logParser terminate];
	[logParser release];
	logParser=nil;
}

//*****************************************************************************
// NSWindowDelegate Protocol
//*****************************************************************************
- (void)windowDidBecomeKey:(NSNotification *)notification {
	
    NSPasteboard	*pasteboard=[NSPasteboard pasteboardWithName:NSFindPboard];
	NSString		*s=[pasteboard stringForType:NSStringPboardType];
	
	if(s && [s length]>0 && ![s isEqualToString:searchString])
	{
		self.searchString=s;
	}
}

//*****************************************************************************
// Synthesized Accessors
//*****************************************************************************
@synthesize searchField;
@synthesize searchString;
@synthesize numMatches;
@dynamic searchButtonsEnabled;
@synthesize aploWebView;
@synthesize identifier;

@end
