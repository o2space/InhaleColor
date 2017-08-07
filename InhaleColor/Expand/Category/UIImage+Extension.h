

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface UIImage (Extension)
+(UIImage *)imageWithName:(NSString *)name;

+(UIImage *)resizedImage:(NSString *)name;

+(UIImage *)imageWithNameGS:(NSString *)name Number:(float)number;
+(UIImage *)imageWithImageGS:(UIImage *)toImage Number:(float)number;

+(UIImage *)imageWithColor:(UIColor *)aColor;
+(UIImage *)imageWithColor:(UIColor *)aColor withFrame:(CGRect)aFrame;
-(UIImage*)scaledToSize:(CGSize)targetSize;
-(UIImage*)scaledToSize:(CGSize)targetSize highQuality:(BOOL)highQuality;
+ (UIImage *)fullResolutionImageFromALAsset:(ALAsset *)asset;
@end
