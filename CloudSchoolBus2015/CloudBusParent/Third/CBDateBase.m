//
//  CBDateBase.m
//  CloudBusParent
//
//  Created by HELLO  on 15/11/5.
//  Copyright (c) 2015年 BeiJingYinChuang. All rights reserved.
//

#import "CBDateBase.h"
#import "CBLoginInfo.h"
#import "School.h"
#import "Student.h"
#import "Message.h"
@implementation CBDateBase

-(NSString *)datebasePath
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"CloudBusParent.sqlite"];
}
-(id) init
{
    self = [super init];
    if(self){
        NSString *dbFilePath = [self datebasePath];
        NSLog(@"db_ _ _ _ _%@",dbFilePath);
        queue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];
        
        [self createTable];
    }
    return self;
    
}
-(void)createTable
{
    [queue inDatabase:^(FMDatabase *db) {
        NSString *sqlStr = @"CREATE TABLE IF NOT EXISTS loginInfo('c_id' int,'token' text,'phone' text,'sid' text,'rongtoken' text);";
        [db executeUpdate:sqlStr];
        
        sqlStr = @"CREATE TABLE IF NOT EXISTS baseInfo('baseinfoJsonStr' text);";
        [db executeUpdate:sqlStr];
        
        sqlStr = @"CREATE TABLE IF NOT EXISTS messagesTbl('messageid' int,'desc' text,'apptype' text,'ismass' text,'body' text, 'sendtime' text, 'title' text, 'tag' text, 'isconfirm' text, 'isreaded' text, 'senderid' int, 'studentid' text);";
        [db executeUpdate:sqlStr];
        
        sqlStr = @"CREATE TABLE IF NOT EXISTS senderTbl('senderid' INT NOT NULL PRIMARY KEY, 'classname' text, 'name' text, 'role' text, 'avatar' text);";
        [db executeUpdate:sqlStr];
        
    }];
}

-(void)clearTable
{
    [queue inDatabase:^(FMDatabase *db) {
        NSString *sqlStr = @"delete from loginInfo;";
        [db executeUpdate:sqlStr];
        
        sqlStr = @"delete from baseInfo;";
        [db executeUpdate:sqlStr];
        
        sqlStr = @"delete from messagesTbl;";
        [db executeUpdate:sqlStr];
        
        sqlStr = @"delete from senderTbl;";
        [db executeUpdate:sqlStr];
        
    }];
}

+(CBDateBase*) sharedDatabase
{
    
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
    
}
-(void)insertDataToLoginInfoTable:(NSNumber *)cid token:(NSString *)token phone:(NSString *)phone sid:(NSString *)sid rong:(NSString *)rongCloudToken
{
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"delete  from loginInfo"];
        [db executeUpdate:@"insert into loginInfo(c_id,token,phone,sid,rongtoken) values(?,?,?,?,?)",cid,token,phone,sid,rongCloudToken];
    }];
}

-(void)updateLoginInfoSid:(NSString *)sid rong:(NSString *)rongCloudToken
{
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"UPDATE loginInfo SET sid=? AND rongtoken=?",sid,rongCloudToken];
    }];
}

-(void)selectFormTableLoginInfo
{
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet * set = [db executeQuery:@"select * from loginInfo limit 1"];
        while ([set next]) {
            int cid = [set intForColumn:@"c_id"];
            NSString *token = [set stringForColumn:@"token"];
            NSString * phone = [set stringForColumn:@"phone"];
            NSString * sid = [set stringForColumn:@"sid"];
            NSString * rongtoken = [set stringForColumn:@"rongtoken"];
            
            CBLoginInfo * info = [CBLoginInfo shareInstance];
            info.userid = [NSString stringWithFormat:@"%@",@(cid)];
            info.token = token;
            info.phone = phone;
            info.sid = sid;
            info.rongToken = rongtoken;
        }
    }];
}

-(void)insertDataToBaseInfoTableWithBaseinfo:(NSString *)baseinfoString
{
    
    [queue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"delete from baseInfo"];
        [db executeUpdate:@"insert into baseInfo(baseinfoJsonStr) values(?)",baseinfoString];
    }];
}

