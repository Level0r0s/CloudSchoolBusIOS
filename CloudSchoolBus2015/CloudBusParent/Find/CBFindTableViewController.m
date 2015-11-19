//
//  CBFindTableViewController.m
//  CloudBusParent
//
//  Created by HELLO  on 15/11/5.
//  Copyright (c) 2015年 BeiJingYinChuang. All rights reserved.
//

#import "CBFindTableViewController.h"
#import "EKRequest.h"
#import "CBLoginInfo.h"
#import "Message.h"
#import "FindNoticeTableViewCell.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "FPPopoverController.h"
#import "UIColor+RCColor.h"
#import "CBDateBase.h"
#import "ClassifyViewController.h"
static NSString * cellidenty = @"listcell";
@interface CBFindTableViewController ()<EKProtocol>
{
    FPPopoverController *popover;
}
@end

@implementation CBFindTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Init Data
    _dataList = [NSMutableArray array];
    
    
    /*
     * Init UI
     */
    //Background
    self.view.backgroundColor = [UIColor whiteColor];
    
    //Pull to refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"努力加载中……"];
    self.refreshControl.tintColor = [UIColor grayColor];
    [self.refreshControl addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
    
    //Tableview
    [self.tableView registerClass:[FindNoticeTableViewCell class] forCellReuseIdentifier:cellidenty];
    self.tableView.separatorColor = UITableViewCellSeparatorStyleNone;
    
    //Filter Button
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"分类" forState:UIControlStateNormal];
    btn.frame = CGRectMake(0, 0, 50, 50);
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(itemClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem * item = [[UIBarButtonItem alloc]initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = item;
    
    //Check if we have logged in
    [[CBLoginInfo shareInstance] baseInfoIsExist:^(BOOL isExist) {
        if(isExist)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //先从数据库里读出消息
            [[CBDateBase sharedDatabase] fetchMessagesFromDB:^(NSMutableArray *messageArray) {
                _dataList = messageArray;
            }];
            
            //如果数据库为空，从头开始获取。否则从本地最新的一条开始获取。
            NSDictionary * paramDict;
            if([_dataList count]==0)
            {
                paramDict = @{@"newid":@"0"};
            } else {
                NSString *lastestMessageId = [[_dataList lastObject] messageid];
                paramDict = @{@"newid":lastestMessageId};
            }
            
            [[EKRequest Instance] EKHTTPRequest:getmessage parameters:paramDict requestMethod:GET forDelegate:self];
            });
        } else {
            NSString *token = [[CBLoginInfo shareInstance] token];
            NSString *mobile = [[CBLoginInfo shareInstance] phone];
            NSDictionary *paramDict = @{@"token":token, @"mobile":mobile};
            //Session Expired
            [[EKRequest Instance] EKHTTPRequest:login parameters:paramDict requestMethod:POST forDelegate:[CBLoginInfo shareInstance]];
        }
    }];
    
}
-(void)itemClick:(id)sender
{
    ClassifyViewController * vc = [[ClassifyViewController alloc]init];
    vc.title = nil;
    vc.delegate = self;
    popover = [[FPPopoverController alloc] initWithViewController:vc];
    popover.border = NO;
    popover.tint = FPPopoverWhiteTint;
    popover.contentSize = CGSizeMake(150, 300);
    [popover presentPopoverFromPoint:CGPointMake(self.view.frame.size.width - 20, 20)];
}
-(void)selectedTableRow:(NSUInteger)rowNum
{
    NSLog(@"SELECTED ROW %lu",(unsigned long)rowNum);
    [popover dismissPopoverAnimated:YES];
}

-(void) getErrorInfo:(NSError *) error forMethod:(RequestFunction) method
{
    
}
-(void) getEKResponse:(id) response forMethod:(RequestFunction) method resultCode:(int) code withParam:(NSDictionary *)param
{
    if(method == getmessage && code == 1)
    {
        NSArray * arr = response;
        if(![arr isKindOfClass:[NSArray class]])
        {
            return;
        }
        
        for (int i = 0; i < arr.count; i++) {
            Message *message = [[Message alloc]initWithDic:arr[i]];
            [_dataList insertObject:message atIndex:0];
        }
        
        //Save messages to DB
        [[CBDateBase sharedDatabase] insertMessagesData:_dataList];
        
        [self.tableView reloadData];
    }
    
}
- (void)refreshAction{
    
    
    // 请求数据
    
    // 结束刷新
    
    [self.refreshControl endRefreshing];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return [_dataList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FindNoticeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidenty forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.fd_enforceFrameLayout = NO;
    Message *message = [_dataList objectAtIndex:indexPath.row];
    //    cell.textLabel.text  =message.body;
    cell.messsage = message;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Message *message = [_dataList objectAtIndex:indexPath.row];
    
    return [tableView fd_heightForCellWithIdentifier:cellidenty configuration:^(FindNoticeTableViewCell * cell) {
        cell.fd_enforceFrameLayout = NO;
        cell.messsage = message;
        
    }];
    
    //return 120+20;
}
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
