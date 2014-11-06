#import "WPStatsServiceV2Remote.h"
#import "NSObject+SafeExpectations.h"
#import "NSDictionary+SafeExpectations.h"
#import "WPStatsGroup.h"
#import "WPStatsViewByCountry.h"
#import "WPStatsTitleCountItem.h"
#import "WPStatsTopPost.h"
#import <AFNetworking/AFNetworking.h>
#import "StatsItem.h"
#import "StatsItemAction.h"
#import <NSObject+SafeExpectations.h>

static NSString *const WordPressComApiClientEndpointURL = @"https://public-api.wordpress.com/rest/v1.1";

@interface WPStatsServiceV2Remote ()

@property (nonatomic, copy)     NSString                        *oauth2Token;
@property (nonatomic, strong)   NSNumber                        *siteId;
@property (nonatomic, strong)   NSTimeZone                      *siteTimeZone;
@property (nonatomic, copy)     NSString                        *statsPathPrefix;
@property (nonatomic, strong)   NSDateFormatter                 *deviceDateFormatter;
@property (nonatomic, strong)   AFHTTPRequestOperationManager   *manager;

@end

@implementation WPStatsServiceV2Remote {
    
}

- (instancetype)initWithOAuth2Token:(NSString *)oauth2Token siteId:(NSNumber *)siteId andSiteTimeZone:(NSTimeZone *)timeZone
{
    NSParameterAssert(oauth2Token.length > 0);
    NSParameterAssert(siteId != nil);
    NSParameterAssert(timeZone != nil);
    
    self = [super init];
    if (self) {
        _oauth2Token = oauth2Token;
        _siteId = siteId;
        _siteTimeZone = timeZone;
        _statsPathPrefix = [NSString stringWithFormat:@"%@/sites/%@/stats", WordPressComApiClientEndpointURL, _siteId];
        _deviceDateFormatter = [NSDateFormatter new];
        _deviceDateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _deviceDateFormatter.dateFormat = @"yyyy-MM-dd";
        
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [_manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", _oauth2Token]
                          forHTTPHeaderField:@"Authorization"];
    }
    
    return self;
}

- (void)fetchSummaryStatsForTodayWithCompletionHandler:(void (^)(StatsSummary *summary))completionHandler failureHandler:(void (^)(NSError *error))failureHandler
{
    [self.manager GET:[self urlForSummary]
           parameters:nil
              success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (![responseObject isKindOfClass:[NSDictionary class]]) {
             if (failureHandler) {
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                 failureHandler(error);
             }
             
             return;
         }
         
         NSDictionary *statsSummaryDict = (NSDictionary *)responseObject;
         StatsSummary *statsSummary = [StatsSummary new];
         statsSummary.periodUnit = [self periodUnitForString:statsSummaryDict[@"period"]];
         statsSummary.date = [self deviceLocalDateForString:statsSummaryDict[@"date"]];
         statsSummary.views = statsSummaryDict[@"views"];
         statsSummary.visitors = statsSummaryDict[@"visitors"];
         statsSummary.likes = statsSummaryDict[@"likes"];
         statsSummary.reblogs = statsSummaryDict[@"reblogs"];
         statsSummary.comments = statsSummaryDict[@"comments"];
         
         if (completionHandler) {
             completionHandler(statsSummary);
         }
     }
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         DDLogError(@"Error with today summary stats: %@", error);
         
         if (failureHandler) {
             failureHandler(error);
         }
     }];
}

