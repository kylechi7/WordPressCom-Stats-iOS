#import "WPStatsServiceRemote.h"
#import "NSObject+SafeExpectations.h"
#import "NSDictionary+SafeExpectations.h"
#import <AFNetworking/AFNetworking.h>
#import "StatsItem.h"
#import "StatsItemAction.h"
#import <NSObject+SafeExpectations.h>

static NSString *const WordPressComApiClientEndpointURL = @"https://public-api.wordpress.com/rest/v1.1";

@interface WPStatsServiceRemote ()

@property (nonatomic, copy)     NSString                        *oauth2Token;
@property (nonatomic, strong)   NSNumber                        *siteId;
@property (nonatomic, strong)   NSTimeZone                      *siteTimeZone;
@property (nonatomic, copy)     NSString                        *statsPathPrefix;
@property (nonatomic, strong)   NSDateFormatter                 *deviceDateFormatter;
@property (nonatomic, strong)   AFHTTPRequestOperationManager   *manager;

@end

@implementation WPStatsServiceRemote {
    
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


#pragma mark - Public methods


- (void)batchFetchStatsForDates:(NSArray *)dates
                        andUnit:(StatsPeriodUnit)unit
    withVisitsCompletionHandler:(StatsRemoteVisitsCompletion)visitsCompletion
         postsCompletionHandler:(StatsRemoteItemsCompletion)postsCompletion
     referrersCompletionHandler:(StatsRemoteItemsCompletion)referrersCompletion
        clicksCompletionHandler:(StatsRemoteItemsCompletion)clicksCompletion
       countryCompletionHandler:(StatsRemoteItemsCompletion)countryCompletion
         videosCompetionHandler:(StatsRemoteItemsCompletion)videosCompletion
             commentsCompletion:(StatsRemoteItemsCompletion)commentsCompletion
       tagsCategoriesCompletion:(StatsRemoteItemsCompletion)tagsCategoriesCompletion
            followersCompletion:(StatsRemoteItemsCompletion)followersCompletion
            publicizeCompletion:(StatsRemoteItemsCompletion)publicizeCompletion
    andOverallCompletionHandler:(void (^)())completionHandler
          overallFailureHandler:(void (^)(NSError *error))failureHandler
{
    // TODO - Implement comments, and followers endpoints
    
    NSMutableArray *mutableOperations = [NSMutableArray new];
    
    for (NSDate *date in dates) {
        if (visitsCompletion) {
            [mutableOperations addObject:[self operationForVisitsForDate:date andUnit:unit withCompletionHandler:visitsCompletion failureHandler:nil]];
        }
        if (postsCompletion) {
            [mutableOperations addObject:[self operationForPostsForDate:date andUnit:unit withCompletionHandler:postsCompletion failureHandler:nil]];
        }
        if (referrersCompletion) {
            [mutableOperations addObject:[self operationForReferrersForDate:date andUnit:unit withCompletionHandler:referrersCompletion failureHandler:nil]];
        }
        if (clicksCompletion) {
            [mutableOperations addObject:[self operationForClicksForDate:date andUnit:unit withCompletionHandler:clicksCompletion failureHandler:nil]];
        }
        if (countryCompletion) {
            [mutableOperations addObject:[self operationForCountryForDate:date andUnit:unit withCompletionHandler:countryCompletion failureHandler:nil]];
        }
        if (videosCompletion) {
            [mutableOperations addObject:[self operationForVideosForDate:date andUnit:unit withCompletionHandler:videosCompletion failureHandler:nil]];
        }
        if (commentsCompletion) {
            
        }
        if (tagsCategoriesCompletion) {
            [mutableOperations addObject:[self operationForTagsCategoriesForDate:date andUnit:unit withCompletionHandler:tagsCategoriesCompletion failureHandler:nil]];
        }
        if (followersCompletion) {
            
        }
        if (publicizeCompletion) {
            [mutableOperations addObject:[self operationForPublicizeForDate:date andUnit:unit withCompletionHandler:publicizeCompletion failureHandler:nil]];
        }
    }
    
    NSArray *operations = [AFURLConnectionOperation batchOfRequestOperations:mutableOperations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        DDLogVerbose(@"Finished remote operations %@ of %@", @(numberOfFinishedOperations), @(totalNumberOfOperations));
    } completionBlock:^(NSArray *operations) {
        if (completionHandler) {
            completionHandler();
        }
    }];
    
    [[NSOperationQueue mainQueue] addOperations:operations waitUntilFinished:NO];
}

