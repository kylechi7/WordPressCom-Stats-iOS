#import "StatsTableViewController.h"
#import "WPStatsGraphViewController.h"
#import "WPStatsServiceV2.h"
#import "StatsGroup.h"
#import "StatsItem.h"
#import "StatsGroup+View.h"
#import "StatsItem+View.h"
#import <WPFontManager.h>
#import "WPStyleGuide+Stats.h"

typedef NS_ENUM(NSInteger, StatsSection) {
    StatsSectionGraph,
    StatsSectionPosts,
    StatsSectionReferrers,
    StatsSectionClicks,
    StatsSectionCountry,
    StatsSectionVideos,
    StatsSectionComments,
    StatsSectionTagsCategories,
    StatsSectionFollowers
};

static CGFloat const kGraphHeight = 175.0f;
static CGFloat const kNoResultsHeight = 100.0f;

@interface StatsTableViewController ()

@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableDictionary *sectionData;
@property (nonatomic, strong) WPStatsGraphViewController *graphViewController;
@property (nonatomic, strong) WPStatsServiceV2 *statsService;
@property (nonatomic, assign) StatsPeriodUnit selectedPeriodUnit;
@property (nonatomic, assign) StatsSummaryType selectedSummaryType;
@property (nonatomic, strong) NSDate *selectedDate;

@end