- (void)fetchVisitsStatsForPeriodUnit:(StatsPeriodUnit)unit
                withCompletionHandler:(void (^)(StatsVisits *visits))completionHandler
                       failureHandler:(void (^)(NSError *error))failureHandler
{
    // TODO :: Abstract this out to the local service
    NSNumber *quantity = IS_IPAD ? @12 : @7;
    
    [self.manager GET:[self urlForVisits]
           parameters:@{@"quantity" : quantity,
                        @"unit"     : [self stringForPeriodUnit:unit]}
              success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (![responseObject isKindOfClass:[NSDictionary class]]) {
             if (failureHandler) {
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                 failureHandler(error);
             }
             
             return;
         }
         
         NSDictionary *statsVisitsDict = (NSDictionary *)responseObject;

         StatsVisits *statsVisits = [StatsVisits new];
         statsVisits.date = [self deviceLocalDateForString:statsVisitsDict[@"date"]];
         statsVisits.unit = unit;
         
         NSArray *fields = (NSArray *)statsVisitsDict[@"fields"];
         
         NSUInteger periodIndex = [fields indexOfObject:@"period"];
         NSUInteger viewsIndex = [fields indexOfObject:@"views"];
         NSUInteger visitorsIndex = [fields indexOfObject:@"visitors"];
         NSUInteger likesIndex = [fields indexOfObject:@"likes"];
         NSUInteger reblogsIndex = [fields indexOfObject:@"reblogs"];
         NSUInteger commentsIndex = [fields indexOfObject:@"comments"];
         
         NSMutableArray *array = [NSMutableArray new];
         for (NSArray *period in statsVisitsDict[@"data"]) {
             StatsSummary *periodSummary = [StatsSummary new];
             periodSummary.date = [self deviceLocalDateForString:period[periodIndex]];
             periodSummary.views = period[viewsIndex];
             periodSummary.visitors = period[visitorsIndex];
             periodSummary.likes = period[likesIndex];
             periodSummary.reblogs = period[reblogsIndex];
             periodSummary.comments = period[commentsIndex];
             [array addObject:periodSummary];
         }

         statsVisits.statsData = array;
         
         if (completionHandler) {
             completionHandler(statsVisits);
         }
     }
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         DDLogError(@"Error with today summary stats: %@", error);
         
         if (failureHandler) {
             failureHandler(error);
         }
     }];
}

- (void)fetchPostsStatsForDate:(NSDate *)date
                       andUnit:(StatsPeriodUnit)unit
         withCompletionHandler:(void (^)(NSArray *items, NSNumber *totalViews))completionHandler
                failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    [self.manager GET:[self urlForTopPosts]
           parameters:@{@"period" : [self stringForPeriodUnit:unit],
                        @"date"   : [self siteLocalStringForDate:date]}
              success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (![responseObject isKindOfClass:[NSDictionary class]]) {
             if (failureHandler) {
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                 failureHandler(error);
             }
             
             return;
         }
         
         NSDictionary *statsPostsDict = (NSDictionary *)responseObject;
         NSDictionary *days = statsPostsDict[@"days"];
         NSDictionary *postViewsDict = [days allValues][0][@"postviews"];
         NSNumber *totalViews = [days allValues][0][@"total_views"];
         NSMutableArray *items = [NSMutableArray new];

         for (NSDictionary *post in postViewsDict) {
             StatsItem *statsItem = [StatsItem new];
             statsItem.itemID = post[@"id"];
             statsItem.value = post[@"views"];
             statsItem.label = post[@"title"];
             
             StatsItemAction *statsItemAction = [StatsItemAction new];
             statsItemAction.url = [NSURL URLWithString:post[@"href"]];
             statsItemAction.defaultAction = YES;
             
             statsItem.actions = @[statsItemAction];
             
             [items addObject:statsItem];
         }
         
         
         if (completionHandler) {
             completionHandler(items, totalViews);
         }
     }
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         DDLogError(@"Error with fetchPostsStatsForDate: %@", error);
         
         if (failureHandler) {
             failureHandler(error);
         }
     }];
}


