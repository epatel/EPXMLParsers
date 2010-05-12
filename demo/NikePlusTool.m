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

NSDictionary *GetChallengeName(int id) {
	NSURLRequest *request;
	
	request = [NSURLRequest requestWithURL:
			   [NSURL URLWithString:
				[NSString stringWithFormat:@"http://nikerunning.nike.com/nikeplus/v1/services/widget/get_challenge_public_information.jsp?id=%d", id]]];
	
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request 
										 returningResponse:nil 
													 error:&error];
	
	ListParser *parser = [ListParser parser];
	[parser addFieldName:@"name"];
	[parser addFieldName:@"greeting"];
	[parser parseData:data];
	
	if ([parser numEntries] == 1) 
		return [NSDictionary dictionaryWithObject:[NSString stringWithString:[[parser list] objectAtIndex:0]] forKey:@"name"];

	if ([parser numEntries] == 2) 
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSString stringWithString:[[parser list] objectAtIndex:0]], @"name",
				[NSString stringWithString:[[parser list] objectAtIndex:1]], @"info",
				nil];
	
	return nil;
}

// ===========================================================================

NSArray *GetChallengeList(int id) {
	NSURLRequest *request;
	
	request = [NSURLRequest requestWithURL:
			   [NSURL URLWithString:
				[NSString stringWithFormat:@"http://nikerunning.nike.com/nikeplus/v1/services/widget/get_public_challenge_member_list.jsp?challengeID=%d&startidx=0&endidx=100", id]]];
	
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request 
										 returningResponse:nil 
													 error:&error];
	
	
	NameValueParser *parser = [NameValueParser parser];
	[parser addFieldName:@"rank"];
	[parser addFieldName:@"email"];
	[parser addFieldName:@"screenName"];
	[parser addFieldName:@"progress"];
	[parser addFieldName:@"winner"];
	[parser addFieldName:@"status"];
	[parser parseData:data];
	
	return [parser list];
}

// ===========================================================================

NSInteger sortMembersByRank(id arg1, id arg2, void *ud) {
	int rank1 = [[arg1 objectForKey:@"rank"] intValue];
	int rank2 = [[arg2 objectForKey:@"rank"] intValue];
	return rank1 - rank2;
}

// ===========================================================================

enum {
	S_confirmed,
	S_pending,
	S_denied
};

// ===========================================================================

int main (int argc, const char * argv[]) {
	int id;
	
	if (argc == 2) {
		id = atoi(argv[1]);
	} else {
		printf("Usage: %s <challenge id>\n", argv[0]);
		return 1;
	}

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSDictionary *dname = GetChallengeName(id);	
	NSString *cname = [dname objectForKey:@"name"];
	NSString *cinfo = [dname objectForKey:@"info"];
	
	NSArray *members = GetChallengeList(id);
	NSArray *smembers = [members sortedArrayUsingFunction:sortMembersByRank context:nil];
	
	float max = -1;
	
	if (cname && cinfo)
		printf("<h2><a title='%s'>%s</a></h2>\n", 
			   [cinfo cStringUsingEncoding:NSUTF8StringEncoding], 
			   [cname cStringUsingEncoding:NSUTF8StringEncoding]);
	else if (cname)
		printf("<h2>%s</h2>\n", [cname cStringUsingEncoding:NSUTF8StringEncoding]);
	
	printf("<table cellspacing='0'>\n");
	
	for (NSDictionary *dmember in smembers) {
		float progress = [[dmember objectForKey:@"progress"] floatValue];
		NSString *name = [dmember objectForKey:@"screenName"];
		NSString *email = [dmember objectForKey:@"email"];
		NSString *status = [dmember objectForKey:@"status"];
		BOOL winner = [dmember objectForKey:@"winner"] ? YES : NO;
		int mstatus = -1;
		
		if ([status isEqual:@"confirmed"]) {
			mstatus = S_confirmed;
		} else if ([status isEqual:@"pending"]) {
			mstatus = S_pending;
		} else if ([status isEqual:@"denied"]) {
			mstatus = S_denied;
		} 
		
		if (max < 0 && progress > 0.0)
			max = progress;
		
		if ([name length] < 1)
			name = email;
			
		switch (mstatus) {
			case S_confirmed:
				printf("<tr style='color: darkblue'>");
				break;
			case S_pending:
				printf("<tr style='color: gray'>");
				break;
			case S_denied:
				printf("<tr style='color: lightred'>");
				break;
		}
		
		printf("<td>%s</td>", [name cStringUsingEncoding:NSUTF8StringEncoding]);

		switch (mstatus) {
			case S_confirmed:
				printf("<td align='right'>%.2f km</td>", progress);
				if (winner)
					printf("<td align='center'><div style='background-color:darkblue; color: yellow; height: 15px; width:%d'>**WINNER**</div></td>", (int)(100.0*progress/max));
				else
					printf("<td><div style='background-color:darkblue; height: 15px; width:%d'> </div></td>", (int)(100.0*progress/max));
				break;
			case S_pending:
				printf("<td align='right'>- km</td>");
				printf("<td>pending</td>");
				break;
			case S_denied:
				printf("<td align='right'>- km</td>");
				printf("<td>denied</td>");
				break;
			default:
				printf("<td>unknown status</td>");
				break;
		}
		
		printf("</tr>\n");
		
	}

	printf("</table>\n");

    [pool drain];
    return 0;
}
