#import <UIKit/UIKit.h>
#import "StatsVisits.h"
#import "StatsSummary.h"

@protocol WPStatsGraphViewControllerDelegate;

@interface WPStatsGraphViewController : UICollectionViewController

@property (nonatomic, weak) id<WPStatsGraphViewControllerDelegate> graphDelegate;
@property (nonatomic, strong) StatsVisits *visits;
@property (nonatomic, assign) StatsPeriodUnit currentUnit;
@property (nonatomic, assign) StatsSummaryType currentSummaryType;
@property (nonatomic, assign) BOOL allowDeselection; // defaults to YES

- (void)selectGraphBarWithDate:(NSDate *)selectedDate;

@end

@protocol WPStatsGraphViewControllerDelegate <NSObject>

@optional

- (void)statsGraphViewController:(WPStatsGraphViewController *)controller didSelectDate:(NSDate *)date;
- (void)statsGraphViewControllerDidDeselectAllBars:(WPStatsGraphViewController *)controller;

@end
