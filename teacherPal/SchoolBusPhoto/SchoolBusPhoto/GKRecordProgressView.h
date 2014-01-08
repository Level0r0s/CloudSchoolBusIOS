//
//  GKRecordProgressView.h
//  Camera
//
//  Created by caijingpeng on 13-12-15.
//  Copyright (c) 2013年 caijingpeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GKRecordProgressViewDelegate <NSObject>

- (void)reachMinProgress;

@end

@interface GKRecordProgressView : UIView
{
    NSMutableArray *progressSegments;
    UIView *headView;
}

@property (nonatomic) float progress;
@property (nonatomic) id<GKRecordProgressViewDelegate> delegate;

- (void)markSegment;

@end
