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


#import "ListParser.h"


@implementation ListParser

+ (ListParser *)parser
{
	return [[[ListParser alloc] init] autorelease];
}

- (id)init
{
	if (self = [super init]) {
		list = [[NSMutableArray alloc] init];
		fieldNames = [[NSMutableArray alloc] init];
        attributeNames = [[NSMutableArray alloc] init]; 
	}
	return self;
}

- (void)dealloc
{
	if (activeText)
		[activeText release];
	[list release];
	[fieldNames release];
    [attributeNames release];
	[super dealloc];
}

- (NSArray *)list
{
	return [NSArray arrayWithArray:list];
}

- (int)numEntries
{
	return list.count;
}

- (void)parseData:(NSData *)data
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    [parser release];
}

- (void)parseString:(NSString *)string
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
    if ([fieldNames containsObject:elementName]) {
		activeText = [[NSMutableString alloc] init];
    }
    unsigned count = [attributeNames count]; 
    while (count--) { 
        if ([attributeDict objectForKey:[attributeNames objectAtIndex:count]]) { 
            [list addObject:[attributeDict valueForKey:[attributeNames objectAtIndex:count]]]; 
        } 
    } 
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if ([fieldNames containsObject:elementName]) {
		if (activeText) {
			[list addObject:activeText];
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

- (void)addFieldName:(NSString *)name
{
	[fieldNames addObject:[NSString stringWithString:name]];
}

- (void)addAttributeName:(NSString *)name 
{ 
    [attributeNames addObject:[NSString stringWithString:name]]; 
} 

@end
