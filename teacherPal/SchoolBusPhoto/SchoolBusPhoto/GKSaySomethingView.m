//
//  GKSaySomethingView.m
//  SchoolBusPhoto
//
//  Created by wen peifang on 14-1-22.
//  Copyright (c) 2014年 mactop. All rights reserved.
//

#import "GKSaySomethingView.h"
#import <QuartzCore/QuartzCore.h>
#import "GKUserLogin.h"
@implementation GKSaySomethingView
@synthesize delegate;
@synthesize tagStr;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
       // self.backgroundColor=[UIColor re];
        
        _contextView=[[UITextView alloc]initWithFrame:CGRectMake(10, 10, self.frame.size.width-20, 150)];
        _contextView.layer.cornerRadius=5;
        _contextView.backgroundColor = [UIColor whiteColor];
        //_contextView.backgroundColor = [UIColor colorWithRed:240/255.0f green:238/255.0f blue:227/255.0f alpha:1.0f];
        _contextView.text = @"";
        _contextView.font=[UIFont systemFontOfSize:16];
        _contextView.layer.cornerRadius=5;
        _contextView.delegate = self;
        
        [self addSubview:_contextView];
        
        //增加字数限制
        labelNum=[[UILabel alloc]initWithFrame:CGRectMake(10, _contextView.frame.size.height+_contextView.frame.origin.y+5, 50, 20)];
        labelNum.backgroundColor=[UIColor clearColor];
        labelNum.text=@"0/140";
        labelNum.font=[UIFont systemFontOfSize:12];
        [self addSubview:labelNum];
        [labelNum release];
        
        
      
        
        
        UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
        
        //apply
        [button setTitle:NSLocalizedString(@"apply", @"") forState:UIControlStateNormal];
        button.frame=CGRectMake(230, _contextView.frame.origin.y+_contextView.frame.size.height+5, 80, 40);
        
        UIImage *iamge=[[UIImage imageNamed:@"loginBtn"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 20, 15, 20)];
        
        [button setBackgroundImage:iamge forState:UIControlStateNormal];
        button.titleLabel.font=[UIFont systemFontOfSize:16];
        [button addTarget:self action:@selector(applyAll:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];

        
        _tagScrollerView = [[GKPhotoTagScrollView alloc] initWithFrame:CGRectMake(10,  _contextView.frame.origin.y+_contextView.frame.size.height+5+40, 300, 60)];
        _tagScrollerView.backgroundColor = [UIColor clearColor];
        _tagScrollerView.tagDelegate = self;
        [self addSubview:_tagScrollerView];

        
        GKUserLogin *user=[GKUserLogin currentLogin];
        
        [_tagScrollerView setPhotoTags:user.photoTagArray];
        
    }
    return self;
}
-(void)applyAll:(UIButton *)btn
{
    if([_contextView.text isEqualToString:@""])
    {
        return;
    }
    
    if([self textLength:_contextView.text] > 140)
    {
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"alert", @"") message:@"字数过长" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        return;
    }
    [delegate applyAll:_contextView.text];
    

}
-(void)setTagStr:(NSString *)_tagStr
{
    [tagStr release];
    tagStr=[_tagStr retain];
    
    [_tagScrollerView setSelectTag:_tagStr];
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
    
    int a= [self textLength:_contextView.text];
    
    NSLog(@"%d",a);
    
    
    labelNum.text=[NSString stringWithFormat:@"%d/140",a];
    
    if(a>140)
    {
        
        labelNum.textColor=[UIColor redColor];;
        
    }
    else
    {
        labelNum.textColor=[UIColor blackColor];
        //self.preStr=picTxtView.text;
        
    }
}

- (void)didSelectPhotoTag:(NSString *)tag
{
    [delegate tag:tag];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self endEditing:YES];
}
-(void)dealloc
{
    self.contextView=nil;
    self.tagScrollerView=nil;
    self.tagStr=nil;
    [super dealloc];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end