-(void)selectFormTableBaseinfo:(sessionNotOver)block
{
    __block NSString *baseinfoStr = nil;
    [queue inDatabase:^(FMDatabase *db) {
        BOOL isBaseInfoValid = false;
        FMResultSet * set = [db executeQuery:@"select * from baseInfo limit 1"];
        while ([set next]) {
            baseinfoStr = [set stringForColumn:@"baseinfoJsonStr"];
            
            //De-serialisation
            if(baseinfoStr)
            {
                NSError *jsonError;
                NSData *objectData = [baseinfoStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *baseinfoDict = [NSJSONSerialization JSONObjectWithData:objectData
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:&jsonError];
                if(!baseinfoDict)
                {
                    NSLog(@"Json Deserialisation error %@", jsonError.localizedDescription);
                } else {
                    NSArray * schoolarr = baseinfoDict[@"schools"];
                    for (int i = 0; i < schoolarr.count; i++) {
                        NSDictionary * schooldic = schoolarr[i];
                        School *school = [[School alloc]initWithSchoolDic:schooldic];
                        [[[CBLoginInfo shareInstance] schoolArr] addObject:school];
                    }
                    
                    NSArray * stuArr = baseinfoDict[@"students"];
                    for (int i=0; i<stuArr.count; i++) {
                        Student * st = [[Student alloc]initWithDic:stuArr[i]];
                        if(i == 0)
                        {
                            [[CBLoginInfo shareInstance] setCurrentStudentId:st.studentid];
                        }
                        [[[CBLoginInfo shareInstance] studentArr] addObject:st];
                        
                        isBaseInfoValid = true;
                    }
                    
                    [[CBLoginInfo shareInstance] setHasValidBaseInfo:YES];
                    
                    [[CBLoginInfo shareInstance] setBaseInfoJsonString:baseinfoStr];
                    
                    block(YES);
                }
            }
        } //End of while
        if([[CBLoginInfo shareInstance] hasValidBaseInfo] == NO)
        {
            [[EKRequest Instance] EKHTTPRequest:baseinfo  parameters:nil requestMethod:POST forDelegate:[CBLoginInfo shareInstance]];
        }
        
    }];
}

-(void)insertMessagesData:(NSMutableArray *)messageArray
{
    for( Message *message in messageArray )
    {
        [queue inDatabase:^(FMDatabase *db) {
            NSNumber *messageid = [[NSNumber alloc] initWithInt:[message.messageid intValue]];
            NSNumber *senderid  = [[NSNumber alloc] initWithInt:[message.sender.senderid intValue]];

            [db executeUpdate:@"INSERT INTO messagesTbl(messageid, desc, apptype, ismass, body, sendtime, title, tag, isconfirm, isreaded, senderid, studentid) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", messageid, message.desc, message.apptype, message.ismass, message.body, message.sendtime, message.title, message.tag,message.isconfirm, message.isreaded, senderid, message.studentid];
            
            Sender *sender = message.sender;
            
            [db executeUpdate:@"INSERT OR REPLACE INTO senderTbl(senderid, classname, name, role, avatar) VALUES(?,?,?,?,?)", senderid, sender.classname, sender.name,sender.role, sender.avatar];
        }];
    }
}

-(void)updateMessageConfirmStatus:(NSString *)status withMessageId:(int)messageid
{
    [queue inDatabase:^(FMDatabase *db) {
        NSString *queryStr = [[NSString alloc] initWithFormat:@"UPDATE messagesTbl SET isconfirm=%@ WHERE messageid=%d",status,messageid];
        [db executeUpdate:queryStr];
    }];
}

-(void)selectLastestMessageId:(void (^)(int lastestMessageId))postQueryHandles
{
    [queue inDatabase:^(FMDatabase *db) {
        int messageid = 0;
        NSString *queryStr = @"SELECT MAX(messageid) AS messageid FROM messagesTbl";
        
        FMResultSet *resultSet = [db executeQuery:queryStr];
        while ([resultSet next]) {
            messageid = [resultSet intForColumn:@"messageid"];
        }
        
        postQueryHandles(messageid);
    }];
}

-(void)fetchMessagesFromDBfromMessageId:(int)messageid postHandle:(void (^)(NSMutableArray *messageArray))postMessageFetchHandles
{
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    [queue inDatabase:^(FMDatabase *db) {
        NSString *queryStr = [[NSString alloc] initWithFormat:@"SELECT * from (SELECT * FROM messagesTbl where messageid>%d ORDER BY messageid ASC LIMIT 100)"
                                                            "sub ORDER BY messageid DESC", messageid];
        FMResultSet * messageSet = [db executeQuery:queryStr];
        while ([messageSet next]) {
            int senderid = [[messageSet stringForColumn:@"senderid"] intValue];
            
            queryStr = [[NSString alloc] initWithFormat: @"SELECT * FROM senderTbl WHERE senderid = %d LIMIT 1", senderid];
            FMResultSet * senderSet = [db executeQuery:queryStr];
            
            Sender *sender = [[Sender alloc] init];
            while([senderSet next]){
                sender.senderid = [[NSString alloc] initWithFormat:@"%d",senderid];
                sender.classname = [senderSet stringForColumn:@"classname"];
                sender.name = [senderSet stringForColumn:@"name"];
                sender.role = [senderSet stringForColumn:@"role"];
                sender.avatar = [senderSet stringForColumn:@"avatar"];
            }
            
            Message *message = [[Message alloc] init];
            message.sender = sender;
            int messageid = [messageSet intForColumn:@"messageid"];
            message.messageid = [[NSString alloc] initWithFormat:@"%d",messageid];
            message.desc = [messageSet stringForColumn:@"desc"];
            message.apptype = [messageSet stringForColumn:@"apptype"];
            message.ismass = [messageSet stringForColumn:@"ismass"];
            message.body = [messageSet stringForColumn:@"body"];
            message.sendtime = [messageSet stringForColumn:@"sendtime"];
            message.title = [messageSet stringForColumn:@"title"];
            message.tag = [messageSet stringForColumn:@"tag"];
            message.isconfirm = [messageSet stringForColumn:@"isconfirm"];
            message.isreaded = [messageSet stringForColumn:@"isreaded"];
            message.studentid = [messageSet stringForColumn:@"studentid"];
            
            [messageArray addObject:message];
        }
        postMessageFetchHandles(messageArray);
    }];
}

-(void)fetchMessagesFromDBBeforeMessageId:(int)messageid postHandle:(void (^)(NSMutableArray *messageArray))postMessageFetchHandles
{
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    [queue inDatabase:^(FMDatabase *db) {
        NSString *queryStr = [[NSString alloc] initWithFormat:@"SELECT * FROM messagesTbl where messageid<%d ORDER BY messageid DESC LIMIT 100", messageid];
        FMResultSet * messageSet = [db executeQuery:queryStr];
        while ([messageSet next]) {
            int senderid = [[messageSet stringForColumn:@"senderid"] intValue];
            
            queryStr = [[NSString alloc] initWithFormat: @"SELECT * FROM senderTbl WHERE senderid=%d LIMIT 1", senderid];
            FMResultSet * senderSet = [db executeQuery:queryStr];
            
            Sender *sender = [[Sender alloc] init];
            while([senderSet next]){
                sender.senderid = [[NSString alloc] initWithFormat:@"%d",senderid];
                sender.classname = [senderSet stringForColumn:@"classname"];
                sender.name = [senderSet stringForColumn:@"name"];
                sender.role = [senderSet stringForColumn:@"role"];
                sender.avatar = [senderSet stringForColumn:@"avatar"];
            }
            
            Message *message = [[Message alloc] init];
            message.sender = sender;
            int messageid = [messageSet intForColumn:@"messageid"];
            message.messageid = [[NSString alloc] initWithFormat:@"%d",messageid];
            message.desc = [messageSet stringForColumn:@"desc"];
            message.apptype = [messageSet stringForColumn:@"apptype"];
            message.ismass = [messageSet stringForColumn:@"ismass"];
            message.body = [messageSet stringForColumn:@"body"];
            message.sendtime = [messageSet stringForColumn:@"sendtime"];
            message.title = [messageSet stringForColumn:@"title"];
            message.tag = [messageSet stringForColumn:@"tag"];
            message.isconfirm = [messageSet stringForColumn:@"isconfirm"];
            message.isreaded = [messageSet stringForColumn:@"isreaded"];
            message.studentid = [messageSet stringForColumn:@"studentid"];
            
            [messageArray addObject:message];
        }
        postMessageFetchHandles(messageArray);
    }];
}

-(void)fetchMessagesFromDBwithType:(NSString *)apptype forStudent:(NSString *)studentid fromMessageId:(int)messageid postHandle:(void (^)(NSMutableArray *messageArray))postMessageFetchHandles
{
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    [queue inDatabase:^(FMDatabase *db) {
        NSString *queryStr;
        
        if([apptype isEqualToString:@"All"]) {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT * from (SELECT * FROM messagesTbl where messageid>%d AND studentid='%@' ORDER BY messageid ASC LIMIT 100)"
                "sub ORDER BY messageid DESC", messageid, studentid];
        } else {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT * from (SELECT * FROM messagesTbl where messageid>%d AND apptype='%@' AND studentid='%@' ORDER BY messageid ASC LIMIT 100)"
                "sub ORDER BY messageid DESC", messageid, apptype, studentid];
        }
        
        FMResultSet * messageSet = [db executeQuery:queryStr];
        while ([messageSet next]) {
            int senderid = [[messageSet stringForColumn:@"senderid"] intValue];
            
            NSString *queryStr = [[NSString alloc] initWithFormat: @"SELECT * FROM senderTbl WHERE senderid = %d LIMIT 1 ", senderid];
            FMResultSet * senderSet = [db executeQuery:queryStr];
            
            Sender *sender = [[Sender alloc] init];
            while([senderSet next]){
                sender.senderid = [[NSString alloc] initWithFormat:@"%d",senderid];
                sender.classname = [senderSet stringForColumn:@"classname"];
                sender.name = [senderSet stringForColumn:@"name"];
                sender.role = [senderSet stringForColumn:@"role"];
                sender.avatar = [senderSet stringForColumn:@"avatar"];
            }
            
            Message *message = [[Message alloc] init];
            message.sender = sender;
            int messageid = [messageSet intForColumn:@"messageid"];
            message.messageid = [[NSString alloc] initWithFormat:@"%d",messageid];
            message.desc = [messageSet stringForColumn:@"desc"];
            message.apptype = [messageSet stringForColumn:@"apptype"];
            message.ismass = [messageSet stringForColumn:@"ismass"];
            message.body = [messageSet stringForColumn:@"body"];
            message.sendtime = [messageSet stringForColumn:@"sendtime"];
            message.title = [messageSet stringForColumn:@"title"];
            message.tag = [messageSet stringForColumn:@"tag"];
            message.isconfirm = [messageSet stringForColumn:@"isconfirm"];
            message.isreaded = [messageSet stringForColumn:@"isreaded"];
            message.studentid = [messageSet stringForColumn:@"studentid"];
            
            [messageArray addObject:message];
        }
        postMessageFetchHandles(messageArray);
    }];
}

