//
//  DBManager.h
//  SqliteTest
//
//  Created by ZihaoLin on 12/7/14.
//  Copyright (c) 2014 ZihaoLin. All rights reserved.
//

/*
 profileList.sql ;
 TABLE profiles(profilename text primary key,connectedname text,connectedtime text)
 TABLE contactInfo(displayname text,connectedtime text);
 TABLE receivedMessage(messageid text primary key,protocol text,textcontent text);
 TABLE messageTrack(messageid text ,sendtime text,sendname text);
 TABLE sendMessage(messageid text primary key,sendtime text,protocoltype text,destpeer text,textcontent text)
 */
#import <Foundation/Foundation.h>

@interface DBManager : NSObject

@property (strong,nonatomic) NSMutableArray *arrColumnNames;
@property (nonatomic) int affectedRows;
@property (nonatomic) long long lastInsertedRowID;

- (instancetype)initWithDatabaseFilename:(NSString *)dbFilename;
- (NSArray *)loadDataFromDB:(NSString *)query;
- (void)executeQuery:(NSString *)query;

@end