- (void)fetchReferrersStatsForDate:(NSDate *)date
                           andUnit:(StatsPeriodUnit)unit
             withCompletionHandler:(void (^)(NSArray *items, NSNumber *totalViews, NSNumber *otherViews))completionHandler
                    failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    [self.manager GET:[self urlForReferrers]
           parameters:@{@"period" : [self stringForPeriodUnit:unit],
                        @"date"   : [self siteLocalStringForDate:date]}
              success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (![responseObject isKindOfClass:[NSDictionary class]]) {
             if (failureHandler) {
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                 failureHandler(error);
             }
             
             return;
         }
         
         NSDictionary *referrersDict = (NSDictionary *)responseObject;
         NSDictionary *days = referrersDict[@"days"];
         NSDictionary *groupsDict = [days allValues][0][@"groups"];
         NSNumber *totalViews = [days allValues][0][@"total_views"];
         NSNumber *otherViews = [days allValues][0][@"other_views"];
         NSMutableArray *items = [NSMutableArray new];
         
         for (NSDictionary *group in groupsDict) {
             StatsItem *statsItem = [StatsItem new];
             statsItem.label = [group stringForKey:@"name"];
             statsItem.value = [group numberForKey:@"total"];
             statsItem.iconURL = [NSURL URLWithString:[group stringForKey:@"icon"]];
             
             NSString *url = [group stringForKey:@"url"];
             if (url) {
                 StatsItemAction *action = [StatsItemAction new];
                 action.url = [NSURL URLWithString:url];
                 action.defaultAction = YES;
                 statsItem.actions = @[action];
             }
             // TODO :: group[@"group"] - where does this go
             // TODO :: group[@"total"]
             
             NSArray *results = [group arrayForKey:@"results"];
             NSMutableArray *resultsItems = [NSMutableArray new];
             for (id result in results) {
                 if ([result isKindOfClass:[NSDictionary class]]) {
                     StatsItem *resultItem = [StatsItem new];
                     resultItem.label = [result stringForKey:@"name"];
                     resultItem.iconURL = [NSURL URLWithString:[result stringForKey:@"icon"]];
                     resultItem.value = [result numberForKey:@"views"];
                     
                     NSString *url = [result stringForKey:@"url"];
                     if (url) {
                         StatsItemAction *action = [StatsItemAction new];
                         action.url = [NSURL URLWithString:url];
                         action.defaultAction = YES;
                         resultItem.actions = @[action];
                     }

                     [resultsItems addObject:resultItem];
                     
                     NSArray *children = [result arrayForKey:@"children"];
                     NSMutableArray *childItems = [NSMutableArray new];
                     for (NSDictionary *child in children) {
                         StatsItem *childItem = [StatsItem new];
                         childItem.label = [child stringForKey:@"name"];
                         childItem.iconURL = [NSURL URLWithString:[child stringForKey:@"icon"]];
                         childItem.value = [child numberForKey:@"views"];
                         
                         NSString *url = [child stringForKey:@"url"];
                         if (url) {
                             StatsItemAction *action = [StatsItemAction new];
                             action.url = [NSURL URLWithString:url];
                             action.defaultAction = YES;
                             childItem.actions = @[action];
                         }
                         
                         [childItems addObject:childItem];
                     }
                     resultItem.children = childItems;
                 }
             }
             statsItem.children = resultsItems;
             
             [items addObject:statsItem];
         }
         
         
         if (completionHandler) {
             completionHandler(items, totalViews, otherViews);
         }
     }
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         DDLogError(@"Error with fetchReferrersStatsForDate: %@", error);
         
         if (failureHandler) {
             failureHandler(error);
         }
     }];
}

- (void)fetchClicksStatsForDate:(NSDate *)date
                        andUnit:(StatsPeriodUnit)unit
          withCompletionHandler:(void (^)(NSArray *items, NSNumber *totalClicks, NSNumber *otherClicks))completionHandler
                 failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    [self.manager GET:[self urlForClicks]
           parameters:@{@"period" : [self stringForPeriodUnit:unit],
                        @"date"   : [self siteLocalStringForDate:date]}
              success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (![responseObject isKindOfClass:[NSDictionary class]]) {
             if (failureHandler) {
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                 failureHandler(error);
             }
             
             return;
         }
         
         NSDictionary *referrersDict = (NSDictionary *)responseObject;
         NSDictionary *days = referrersDict[@"days"];
         NSDictionary *clicksDict = [days allValues][0][@"clicks"];
         NSNumber *totalClicks = [days allValues][0][@"total_clicks"];
         NSNumber *otherClicks = [days allValues][0][@"other_clicks"];
         NSMutableArray *items = [NSMutableArray new];
         
         for (NSDictionary *click in clicksDict) {
             StatsItem *statsItem = [StatsItem new];
             statsItem.label = [click stringForKey:@"name"];
             statsItem.value = [click numberForKey:@"views"];
             statsItem.iconURL = [NSURL URLWithString:[click stringForKey:@"icon"]];
             
             NSString *url = [click stringForKey:@"url"];
             if (url) {
                 StatsItemAction *action = [StatsItemAction new];
                 action.url = [NSURL URLWithString:url];
                 action.defaultAction = YES;
                 statsItem.actions = @[action];
             }
             
             NSArray *children = [click arrayForKey:@"children"];
             NSMutableArray *childItems = [NSMutableArray new];
             for (NSDictionary *child in children) {
                 StatsItem *childItem = [StatsItem new];
                 childItem.label = [child stringForKey:@"name"];
                 childItem.iconURL = [NSURL URLWithString:[child stringForKey:@"icon"]];
                 childItem.value = [child numberForKey:@"views"];
                 
                 NSString *url = [child stringForKey:@"url"];
                 if (url) {
                     StatsItemAction *action = [StatsItemAction new];
                     action.url = [NSURL URLWithString:url];
                     action.defaultAction = YES;
                     childItem.actions = @[action];
                 }
                 
                 [childItems addObject:childItem];
             }
             statsItem.children = childItems;
             
             [items addObject:statsItem];
         }
         
         
         if (completionHandler) {
             completionHandler(items, totalClicks, otherClicks);
         }
     }
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         DDLogError(@"Error with fetchClicksStatsForDate: %@", error);
         
         if (failureHandler) {
             failureHandler(error);
         }
     }];
}

