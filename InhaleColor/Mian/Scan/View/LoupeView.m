//
//  LoupeView.m
//  InhaleColor
//
//  Created by wukexiu on 17/4/26.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import "LoupeView.h"

@interface LoupeView()

@end

@implementation LoupeView

-(id)init{
    self = [self initWithFrame:CGRectMake(0, 0, 60*2, 60*2)];
    [self.layer setZPosition:1];
    return self;
}

-(id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.borderWidth = 0;
        self.layer.cornerRadius = frame.size.width / 2.0;
        self.layer.masksToBounds = YES;
        self.touchPointOffset = CGPointMake(0, -110);
        self.scale = 3.0;
        self.scaleAtTouchPoint = YES;
        
        
        UIImageView *loupeImageView = nil;
        if (SYSTEM_VERSION_EQUAL_OR_GREATER_THAN(@"7.0")) {
            loupeImageView = [[UIImageView alloc] initWithFrame:CGRectOffset(CGRectInset(self.bounds, -3.0, -3.0), 0, 2.5)];
            loupeImageView.image = [UIImage imageNamed:@"loupe_7"];
        }else{
            loupeImageView = [[UIImageView alloc] initWithFrame:CGRectOffset(CGRectInset(self.bounds, -5.0, -5.0), 0, 2)];
            loupeImageView.image = [UIImage imageNamed:@"loupe_6"];
        }
        loupeImageView.backgroundColor = [UIColor clearColor];
        [self addSubview:loupeImageView];
        
    }
    return self;
}
-(void)setTouchPoint:(CGPoint)touchPoint{
    _touchPoint = touchPoint;
    self.center = CGPointMake(touchPoint.x + _touchPointOffset.x, touchPoint.y + _touchPointOffset.y);
}

-(void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, self.frame.size.width/2, self.frame.size.height/2 );
    CGContextScaleCTM(context, _scale, _scale);
    CGContextTranslateCTM(context, -_touchPoint.x, -_touchPoint.y + (self.scaleAtTouchPoint? 0 : self.bounds.size.height/2));
    [self.targetVw.layer renderInContext:context];
}

@end
