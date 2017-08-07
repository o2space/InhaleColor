//
//  FinderPickView.h
//  InhaleColor
//
//  Created by wukexiu on 17/4/22.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FinderPickView;

@protocol FingerPickViewDelegate <NSObject>

-(void)fingerPickViewBegan:(CGPoint)point;
-(void)fingerPickViewChanged:(FinderPickView *)finderPv withCenter:(CGPoint)point;
-(void)fingerPickViewEnded;

@end

@interface FinderPickView : UIView

@property(nonatomic,assign) BOOL isManual;
@property(nonatomic, weak) id<FingerPickViewDelegate> delegate;

@end