- (void)fetchSummaryStatsForDate:(NSDate *)date
           withCompletionHandler:(StatsRemoteSummaryCompletion)completionHandler
                  failureHandler:(void (^)(NSError *error))failureHandler
{
    AFHTTPRequestOperation *operation = [self operationForSummaryForDate:date andUnit:StatsPeriodUnitDay withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchVisitsStatsForDate:(NSDate *)date
                        andUnit:(StatsPeriodUnit)unit
          withCompletionHandler:(StatsRemoteVisitsCompletion)completionHandler
                 failureHandler:(void (^)(NSError *error))failureHandler
{
    
    AFHTTPRequestOperation *operation = [self operationForVisitsForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchPostsStatsForDate:(NSDate *)date
                       andUnit:(StatsPeriodUnit)unit
         withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForPostsForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchReferrersStatsForDate:(NSDate *)date
                           andUnit:(StatsPeriodUnit)unit
             withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                    failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForReferrersForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchClicksStatsForDate:(NSDate *)date
                        andUnit:(StatsPeriodUnit)unit
          withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                 failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForClicksForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchCountryStatsForDate:(NSDate *)date
                         andUnit:(StatsPeriodUnit)unit
           withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                  failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForCountryForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchVideosStatsForDate:(NSDate *)date
                        andUnit:(StatsPeriodUnit)unit
          withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                 failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForVideosForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchCommentsStatsForDate:(NSDate *)date
                          andUnit:(StatsPeriodUnit)unit
            withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                   failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForCommentsForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchTagsCategoriesStatsForDate:(NSDate *)date
                                andUnit:(StatsPeriodUnit)unit
                  withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                         failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForTagsCategoriesForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchFollowersStatsForDate:(NSDate *)date
                           andUnit:(StatsPeriodUnit)unit
             withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                    failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForFollowersForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


- (void)fetchPublicizeStatsForDate:(NSDate *)date
                           andUnit:(StatsPeriodUnit)unit
             withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                    failureHandler:(void (^)(NSError *error))failureHandler
{
    NSParameterAssert(date != nil);
    
    AFHTTPRequestOperation *operation = [self operationForPublicizeForDate:date andUnit:unit withCompletionHandler:completionHandler failureHandler:failureHandler];
    [operation start];
}


#pragma mark - Private methods to compose request operations to be reusable


- (AFHTTPRequestOperation *)operationForSummaryForDate:(NSDate *)date
                                               andUnit:(StatsPeriodUnit)unit
                                 withCompletionHandler:(StatsRemoteSummaryCompletion)completionHandler
                                        failureHandler:(void (^)(NSError *error))failureHandler
{
    
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *statsSummaryDict = (NSDictionary *)responseObject;
        StatsSummary *statsSummary = [StatsSummary new];
        statsSummary.periodUnit = [self periodUnitForString:statsSummaryDict[@"period"]];
        statsSummary.date = [self deviceLocalDateForString:statsSummaryDict[@"date"] withPeriodUnit:unit];
        statsSummary.label = [self nicePointNameForDate:statsSummary.date forStatsPeriodUnit:statsSummary.periodUnit];
        statsSummary.views = statsSummaryDict[@"views"];
        statsSummary.visitors = statsSummaryDict[@"visitors"];
        statsSummary.likes = statsSummaryDict[@"likes"];
        statsSummary.comments = statsSummaryDict[@"comments"];
        
        if (completionHandler) {
            completionHandler(statsSummary);
        }
    };
    
    AFHTTPRequestOperation *operation =  [self requestOperationForURLString:[self urlForSummary]
                                                                 parameters:nil
                                                                    success:handler
                                                                    failure:[self failureForFailureCompletionHandler:failureHandler]];
    return operation;
}


- (AFHTTPRequestOperation *)operationForVisitsForDate:(NSDate *)date
                                              andUnit:(StatsPeriodUnit)unit
                                 withCompletionHandler:(StatsRemoteVisitsCompletion)completionHandler
                                       failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *statsVisitsDict = (NSDictionary *)responseObject;
        
        StatsVisits *statsVisits = [StatsVisits new];
        statsVisits.date = [self deviceLocalDateForString:statsVisitsDict[@"date"] withPeriodUnit:unit];
        
        NSArray *fields = (NSArray *)statsVisitsDict[@"fields"];
        
        NSUInteger periodIndex = [fields indexOfObject:@"period"];
        NSUInteger viewsIndex = [fields indexOfObject:@"views"];
        NSUInteger visitorsIndex = [fields indexOfObject:@"visitors"];
        NSUInteger likesIndex = [fields indexOfObject:@"likes"];
        NSUInteger commentsIndex = [fields indexOfObject:@"comments"];
        
        NSMutableArray *array = [NSMutableArray new];
        for (NSArray *period in statsVisitsDict[@"data"]) {
            StatsSummary *periodSummary = [StatsSummary new];
            periodSummary.periodUnit = unit;
            periodSummary.date = [self deviceLocalDateForString:period[periodIndex] withPeriodUnit:unit];
            periodSummary.label = [self nicePointNameForDate:periodSummary.date forStatsPeriodUnit:periodSummary.periodUnit];
            periodSummary.views = period[viewsIndex];
            periodSummary.visitors = period[visitorsIndex];
            periodSummary.likes = period[likesIndex];
            periodSummary.comments = period[commentsIndex];
            [array addObject:periodSummary];
        }
        
        statsVisits.statsData = array;
        
        if (completionHandler) {
            completionHandler(statsVisits);
        }
    };
    
    // TODO :: Abstract this out to the local service
    NSNumber *quantity = IS_IPAD ? @12 : @7;
    NSDictionary *parameters = @{@"quantity" : quantity,
                                 @"unit"     : [self stringForPeriodUnit:unit],
                                 @"date"     : [self siteLocalStringForDate:date]};

    AFHTTPRequestOperation *operation =  [self requestOperationForURLString:[self urlForVisits]
                                                                 parameters:parameters
                                                                    success:handler
                                                                    failure:[self failureForFailureCompletionHandler:failureHandler]];
    return operation;
}


- (AFHTTPRequestOperation *)operationForPostsForDate:(NSDate *)date
                                             andUnit:(StatsPeriodUnit)unit
                               withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                      failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *statsPostsDict = (NSDictionary *)responseObject;
        NSDictionary *days = [statsPostsDict dictionaryForKey:@"days"];
        NSDictionary *postViewsDict = [[days allValues][0] dictionaryForKey:@"postviews"];
        NSNumber *totalViews = [days allValues][0][@"total_views"];
        NSNumber *otherViews = [days allValues][0][@"other_views"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *post in postViewsDict) {
            StatsItem *statsItem = [StatsItem new];
            statsItem.itemID = post[@"id"];
            statsItem.value = [post stringForKey:@"views"];
            statsItem.label = [post stringForKey:@"title"];
            
            StatsItemAction *statsItemAction = [StatsItemAction new];
            statsItemAction.url = [NSURL URLWithString:post[@"href"]];
            statsItemAction.defaultAction = YES;
            
            statsItem.actions = @[statsItemAction];
            
            [items addObject:statsItem];
        }
        
        
        if (completionHandler) {
            completionHandler(items, totalViews, otherViews);
        }
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date]};
    AFHTTPRequestOperation *operation =  [self requestOperationForURLString:[self urlForTopPosts]
                                                                 parameters:parameters
                                                                    success:handler
                                                                    failure:[self failureForFailureCompletionHandler:failureHandler]];
    return operation;
}


