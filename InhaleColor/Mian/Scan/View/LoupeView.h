//
//  LoupeView.
//  InhaleColor
//
//  Created by wukexiu on 17/4/26.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoupeView : UIView

@property(nonatomic,weak)UIView *targetVw;
@property(nonatomic,assign)CGPoint touchPoint;
@property(nonatomic,assign)CGPoint touchPointOffset;
@property(nonatomic,assign)CGFloat scale;
@property(nonatomic,assign)BOOL scaleAtTouchPoint;

@end
