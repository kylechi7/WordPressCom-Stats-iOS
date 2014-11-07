#import <XCTest/XCTest.h>
#import "WPStatsService.h"
#import "WPStatsServiceV2Remote.h"
#import <OCMock/OCMock.h>

@interface WPStatsServiceTest : XCTestCase

@property (strong) id remoteMock;
@property (strong) WPStatsService *statsService;

@end

@implementation WPStatsServiceTest

- (void)setUp
{
    [super setUp];


    self.remoteMock = [OCMockObject mockForClass:[WPStatsServiceV2Remote class]];

    self.statsService = [[WPStatsService alloc] initWithSiteId:@2 siteTimeZone:[NSTimeZone systemTimeZone] andOAuth2Token:@"token"];
    self.statsService.remote = self.remoteMock;
}

- (void)tearDown
{
    [super tearDown];

    self.statsService = nil;
    self.remoteMock = nil;
}

- (void)testRetrieveAllStatsRemoteCalled
{
    void (^failure)(NSError *error) = ^void(NSError *error) {
    };
    
    StatsCompletion completion = ^(WPStatsSummary *summary, NSDictionary *topPosts, NSDictionary *clicks, NSDictionary *countryViews, NSDictionary *referrers, NSDictionary *searchTerms, WPStatsViewsVisitors *viewsVisitors) {
    };
    
//    [[self.remoteMock expect] fetchStatsForTodayDate:[OCMArg any] andYesterdayDate:[OCMArg any] withCompletionHandler:completion failureHandler:[OCMArg isNotNil]];
    
    [self.statsService retrieveAllStatsWithCompletionHandler:completion failureHandler:failure];
    
    [self.remoteMock verify];
}

- (void)testRetrieveStatsSummaryRemoteCalled
{
    void (^failure)(NSError *error) = ^void(NSError *error) {
    };
    
    void (^completion)(WPStatsSummary *) = ^void(WPStatsSummary *summary) {
    };
    
//    [[self.remoteMock expect] fetchSummaryStatsForTodayWithCompletionHandler:completion failureHandler:[OCMArg isNotNil]];
    [[self.remoteMock expect] fetchSummaryStatsForTodayWithCompletionHandler:[OCMArg isNotNil] failureHandler:[OCMArg isNotNil]];
    
    [self.statsService retrieveTodayStatsWithCompletionHandler:completion failureHandler:failure];
    
    [self.remoteMock verify];
}

//- (void)testDatesPassedAreTodayAndYesterday
//{
//    NSDate *today = [NSDate date];
//    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
//    [dateComponents setDay:-1];
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//    NSDate *yesterday = [calendar dateByAddingComponents:dateComponents toDate:today options:0];
//    
//    [[self.remoteMock expect] fetchStatsForTodayDate:[OCMArg checkWithBlock:^BOOL(id obj) {
//        return [today timeIntervalSinceDate:obj] < 1000;
//    }] andYesterdayDate:[OCMArg checkWithBlock:^BOOL(id obj) {
//        return [yesterday timeIntervalSinceDate:obj] < 1000;
//    }] withCompletionHandler:[OCMArg isNil] failureHandler:[OCMArg isNotNil]];
//    
//    [self.statsService retrieveAllStatsWithCompletionHandler:nil failureHandler:nil];
//    
//    [self.remoteMock verify];
//}

@end
