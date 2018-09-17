//
//  HTMLPreviewGenerator.h
//  SQLite Pro
//
//  Created by Carl Wieland on 4/21/14.
//  Copyright (c) 2014 Carl Wieland. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTMLPreviewBuilder : NSObject
-(NSString*)htmlPreviewForPath:(NSURL*)path;
@end
