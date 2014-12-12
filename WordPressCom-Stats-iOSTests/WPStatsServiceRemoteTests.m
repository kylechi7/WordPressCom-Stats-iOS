#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OCMock/OCMock.h>
#import "WPStatsServiceRemote.h"
#import "StatsItem.h"
#import "StatsItemAction.h"

@interface WPStatsServiceRemoteTests : XCTestCase

@property (nonatomic, strong) WPStatsServiceRemote *subject;

@end

@implementation WPStatsServiceRemoteTests

- (void)setUp {
    [super setUp];
    
    self.subject = [[WPStatsServiceRemote alloc] initWithOAuth2Token:@"token" siteId:@123456 andSiteTimeZone:[NSTimeZone systemTimeZone]];
}

- (void)tearDown {
    [super tearDown];
    
    self.subject = nil;
}

- (void)testSummary
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testFetchSummaryStats completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/summary"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-summary.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchSummaryStatsForDate:[NSDate date] withCompletionHandler:^(StatsSummary *summary) {
        XCTAssertNotNil(summary, @"summary should not be nil.");
        XCTAssertNotNil(summary.date);
        XCTAssertTrue(summary.periodUnit == StatsPeriodUnitDay);
        XCTAssertTrue([summary.views isEqualToString:@"56"]);
        XCTAssertTrue([summary.visitors isEqualToString:@"44"]);
        XCTAssertTrue([summary.likes isEqualToString:@"1"]);
        XCTAssertTrue([summary.comments isEqualToString:@"3"]);
        
        [expectation fulfill];
    } failureHandler:^(NSError *error) {
        XCTFail(@"Failure handler should not be called here.");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testVisitsDaySmall
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchVisitsStatsForPeriodUnit completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/visits"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-visits-day.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchVisitsStatsForDate:[NSDate date]
                                  andUnit:StatsPeriodUnitDay
                    withCompletionHandler:^(StatsVisits *visits)
     {
         XCTAssertNotNil(visits, @"visits should not be nil.");
         XCTAssertNotNil(visits.date);
         XCTAssertEqual(30, visits.statsData.count);
         XCTAssertEqual(StatsPeriodUnitDay, visits.unit);
         
         StatsSummary *firstSummary = visits.statsData[0];
         XCTAssertNotNil(firstSummary.date);
         XCTAssertTrue([firstSummary.views isEqualToString:@"58"]);
         XCTAssertTrue([firstSummary.visitors isEqualToString:@"39"]);
         XCTAssertTrue([firstSummary.likes isEqualToString:@"1"]);
         XCTAssertTrue([firstSummary.comments isEqualToString:@"3"]);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}


- (void)testVisitsDayLarge
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchVisitsStatsForPeriodUnit completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/visits"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-visits-day-large.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchVisitsStatsForDate:[NSDate date]
                                  andUnit:StatsPeriodUnitDay
                    withCompletionHandler:^(StatsVisits *visits)
     {
         XCTAssertNotNil(visits, @"visits should not be nil.");
         XCTAssertNotNil(visits.date);
         XCTAssertEqual(30, visits.statsData.count);
         XCTAssertEqual(StatsPeriodUnitDay, visits.unit);
         
         StatsSummary *firstSummary = visits.statsData[0];
         XCTAssertNotNil(firstSummary.date);
         XCTAssertTrue([firstSummary.views isEqualToString:@"7,808"]);
         XCTAssertTrue([firstSummary.visitors isEqualToString:@"4,331"]);
         XCTAssertTrue([firstSummary.likes isEqualToString:@"0"]);
         XCTAssertTrue([firstSummary.comments isEqualToString:@"0"]);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTopPostsDay
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchPostsStatsForDate completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/top-posts"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-top-posts-day.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchPostsStatsForDate:[NSDate date]
                                 andUnit:StatsPeriodUnitDay
                   withCompletionHandler:^(NSArray *items, NSString *totalViews, NSString *otherViews)
     {
         XCTAssertNotNil(items, @"Posts should not be nil.");
         XCTAssertNotNil(totalViews, @"There should be a number provided.");
         
         XCTAssertEqual(10, items.count);
         
         StatsItem *item = items[0];
         XCTAssertTrue([item.itemID isEqualToNumber:@750]);
         XCTAssertTrue([item.label isEqualToString:@"Asynchronous unit testing Core Data with Xcode 6"]);
         XCTAssertTrue([item.value isEqualToString:@"7"]);
         XCTAssertEqual(1, item.actions.count);
         
         StatsItemAction *action = item.actions[0];
         XCTAssertTrue(action.defaultAction);
         XCTAssertTrue([action.url.absoluteString isEqualToString:@"http://astralbodi.es/2014/08/06/asynchronous-unit-testing-core-data-with-xcode-6/"]);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTopPostsDayLarge
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchPostsStatsForDate completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/top-posts"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-top-posts-day-large.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchPostsStatsForDate:[NSDate date]
                                 andUnit:StatsPeriodUnitDay
                   withCompletionHandler:^(NSArray *items, NSString *totalViews, NSString *otherViews)
     {
         XCTAssertNotNil(items, @"Posts should not be nil.");
         XCTAssertNotNil(totalViews, @"There should be a number provided.");
         
         XCTAssertEqual(10, items.count);
         
         StatsItem *item = items[0];
         XCTAssertTrue([item.itemID isEqualToNumber:@39806]);
         XCTAssertTrue([item.label isEqualToString:@"Home"]);
         XCTAssertTrue([item.value isEqualToString:@"2,420"]);
         XCTAssertEqual(1, item.actions.count);
         
         StatsItemAction *action = item.actions[0];
         XCTAssertTrue(action.defaultAction);
         XCTAssertTrue([action.url.absoluteString isEqualToString:@"http://automattic.com/home/"]);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testReferrersDay
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchReferrersStatsForDate completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/referrers"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-referrers-day.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchReferrersStatsForDate:[NSDate date]
                                     andUnit:StatsPeriodUnitDay
                       withCompletionHandler:^(NSArray *items, NSString *totalViews, NSString *otherViews)
     {
         XCTAssertNotNil(items, @"Posts should not be nil.");
         XCTAssertNotNil(totalViews, @"There should be a number provided.");
         XCTAssertNotNil(otherViews, @"There should be a number provided.");
         
         XCTAssertEqual(4, items.count);
         
         /*
          * Search Engines (children + children)
          */
         StatsItem *searchEnginesItem = items[0];
         XCTAssertNil(searchEnginesItem.itemID);
         XCTAssertTrue([searchEnginesItem.value isEqualToString:@"38"]);
         XCTAssertTrue([searchEnginesItem.label isEqualToString:@"Search Engines"]);
         XCTAssertTrue([searchEnginesItem.iconURL.absoluteString isEqualToString:@"https://wordpress.com/i/stats/search-engine.png"]);
         XCTAssertEqual(0, searchEnginesItem.actions.count);
         XCTAssertEqual(1, searchEnginesItem.children.count);
         
         StatsItem *googleSearchItem = searchEnginesItem.children.firstObject;
         XCTAssertNil(googleSearchItem.itemID);
         XCTAssertTrue([googleSearchItem.value isEqualToString:@"38"]);
         XCTAssertTrue([googleSearchItem.label isEqualToString:@"Google Search"]);
         XCTAssertTrue([googleSearchItem.iconURL.absoluteString isEqualToString:@"https://secure.gravatar.com/blavatar/6741a05f4bc6e5b65f504c4f3df388a1?s=48"]);
         XCTAssertEqual(0, googleSearchItem.actions.count);
         XCTAssertEqual(11, googleSearchItem.children.count);
         
         StatsItem *googleDotComItem = googleSearchItem.children[0];
         XCTAssertNil(googleDotComItem.itemID);
         XCTAssertTrue([googleDotComItem.value isEqualToString:@"10"]);
         XCTAssertTrue([googleDotComItem.label isEqualToString:@"google.com"]);
         XCTAssertTrue([googleDotComItem.iconURL.absoluteString isEqualToString:@"https://secure.gravatar.com/blavatar/ff90821feeb2b02a33a6f9fc8e5f3fcd?s=48"]);
         XCTAssertEqual(1, googleDotComItem.actions.count);
         XCTAssertEqual(0, googleDotComItem.children.count);
         
         StatsItemAction *googleDotComItemAction = googleDotComItem.actions.firstObject;
         XCTAssertTrue([googleDotComItemAction.url.absoluteString isEqualToString:@"http://www.google.com/"]);
         XCTAssertNil(googleDotComItemAction.label);
         XCTAssertNil(googleDotComItemAction.iconURL);
         XCTAssertTrue(googleDotComItemAction.defaultAction);
         
         /*
          * Flipboard (no children)
          */
         StatsItem *flipBoardItem = items[3];
         XCTAssertNil(flipBoardItem.itemID);
         XCTAssertTrue([flipBoardItem.value isEqualToString:@"1"]);
         XCTAssertTrue([flipBoardItem.label isEqualToString:@"flipboard.com/redirect?url=http%3A%2F%2Fastralbodi.es%2F2014%2F08%2F06%2Fasynchronous-unit-testing-core-data-with-xcode-6%2F"]);
         XCTAssertNil(flipBoardItem.iconURL);
         XCTAssertEqual(1, flipBoardItem.actions.count);
         XCTAssertEqual(0, flipBoardItem.children.count);
         
         StatsItemAction *flipBoardItemAction = flipBoardItem.actions.firstObject;
         XCTAssertTrue([flipBoardItemAction.url.absoluteString isEqualToString:@"https://flipboard.com/redirect?url=http%3A%2F%2Fastralbodi.es%2F2014%2F08%2F06%2Fasynchronous-unit-testing-core-data-with-xcode-6%2F"]);
         XCTAssertNil(flipBoardItemAction.label);
         XCTAssertNil(flipBoardItemAction.iconURL);
         XCTAssertTrue(flipBoardItemAction.defaultAction);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}


- (void)testReferrersDayLarge
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchReferrersStatsForDate completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/referrers"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-referrers-day-large.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchReferrersStatsForDate:[NSDate date]
                                     andUnit:StatsPeriodUnitDay
                       withCompletionHandler:^(NSArray *items, NSString *totalViews, NSString *otherViews)
     {
         XCTAssertNotNil(items, @"Posts should not be nil.");
         XCTAssertTrue([@"2,161" isEqualToString:totalViews]);
         XCTAssertTrue([@"938" isEqualToString:otherViews]);
         
         XCTAssertEqual(10, items.count);
         
         /*
          * Search Engines (children + children)
          */
         StatsItem *searchEnginesItem = items[0];
         XCTAssertNil(searchEnginesItem.itemID);
         XCTAssertTrue([searchEnginesItem.value isEqualToString:@"480"]);
         XCTAssertTrue([searchEnginesItem.label isEqualToString:@"Search Engines"]);
         XCTAssertTrue([searchEnginesItem.iconURL.absoluteString isEqualToString:@"https://wordpress.com/i/stats/search-engine.png"]);
         XCTAssertEqual(0, searchEnginesItem.actions.count);
         XCTAssertEqual(7, searchEnginesItem.children.count);
         
         StatsItem *googleSearchItem = searchEnginesItem.children.firstObject;
         XCTAssertNil(googleSearchItem.itemID);
         XCTAssertTrue([googleSearchItem.value isEqualToString:@"461"]);
         XCTAssertTrue([googleSearchItem.label isEqualToString:@"Google Search"]);
         XCTAssertTrue([googleSearchItem.iconURL.absoluteString isEqualToString:@"https://secure.gravatar.com/blavatar/6741a05f4bc6e5b65f504c4f3df388a1?s=48"]);
         XCTAssertEqual(0, googleSearchItem.actions.count);
         XCTAssertEqual(11, googleSearchItem.children.count);
         
         StatsItem *googleDotComItem = googleSearchItem.children[0];
         XCTAssertNil(googleDotComItem.itemID);
         XCTAssertTrue([googleDotComItem.value isEqualToString:@"176"]);
         XCTAssertTrue([googleDotComItem.label isEqualToString:@"google.com"]);
         XCTAssertTrue([googleDotComItem.iconURL.absoluteString isEqualToString:@"https://secure.gravatar.com/blavatar/ff90821feeb2b02a33a6f9fc8e5f3fcd?s=48"]);
         XCTAssertEqual(1, googleDotComItem.actions.count);
         XCTAssertEqual(0, googleDotComItem.children.count);
         
         StatsItemAction *googleDotComItemAction = googleDotComItem.actions.firstObject;
         XCTAssertTrue([googleDotComItemAction.url.absoluteString isEqualToString:@"http://www.google.com/"]);
         XCTAssertNil(googleDotComItemAction.label);
         XCTAssertNil(googleDotComItemAction.iconURL);
         XCTAssertTrue(googleDotComItemAction.defaultAction);
         
         /*
          * Ma.tt
          */
         StatsItem *mattItem = items[6];
         XCTAssertNil(mattItem.itemID);
         XCTAssertTrue([mattItem.value isEqualToString:@"56"]);
         XCTAssertTrue([mattItem.label isEqualToString:@"ma.tt"]);
         XCTAssertTrue([mattItem.iconURL.absoluteString isEqualToString:@"https://secure.gravatar.com/blavatar/733a27a6b983dd89d6dd64d0445a3e8e?s=48"]);
         XCTAssertEqual(0, mattItem.actions.count);
         XCTAssertEqual(11, mattItem.children.count);
         
         StatsItem *mattRootItem = mattItem.children[0];
         XCTAssertTrue([mattRootItem.value isEqualToString:@"34"]);
         XCTAssertTrue([mattRootItem.label isEqualToString:@"ma.tt"]);
         XCTAssertNil(mattRootItem.iconURL);
         XCTAssertEqual(1, mattRootItem.actions.count);
         XCTAssertEqual(0, mattRootItem.children.count);

         StatsItemAction *mattRootItemAction = mattRootItem.actions.firstObject;
         XCTAssertTrue([mattRootItemAction.url.absoluteString isEqualToString:@"http://ma.tt/"]);
         XCTAssertNil(mattRootItemAction.label);
         XCTAssertNil(mattRootItemAction.iconURL);
         XCTAssertTrue(mattRootItemAction.defaultAction);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}


- (void)testClicksDay
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchClicksStatsForDate completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/clicks"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-clicks-day.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchClicksStatsForDate:[NSDate date]
                                  andUnit:StatsPeriodUnitDay
                    withCompletionHandler:^(NSArray *items, NSString *totalClicks, NSString *otherClicks)
     {
         XCTAssertNotNil(items, @"Posts should not be nil.");
         XCTAssertNotNil(totalClicks, @"There should be a number provided.");
         XCTAssertNotNil(otherClicks, @"There should be a number provided.");
         
         XCTAssertEqual(2, items.count);
         
         StatsItem *statsItem1 = items[0];
         XCTAssertTrue([statsItem1.label isEqualToString:@"astralbodies.net/blog/2013/10/31/paying-attention-at-automattic/"]);
         XCTAssertNil(statsItem1.iconURL);
         XCTAssertTrue([@"1" isEqualToString:statsItem1.value]);
         XCTAssertEqual(1, statsItem1.actions.count);
         XCTAssertEqual(0, statsItem1.children.count);
         StatsItemAction *statsItemAction1 = statsItem1.actions[0];
         XCTAssertTrue([statsItemAction1.url.absoluteString isEqualToString:@"http://astralbodies.net/blog/2013/10/31/paying-attention-at-automattic/"]);
         XCTAssertTrue(statsItemAction1.defaultAction);
         XCTAssertNil(statsItemAction1.label);
         XCTAssertNil(statsItemAction1.iconURL);
         
         StatsItem *statsItem2 = items[1];
         XCTAssertTrue([statsItem2.label isEqualToString:@"devforums.apple.com/thread/86137"]);
         XCTAssertNil(statsItem2.iconURL);
         XCTAssertTrue([@"1" isEqualToString:statsItem2.value]);
         XCTAssertEqual(1, statsItem2.actions.count);
         XCTAssertEqual(0, statsItem2.children.count);
         StatsItemAction *statsItemAction2 = statsItem2.actions[0];
         XCTAssertTrue([statsItemAction2.url.absoluteString isEqualToString:@"https://devforums.apple.com/thread/86137"]);
         XCTAssertTrue(statsItemAction2.defaultAction);
         XCTAssertNil(statsItemAction2.label);
         XCTAssertNil(statsItemAction2.iconURL);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testClicksMonthLarge
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchClicksStatsForDate completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/clicks"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-clicks-month-large.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchClicksStatsForDate:[NSDate date]
                                  andUnit:StatsPeriodUnitMonth
                    withCompletionHandler:^(NSArray *items, NSString *totalClicks, NSString *otherClicks)
     {
         XCTAssertNotNil(items);
         XCTAssertTrue([@"9" isEqualToString:totalClicks]);
         XCTAssertTrue([@"0" isEqualToString:otherClicks]);
         
         XCTAssertEqual(6, items.count);
         
         StatsItem *statsItem1 = items[0];
         XCTAssertTrue([statsItem1.label isEqualToString:@"wp.com"]);
         XCTAssertNil(statsItem1.iconURL);
         XCTAssertTrue([@"3" isEqualToString:statsItem1.value]);
         XCTAssertEqual(1, statsItem1.actions.count);
         XCTAssertEqual(0, statsItem1.children.count);
         StatsItemAction *statsItemAction1 = statsItem1.actions[0];
         XCTAssertTrue([statsItemAction1.url.absoluteString isEqualToString:@"http://wp.com/"]);
         XCTAssertTrue(statsItemAction1.defaultAction);
         XCTAssertNil(statsItemAction1.label);
         XCTAssertNil(statsItemAction1.iconURL);
         
         StatsItem *statsItem2 = items[1];
         XCTAssertTrue([statsItem2.label isEqualToString:@"blog.wordpress.tv"]);
         XCTAssertNil(statsItem2.iconURL);
         XCTAssertTrue([@"2" isEqualToString:statsItem2.value]);
         XCTAssertEqual(0, statsItem2.actions.count);
         XCTAssertEqual(2, statsItem2.children.count);
         
         StatsItem *child1 = statsItem2.children[0];
         XCTAssertTrue([child1.label isEqualToString:@"blog.wordpress.tv/2014/10/03/build-your-audience-recent-wordcamp-videos-from-experienced-content-creators/"]);
         XCTAssertNil(child1.iconURL);
         XCTAssertTrue([@"1" isEqualToString:child1.value]);
         XCTAssertEqual(1, child1.actions.count);
         XCTAssertEqual(0, child1.children.count);
         
         StatsItemAction *statsItemAction2 = child1.actions[0];
         XCTAssertTrue([statsItemAction2.url.absoluteString isEqualToString:@"http://blog.wordpress.tv/2014/10/03/build-your-audience-recent-wordcamp-videos-from-experienced-content-creators/"]);
         XCTAssertTrue(statsItemAction2.defaultAction);
         XCTAssertNil(statsItemAction2.label);
         XCTAssertNil(statsItemAction2.iconURL);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testCountryViewsDay
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"fetchCountryStatsForDate completion"];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] hasPrefix:@"https://public-api.wordpress.com/rest/v1.1/sites/123456/stats/country-views"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"stats-v1.1-country-views-day.json", nil) statusCode:200 headers:@{@"Content-Type" : @"application/json"}];
    }];
    
    [self.subject fetchCountryStatsForDate:[NSDate date]
                                   andUnit:StatsPeriodUnitDay
                     withCompletionHandler:^(NSArray *items, NSString *totalViews, NSString *otherViews)
     {
         XCTAssertNotNil(items, @"Posts should not be nil.");
         XCTAssertNotNil(totalViews, @"There should be a number provided.");
         XCTAssertNotNil(otherViews, @"There should be a number provided.");
         
         XCTAssertEqual(12, items.count);
         
         StatsItem *item = items[0];
         XCTAssertTrue([item.label isEqualToString:@"United States"]);
         XCTAssertTrue([@"23" isEqualToString:item.value]);
         XCTAssertNil(item.itemID);
         XCTAssertTrue([item.iconURL.absoluteString isEqualToString:@"https://secure.gravatar.com/blavatar/5a83891a81b057fed56930a6aaaf7b3c?s=48"]);
         XCTAssertEqual(0, item.actions.count);
         XCTAssertEqual(0, item.children.count);
         
         [expectation fulfill];
     } failureHandler:^(NSError *error) {
         XCTFail(@"Failure handler should not be called here.");
         [expectation fulfill];
     }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