- (void)fetchCountryStatsForDate:(NSDate *)date
                         andUnit:(StatsPeriodUnit)unit
           withCompletionHandler:(void (^)(NSArray *items, NSNumber *totalViews, NSNumber *otherViews))completionHandler
                  failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    [self.manager GET:[self urlForCountryViews]
           parameters:@{@"period" : [self stringForPeriodUnit:unit],
                        @"date"   : [self siteLocalStringForDate:date]}
              success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (![responseObject isKindOfClass:[NSDictionary class]]) {
             if (failureHandler) {
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                 failureHandler(error);
             }
             
             return;
         }
         
         NSDictionary *countryViewsDict = (NSDictionary *)responseObject;
         NSDictionary *days = [countryViewsDict dictionaryForKey:@"days"];
         NSDictionary *countryInfoDict = [countryViewsDict dictionaryForKey:@"country-info"];
         NSDictionary *viewsDict = [days allValues][0][@"views"];
         NSNumber *totalViews = [days allValues][0][@"total_views"];
         NSNumber *otherViews = [days allValues][0][@"other_views"];
         NSMutableArray *items = [NSMutableArray new];
         
         for (NSDictionary *view in viewsDict) {
             NSString *key = [view stringForKey:@"country_code"];
             StatsItem *statsItem = [StatsItem new];
             statsItem.label = [countryInfoDict[key] stringForKey:@"country_full"];
             statsItem.value = [view numberForKey:@"views"];
             statsItem.iconURL = [NSURL URLWithString:[countryInfoDict[key] stringForKey:@"flag_icon"]];
             
             [items addObject:statsItem];
         }
         
         if (completionHandler) {
             completionHandler(items, totalViews, otherViews);
         }
     }
              failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         DDLogError(@"Error with fetchCountryStatsForDate: %@", error);
         
         if (failureHandler) {
             failureHandler(error);
         }
     }];
}


- (NSString *)urlForSummary
{
    return [NSString stringWithFormat:@"%@/summary/", self.statsPathPrefix];
}

- (NSString *)urlForVisits
{
    return [NSString stringWithFormat:@"%@/visits/", self.statsPathPrefix];
}

- (NSString *)urlForClicks
{
    return [NSString stringWithFormat:@"%@/clicks", self.statsPathPrefix];
}

- (NSString *)urlForCountryViews
{
    return [NSString stringWithFormat:@"%@/country-views", self.statsPathPrefix];
}

- (NSString *)urlForReferrers
{
    return [NSString stringWithFormat:@"%@/referrers/", self.statsPathPrefix];
}

- (NSString *)urlForTopPosts
{
    return [NSString stringWithFormat:@"%@/top-posts/", self.statsPathPrefix];
}

- (NSDate *)deviceLocalDateForString:(NSString *)dateString
{
    NSDate *localDate = [self.deviceDateFormatter dateFromString:dateString];
    
    return localDate;
}

- (NSString *)siteLocalStringForDate:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = self.siteTimeZone;
    
    NSString *todayString = [formatter stringFromDate:date];

    return todayString;
}

- (StatsPeriodUnit)periodUnitForString:(NSString *)unitString
{
    if ([unitString isEqualToString:@"day"]) {
        return StatsPeriodUnitDay;
    } else if ([unitString isEqualToString:@"week"]) {
        return StatsPeriodUnitWeek;
    } else if ([unitString isEqualToString:@"month"]) {
        return StatsPeriodUnitMonth;
    } else if ([unitString isEqualToString:@"year"]) {
        return StatsPeriodUnitYear;
    }
    
    return StatsPeriodUnitDay;
}

- (NSString *)stringForPeriodUnit:(StatsPeriodUnit)unit
{
    switch (unit) {
        case StatsPeriodUnitDay:
            return @"day";
        case StatsPeriodUnitWeek:
            return @"week";
        case StatsPeriodUnitMonth:
            return @"month";
        case StatsPeriodUnitYear:
            return @"year";
    }
    
    return @"";
}

@end
