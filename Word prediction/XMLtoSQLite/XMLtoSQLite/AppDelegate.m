//
//  AppDelegate.m
//  XMLTest
//
//  Created by Tom Nantais on 13-03-20.
//  Copyright (c) 2013 Komodo Open Lab. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    BOOL bSuccess = YES;
    int result = 0;
    NSString *URL = @"file:///Users/owenmcgirr/Desktop/en_wordlist.xml"; // depends on machine
    NSString *agentString = @"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:URL]];
    [request setValue:agentString forHTTPHeaderField:@"User-Agent"];
    NSData* xmlFile = [ NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil ];
    
    NSLog(@"I am here");
    
    //open the database that will hold the word data
    result = sqlite3_open("/Users/owenmcgirr/Desktop/EnWords", &database); // depends on machine
    if (SQLITE_OK!=result)
    {
        NSLog(@"couldn't open database result=%d",result);
        bSuccess = NO;
    }
    
    if (bSuccess)
    {
        char *errMsg = NULL;
        
        const char *dropSQL = "DROP TABLE WORDS";
        result = sqlite3_exec(database, dropSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error dropping WORDS table: %s",errMsg);
            //bSuccess = NO; //not necessarily fatal
        }
        
        const char *createSQL = "CREATE TABLE WORDS(ID INTEGER PRIMARY KEY AUTOINCREMENT, WORD TEXT, FREQUENCY INTEGER);";
        result = sqlite3_exec(database, createSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error creating WORDS table: %s",errMsg);
            bSuccess = NO;
        }
        
        createSQL = "CREATE TABLE BIGRAMDATA(ID INTEGER PRIMARY KEY AUTOINCREMENT, ID1 INTEGER, ID2 INTEGER, BIGRAMFREQ INTEGER);";
        result = sqlite3_exec(database, createSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error creating BIGRAMDATA table: %s",errMsg);
            bSuccess = NO;
        }
        
		createSQL = "CREATE INDEX WORDS_IDX ON WORDS (FREQUENCY DESC, WORD);";
        result = sqlite3_exec(database, createSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error creating index on WORDS table: %s",errMsg);
            bSuccess = NO;
        }
        
		createSQL = "CREATE INDEX BIGRAMDATA_IDX ON BIGRAMDATA (ID1, BIGRAMFREQ DESC);";
        result = sqlite3_exec(database, createSQL, NULL, NULL, &errMsg);
        if (SQLITE_OK!=result)
        {
            NSLog(@"Error creating index on BIGRAMDATA table: %s",errMsg);
            bSuccess = NO;
        }
		
	}
    
    if (bSuccess)
    {
        errorInserting = NO;
        errorParsing=NO;
        count = 0;
        
        rssParser = [[NSXMLParser alloc] initWithData:xmlFile];
        [rssParser setDelegate:self];
        
        // You may need to turn some of these on depending on the type of XML file you are parsing
        [rssParser setShouldProcessNamespaces:NO];
        [rssParser setShouldReportNamespacePrefixes:NO];
        [rssParser setShouldResolveExternalEntities:NO];
        
        [rssParser parse];
    }
	
	if (bSuccess) {
		FILE *file = fopen("/Users/owenmcgirr/Desktop/bigrams.txt", "r"); // depends on machine
		
		if (file==NULL) {
			NSLog(@"file not found");
		}
		else {
			int bigram = 0;
			while (!feof(file)) {
				NSMutableString *strQuery = [[NSMutableString alloc] init];
				NSArray *line = [[NSArray alloc] init];
				int arr1[10], arr2[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; // set to 10 just incase
				int id1, id2, freq;
				
				line = [readLineAsNSString(file) componentsSeparatedByString:@","];
				
				bool isGoodRecord = false;
				
				if (line.count==3) {
					if ([[line objectAtIndex:0] length]!=0 && [[line objectAtIndex:1] length]!=0 && [[line objectAtIndex:2] length]!=0) {
						isGoodRecord=true;
					}
					else {
						isGoodRecord=false;
					}
				}
				
				if (isGoodRecord==true && line.count==3) {
					NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
					NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:[line objectAtIndex:2]];
					isGoodRecord = [alphaNums isSupersetOfSet:inStringSet];
				}
				
				if (isGoodRecord) {
					[strQuery appendString:@"SELECT * FROM WORDS WHERE WORD = '"];
					[strQuery appendString:[line objectAtIndex:0]];
					[strQuery appendString:@"';"];
					sqlite3_stmt *statement;
					int result = sqlite3_prepare_v2(database, [strQuery UTF8String], -1, &statement, nil);
					if (SQLITE_OK==result)
					{
						int counter =0;
						while (SQLITE_ROW==sqlite3_step(statement))
						{
							arr1[counter]=sqlite3_column_int(statement, 0);
							counter++;
						}
					}
					
					[strQuery setString:@"SELECT * FROM WORDS WHERE WORD = '"];
					[strQuery appendString:[line objectAtIndex:1]];
					[strQuery appendString:@"';"];
					result = sqlite3_prepare_v2(database, [strQuery UTF8String], -1, &statement, nil);
					if (SQLITE_OK==result)
					{
						int counter =0;
						while (SQLITE_ROW==sqlite3_step(statement))
						{
							arr2[counter]=sqlite3_column_int(statement, 0);
							counter++;
						}
					}
					
					id1=arr1[0];
					id2=arr2[0];
					freq=[[line objectAtIndex:2] intValue];
					if (id1!=0&&id2!=0) {
						[self addId1:id1 addId2:id2 withFreq:freq];
					}
				}
				if (0==bigram%1000) {
					NSLog(@"%i %@", bigram, @"bigrams passed");
				}
				
				bigram++;
			}
		}
		fclose(file);
	}
	
    sqlite3_close(database);
    NSLog(@"database and bigram file closed");
	
}

