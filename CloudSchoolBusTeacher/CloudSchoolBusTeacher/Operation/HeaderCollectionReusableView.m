//
//  HeaderCollectionReusableView.m
//  CloudSchoolBusTeacher
//
//  Created by macbook on 15/12/30.
//  Copyright © 2015年 BeiJingYinChuang. All rights reserved.
//

#import "HeaderCollectionReusableView.h"

@implementation HeaderCollectionReusableView

- (void)awakeFromNib {
    // Initialization code
    _teacherAvatar.clipsToBounds = YES;
    _teacherAvatar.layer.cornerRadius = 30;
}

@end