-(void)fetchMessagesFromDBwithType:(NSString *)apptype forStudent:(NSString *)studentid belowMessageId:(int)messageid postHandle:(void (^)(NSMutableArray *messageArray))postMessageFetchHandles
{
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    [queue inDatabase:^(FMDatabase *db) {
        NSString *queryStr;
        
        if([apptype isEqualToString:@"All"]) {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT * FROM messagesTbl WHERE messageid<%d AND studentid='%@' ORDER BY messageid DESC LIMIT 100", messageid,studentid];
        } else {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT * FROM messagesTbl WHERE messageid<%d AND apptype='%@' AND studentid='%@' ORDER BY messageid DESC LIMIT 100", messageid, apptype, studentid];
        }
        
        FMResultSet * messageSet = [db executeQuery:queryStr];
        while ([messageSet next]) {
            int senderid = [[messageSet stringForColumn:@"senderid"] intValue];
            
            NSString *queryStr = [[NSString alloc] initWithFormat: @"SELECT * FROM senderTbl WHERE senderid = %d LIMIT 1 ", senderid];
            FMResultSet * senderSet = [db executeQuery:queryStr];
            
            Sender *sender = [[Sender alloc] init];
            while([senderSet next]){
                sender.senderid = [[NSString alloc] initWithFormat:@"%d",senderid];
                sender.classname = [senderSet stringForColumn:@"classname"];
                sender.name = [senderSet stringForColumn:@"name"];
                sender.role = [senderSet stringForColumn:@"role"];
                sender.avatar = [senderSet stringForColumn:@"avatar"];
            }
            
            Message *message = [[Message alloc] init];
            message.sender = sender;
            int messageid = [messageSet intForColumn:@"messageid"];
            message.messageid = [[NSString alloc] initWithFormat:@"%d",messageid];
            message.desc = [messageSet stringForColumn:@"desc"];
            message.apptype = [messageSet stringForColumn:@"apptype"];
            message.ismass = [messageSet stringForColumn:@"ismass"];
            message.body = [messageSet stringForColumn:@"body"];
            message.sendtime = [messageSet stringForColumn:@"sendtime"];
            message.title = [messageSet stringForColumn:@"title"];
            message.tag = [messageSet stringForColumn:@"tag"];
            message.isconfirm = [messageSet stringForColumn:@"isconfirm"];
            message.isreaded = [messageSet stringForColumn:@"isreaded"];
            message.studentid = [messageSet stringForColumn:@"studentid"];
            
            [messageArray addObject:message];
        }
        postMessageFetchHandles(messageArray);
    }];
}


