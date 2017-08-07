//
//  BaseNavigationViewController.m
//  InhaleColor
//
//  Created by wukexiu on 17/4/21.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import "BaseNavigationViewController.h"
#import "RDVTabBarController.h"

@interface BaseNavigationViewController ()

@end

@implementation BaseNavigationViewController

+(void)initialize
{
    [self setupNavigationBarTheme];
    
    [self setupBarButtionItemTheme];
}

+(void)setupNavigationBarTheme
{
    UINavigationBar *appearance=[UINavigationBar appearance];
    appearance.translucent=YES;
    appearance.shadowImage = [UIImage new];
    NSMutableDictionary *textAttrs=[NSMutableDictionary dictionary];
    //设置字体颜色
    textAttrs[UITextAttributeTextColor]=[UIColor colorWithRed:29.0/255.0 green:29.0/255.0 blue:38.0/255.0 alpha:1.0];
    //设置字体大小
    textAttrs[UITextAttributeFont]=[UIFont fontWithName:@"PingFangSC-Regular" size:18];
    //设置字体的偏移量（0）
    //说明：UIOffsetZero是结构体，只有包装成NSValue对象才能放进字典中
    textAttrs[UITextAttributeTextShadowOffset]=[NSValue valueWithUIOffset:UIOffsetZero];
    [appearance setTitleTextAttributes:textAttrs];
}

+(void)setupBarButtionItemTheme
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBarHidden=YES;
}

-(void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    //如果push的不是栈顶控制器，那么隐藏tabbar工具条
    if(self.viewControllers.count>0){
        //viewController.hidesBottomBarWhenPushed=YES;//底部bar隐藏
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        [self.rdv_tabBarController setTabBarHidden:YES animated:YES];
    }
    [super pushViewController:viewController animated:YES];
}

-(UIViewController *) popViewControllerAnimated:(BOOL)animated
{
    if (self.viewControllers.count <=2 ) {
        [self.rdv_tabBarController setTabBarHidden:NO animated:YES];
    }
    return [super popViewControllerAnimated:animated];
}

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated{
    return [super popToViewController:viewController animated:animated];
}

-(UIViewController *)childViewControllerForStatusBarStyle{
    return self.topViewController;
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
