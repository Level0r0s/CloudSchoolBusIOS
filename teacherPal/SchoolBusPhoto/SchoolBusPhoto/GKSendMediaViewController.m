//
//  GKSendMediaViewController.m
//  SchoolBusPhoto
//
//  Created by CaiJingPeng on 14-1-7.
//  Copyright (c) 2014年 mactop. All rights reserved.
//

#import "GKSendMediaViewController.h"
#import "GKUserLogin.h"
#import "GKFilterViewController.h"
#import "GKLoaderManager.h"
#import "GKCoreDataManager.h"
@interface GKSendMediaViewController ()

@end

@implementation GKSendMediaViewController
@synthesize stuList,sourcePicture,photoTag,thumbnail,moviePath,isPresent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isPresent = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.moviePath != nil)
    {
        self.titlelabel.text = @"上传视频";
    }
    else if (self.sourcePicture != nil)
    {
        self.titlelabel.text = @"上传图片";
    }
    
    
    UIButton *buttonBack=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonBack.frame=CGRectMake(10, 5, 34, 35);
    [buttonBack setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [buttonBack setBackgroundImage:[UIImage imageNamed:@"backH.png"] forState:UIControlStateHighlighted];
    [navigationView addSubview:buttonBack];
    [buttonBack addTarget:self action:@selector(doBack:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *sendButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendButton.frame=CGRectMake(320 - 50, 5, 50, 35);
    [sendButton setBackgroundImage:[UIImage imageNamed:@"OKBtn.png"] forState:UIControlStateNormal];
    [sendButton setBackgroundImage:[UIImage imageNamed:@"OKBtn_sel.png"] forState:UIControlStateHighlighted];
    [navigationView addSubview:sendButton];
    [sendButton addTarget:self action:@selector(uploadMedia:) forControlEvents:UIControlEventTouchUpInside];
    
    // 背景 框
    UIImageView *boardImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 130)];
    boardImageView.center = CGPointMake(160, navigationView.frame.origin.y + navigationView.frame.size.height + 15 + boardImageView.frame.size.height/2.0f);
    boardImageView.image = IMAGENAME(IMAGEWITHPATH(@"视频框(1)"));
    [self.view addSubview:boardImageView];
    [boardImageView release];
    
    // 缩略图
    thumbImgV = [[UIImageView alloc] initWithFrame:CGRectMake(boardImageView.frame.origin.x + 15, boardImageView.frame.origin.y + 15, 60, 60)];
    if (self.sourcePicture != nil)
    {
        thumbImgV.image = self.sourcePicture;
    }
    else
    {
        thumbImgV.image = self.thumbnail;
    }
    [self.view addSubview:thumbImgV];
    
    UIButton *presetBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [presetBtn setFrame:thumbImgV.frame];
    if (self.moviePath != nil)
    {
        [presetBtn setImage:nil forState:UIControlStateNormal];
    }
    [presetBtn addTarget:self action:@selector(presetMedia:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:presetBtn];
    
    
    // 输入框
    contentTV = [[UITextView alloc] initWithFrame:CGRectMake(thumbImgV.frame.origin.x + thumbImgV.frame.size.width + 10, thumbImgV.frame.origin.y - 7, 200, 100)];
    contentTV.text = @"描述。。。。。";
    contentTV.delegate = self;
    contentTV.font = [UIFont systemFontOfSize:15];
    contentTV.textColor = [UIColor grayColor];
    contentTV.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:contentTV];
    
    // 计数 label
    calWordsLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 30)];
    calWordsLab.backgroundColor = [UIColor clearColor];
    calWordsLab.textAlignment = NSTextAlignmentCenter;
    calWordsLab.text = @"0/140";
    calWordsLab.font = [UIFont systemFontOfSize:15];
    calWordsLab.center = CGPointMake(thumbImgV.center.x, thumbImgV.frame.origin.y + thumbImgV.frame.size.height + 25);
    [self.view addSubview:calWordsLab];
    
    
    GKPhotoTagScrollView *tagView = [[GKPhotoTagScrollView alloc] initWithFrame:CGRectMake(boardImageView.frame.origin.x, boardImageView.frame.origin.y + boardImageView.frame.size.height + 5, boardImageView.frame.size.width, iphone5 ? boardImageView.frame.size.height : 40)];
    tagView.backgroundColor = [UIColor clearColor];
    tagView.tagDelegate = self;
    [self.view addSubview:tagView];
    [tagView release];
    
    
    GKUserLogin *user=[GKUserLogin currentLogin];
    
    [tagView setPhotoTags:user.photoTagArray];
    
    int col=([user.studentArr count] )/4; //行
    //int row=([user.studentArr count] )%4;
    int y = MIN(col+1, 4);
    
    GKStudentView *studentView=[[GKStudentView alloc]initWithFrame:CGRectMake(0, (iphone5 ? 548 : 460) + (ios7 ? 20 : 0) - (y*50), 320,( y*50))];
    studentView.backgroundColor=[UIColor whiteColor];
    studentView.delegate=self;
    studentView.studentArr=user.studentArr;
    [self.view addSubview:studentView];
    [studentView release];
    
    self.stuList = [NSMutableArray array];
    
}
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"描述。。。。。"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    return YES;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"描述。。。。。";
        textView.textColor = [UIColor grayColor];
    }
    return YES;
}