NSString *readLineAsNSString(FILE *file)
{
    char buffer[4096];
	
    // tune this capacity to your liking -- larger buffer sizes will be faster, but
    // use more memory
    NSMutableString *result = [NSMutableString stringWithCapacity:256];
	
    // Read up to 4095 non-newline characters, then read and discard the newline
    int charsRead;
    do
    {
        if(fscanf(file, "%4095[^\n]%n%*c", buffer, &charsRead) == 1)
            [result appendFormat:@"%s", buffer];
        else
            break;
    } while(charsRead == 4095);
	
    return result;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"File found and parsing started");
    
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    NSString *errorString = [NSString stringWithFormat:@"Error code %ld", [parseError code]];
    NSLog(@"Error parsing XML: %@", errorString);
    
    
    errorParsing=YES;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    currentElement = [elementName copy];
    ElementValue = [[NSMutableString alloc] init];
    attribs = [attributeDict copy];
    
    if ([elementName isEqualToString:@"w"]) {
        item = [[NSMutableDictionary alloc] init];
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    [ElementValue appendString:string];
}

- (BOOL)addNewWord:(NSString*)wordstr withFreq:(int)freq
{
    BOOL bSuccess = YES;
    char* ins = "INSERT INTO WORDS (WORD, FREQUENCY) VALUES(?, ?);";
    
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(database,ins,-1,&stmt,nil)!=SQLITE_OK)
    {
        NSLog(@"failed to prepare");
        bSuccess = NO;
    }
    if(bSuccess)
    {
        sqlite3_bind_text(stmt, 1, [wordstr UTF8String], -1, NULL);
        sqlite3_bind_int(stmt, 2, freq);
        if (SQLITE_DONE!=sqlite3_step(stmt))
        {
            NSLog(@"failed to step");
            bSuccess = NO;
        }
    }
    
    sqlite3_finalize(stmt);
    
    return(bSuccess);
}

- (BOOL)addId1:(int)idOne addId2:(int)idTwo withFreq:(int)freq
{
    BOOL bSuccess = YES;
    char* ins = "INSERT INTO BIGRAMDATA (ID1, ID2, BIGRAMFREQ) VALUES(?, ?, ?);";
    
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(database,ins,-1,&stmt,nil)!=SQLITE_OK)
    {
        NSLog(@"failed to prepare");
        bSuccess = NO;
    }
    if(bSuccess)
    {
		sqlite3_bind_int(stmt, 1, idOne);
        sqlite3_bind_int(stmt, 2, idTwo);
        sqlite3_bind_int(stmt, 3, freq);
        if (SQLITE_DONE!=sqlite3_step(stmt))
        {
            NSLog(@"failed to step");
            bSuccess = NO;
        }
    }
    
    sqlite3_finalize(stmt);
    
    return(bSuccess);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"w"]) {
        
        NSString* strFreq = [attribs objectForKey:@"f"];
        int nFreq = [strFreq intValue];
        
        if (!errorInserting)
        {
            if (![self addNewWord:ElementValue withFreq:nFreq])
            {
                errorInserting = YES;
            }
			
            count++;
            
            if (0==count%1000)
            {
                NSLog(@"%d passes",count);
            }
        }
    } else {
        [item setObject:ElementValue forKey:elementName];
    }
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (errorParsing == NO)
    {
        NSLog(@"XML processing done!");
        NSLog(@"Total number of words: %d",count);
    } else {
        NSLog(@"Error occurred during XML processing");
    }
    
}



@end