- (AFHTTPRequestOperation *)operationForReferrersForDate:(NSDate *)date
                                                 andUnit:(StatsPeriodUnit)unit
                                   withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                          failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *referrersDict = (NSDictionary *)responseObject;
        NSDictionary *days = [referrersDict dictionaryForKey:@"days"];
        NSDictionary *groupsDict = [[days allValues][0] dictionaryForKey:@"groups"];
        NSNumber *totalViews = [days allValues][0][@"total_views"];
        NSNumber *otherViews = [days allValues][0][@"other_views"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *group in groupsDict) {
            StatsItem *statsItem = [StatsItem new];
            statsItem.label = [group stringForKey:@"name"];
            statsItem.value = [group stringForKey:@"total"];
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
                    resultItem.value = [result stringForKey:@"views"];
                    
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
                        childItem.value = [child stringForKey:@"views"];
                        
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
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date]};
    
    AFHTTPRequestOperation *operation = [self requestOperationForURLString:[self urlForReferrers]
                                                                parameters:parameters
                                                                   success:handler
                                                                   failure:[self failureForFailureCompletionHandler:failureHandler]];
    
    return operation;
}


- (AFHTTPRequestOperation *)operationForClicksForDate:(NSDate *)date
                                              andUnit:(StatsPeriodUnit)unit
                                withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                       failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *referrersDict = (NSDictionary *)responseObject;
        NSDictionary *days = [referrersDict dictionaryForKey:@"days"];
        NSDictionary *clicksDict = [[days allValues][0] dictionaryForKey:@"clicks"];
        NSNumber *totalClicks = [days allValues][0][@"total_clicks"];
        NSNumber *otherClicks = [days allValues][0][@"other_clicks"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *click in clicksDict) {
            StatsItem *statsItem = [StatsItem new];
            statsItem.label = [click stringForKey:@"name"];
            statsItem.value = [click stringForKey:@"views"];
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
                childItem.value = [child stringForKey:@"views"];
                
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
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date]};
    
    AFHTTPRequestOperation *operation = [self requestOperationForURLString:[self urlForClicks]
                                                                parameters:parameters
                                                                   success:handler
                                                                   failure:[self failureForFailureCompletionHandler:failureHandler]];
    return operation;
}


