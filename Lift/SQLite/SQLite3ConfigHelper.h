//
//  SQLite3ConfigHelper.h
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@interface SQLite3ConfigHelper : NSObject


/**
 Checks if extensions are enabled or not for the connection (`SQLITE_DBCONFIG_ENABLE_LOAD_EXTENSION`)

 @param connection `sqlite3` connection to check on
 @return true if enabled, false otherwise
 */
+ (BOOL) extensionsEnabledFor:(struct sqlite3*) connection;

/**
 Checks the foreign key constraint values on the connection (`SQLITE_DBCONFIG_ENABLE_FKEY`)

 @param connection `sqlite3` connection
 @return true if foreign keys are enabled, false otherwise
 */
+ (BOOL) foreignKeysEnabledFor:(struct sqlite3 *)connection;

/**
 Sets the foreign key constraints active or not for the connection

 @param enabled weither the constrants should be enforced or not, `true`:enforce, `false`: disregard
 @param connection the sqlite3 connection to use
 @return true that it was successfully set, false otherwise.
 */
+ (BOOL) setForeignKeysEnabled:(BOOL)enabled forConnection:(struct sqlite3 *)connection;

/**
 Enables or disables extension for the `sqlite3` connection

 @param enabled if extensions should be allowed on the connection.
 @param connection sqlite3 connection to enable or disable them
 @return true if it was successfully set, false otherwise
 */
+ (BOOL) setExtensionsEnabled:(BOOL) enabled forConnection:(struct sqlite3*) connection;

/**
 Returns if the `fts3` tokenizer is enabled or not

 @param connection sqlite3 connection to check on
 @return true if enabled, false otherwise
 */
+ (BOOL) FTS3TokenizerEnabledFor:(struct sqlite3 *) connection;

/**
 Allows the FTS3 tokenizer to be enabled or disabled for the sqlite3  connection

 @param enabled if the tokenizer should be active on the connection
 @param connection sqlite3 connection
 @return true if successfully set, false otherwise.
 */
+ (BOOL) setFTS3TokenizerEnabled: (BOOL) enabled forConnection:(struct sqlite3 *) connection;



/**
 Returns if triggers are enabled or not for the connection (`SQLITE_DBCONFIG_ENABLE_TRIGGER`)

 @param connection `sqlite3` connection to check on
 @return true if successfully set, false otherwise.
 */
+ (BOOL) triggersEnabledFor:(struct sqlite3*)connection;

/**
 Enables or disables triggers on the the sqlite3  connection

 @param enabled true if triggers should be ran on the connection
 @param connection sqlite3 connection
 @return true if successfully set, false otherwise.
 */
+ (BOOL) setTriggersEnabled: (BOOL) enabled forConnection:(struct sqlite3 *) connection;


@end