- (int)textLength:(NSString *)text//计算字符串长度
{
    float number = 0.0;
    for (int index = 0; index < [text length]; index++)
    {
        
        NSString *character = [text substringWithRange:NSMakeRange(index, 1)];
        
        //        NSLog(@"%d",[character lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        
        if ([character lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 3)
        {
            number+=2;
        }
        else
        {
            number++;
        }
    }
    return number;
}

- (void)textViewDidChange:(UITextView *)textView
{
    int a= [self textLength:textView.text];
    
    NSLog(@"%d",a);
    calWordsLab.text=[NSString stringWithFormat:@"%d/140",a];
    
    if(a>140)
    {
        calWordsLab.textColor=[UIColor redColor];;
    }
    else
    {
        calWordsLab.textColor=[UIColor blackColor];
    }
}

- (void)showBigImage:(UITapGestureRecognizer *)sender
{
    [sender.view removeFromSuperview];
}

- (void)presetMedia:(id)sender
{
    [self.view endEditing:YES];
    
    GKFilterViewController *fvc = [[GKFilterViewController alloc] init];
    fvc.isPreview = NO; // 不是预览页面.
    if (self.sourcePicture != nil)
    {
        //显示图片
        fvc.sourceImage = self.sourcePicture;
    }
    else
    {
        //播放视频
        fvc.moviePath = self.moviePath;
    }
    [self presentModalViewController:fvc animated:YES];
    [fvc release];
    
}

-(void)whitchSelected:(BOOL)selected uid:(NSString *)uid isAll:(int)an
{
    GKUserLogin *user=[GKUserLogin currentLogin];
    
//    NSLog(@"%d,%d",selected,an);
    
    
    if (an == 0)    // 默认单选
    {
        
        if (selected) //选中
        {
            [stuList addObject:uid];
        }
        else     // 取消选中
        {
            [stuList removeObject:uid];
        }
        
    }
    else if (an == 1)  // 选择全部
    {
        [stuList removeAllObjects];
        
        for (int i=0; i<[user.studentArr count]; i++) {
            Student *st=[user.studentArr objectAtIndex:i];
            [stuList addObject:[NSString stringWithFormat:@"%@",st.studentid]];
        }
        
    }
    else if (an == 2)  //取消全部
    {
        [stuList removeAllObjects];
    }
    
    NSLog(@"%@",stuList);
   
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (void)uploadMedia:(id)sender
{
    
    [self.view endEditing:YES];
    
    if (![self checkContentLength])
    {
        return;
    }
    
    if (self.stuList.count == 0)
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert", @"") message:NSLocalizedString(@"selectstuent", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return;
    }
    
    
    GKLoaderManager *manager = [GKLoaderManager createLoaderManager];
    
    GKUserLogin *user=[GKUserLogin currentLogin];
    
    NSString *timestamp = [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
    
    NSString *filePath;
    
    if (self.sourcePicture != nil)
    { //上传图片.
        
        NSData *imageData = UIImageJPEGRepresentation(self.sourcePicture, 1.0);
        
        NSArray *arr= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentpath=[arr objectAtIndex:0];
        NSString *filename=[NSString stringWithFormat:@"tempimage%@",timestamp];
        filePath=[NSString stringWithFormat:@"%@/%@",documentpath,filename];
        NSFileManager *fileManage=[NSFileManager defaultManager];
        if(![fileManage fileExistsAtPath:filePath])
        {
            [fileManage createFileAtPath:filePath contents:nil attributes:nil];
        }
        else
        {
            NSLog(@"image write path has been exist");
            return;
        }
        BOOL success = [imageData writeToFile:filePath atomically:YES];
        
        if (!success) {
            NSLog(@"image write path error ");
            return;
        }
    }
    else
    {
        //上传视频.
        filePath = [NSString stringWithFormat:@"%@",self.moviePath];
    }
    
    NSString *students = [self.stuList componentsJoinedByString:@","];
    
    NSLog(@"students %@ , photo tag : %@",students,(photoTag == nil ? @"" : photoTag));
    
    [manager addNewPicToCoreData:filePath name:@"" iSloading:[NSNumber numberWithInt:1] nameId:[NSString stringWithFormat:@"draft%@",timestamp] studentId:students time:[NSNumber numberWithInt:[timestamp intValue]] fsize:[NSNumber numberWithInt:0] classID:[NSNumber numberWithInt:[user.classInfo.uid integerValue]] intro:contentTV.text data:UIImageJPEGRepresentation(thumbImgV.image, 0.1) tag:(photoTag == nil ? @"" : photoTag)] ;
    
    [manager addWraperToArr:filePath name:@"" iSloading:[NSNumber numberWithInt:1] nameId:[NSString stringWithFormat:@"draft%@",timestamp] studentId:students time:[NSNumber numberWithInt:[timestamp intValue]] fsize:[NSNumber numberWithInt:0] classID:[NSNumber numberWithInt:[user.classInfo.uid integerValue]] intro:contentTV.text data:UIImageJPEGRepresentation(thumbImgV.image, 0.1) tag:(photoTag == nil ? @"":photoTag)];
    
    [self.navigationController dismissModalViewControllerAnimated:YES];
    
}

- (void)doBack:(id)sender
{
    
    if (self.isPresent) {
        [self dismissModalViewControllerAnimated:YES];
        return;
    }
    
    if (self.moviePath != nil)
    {
        UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"您是否要保存到草稿箱" delegate:self cancelButtonTitle:NSLocalizedString(@"cancel",@"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"savedraft",@""),NSLocalizedString(@"dontsavedraft",@""), nil];
        [as showInView:self.view];
        [as release];
    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        // save draft
        NSString *stamp = [NSString stringWithFormat:@"%d", (int)[[NSDate date] timeIntervalSince1970]];
        
        GKUserLogin *user=[GKUserLogin currentLogin];
        BOOL success = [GKCoreDataManager addMovieDraftWithUserid:[NSString stringWithFormat:@"%@", user.classInfo.classid] moviePath:self.moviePath dateStamp:stamp thumbnail:UIImageJPEGRepresentation(self.thumbnail, 0.1)];
        NSLog(@"save draft : %d",success);
        
        [self.navigationController dismissModalViewControllerAnimated:YES];
    }
    else if (buttonIndex == 1)
    {
        //不保存
//        NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] removeItemAtPath:self.moviePath error:nil];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didSelectPhotoTag:(NSString *)tag
{
    self.photoTag = [NSString stringWithFormat:@"%@",tag];
}

- (BOOL)checkContentLength
{
    int a = [self textLength:contentTV.text];
    if (a > 140) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] autorelease];
        [alert show];
        return NO;
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
