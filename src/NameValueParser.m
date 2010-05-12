/* ===========================================================================
 
 Copyright (c) 2010 Edward Patel
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 =========================================================================== */


#import "NameValueParser.h"


@implementation NameValueParser

+ (NameValueParser*)parser
{
	return [[[NameValueParser alloc] init] autorelease];
}

- (id)init
{
	if (self = [super init]) {
		list = [[NSMutableArray alloc] init];
		fieldNames = [[NSMutableArray alloc] init];
		entryName = [[NSString stringWithString:@"member"] retain];
	}
	return self;
}

- (void)dealloc
{
	if (activeText)
		[activeText release];
	if (activeEntry)
		[activeEntry release];
	[entryName release];
	[fieldNames release];
	[list release];
	[super dealloc];
}

- (NSArray*)list
{
	return [NSArray arrayWithArray:list];
}

- (int)numEntries
{
	return list.count;
}

- (void)parseData:(NSData*)data
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    [parser release];
}

- (void)parseString:(NSString*)string
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [parser setDelegate:self];
    [parser parse];
    [parser release];
}


- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
	 attributes:(NSDictionary *)attributeDict
{
	if (activeText)
		[activeText release];
	activeText = nil;
    if ([elementName isEqual:entryName]) {
		if (activeEntry)
			[activeEntry release];
		activeEntry = [[NSMutableDictionary alloc] init];
        return;
    }
    if ([fieldNames containsObject:elementName]) {
		activeText = [[NSMutableString alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if ([elementName isEqual:entryName]) {
		if (activeEntry) {
			[list addObject:activeEntry];
			[activeEntry release];
			activeEntry = nil;
		}
        return;
    }
    if ([fieldNames containsObject:elementName]) {
		if (activeText) {
			if (activeEntry) 
				[activeEntry setObject:activeText
								forKey:elementName];
			[activeText release];
			activeText = nil;
		}
    }
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
	if (activeText)
		[activeText appendString:string];
}

- (void)setEntryName:(NSString*)name
{
	[name retain];
	[entryName release];
	entryName = [name copy];
	[name release];
}

- (void)addFieldName:(NSString*)name
{
	[fieldNames addObject:[NSString stringWithString:name]];
}

@end