-(void)initMessageQueueWithType:(NSString *)apptype withStudentId:(NSString *)studentid postHandle:(void (^)(NSMutableArray *messageArray))postMessageFetchHandles
{
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    [queue inDatabase:^(FMDatabase *db) {
        NSString *queryStr;
        
        //Calculate the total number of records
        if([apptype isEqualToString:@"All"]) {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT count(messageid) FROM messagesTbl WHERE studentid='%@' ORDER BY messageid DESC", studentid];
        } else {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT count(messageid) FROM messagesTbl WHERE apptype='%@' AND studentid='%@' ORDER BY messageid DESC", apptype, studentid];
        }
        
        int count = [db intForQuery:queryStr];
        
        //Calculate the limit start and total limit number
        int rowStart;
        int limitNumber;
        
        if(count == 0) //Nothing
        {
            rowStart=0;
            limitNumber=0;
        }
        else if(count < 200) //All records
        {
            rowStart = 0;
            limitNumber = 200;
        }
        else //Latest 100
        {
            rowStart = 0;
            limitNumber = 100;
        }
        
        //Query the rows
        if([apptype isEqualToString:@"All"]) {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT * FROM messagesTbl WHERE studentid='%@' ORDER BY messageid DESC LIMIT %d, %d", studentid, rowStart, limitNumber];
        } else {
            queryStr = [[NSString alloc] initWithFormat:@"SELECT * FROM messagesTbl WHERE apptype='%@' AND studentid='%@' ORDER BY messageid DESC LIMIT %d, %d", apptype, studentid, rowStart, limitNumber];
        }
        
        FMResultSet * messageSet = [db executeQuery:queryStr];
        
        while ([messageSet next]) {
            int senderid = [[messageSet stringForColumn:@"senderid"] intValue];
            
            NSString *queryStr = [[NSString alloc] initWithFormat: @"SELECT * FROM senderTbl WHERE senderid = %d LIMIT 1 ", senderid];
            FMResultSet * senderSet = [db executeQuery:queryStr];
            
            Sender *sender = [[Sender alloc] init];
            while([senderSet next]){
                sender.senderid = [[NSString alloc] initWithFormat:@"%d",senderid];
                sender.classname = [senderSet stringForColumn:@"classname"];
                sender.name = [senderSet stringForColumn:@"name"];
                sender.role = [senderSet stringForColumn:@"role"];
                sender.avatar = [senderSet stringForColumn:@"avatar"];
            }
            
            Message *message = [[Message alloc] init];
            message.sender = sender;
            int messageid = [messageSet intForColumn:@"messageid"];
            message.messageid = [[NSString alloc] initWithFormat:@"%d",messageid];
            message.desc = [messageSet stringForColumn:@"desc"];
            message.apptype = [messageSet stringForColumn:@"apptype"];
            message.ismass = [messageSet stringForColumn:@"ismass"];
            message.body = [messageSet stringForColumn:@"body"];
            message.sendtime = [messageSet stringForColumn:@"sendtime"];
            message.title = [messageSet stringForColumn:@"title"];
            message.tag = [messageSet stringForColumn:@"tag"];
            message.isconfirm = [messageSet stringForColumn:@"isconfirm"];
            message.isreaded = [messageSet stringForColumn:@"isreaded"];
            message.studentid = [messageSet stringForColumn:@"studentid"];
            
            [messageArray addObject:message];
        }
        postMessageFetchHandles(messageArray);
    }];
}



@end