- (AFHTTPRequestOperation *)operationForCountryForDate:(NSDate *)date
                                               andUnit:(StatsPeriodUnit)unit
                                 withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                        failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *countryViewsDict = (NSDictionary *)responseObject;
        NSDictionary *days = [countryViewsDict dictionaryForKey:@"days"];
        NSDictionary *countryInfoDict = [countryViewsDict dictionaryForKey:@"country-info"];
        NSDictionary *viewsDict = [[days allValues][0] dictionaryForKey:@"views"];
        NSNumber *totalViews = [days allValues][0][@"total_views"];
        NSNumber *otherViews = [days allValues][0][@"other_views"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *view in viewsDict) {
            NSString *key = [view stringForKey:@"country_code"];
            StatsItem *statsItem = [StatsItem new];
            statsItem.label = [countryInfoDict[key] stringForKey:@"country_full"];
            statsItem.value = [view stringForKey:@"views"];
            statsItem.iconURL = [NSURL URLWithString:[countryInfoDict[key] stringForKey:@"flag_icon"]];
            
            [items addObject:statsItem];
        }
        
        if (completionHandler) {
            completionHandler(items, totalViews, otherViews);
        }
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date]};
    
    AFHTTPRequestOperation *operation = [self requestOperationForURLString:[self urlForCountryViews]
                                                                parameters:parameters
                                                                   success:handler
                                                                   failure:[self failureForFailureCompletionHandler:failureHandler]];

    return operation;
}


- (AFHTTPRequestOperation *)operationForVideosForDate:(NSDate *)date
                                              andUnit:(StatsPeriodUnit)unit
                                withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                       failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *videosDict = (NSDictionary *)responseObject;
        NSDictionary *days = [videosDict dictionaryForKey:@"days"];
        NSDictionary *playsDict = [[days allValues][0] dictionaryForKey:@"plays"];
        NSNumber *totalPlays = [days allValues][0][@"total_plays"];
        NSNumber *otherPlays = [days allValues][0][@"other_plays"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *play in playsDict) {
            StatsItem *statsItem = [StatsItem new];
            statsItem.itemID = [play numberForKey:@"post_id"];
            statsItem.label = [play stringForKey:@"title"];
            statsItem.value = [play stringForKey:@"plays"];

            NSString *url = [play stringForKey:@"url"];
            if (url) {
                StatsItemAction *action = [StatsItemAction new];
                action.url = [NSURL URLWithString:url];
                action.defaultAction = YES;
                statsItem.actions = @[action];
            }

            [items addObject:statsItem];
        }
        
        if (completionHandler) {
            completionHandler(items, totalPlays, otherPlays);
        }
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date]};
    
    AFHTTPRequestOperation *operation = [self requestOperationForURLString:[self urlForVideos]
                                                                parameters:parameters
                                                                   success:handler
                                                                   failure:[self failureForFailureCompletionHandler:failureHandler]];
    
    return operation;
}


- (AFHTTPRequestOperation *)operationForCommentsForDate:(NSDate *)date
                                                andUnit:(StatsPeriodUnit)unit
                                  withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                         failureHandler:(void (^)(NSError *error))failureHandler
{
    // TODO :: Implement
    return nil;
}


