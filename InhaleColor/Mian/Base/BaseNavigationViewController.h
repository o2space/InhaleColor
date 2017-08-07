//
//  BaseNavigationViewController.h
//  InhaleColor
//
//  Created by wukexiu on 17/4/21.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseNavigationViewController : UINavigationController

@property (nonatomic, copy) void (^didOnNavigationCloseBlock)();

@end
