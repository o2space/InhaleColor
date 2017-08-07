//
//  BaseViewController.h
//  XMProject
//
//  Created by wukexiu on 16/12/23.
//  Copyright © 2016年 wukexiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

@property(nonatomic,strong)UIImageView *navBarHairlineImageView;

//- (UIImageView *)findHairlineImageViewUnder:(UIView *)view;

- (void)setNavBarBgColor:(UIColor *)color;
- (void)setNavgationBarTitleTextColor:(UIColor *)titleColor;

- (UIButton *)getNavBarButtonWithImageName:(NSString *)imageName Target:(id)target Action:(SEL)action;
- (void)addLeftBarItemCustomButtons:(NSArray *)buttons;
- (void)addRightBarItemCustomButtons:(NSArray *)buttons;
- (void)addLeftButtonWithImageName:(NSString *)imageName Target:(id)target Action:(SEL)action;
@end
