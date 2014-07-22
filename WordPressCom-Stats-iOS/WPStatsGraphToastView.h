#import <UIKit/UIKit.h>

@interface WPStatsGraphToastView : UIView

@property (nonatomic, assign) CGFloat xOffset;
@property (nonatomic, copy) NSString *dateText;
@property (nonatomic, assign) NSUInteger viewCount;
@property (nonatomic, assign) NSUInteger visitorsCount;

@end
