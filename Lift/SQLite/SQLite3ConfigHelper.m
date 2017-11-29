//
//  SQLite3ConfigHelper.m
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

#import "SQLite3ConfigHelper.h"

@implementation SQLite3ConfigHelper

+ (BOOL) setConfig:(int) config enabled: (BOOL) enabled onConnection:(struct sqlite3*) connection {
    int turnedOn = 0;
    int rc = sqlite3_db_config(connection, config, enabled, &turnedOn);
    return rc == SQLITE_OK && turnedOn == enabled;
}

+ (BOOL)config:(int) config enabledOn:(struct sqlite3*) connection {
    int turnedOn = 0;
    int rc = sqlite3_db_config(connection, config, -1, &turnedOn);
    return rc == SQLITE_OK && turnedOn == 1;
}

+(BOOL) extensionsEnabledFor:(struct sqlite3 *)connection {
    return [self config:SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION enabledOn:connection];
}

+ (BOOL) setExtensionsEnabled:(BOOL)enabled forConnection:(struct sqlite3 *)connection {
    return [self setConfig:SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION enabled:enabled onConnection:connection];
}


+(BOOL) foreignKeysEnabledFor:(struct sqlite3 *)connection {
    return [self config:SQLITE_DBCONFIG_ENABLE_FKEY enabledOn:connection];
}
+ (BOOL) setForeignKeysEnabled:(BOOL)enabled forConnection:(struct sqlite3 *)connection {
    return [self setConfig:SQLITE_DBCONFIG_ENABLE_FKEY enabled:enabled onConnection:connection];
}





+ (BOOL) FTS3TokenizerEnabledFor:(struct sqlite3 *) connection {
    return [self config:SQLITE_DBCONFIG_ENABLE_FTS3_TOKENIZER enabledOn:connection];
}

+ (BOOL) setFTS3TokenizerEnabled: (BOOL)enabled forConnection:(struct sqlite3 *) connection {
    return [self setConfig:SQLITE_DBCONFIG_ENABLE_FTS3_TOKENIZER enabled:enabled onConnection:connection];
}





+ (BOOL) triggersEnabledFor:(struct sqlite3*)connection {
    return [self config:SQLITE_DBCONFIG_ENABLE_TRIGGER enabledOn:connection];
}

+ (BOOL) setTriggersEnabled: (BOOL) enabled forConnection:(struct sqlite3 *) connection {
    return [self setConfig:SQLITE_DBCONFIG_ENABLE_TRIGGER enabled:enabled onConnection:connection];
}

@end
