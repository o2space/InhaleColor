//
//  UIColor+Extension.h
//  InhaleColor
//
//  Created by wukexiu on 17/4/25.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)


+(NSArray *)getRgbByColor:(UIColor *)color;
+(NSString*)toStrByUIColor:(UIColor*)color;
+(UIColor *)getColorStr:(NSString *)hexColor;
@end
