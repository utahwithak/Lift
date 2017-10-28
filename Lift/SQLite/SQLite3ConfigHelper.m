//
//  SQLite3ConfigHelper.m
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

#import "SQLite3ConfigHelper.h"

@implementation SQLite3ConfigHelper

+ (BOOL) enableExtensionsFor:(struct sqlite3 *)connection {
    int success = 0;
    int rc = sqlite3_db_config(connection, SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION, 1, &success);
    return rc == SQLITE_OK && success == 1;
}

+(BOOL)disableExtensionsFor:(struct sqlite3 *)connection {
    int success = 0;
    int rc = sqlite3_db_config(connection, SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION, 0, &success);
    return rc == SQLITE_OK && success == 0;
}
@end
