//
//  BaseViewController.m
//  XMProject
//
//  Created by wukexiu on 16/12/23.
//  Copyright © 2016年 wukexiu. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.automaticallyAdjustsScrollViewInsets = false;
    self.view.backgroundColor = IC_ColorHexInt(0xf3f3f3);
    if (self.navigationController) {
        self.navBarHairlineImageView =[self findHairlineImageViewUnder:self.navigationController.navigationBar];
        self.navBarHairlineImageView.alpha = 0.5;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    /*
    if (self.navigationController) {
        self.navigationController.navigationBar.translucent = NO;
    }
     */
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

/**
 设置导航栏及状态栏颜色
 @param color 背景颜色
 */
- (void)setNavBarBgColor:(UIColor *)color
{
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:color] forBarMetrics:UIBarMetricsDefault];
}

/**
 设置导航栏文字颜色
 @param titleColor 文字颜色
 */
- (void)setNavgationBarTitleTextColor:(UIColor *)titleColor
{
    NSDictionary *dic = @{NSForegroundColorAttributeName :titleColor,
                          NSFontAttributeName :[UIFont fontWithName:@"PingFangSC-Regular" size:18]};
    [self.navigationController.navigationBar setTitleTextAttributes:dic];
}

-(UIButton *)getNavBarButtonWithImageName:(NSString *)imageName Target:(id)target Action:(SEL)action{
    UIButton *btn       = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor clearColor];
    btn.bounds          = CGRectMake(0, 0, 30, 44);
    UIImage * image = [UIImage imageNamed:imageName];
    [btn setImage:image forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    btn.contentMode = UIViewContentModeCenter;
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}
-(void)addLeftBarItemCustomButtons:(NSArray *)buttons{
    if (buttons != nil && buttons.count > 0) {
        NSMutableArray *barButtonItems = [NSMutableArray array];
        for (UIButton *btn in buttons) {
            UIBarButtonItem *barbtn = [[UIBarButtonItem alloc] initWithCustomView:btn];
            barbtn.style = UIBarButtonItemStylePlain;
            [barButtonItems addObject:barbtn];
        }
        self.navigationItem.leftBarButtonItems = [barButtonItems copy];
    }
}
-(void)addRightBarItemCustomButtons:(NSArray *)buttons{
    if (buttons != nil && buttons.count > 0) {
        NSMutableArray *barButtonItems = [NSMutableArray array];
        for (UIButton *btn in buttons) {
            UIBarButtonItem *barbtn = [[UIBarButtonItem alloc] initWithCustomView:btn];
            barbtn.style = UIBarButtonItemStylePlain;
            [barButtonItems addObject:barbtn];
        }
        self.navigationItem.rightBarButtonItems = [barButtonItems copy];
    }
}
-(void)addLeftButtonWithImageName:(NSString *)imageName Target:(id)target Action:(SEL)action
{
    UIButton *btn = [self getNavBarButtonWithImageName:imageName Target:target Action:action];
    [self addLeftBarItemCustomButtons:@[btn]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
