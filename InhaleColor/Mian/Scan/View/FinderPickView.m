//
//  FinderPickView.m
//  InhaleColor
//
//  Created by wukexiu on 17/4/22.
//  Copyright © 2017年 com.xm.InhaleColor. All rights reserved.
//

#import "FinderPickView.h"

@interface FinderPickView()
{
    CGPoint startPoint;
    CGPoint originPoint;
}

@end

@implementation FinderPickView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
*/

-(instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.width = 50;
        self.height = 50;
        self.layer.cornerRadius = 25;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.masksToBounds = YES;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = 25;
        self.layer.shadowOpacity = 0.2;
        [self.layer setZPosition:1];
        UILongPressGestureRecognizer *longGesture =[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressed:)];
        [self addGestureRecognizer:longGesture];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
}

-(void)handleLongPressed:(UILongPressGestureRecognizer *)sender{
    UIView *vw = (UIView *)sender.view;
    if (self.isManual == NO) {
        return;
    }
    if (sender.state == UIGestureRecognizerStateBegan) {
        [[self superview] bringSubviewToFront:vw];
        //[vw.layer setZPosition:2];
        startPoint = [sender locationInView:sender.view];
        originPoint = vw.center;
        [UIView animateWithDuration:0.2 animations:^{
            vw.transform = CGAffineTransformMakeScale(1.8, 1.8);
        } completion:^(BOOL finished) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(fingerPickViewBegan:)]) {
                [self.delegate fingerPickViewBegan:originPoint];
            }
        }];
        
    }else if (sender.state == UIGestureRecognizerStateChanged){
        vw.transform = CGAffineTransformMakeScale(1, 1);
        CGPoint newPoint = [sender locationInView:sender.view];
        CGFloat deltaX = newPoint.x-startPoint.x;
        CGFloat deltaY = newPoint.y-startPoint.y;
        CGFloat centerX = vw.center.x+deltaX;
        CGFloat centerY = vw.center.y+deltaY;
        if (centerY > (kScreen_Height - 64 *2)) {
            centerY = kScreen_Height - 64 *2;
        }else if (centerY <= 0) {
            centerY = 0;
        }
        if (centerX > kScreen_Width) {
            centerX = kScreen_Width;
        }else if (centerX <= 0) {
            centerX = 0;
        }
        vw.center = CGPointMake(centerX,centerY);
        vw.transform = CGAffineTransformMakeScale(1.8, 1.8);
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(fingerPickViewChanged:withCenter:)]) {
            [self.delegate fingerPickViewChanged:self withCenter:vw.center];
        }
        
    }else if (sender.state == UIGestureRecognizerStateEnded){
        [UIView animateWithDuration:0.2 animations:^{
            vw.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            //NSLog(@"UIGestureRecognizerStateEnded Point(%lf,%lf)",vw.center.x,vw.center.y);
        }];
        [vw.layer setZPosition:1];
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(fingerPickViewEnded)]) {
            [self.delegate fingerPickViewEnded];
        }
    }
}


@end