@implementation StatsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Force load fonts from bundle
    [WPFontManager openSansBoldFontOfSize:1.0f];
    [WPFontManager openSansRegularFontOfSize:1.0f];

    self.sections = @[ @(StatsSectionGraph),
                       @(StatsSectionPosts),
                       @(StatsSectionReferrers),
                       @(StatsSectionClicks),
                       @(StatsSectionCountry),
                       @(StatsSectionVideos),
                       @(StatsSectionComments),
                       @(StatsSectionTagsCategories),
                       @(StatsSectionFollowers)];
    self.sectionData = [NSMutableDictionary new];
    
    self.graphViewController = [WPStatsGraphViewController new];
    self.selectedPeriodUnit = StatsPeriodUnitDay;
    self.selectedSummaryType = StatsSummaryTypeViews;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.statsService = [[WPStatsServiceV2 alloc] initWithSiteId:self.siteID siteTimeZone:self.siteTimeZone andOAuth2Token:self.oauth2Token];

    [self.statsService retrieveAllStatsForDates:@[]
                                        andUnit:self.selectedPeriodUnit
                   withSummaryCompletionHandler:^(StatsSummary *summary)
    {
        
    }
                        visitsCompletionHandler:^(StatsVisits *visits)
    {
        self.sectionData[@(StatsSectionGraph)] = visits;
        self.selectedDate = ((StatsSummary *)visits.statsData.lastObject).date;

        [self.tableView beginUpdates];

        NSUInteger sectionNumber = [self.sections indexOfObject:@(StatsSectionGraph)];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(self.selectedSummaryType + 1) inSection:sectionNumber];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
                         postsCompletionHandler:^(StatsGroup *group)
    {
        self.sectionData[@(StatsSectionPosts)] = group;
        
        [self.tableView beginUpdates];
        
        NSUInteger sectionNumber = [self.sections indexOfObject:@(StatsSectionPosts)];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
                     referrersCompletionHandler:^(StatsGroup *group)
    {
        self.sectionData[@(StatsSectionReferrers)] = group;
        
        [self.tableView beginUpdates];
        
        NSUInteger sectionNumber = [self.sections indexOfObject:@(StatsSectionReferrers)];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
                        clicksCompletionHandler:^(StatsGroup *group)
    {
        self.sectionData[@(StatsSectionClicks)] = group;
        
        [self.tableView beginUpdates];
        
        NSUInteger sectionNumber = [self.sections indexOfObject:@(StatsSectionClicks)];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
                       countryCompletionHandler:^(StatsGroup *group)
    {
        self.sectionData[@(StatsSectionCountry)] = group;
        
        [self.tableView beginUpdates];
        
        NSUInteger sectionNumber = [self.sections indexOfObject:@(StatsSectionCountry)];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionNumber];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
    }
                         videosCompetionHandler:^(StatsGroup *group)
    {

    }
                             commentsCompletion:^(StatsGroup *group)
    {

    }
                       tagsCategoriesCompletion:^(StatsGroup *group)
    {

    }
                            followersCompletion:^(StatsGroup *group)
    {

    }
                            publicizeCompletion:^(StatsGroup *group)
    {

    }
                    andOverallCompletionHandler:^
    {

    }
                          overallFailureHandler:^(NSError *error)
    {

    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    StatsSection statsSection = (StatsSection)[self.sections[section] integerValue];
    switch (statsSection) {
        case StatsSectionGraph:
            return 5;
        case StatsSectionPosts: {
            NSUInteger count = ((StatsGroup *)self.sectionData[@(StatsSectionPosts)]).items.count;
            return count == 0 ? 3 : 2 + count;
        }
        case StatsSectionReferrers: {
            NSUInteger count = ((StatsGroup *)self.sectionData[@(StatsSectionReferrers)]).items.count;
            return count == 0 ? 3 : 2 + count;
        }
        case StatsSectionClicks: {
            NSUInteger count = ((StatsGroup *)self.sectionData[@(StatsSectionClicks)]).items.count;
            return count == 0 ? 3 : 2 + count;
        }
        case StatsSectionCountry: {
            NSUInteger count = ((StatsGroup *)self.sectionData[@(StatsSectionCountry)]).items.count;
            return count == 0 ? 3 : 2 + count;
        }
        case StatsSectionVideos:
            return 3;
        case StatsSectionComments:
            return 3;
        case StatsSectionTagsCategories:
            return 3;
        case StatsSectionFollowers:
            return 3;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];

    if ([cellIdentifier isEqualToString:@"GraphRow"]) {
        return kGraphHeight;
    } else if ([cellIdentifier isEqualToString:@"NoResultsRow"]) {
        return kNoResultsHeight;
    } else if ([cellIdentifier isEqualToString:@"SelectableRow"]) {
        return 35.0f;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.sections[indexPath.section] isEqualToNumber:@(StatsSectionGraph)] && indexPath.row > 0) {
        for (NSIndexPath *selectedIndexPath in [tableView indexPathsForSelectedRows]) {
            [tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
        }
        
        return indexPath;
    }
    
    return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.sections[indexPath.section] isEqualToNumber:@(StatsSectionGraph)] && indexPath.row > 0) {
        return nil;
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.sections[indexPath.section] isEqualToNumber:@(StatsSectionGraph)] && indexPath.row > 0) {
        self.selectedSummaryType = (StatsSummaryType)(indexPath.row - 1);
        
        NSIndexPath *graphIndexPath = [NSIndexPath indexPathForItem:0 inSection:indexPath.section];
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[graphIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [tableView endUpdates];
    }
}

#pragma mark - Private methods

- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"";
    
    StatsSection statsSection = (StatsSection)[self.sections[indexPath.section] integerValue];
    
    switch (statsSection) {
        case StatsSectionGraph: {
            switch (indexPath.row) {
                case 0:
                    identifier = @"GraphRow";
                    break;
                    
                default:
                    identifier = @"SelectableRow";
                    break;
            }
            break;
        }
        case StatsSectionPosts:
        case StatsSectionReferrers:
        case StatsSectionClicks:
        case StatsSectionCountry:
        case StatsSectionVideos:
        case StatsSectionComments:
        case StatsSectionTagsCategories:
        case StatsSectionFollowers: {
            switch (indexPath.row) {
                case 0:
                    identifier = @"GroupHeader";
                    break;
                case 1:
                    identifier = @"TwoColumnHeader";
                    break;
                default:
                    if (((StatsGroup *)self.sectionData[@(statsSection)]).items.count > 0) {
                        identifier = @"TwoColumnRow";
                    } else {
                        identifier = @"NoResultsRow";
                    }
                    break;
            }
            break;
        }
            
        default:
            break;
    }
    
    return identifier;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    StatsSection statsSection = (StatsSection)[self.sections[indexPath.section] integerValue];
    
    switch (statsSection) {
        case StatsSectionGraph:
            [self configureSectionGraphCell:cell forRow:indexPath.row];
            break;
        case StatsSectionPosts:
            [self configureSectionPostsCell:cell forRow:indexPath.row];
            break;
        case StatsSectionReferrers:
            [self configureSectionReferrersCell:cell forRow:indexPath.row];
            break;
        case StatsSectionClicks:
            [self configureSectionClicksCell:cell forRow:indexPath.row];
            break;
        case StatsSectionCountry:
            [self configureSectionCountryCell:cell forRow:indexPath.row];
            break;
        case StatsSectionVideos:
            [self configureSectionVideosCell:cell forRow:indexPath.row];
            break;
        case StatsSectionComments:
            [self configureSectionCommentsCell:cell forRow:indexPath.row];
            break;
        case StatsSectionTagsCategories:
            [self configureSectionTagsCategoriesCell:cell forRow:indexPath.row];
            break;
        case StatsSectionFollowers:
            [self configureSectionFollowersCell:cell forRow:indexPath.row];
            break;
        default:
            break;
    }
}

