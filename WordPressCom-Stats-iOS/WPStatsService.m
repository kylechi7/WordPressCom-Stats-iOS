#import "WPStatsService.h"
#import "WPStatsServiceRemote.h"
#import "StatsItem.h"
#import "StatsItemAction.h"
#import "StatsGroup.h"
#import "StatsVisits.h"
#import "StatsSummary.h"

@interface WPStatsService ()

@property (nonatomic, strong) NSNumber *siteId;
@property (nonatomic, strong) NSString *oauth2Token;
@property (nonatomic, strong) NSTimeZone *siteTimeZone;

@end

@implementation WPStatsService
{

}

- (instancetype)initWithSiteId:(NSNumber *)siteId siteTimeZone:(NSTimeZone *)timeZone andOAuth2Token:(NSString *)oauth2Token
{
    NSAssert(oauth2Token.length > 0, @"OAuth2 token must not be empty.");
    NSAssert(siteId != nil, @"Site ID must not be nil.");
    NSAssert(timeZone != nil, @"Timezone must not be nil.");

    self = [super init];
    if (self) {
        _siteId = siteId;
        _oauth2Token = oauth2Token;
        _siteTimeZone = timeZone ?: [NSTimeZone systemTimeZone];
    }

    return self;
}

- (void)retrieveAllStatsForDates:(NSArray *)dates
                         andUnit:(StatsPeriodUnit)unit
     withVisitsCompletionHandler:(StatsVisitsCompletion)visitsCompletion
          postsCompletionHandler:(StatsItemsCompletion)postsCompletion
      referrersCompletionHandler:(StatsItemsCompletion)referrersCompletion
         clicksCompletionHandler:(StatsItemsCompletion)clicksCompletion
        countryCompletionHandler:(StatsItemsCompletion)countryCompletion
         videosCompletionHandler:(StatsItemsCompletion)videosCompletion
 commentsAuthorCompletionHandler:(StatsItemsCompletion)commentsAuthorsCompletion
  commentsPostsCompletionHandler:(StatsItemsCompletion)commentsPostsCompletion
 tagsCategoriesCompletionHandler:(StatsItemsCompletion)tagsCategoriesCompletion
followersDotComCompletionHandler:(StatsItemsCompletion)followersDotComCompletion
 followersEmailCompletionHandler:(StatsItemsCompletion)followersEmailCompletion
      publicizeCompletionHandler:(StatsItemsCompletion)publicizeCompletion
     andOverallCompletionHandler:(void (^)())completionHandler
           overallFailureHandler:(void (^)(NSError *error))failureHandler
{
    if (!completionHandler) {
        return;
    }
    
    void (^failure)(NSError *error) = ^void (NSError *error) {
        DDLogError(@"Error while retrieving stats: %@", error);

        if (failureHandler) {
            failureHandler(error);
        }
    };
    
    NSMutableArray *endDates = [NSMutableArray new];
    for (NSDate *date in dates) {
        NSDate *endDate = [self calculateEndDateForPeriodUnit:unit withDateWithinPeriod:date];
        [endDates addObject:endDate];
    }

    __block StatsVisits *visitsResult = nil;
    __block StatsGroup *postsResult = [StatsGroup new];
    __block StatsGroup *referrersResult = [StatsGroup new];
    __block StatsGroup *clicksResult = [StatsGroup new];
    __block StatsGroup *countriesResult = [StatsGroup new];
    __block StatsGroup *videosResult = [StatsGroup new];
    __block StatsGroup *commentsAuthorsResult = [StatsGroup new];
    __block StatsGroup *commentsPostsResult = [StatsGroup new];
    __block StatsGroup *tagsCategoriesResult = [StatsGroup new];
    __block StatsGroup *followersDotComResult = [StatsGroup new];
    __block StatsGroup *followersEmailResult = [StatsGroup new];
    __block StatsGroup *publicizeResult = [StatsGroup new];
    
    [self.remote batchFetchStatsForDates:endDates
                                 andUnit:unit
             withVisitsCompletionHandler:^(StatsVisits *visits)
    {
        visitsResult = visits;
        
        if (visitsCompletion) {
            visitsCompletion(visits);
        }
    }
                  postsCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        postsResult.items = items;
        postsResult.titlePrimary = NSLocalizedString(@"Posts & Pages", @"Title for stats section for Posts & Pages");
        postsResult.moreItemsExist = moreViewsAvailable;
        
        if (postsCompletion) {
            postsCompletion(postsResult);
        }
    }
              referrersCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        referrersResult.items = items;
        referrersResult.moreItemsExist = moreViewsAvailable;
        
        if (referrersCompletion) {
            referrersCompletion(referrersResult);
        }
    }
                 clicksCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        clicksResult.items = items;
        clicksResult.moreItemsExist = moreViewsAvailable;
        
        if (clicksCompletion) {
            clicksCompletion(clicksResult);
        }
    }
                countryCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        countriesResult.items = items;
        countriesResult.moreItemsExist = moreViewsAvailable;
        
        if (countryCompletion) {
            countryCompletion(countriesResult);
        }
    }
                 videosCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        videosResult.items = items;
        videosResult.moreItemsExist = moreViewsAvailable;
        
        if (videosCompletion) {
            videosCompletion(videosResult);
        }
    }
               commentsCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        commentsAuthorsResult.items = items.firstObject;
        commentsPostsResult.items = items.lastObject;
        
        if (commentsAuthorsCompletion) {
            commentsAuthorsCompletion(commentsAuthorsResult);
        }
        
        if (commentsPostsResult) {
            commentsPostsCompletion(commentsPostsResult);
        }
    }
         tagsCategoriesCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        tagsCategoriesResult.items = items;
        tagsCategoriesResult.moreItemsExist = moreViewsAvailable;
        
        if (tagsCategoriesCompletion) {
            tagsCategoriesCompletion(tagsCategoriesResult);
        }
    }
        followersDotComCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
     {
         followersDotComResult.items = items;
         followersDotComResult.moreItemsExist = moreViewsAvailable;
         
         for (StatsItem *item in items) {
             NSString *age = [self dateAgeForDate:item.date];
             item.value = age;
         }
         
         if (followersDotComCompletion) {
             followersDotComCompletion(followersDotComResult);
         }
     }
         followersEmailCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
     {
         followersEmailResult.items = items;
         followersEmailResult.moreItemsExist = moreViewsAvailable;
         
         for (StatsItem *item in items) {
             NSString *age = [self dateAgeForDate:item.date];
             item.value = age;
         }
         
         if (followersEmailCompletion) {
             followersEmailCompletion(followersEmailResult);
         }
     }
              publicizeCompletionHandler:^(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable)
    {
        publicizeResult.items = items;
        publicizeResult.moreItemsExist = moreViewsAvailable;
        
        if (publicizeCompletion) {
            publicizeCompletion(publicizeResult);
        }
    }
             andOverallCompletionHandler:^
    {
        completionHandler();
    }
                   overallFailureHandler:failure];
}


