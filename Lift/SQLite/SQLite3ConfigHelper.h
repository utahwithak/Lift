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

+ (BOOL) enableExtensionsFor:(struct sqlite3 *)connection;
+ (BOOL) disableExtensionsFor:(struct sqlite3 *)connection;
@end