- (AFHTTPRequestOperation *)operationForTagsCategoriesForDate:(NSDate *)date
                                                      andUnit:(StatsPeriodUnit)unit
                                        withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                               failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *responseDict = (NSDictionary *)responseObject;
        NSArray *tagGroups = [responseDict dictionaryForKey:@"tags"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *tagGroup in tagGroups) {
            NSArray *tags = [tagGroup arrayForKey:@"tags"];
            
            if (tags.count == 1) {
                NSDictionary *theTag = tags[0];
                StatsItem *statsItem = [StatsItem new];
                statsItem.label = [theTag stringForKey:@"name"];
                statsItem.value = [tagGroup stringForKey:@"views"];
                [items addObject:statsItem];
            } else {
                NSMutableString *tagLabel = [NSMutableString new];
                
                NSMutableArray *childStatsItems = [NSMutableArray new];
                for (NSDictionary *subTag in tags) {
                    
                    StatsItem *childItem = [StatsItem new];
                    childItem.label = [subTag stringForKey:@"name"];
                    
                    [tagLabel appendFormat:@"%@ ", childItem.label];
                    
                    [childStatsItems addObject:childItem];
                }
                
                StatsItem *statsItem = [StatsItem new];
                statsItem.label = tagLabel;
                statsItem.value = [tagGroup stringForKey:@"views"];
                statsItem.children = childStatsItems;
                
                [items addObject:statsItem];
            }
        }
        
        if (completionHandler) {
            completionHandler(items, nil, nil);
        }
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date]};
    
    AFHTTPRequestOperation *operation = [self requestOperationForURLString:[self urlForTagsCategories]
                                                                parameters:parameters
                                                                   success:handler
                                                                   failure:[self failureForFailureCompletionHandler:failureHandler]];
    return operation;}


- (AFHTTPRequestOperation *)operationForFollowersForDate:(NSDate *)date
                                                 andUnit:(StatsPeriodUnit)unit
                                   withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                          failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *response = (NSDictionary *)responseObject;
        
        NSArray *subscribers = [response arrayForKey:@"subscribers"];
        NSMutableArray *items = [NSMutableArray new];
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy-mm-dd hh:mi:ss";
        
        for (NSDictionary *subscriber in subscribers) {
            StatsItem *statsItem = [StatsItem new];
            statsItem.label = [subscriber stringForKey:@"label"];
            statsItem.date = [self deviceLocalDateForString:[subscriber stringForKey:@"date_subscribed"] withPeriodUnit:unit];
        }
        
        if (completionHandler) {
            completionHandler(items, nil, nil);
        }
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date],
                                 @"type"   : @"wpcom",
                                 @"max"    : @7};
    
    AFHTTPRequestOperation *operation = [self requestOperationForURLString:[self urlForPublicize]
                                                                parameters:parameters
                                                                   success:handler
                                                                   failure:[self failureForFailureCompletionHandler:failureHandler]];
    
    return operation;
}


- (AFHTTPRequestOperation *)operationForPublicizeForDate:(NSDate *)date
                                                 andUnit:(StatsPeriodUnit)unit
                                   withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler
                                          failureHandler:(void (^)(NSError *error))failureHandler
{
    id handler = ^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *servicesDict = (NSDictionary *)responseObject;
        NSArray *services = [servicesDict arrayForKey:@"services"];
        NSMutableArray *items = [NSMutableArray new];
        
        for (NSDictionary *service in services) {
            StatsItem *statsItem = [StatsItem new];
            NSString *serviceID = [service stringForKey:@"service"];
            NSString *serviceLabel = serviceID;
            NSURL *iconURL = nil;
            
            if ([serviceID isEqualToString:@"facebook"]) {
                serviceLabel = @"Facebook";
                iconURL = [NSURL URLWithString:@"https://secure.gravatar.com/blavatar/2343ec78a04c6ea9d80806345d31fd78?s=48"];
            } else if ([serviceID isEqualToString:@"twitter"]) {
                serviceLabel = @"Twitter";
                iconURL = [NSURL URLWithString:@"https://secure.gravatar.com/blavatar/7905d1c4e12c54933a44d19fcd5f9356?s=48"];
            } else if ([serviceID isEqualToString:@"tumblr"]) {
                serviceLabel = @"Tumblr";
                iconURL = [NSURL URLWithString:@"https://secure.gravatar.com/blavatar/84314f01e87cb656ba5f382d22d85134?s=48"];
            } else if ([serviceID isEqualToString:@"google_plus"]) {
                serviceLabel = @"Google+";
                iconURL = [NSURL URLWithString:@"https://secure.gravatar.com/blavatar/4a4788c1dfc396b1f86355b274cc26b3?s=48"];
            } else if ([serviceID isEqualToString:@"linkedin"]) {
                serviceLabel = @"LinkedIn";
                iconURL = [NSURL URLWithString:@"https://secure.gravatar.com/blavatar/f54db463750940e0e7f7630fe327845e?s=48"];
            } else if ([serviceID isEqualToString:@"path"]) {
                serviceLabel = @"Path";
                iconURL = [NSURL URLWithString:@"https://secure.gravatar.com/blavatar/3a03c8ce5bf1271fb3760bb6e79b02c1?s=48"];
            }
            
            statsItem.label = serviceLabel;
            statsItem.iconURL = iconURL;
            statsItem.value = [service stringForKey:@"followers"];
            
            [items addObject:statsItem];
        }
        
        if (completionHandler) {
            completionHandler(items, nil, nil);
        }
    };
    
    NSDictionary *parameters = @{@"period" : [self stringForPeriodUnit:unit],
                                 @"date"   : [self siteLocalStringForDate:date]};
    
    AFHTTPRequestOperation *operation = [self requestOperationForURLString:[self urlForPublicize]
                                                                parameters:parameters
                                                                   success:handler
                                                                   failure:[self failureForFailureCompletionHandler:failureHandler]];
    
    return operation;
}