- (void)retrieveTodayStatsWithCompletionHandler:(void (^)(StatsSummaryCompletion *))completion failureHandler:(void (^)(NSError *))failureHandler
{
    void (^failure)(NSError *error) = ^void (NSError *error) {
        DDLogError(@"Error while retrieving stats: %@", error);
        
        if (failureHandler) {
            failureHandler(error);
        }
    };
    
}

- (WPStatsServiceRemote *)remote
{
    if (!_remote) {
        _remote = [[WPStatsServiceRemote alloc] initWithOAuth2Token:self.oauth2Token siteId:self.siteId andSiteTimeZone:self.siteTimeZone];
    }

    return _remote;
}

// TODO - Extract this into a separate class that's unit testable
- (NSString *)dateAgeForDate:(NSDate *)date
{
    if (!date) {
        return @"";
    }
    
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *now = [NSDate date];
    
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                   fromDate:date
                                                     toDate:now
                                                    options:0];
    if (dateComponents.year == 1) {
        return NSLocalizedString(@"a year", @"Age between dates equaling one year.");
    } else if (dateComponents.year > 1) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d years", @"Age between dates over one year."), dateComponents.year];
    } else if (dateComponents.month > 1) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d months", @"Age between dates over one month."), dateComponents.month];
    } else if (dateComponents.month == 1) {
        return NSLocalizedString(@"a month", @"Age between dates equaling one month.");
    } else if (dateComponents.day > 1) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d days", @"Age between dates over one day."), dateComponents.day];
    } else if (dateComponents.day == 1) {
        return NSLocalizedString(@"a day", @"Age between dates equaling one day.");
    } else if (dateComponents.hour > 1) {
        return [NSString stringWithFormat:NSLocalizedString(@"%d hours", @"Age between dates over one hour."), dateComponents.hour];
    } else if (dateComponents.hour == 1) {
        return NSLocalizedString(@"an hour", @"Age between dates equaling one hour.");
    } else {
        return NSLocalizedString(@"<1 hour", @"Age between dates less than one hour.");
    }
}

- (NSDate *)calculateEndDateForPeriodUnit:(StatsPeriodUnit)unit withDateWithinPeriod:(NSDate *)date
{
    if (unit == StatsPeriodUnitDay) {
        return date;
    }
    
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];

    if (unit == StatsPeriodUnitMonth) {
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:date];
        date = [calendar dateFromComponents:dateComponents];
        
        dateComponents = [NSDateComponents new];
        dateComponents.day = -1;
        dateComponents.month = +1;
        date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
        
        return date;
    } else if (unit == StatsPeriodUnitWeek) {
        // Weeks are Monday - Sunday
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear fromDate:date];
        NSInteger weekDay = dateComponents.weekday;
        
        if (weekDay > 1) {
            dateComponents = [NSDateComponents new];
            dateComponents.weekday = 8 - weekDay;
            date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
        }
        
        return date;
    } else if (unit == StatsPeriodUnitYear) {
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear fromDate:date];
        date = [calendar dateFromComponents:dateComponents];
        
        dateComponents = [NSDateComponents new];
        dateComponents.day = -1;
        dateComponents.year = +1;
        date = [calendar dateByAddingComponents:dateComponents toDate:date options:0];
        
        return date;
    }
    
    return nil;
}

@end