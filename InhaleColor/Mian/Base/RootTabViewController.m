//
//  RootTabViewController.m
//  InhaleColor
//
//  Created by wukexiu on 17/4/21.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import "RootTabViewController.h"
#import "RDVTabBarItem.h"
#import "RootViewController.h"
#import "BaseNavigationViewController.h"
#import "RssRootController.h"
#import "MeRootController.h"
#import "PhotoScanViewController.h"
#import "CollectColorViewController.h"

@interface RootTabViewController ()

@end

@implementation RootTabViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViewControllers];
    UIImageView *iv_a = [[UIImageView alloc] initWithFrame:CGRectMake((kScreen_Width-75)/2.0, 49 - 65, 75, 65)];
    iv_a.image = [UIImage imageNamed:@"tabbar_np_shadow"];
    iv_a.contentMode = UIViewContentModeScaleAspectFill;
    [self.tabBar addSubview:iv_a];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake((kScreen_Width-65)/2.0, 49 - 65, 65, 65)];
    [btn setBackgroundImage:[UIImage imageNamed:@"tabbar_np_normal"] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"tabbar_np_normal"] forState:UIControlStateHighlighted];
    btn.contentMode = UIViewContentModeScaleAspectFill;
    [btn addTarget:self action:@selector(openPhotoScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:btn];
    btn.userInteractionEnabled = YES;
    
    self.tabBar.clipsToBounds = NO;
}

-(void)openPhotoScan:(id)sender{
    //PhotoScanViewController *vc = [[PhotoScanViewController alloc] init];
    CollectColorViewController *vc = [[CollectColorViewController alloc] init];
    [self presentViewController:vc animated:NO completion:^{
        
    }];
}

-(void)setupViewControllers{
    
    RssRootController *vc_rss=[[RssRootController alloc] initWithNibName:@"RssRootController" bundle:nil];
    BaseNavigationViewController *nav_rss = [[BaseNavigationViewController alloc] initWithRootViewController:vc_rss];
    
    RootViewController *vc_other = [[RootViewController alloc] init];
    BaseNavigationViewController *nav_other = [[BaseNavigationViewController alloc] initWithRootViewController:vc_other];
    
    MeRootController *vc_me=[[MeRootController alloc] initWithNibName:@"MeRootController" bundle:nil];
    BaseNavigationViewController *nav_me = [[BaseNavigationViewController alloc] initWithRootViewController:vc_me];
    
    [self setViewControllers:@[nav_rss,nav_other,nav_me]];
    [self customizeTabBarForController];
    self.delegate=self;
    self.selectedIndex = 0;
}

-(void)customizeTabBarForController{
    UIImage *backgroundImage=[UIImage imageWithColor:IC_Color(255, 255, 255, 1.0) withFrame:CGRectMake(0, 0, kScreen_Width, 50)];

    self.tabBar.layer.shadowColor = IC_Color(121, 121, 121, 0.2).CGColor;
    self.tabBar.layer.shadowOpacity = 1.0;
    self.tabBar.layer.shadowOffset = CGSizeMake(0, -4);
    
    NSArray *tabBarItemImages=@[@"tab_recommend",@"",@"tab_me"];
    //tabbar_np_normal tabbar_np_shadow
    NSArray *tabBarItemTitles = @[@"收藏", @"", @"我的"];
    NSInteger index = 0;
    
    for (RDVTabBarItem *item in [[self tabBar] items]) {
        item.titlePositionAdjustment = UIOffsetMake(0, 3);
        [item setBackgroundSelectedImage:backgroundImage withUnselectedImage:backgroundImage];
        UIImage *selectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_sle",
                                                      [tabBarItemImages objectAtIndex:index]]];//_selected
        UIImage *unselectedimage = [UIImage imageNamed:[NSString stringWithFormat:@"%@_nor",
                                                        [tabBarItemImages objectAtIndex:index]]];//_normal
        if (index == 1) {
            [item setFinishedSelectedImage:nil withFinishedUnselectedImage:nil];
        }else{
            [item setFinishedSelectedImage:selectedimage withFinishedUnselectedImage:unselectedimage];
        }
        
         [item setTitle:[tabBarItemTitles objectAtIndex:index]];
         item.unselectedTitleAttributes = @{
         NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:10],
         NSForegroundColorAttributeName: IC_Color(121, 121, 121, 1),
         };
         item.selectedTitleAttributes = @{
         NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:10],
         NSForegroundColorAttributeName: IC_Color(121, 121, 121, 1),
         };
        
        index++;
    }
}

#pragma mark RDVTabBarControllerDelegate
-(BOOL)tabBarController:(RDVTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController{
    return YES;
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