#pragma mark - Private convenience methods for building requests

- (AFHTTPRequestOperation *)requestOperationForURLString:(NSString *)url
                                              parameters:(NSDictionary *)parameters
                                                 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self.manager.requestSerializer requestWithMethod:@"GET"
                                                                    URLString:url
                                                                   parameters:parameters
                                                                        error:nil];
    AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request
                                                                              success:success
                                                                              failure:failure];
    
    return operation;
}


- (void(^)(AFHTTPRequestOperation *operation, NSError *error))failureForFailureCompletionHandler:(void (^)(NSError *error))failureHandler
{
    return ^(AFHTTPRequestOperation *operation, NSError *error)
    {
        DDLogError(@"Error with today summary stats: %@", error);
        
        if (failureHandler) {
            failureHandler(error);
        }
    };
}


// TODO :: These could probably go into the operation methods since it's not really helpful any more
#pragma mark - Private methods for URL convenience


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


- (NSString *)urlForVideos
{
    return [NSString stringWithFormat:@"%@/video-plays/", self.statsPathPrefix];
}


- (NSString *)urlForComments
{
    return [NSString stringWithFormat:@"%@/comments/", self.statsPathPrefix];
}


- (NSString *)urlForTagsCategories
{
    return [NSString stringWithFormat:@"%@/tags/", self.statsPathPrefix];
}


- (NSString *)urlForFollowers
{
    return [NSString stringWithFormat:@"%@/followers/", self.statsPathPrefix];
}


- (NSString *)urlForPublicize
{
    return [NSString stringWithFormat:@"%@/publicize/", self.statsPathPrefix];
}


#pragma mark - Private convenience methods for data conversion


- (NSDate *)deviceLocalDateForString:(NSString *)dateString withPeriodUnit:(StatsPeriodUnit)unit
{
    switch (unit) {
        case StatsPeriodUnitDay:
        {
            self.deviceDateFormatter.dateFormat = @"yyyy-MM-dd";
            break;
        }
        case StatsPeriodUnitWeek:
        {
            // Assumes format: yyyyWxxWxx first xx is month, second xx is first day of that week
            self.deviceDateFormatter.dateFormat = @"yyyy'W'MM'W'dd";
            break;
        }
        case StatsPeriodUnitMonth:
        {
            self.deviceDateFormatter.dateFormat = @"yyyy-MM-dd";
            break;
        }
        case StatsPeriodUnitYear:
            
            break;
    }
    
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

- (NSString *)nicePointNameForDate:(NSDate *)date forStatsPeriodUnit:(StatsPeriodUnit)unit {
    if (!date) {
        return @"";
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
    
    switch (unit) {
        case StatsPeriodUnitDay:
            dateFormatter.dateFormat = @"LLL dd";
            break;
        case StatsPeriodUnitWeek:
            dateFormatter.dateFormat = @"LLL dd";
            break;
        case StatsPeriodUnitMonth:
            dateFormatter.dateFormat = @"LLL";
            break;
        case StatsPeriodUnitYear:
            dateFormatter.dateFormat = @"yyyy";
            break;
    }
    
    NSString *niceName = [dateFormatter stringFromDate:date] ?: @"";

    return niceName;
}


@end
