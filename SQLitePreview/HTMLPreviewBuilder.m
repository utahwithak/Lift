//
//  HTMLPreviewGenerator.m
//  SQLite Pro
//
//  Created by Carl Wieland on 4/21/14.
//  Copyright (c) 2014 Carl Wieland. All rights reserved.
//

#import "HTMLPreviewBuilder.h"
#import "sqlite3.h"

@implementation HTMLPreviewBuilder
-(NSString*)htmlPreviewForPath:(NSURL *)path{
    NSString* body = [self bodyForURL:path];
    if(body == nil){
        return nil;
    }
    NSString* file =  [NSString stringWithFormat:@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\nhttp://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd>\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n\
            <head> <style>\n\
            body\
            {\
            line-height: 1.6em;\
            }\
            #SqliteEditor\
            {\
            font-family: \"Lucida Sans Unicode\", \"Lucida Grande\", Sans-Serif;\
            font-size: 12px;\
            margin: 0px;\
            padding:0px auto;\
            text-align: left;\
            border-collapse: collapse;\
            }\
            #SqliteEditor caption\
            {\
            background: #e8edff; \
            text-align: left;\
            font-size: 24px;\
            }\
            #SqliteEditor thead\
            {\
            background: #e8edff; \
            }\
            #SqliteEditor th\
            {\
            font-size: 14px;\
            font-weight: normal;\
            padding: 10px 8px;\
            color: #039;\
            }\
            #SqliteEditor td\
            {\
            padding: 8px;\
            color: #669;\
            }\
            #SqliteEditor .odd\
            {\
            background: #f3f6fa; \
            }\
            </style>\n<title>An XHTML 1.0 Strict standard template</title>\n <meta http-equiv=\"content-type\"\ncontent=\"text/html;charset=utf-8\" />\n</head>\n%@",body];
    return file;
}
-(NSString*)bodyForURL:(NSURL*)url{
    sqlite3* database = nil;
    int rc = sqlite3_open_v2(url.path.UTF8String, &database, SQLITE_OPEN_READONLY, NULL);
    if(rc != SQLITE_OK || database == nil) {
        sqlite3_close_v2(database);
        return nil;
    }

    sqlite3_stmt* masterStatement = NULL;
    rc = sqlite3_prepare(database, "SELECT name FROM sqlite_master WHERE type='table';", -1, &masterStatement, nil);
    if (rc != SQLITE_OK || masterStatement == nil) {
        sqlite3_close_v2(database);
        return nil;
    }

    NSMutableArray<NSString*>* tableNames = [NSMutableArray new];
    while (sqlite3_step(masterStatement) == SQLITE_ROW ){
        const char * name = (char *)sqlite3_column_text(masterStatement, 0);
        if (name != nil) {
            NSString* tableName = [NSString stringWithUTF8String: name];
            if (tableName != nil) {
                [tableNames addObject:tableName];
            }
        }
    }

    NSMutableString* body = [NSMutableString stringWithString:@"<body>"];
    for (NSString* name in tableNames) {
        if([name length] == 0){
            continue;
        }
        sqlite3_stmt* queryStatement = NULL;

        //we do 11 to show the ...s
        const char* queryString = [NSString stringWithFormat:@"SELECT * FROM \"%@\" LIMIT 11;", [name stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]].UTF8String;
        rc = sqlite3_prepare(database, queryString, -1, &queryStatement, nil);
        if (rc != SQLITE_OK || queryStatement == NULL) {
            continue;
        }
        NSMutableArray* columns = [NSMutableArray new];
        for(int i = 0; i < sqlite3_column_count(queryStatement); i ++) {
            const char* name = (char *)sqlite3_column_name(queryStatement, i);
            if (name != NULL) {
                [columns addObject:[NSString stringWithUTF8String:name]];
            }
        }

        NSString* tableHeader = [NSString stringWithFormat:@"<caption><b>%@</b></caption>\n",name];
        NSMutableString* tableStr = [NSMutableString stringWithFormat:@"<table id=\"SqliteEditor\"><thead>%@<tr><th scope=\"col\"> %@</th></tr></thead><tbody>",tableHeader,[columns componentsJoinedByString:@"</th><th scope=\"col\">"]];

        NSInteger colCount = sqlite3_column_count(queryStatement);
        NSInteger rowCount = 0;

        while (sqlite3_step(queryStatement) == SQLITE_ROW && rowCount < 11) {
            [tableStr appendString:@"<tr>"];

            for(int i = 0; i < sqlite3_column_count(queryStatement); i ++) {
                NSString* dataStr;
                switch (sqlite3_column_type( queryStatement, i)) {
                    case SQLITE_INTEGER:
                        dataStr = [[NSNumber numberWithInteger: sqlite3_column_int(queryStatement, i)] description];
                        break;
                    case SQLITE_FLOAT:
                        dataStr = [[NSNumber numberWithDouble: sqlite3_column_int(queryStatement, i)] description];
                        break;
                    case SQLITE_BLOB:
                        dataStr = @"<BLOB DATA>";
                        break;
                    case SQLITE_TEXT:
                        dataStr = [NSString stringWithUTF8String:(char*)sqlite3_column_text(queryStatement, i)];
                        break;
                    case SQLITE_NULL:
                        dataStr = @"<NULL>";
                        break;
                    default:
                        dataStr = @"";
                        break;
                }
                if (rowCount % 2 == 0) {
                    [tableStr appendFormat:@"<th>%@</th>", dataStr];
                } else {
                    [tableStr appendFormat:@"<th class=\"odd\">%@</th>",dataStr];
                }
            }

            [tableStr appendString:@"</tr>"];
            rowCount += 1;
        }

        if (rowCount == 11) {
            [tableStr appendFormat:@"<tr>"];
            for(int fake = 0; fake < colCount; fake++){
                [tableStr appendString:@"<th>...</th>"];
            }
            [tableStr appendFormat:@"</tr>"];
        }

        [tableStr appendString:@"</tbody></table>\n"];
        [body appendFormat:@"%@<br>",tableStr];
    }

    [body appendString:@"</body>"];

    sqlite3_close_v2(database);
    return body;
}
@end
