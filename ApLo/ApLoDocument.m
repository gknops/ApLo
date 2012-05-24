// 
// ApLoDocument.m
// ApLo (BITart)
// 
// Created by Gerd Knops on 01/03/12.
// Copyright 2012 BITart Consulting, Gerd Knops. All rights reserved.
//
#import "ApLoDocument.h"
#import "ApLoAppDelegate.h"

@implementation ApLoDocument

//*****************************************************************************
// Factory methods
//*****************************************************************************
- (id)init {
	
	if((self=[super init]))
	{
		readBuffer=[[NSMutableData alloc]init];
		
	    [[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(defaultsChanged:)
			name:NSUserDefaultsDidChangeNotification
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
	
	[readBuffer release];
	self.previewPath=nil;
	
	[super dealloc];
}

//*****************************************************************************
// NSDocument implementation
//*****************************************************************************
- (NSString *)windowNibName {
	
	return @"ApLoDocument";
}
- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	
	[self defaultsChanged:nil];
	
	if(self.taskEnvironment)
	{
		NSString	*windowName=[self.taskEnvironment objectForKey:@"APLO_WINDOW_NAME"];
		
		if(windowName)
		{
			[aController setShouldCascadeWindows:NO];
			[aController setWindowFrameAutosaveName:windowName];
			[self setDisplayName:windowName];
		}
	}
	
	[super windowControllerDidLoadNib:aController];
	
	[aploWebView setPreferencesIdentifier:@"ApLoWebViewPreferences"];
	[aploWebView setFrameLoadDelegate:self];
	
	if(self.taskEnvironment)
	{
		[self startMonitoring:self];
	}
}
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	
	return nil;
}
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	
	self.taskEnvironment=[[NSApp delegate]environmentDictionaryFromData:data];
	self.previewPath=[self.taskEnvironment objectForKey:@"APLO_PREVIEW_HTML_FILE"];
	
	dispatch_async(dispatch_get_main_queue(),^{
		[self deleteApLoFileIfRequested:[[self fileURL]path]];
	});
	
	return YES;
}
+ (BOOL)autosavesInPlace {
	
    return NO;
}
- (BOOL)isDocumentEdited {
	
	//
	// Editing search field would dirty document, so we override this here.
	// 
	return NO;
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
			[self checkFindPasteboard];
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
	
	if(self.numMatches<1)
	{
		NSBeep();
		
		return;
	}
	
	[aploWebView stringByEvaluatingJavaScriptFromString:javascript];
	[self forceWebViewRedraw];
	
	if(self.numMatches==1) NSBeep();
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
- (void)checkFindPasteboard {
	
    NSPasteboard	*pasteboard=[NSPasteboard pasteboardWithName:NSFindPboard];
	NSString		*s=[pasteboard stringForType:NSStringPboardType];
	
	if(s && [s length]>0 && ![s isEqualToString:searchString])
	{
		self.searchString=s;
	}
}

//*****************************************************************************
// Implementation
//*****************************************************************************
- (void)startMonitoring:sender {
	
	if(self.previewPath)
	{
		[self showPreview];
		
		return;
	}
	
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
	
	[[aploWebView mainFrame]loadHTMLString:html baseURL:[NSURL URLWithString:@"file:///"]];
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
	
	// DLog(@"%@  html: %@  (%@)",_CMD,html,self);
	
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
	NSRect				docViewBounds=[docView bounds];
	NSScrollView 		*scrollView=[docView enclosingScrollView];
	NSRect 				scrollViewBounds=[[scrollView contentView]bounds];
	
	BOOL				shouldScroll=((scrollViewBounds.origin.y+scrollViewBounds.size.height)==docViewBounds.size.height);
	
	
	// DLog(@"scrollViewBounds: %@",NSStringFromRect(scrollViewBounds));
	// DLog(@"docViewBounds: %@",NSStringFromRect(docViewBounds));
	// DLog(@"shouldScroll: %d",shouldScroll);
	
	// Add the new element to the bodyNode as the last child.
	
	DOMNodeList			*nodeList=newNode.childNodes;
	DOMNode 			*node=nil;
	
	while((node=[nodeList item:0]))
	{
		[bodyNode appendChild:node];
	}
	
	if(shouldScroll)
	{
		[bodyNode setValue:[bodyNode valueForKey:@"scrollHeight"] forKey:@"scrollTop"];
	}
}
- (void)processNewData {
	
	NSString		*html=nil;
	NSMutableString	*localBuffer=[[NSMutableString alloc]init];
	
	while((html=[self getLineFromBuffer]))
	{
		// <script type="text/javascript">toggleVisibilityOfElementsNamed('levelID00007');</script>
		if([html hasPrefix:@"<script type=\"text/javascript\">"] && [html hasSuffix:@"</script>"])
		{
			NSUInteger	lbl=[localBuffer length];
			
			if(lbl>0)
			{
				[self appendHTML:localBuffer];
				
				[localBuffer deleteCharactersInRange:NSMakeRange(0,lbl)];
			}
			
			NSString	*js=[html substringWithRange:NSMakeRange(31,[html length]-40)];
			
			[aploWebView stringByEvaluatingJavaScriptFromString:js];
		}
		else
		{
			[localBuffer appendString:html];
		}
	}
	
	if([localBuffer length]>0) [self appendHTML:localBuffer];
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
- (void)deleteApLoFileIfRequested:(NSString *)path {
	
	NSString	*s=[self.taskEnvironment objectForKey:@"APLO_DELETE_FILE"];
	
	if(s && [s intValue] && path)
	{
		NSError		*error=nil;
		
		if(![[NSFileManager defaultManager]
			removeItemAtPath:path
			error:&error
		])
		{
			ERRLog(@"Error deleting file at '%@'",path);
		}
	}
}
- (BOOL)relaunchWithEnvironment:(NSDictionary *)newEnv filename:(NSString *)filename {
	
	self.taskEnvironment=newEnv;
	self.previewPath=[self.taskEnvironment objectForKey:@"APLO_PREVIEW_HTML_FILE"];
	
	[self deleteApLoFileIfRequested:filename];
	
	if(self.previewPath)
	{
		return [self showPreview];
	}
	
	NSString	*s=[self.taskEnvironment objectForKey:@"APLO_KEEP_WINDOW_CONTENTS"];
	
	if(!s || ![s intValue])
	{
		[self clear:self];
	}
	
	[self startParser];
	
	return YES;
}
- (BOOL)showPreview {
	
	[[aploWebView mainFrame]
		loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.previewPath]]
	];
	
	[self showWebInspector];
	
	return YES;
}
- (void)showWebInspector {
	
	Class	inspectorClass=NSClassFromString(@"WebInspector");
	
	if(!inspectorClass)
	{
		ERRLog(@"Can't find WebInspector class!");
		
		return;
	}
	
	id 		inspector=[inspectorClass alloc];
	
	if(![inspector respondsToSelector:@selector(initWithWebView:)])
	{
		ERRLog(@"WebInspector class doesn't respond to '-initWithWebView:'!");
		
		return;
	}
	
	inspector=[inspector performSelector:@selector(initWithWebView:) withObject:aploWebView];
	
	if(!inspector)
	{
		ERRLog(@"WebInspector: something went wrong during '-initWithWebView:'!");
		
		return;
	}
	
	if(![inspector respondsToSelector:@selector(detach:)])
	{
		ERRLog(@"WebInspector doesn't respond to '-detach:'!");
		
		return;
	}
	
	[inspector performSelector:@selector(showConsole:) withObject:aploWebView];
	
	if(![inspector respondsToSelector:@selector(showConsole:)])
	{
		ERRLog(@"WebInspector doesn't respond to '-showConsole:'!");
		
		return;
	}
	
	[inspector performSelector:@selector(showConsole:) withObject:aploWebView];
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
- (NSString *)parserPath {
	
	NSString	*path=[taskEnvironment objectForKey:@"APLO_PARSER_PATH"];
	
	ASSERT(path,@"APLO_PARSER_PATH not defined!");
	
	if(![path hasPrefix:@"/"])
	{
		NSString	*p=[path stringByDeletingPathExtension];
		NSString	*e=[path pathExtension];
		
		path=[[NSBundle bundleForClass:[self class]]
			pathForResource:p
			ofType:e
			inDirectory:@"Parsers"
		];
		
		ASSERT(path,@"Could not find parser '%@.%@'",p,e);
	}
	
	return path;
}
- (void)startParser {
	
	[self terminateParser];
	
	if([self.taskEnvironment objectForKey:@"APLO_PREVIEW_HTML_FILE"])
	{
		return;
	}
	
	NSString	*parserPath=[self parserPath];
	NSPipe		*myPipe=[NSPipe pipe];
	NSPipe		*myErrPipe=[NSPipe pipe];
	
	logParser=[[NSTask alloc]init];
	
	[logParser setLaunchPath:parserPath];
	
	if(taskEnvironment)
	{
		[logParser setEnvironment:taskEnvironment];
		
		NSString	*cwd=[taskEnvironment objectForKey:@"APLO_CWD"];
		
		if(cwd)
		{
			[logParser setCurrentDirectoryPath:cwd];
		}
	}
	
	[logParser setStandardOutput:myPipe];
	[logParser setStandardError:myErrPipe];
	
	logParserFH=[myPipe fileHandleForReading];
	logParserErrorFH=[myErrPipe fileHandleForReading];
	
    [[NSNotificationCenter defaultCenter]addObserver:self
        selector:@selector(readFromParser:)
        name:NSFileHandleReadCompletionNotification
        object:logParserFH
	];
	
    [[NSNotificationCenter defaultCenter]addObserver:self
        selector:@selector(readErrorFromParser:)
        name:NSFileHandleReadCompletionNotification
        object:logParserErrorFH
	];
	
	[logParserFH readInBackgroundAndNotify];
	[logParserErrorFH readInBackgroundAndNotify];
	
	[logParser launch];
	
	[[aploWebView window]orderFrontRegardless];
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
- (void)readErrorFromParser:(NSNotification *)notification {
	
    if([notification object]!=logParserErrorFH) return;
	
    NSData		*data=[[notification userInfo]objectForKey:NSFileHandleNotificationDataItem];
	
	if(!data || [data length]==0)
	{
		[self terminateParser];
		
		return;
	}
	
	NSString	*errMsg=[[NSString alloc]
		initWithData:data
		encoding:NSUTF8StringEncoding
	];
	
	WLog(@"Error output from %@: %@",[[self parserPath]lastPathComponent],errMsg);
	
	NSString	*html=[NSString stringWithFormat:
		@"<div><div class=\"scriptError\">%@</div>\n</div>",
		errMsg
	];
	
	[errMsg release];
	
	[self appendHTML:html];
	
	if(logParser) [logParserErrorFH readInBackgroundAndNotify];
}
- (void)terminateParser {
	
	if(!logParser) return;
	
    [[NSNotificationCenter defaultCenter]removeObserver:self
        name:NSFileHandleReadCompletionNotification
        object:logParserFH
	];
	
	logParserFH=nil;
	logParserErrorFH=nil;
	[logParser terminate];
	[logParser release];
	logParser=nil;
}

//*****************************************************************************
// Observers
//*****************************************************************************
- (void)defaultsChanged:(NSNotification *)aNotification {
	
	float	fs=[[NSUserDefaults standardUserDefaults]floatForKey:@"ApLoTextSizeMultiplier"];
	
	if(fs>0.1)
	{
		[aploWebView setTextSizeMultiplier:fs];
	}
}

//*****************************************************************************
// NSWindowDelegate Protocol
//*****************************************************************************
- (void)windowWillClose:(NSNotification *)notification {
	
	[self terminateParser];
}

//*****************************************************************************
// Synthesized Accessors
//*****************************************************************************
@synthesize previewPath;
@synthesize taskEnvironment;
@synthesize searchField;
@synthesize searchString;
@synthesize numMatches;
@dynamic searchButtonsEnabled;
@synthesize aploWebView;
@synthesize identifier;

@end