- (void)configureSectionGraphCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    UILabel *iconLabel = (UILabel *)[cell.contentView viewWithTag:100];
    UILabel *textLabel = (UILabel *)[cell.contentView viewWithTag:200];
    UILabel *valueLabel = (UILabel *)[cell.contentView viewWithTag:300];

    // Find the selected summary
    StatsVisits *visits = self.sectionData[@(StatsSectionGraph)];
    StatsSummary *summary;
    for (StatsSummary *s in visits.statsData) {
        if ([s.date isEqualToDate:self.selectedDate]) {
            summary = s;
            break;
        }
    }
    
    switch (row) {
        case 0: // Graph Row
        {
            if (![[cell.contentView subviews] containsObject:self.graphViewController.view]) {
                UIView *graphView = self.graphViewController.view;
                graphView.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(cell.contentView.bounds), kGraphHeight);
                graphView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                [cell.contentView addSubview:graphView];
            }
            
            self.graphViewController.currentUnit = self.selectedPeriodUnit;
            self.graphViewController.currentSummaryType = self.selectedSummaryType;
            self.graphViewController.visits = visits;
            [self.graphViewController.collectionView reloadData];
            self.graphViewController.allowDeselection = NO;
            [self.graphViewController selectGraphBarWithDate:summary.date];
            
            break;
        }
            
        case 1: // Views
        {
            iconLabel.text = @"";
            textLabel.text = NSLocalizedString(@"Views", @"");
            valueLabel.text = summary.views.stringValue;
//            cell.backgroundColor = self.selectedSummaryType == StatsSummaryTypeViews ? [WPStyleGuide statsLighterOrange] : [UIColor whiteColor];
            break;
        }
            
        case 2: // Visitors
        {
            iconLabel.text = @"";
            textLabel.text = NSLocalizedString(@"Visitors", @"");
            valueLabel.text = summary.visitors.stringValue;
//            cell.backgroundColor = self.selectedSummaryType == StatsSummaryTypeVisitors ? [WPStyleGuide statsLighterOrange] : [UIColor whiteColor];
            break;
        }
            
        case 3: // Likes
        {
            iconLabel.text = @"";
            textLabel.text = NSLocalizedString(@"Likes", @"");
            valueLabel.text = summary.likes.stringValue;
//            cell.backgroundColor = self.selectedSummaryType == StatsSummaryTypeLikes ? [WPStyleGuide statsLighterOrange] : [UIColor whiteColor];
            break;
        }
            
        case 4: // Comments
        {
            iconLabel.text = @"";
            textLabel.text = NSLocalizedString(@"Comments", @"");
            valueLabel.text = summary.comments.stringValue;
//            cell.backgroundColor = self.selectedSummaryType == StatsSummaryTypeComments ? [WPStyleGuide statsLighterOrange] : [UIColor whiteColor];
            break;
        }
            
        default:
            break;
    }
}

