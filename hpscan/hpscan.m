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

#import <Foundation/Foundation.h>
#import "ListParser.h"
#import "NameValueParser.h"

// ===========================================================================

const NSString *post_xml = @"<scan:ScanJob xmlns:scan=\"http://www.hp.com/schemas/imaging/con/cnx/scan/2008/08/19\"" 
"xmlns:dd=\"http://www.hp.com/schemas/imaging/con/dictionaries/1.0/\">"
"<scan:XResolution>200</scan:XResolution>"
"<scan:YResolution>200</scan:YResolution>"
"<scan:XStart>0</scan:XStart>"
"<scan:YStart>0</scan:YStart>"
"<scan:Width>2480</scan:Width>"
"<scan:Height>3508</scan:Height>"
"<scan:Format>Pdf</scan:Format>"
"<scan:CompressionQFactor>15</scan:CompressionQFactor>"
"<scan:ColorSpace>Gray</scan:ColorSpace>"
"<scan:BitDepth>8</scan:BitDepth>"
"<scan:InputSource>Platen</scan:InputSource>"
"<scan:GrayRendering>NTSC</scan:GrayRendering>"
"<scan:ToneMap>"
"<scan:Gamma>0</scan:Gamma>"
"<scan:Brightness>1000</scan:Brightness>"
"<scan:Contrast>1000</scan:Contrast>"
"<scan:Highlite>0</scan:Highlite>"
"<scan:Shadow>0</scan:Shadow>"
"</scan:ToneMap>"
"<scan:ContentType>Document</scan:ContentType>"
"</scan:ScanJob>";

// ===========================================================================

NSArray *GetJobList(NSString *printer) {
	NSURLRequest *request;
	
	request = [NSURLRequest requestWithURL:
			   [NSURL URLWithString:
				[NSString stringWithFormat:@"http://%@/Jobs/JobList", printer]]];
	
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request 
										 returningResponse:nil 
													 error:&error];
	
	NameValueParser *parser = [NameValueParser parser];
	[parser setEntryName:@"Job"];
	[parser addFieldName:@"JobUrl"];
	[parser addFieldName:@"JobState"];
	[parser parseData:data];
	
	return [parser list];
}

// ===========================================================================

NSString *GetBinaryURL(NSString *printer, NSString *jobUrl) {
	NSURLRequest *request;
	
	request = [NSURLRequest requestWithURL:
			   [NSURL URLWithString:
				[NSString stringWithFormat:@"http://%@%@", printer, jobUrl]]];
	
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request 
										 returningResponse:nil 
													 error:&error];
	
	ListParser *parser = [ListParser parser];
	[parser addFieldName:@"BinaryURL"];
	[parser parseData:data];
	
	return [[parser list] objectAtIndex:0];
}

// ===========================================================================

void StartScan(NSString *printer) {
	NSMutableURLRequest *request;
	
	request = [NSMutableURLRequest requestWithURL:
			   [NSURL URLWithString:
				[NSString stringWithFormat:@"http://%@/Scan/Jobs", printer]]];
	
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[post_xml dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSError *error = nil;
	[NSURLConnection sendSynchronousRequest:request 
						  returningResponse:nil 
									  error:&error];
	if (error)
		NSLog(@"%@", error);
}

// ===========================================================================

void GetPage(NSString *printer, NSString *pageUrl, NSString *filename) {
	NSURLRequest *request;
	
	request = [NSURLRequest requestWithURL:
			   [NSURL URLWithString:
				[NSString stringWithFormat:@"http://%@%@", printer, pageUrl]]];
	
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request 
										 returningResponse:nil 
													 error:&error];
	if (error) {
		NSLog(@"%@", error);
	} else {
		[data writeToFile:filename atomically:YES];
	}
}

// ===========================================================================

int main (int argc, const char * argv[]) {
	
	if (argc != 3) {
		printf("Usage: %s <printer-hostname> <filename>\n", argv[0]);
		return 1;
	}
	
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSString *hostname = [NSString stringWithFormat:@"%s", argv[1]];
	NSString *filename = [NSString stringWithFormat:@"%s", argv[2]];
	
	StartScan(hostname);
	
	NSArray *jobs = GetJobList(hostname);	
	
	for (NSDictionary *job in jobs) {
		if ([@"Processing" isEqual:[job objectForKey:@"JobState"]]) {
			NSString *binaryUrl = GetBinaryURL(hostname, [job objectForKey:@"JobUrl"]);
			GetPage(hostname, binaryUrl, filename);
		}
	}
	
    [pool drain];
    return 0;
}