- (void)configureSectionPostsCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    StatsGroup *group = (StatsGroup *)self.sectionData[@(StatsSectionPosts)];

    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Posts & Pages", @"Title for stats section for Posts & Pages")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Title", @"")
                                     andRightText:NSLocalizedString(@"Views", @"")];
    } else if (row > 1 && group.items.count > 0) {
        StatsItem *item = group.items[row - 2];
        [self configureTwoColumnRowCell:cell withLeftText:item.label andRightText:item.value.stringValue];
    }
    
}

- (void)configureSectionReferrersCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Referrers", @"Title for stats section for Referrers")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Referrer", @"")
                                     andRightText:NSLocalizedString(@"Views", @"")];
    }
    
}

- (void)configureSectionClicksCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Clicks", @"Title for stats section for Clicks")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Link", @"")
                                     andRightText:NSLocalizedString(@"Clicks", @"")];
    }
    
}

- (void)configureSectionCountryCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Countries", @"Title for stats section for Countries")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Country", @"")
                                     andRightText:NSLocalizedString(@"Views", @"")];
    }
    
}

- (void)configureSectionVideosCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Videos", @"Title for stats section for Videos")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Video", @"")
                                     andRightText:NSLocalizedString(@"Views", @"")];
    }
    
}

- (void)configureSectionCommentsCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Comments", @"Title for stats section for Comments")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Author", @"")
                                     andRightText:NSLocalizedString(@"Comments", @"")];
    }
    
}

- (void)configureSectionTagsCategoriesCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Tags & Categories", @"Title for stats section for Tags & Categories")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Topic", @"")
                                     andRightText:NSLocalizedString(@"Views", @"")];
    }
    
}

- (void)configureSectionFollowersCell:(UITableViewCell *)cell forRow:(NSInteger)row
{
    if (row == 0) {
        [self configureSectionGroupHeaderCell:cell withText:NSLocalizedString(@"Followers", @"Title for stats section for Followers")];
    } else if (row == 1) {
        [self configureSectionTwoColumnHeaderCell:cell
                                     withLeftText:NSLocalizedString(@"Follower", @"")
                                     andRightText:NSLocalizedString(@"Since", @"")];
    }
    
}

- (void)configureSectionGroupHeaderCell:(UITableViewCell *)cell withText:(NSString *)headerText
{
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:100];
    label.text = headerText;
}

- (void)configureSectionTwoColumnHeaderCell:(UITableViewCell *)cell withLeftText:(NSString *)leftText andRightText:(NSString *)rightText
{
    UILabel *label1 = (UILabel *)[cell.contentView viewWithTag:100];
    label1.text = leftText;
    
    UILabel *label2 = (UILabel *)[cell.contentView viewWithTag:200];
    label2.text = rightText;
}

- (void)configureTwoColumnRowCell:(UITableViewCell *)cell withLeftText:(NSString *)leftText andRightText:(NSString *)rightText
{
    UILabel *label1 = (UILabel *)[cell.contentView viewWithTag:100];
    label1.text = leftText;
    
    UILabel *label2 = (UILabel *)[cell.contentView viewWithTag:200];
    label2.text = rightText;
}

- (NSUInteger)numberOfRowsForStatsGroup:(StatsGroup *)group
{
    return group.expanded == NO ? 0 : [self numberOfRowsForStatsItems:group.items];
}

- (NSUInteger)numberOfRowsForStatsItems:(NSArray *)items
{
    if (items.count == 0) {
        return 0;
    }
    
    NSUInteger itemCount = items.count;
    
    for (StatsItem *item in items) {
        itemCount += [self numberOfRowsForStatsItems:item.children];
    }
    
    return itemCount;
}

@end
