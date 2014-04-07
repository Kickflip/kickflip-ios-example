//
//  KFDemoViewController.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/28/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFDemoViewController.h"
#import "Kickflip.h"
#import "KFAPIClient.h"
#import "KFLog.h"
#import "KFUser.h"
#import "YapDatabase.h"
#import "YapDatabaseView.h"
#import "UIView+AutoLayout.h"
#import "TTTTimeIntervalFormatter.h"
#import "KFDateUtils.h"
#import "KFStreamTableViewCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIActionSheet+Blocks.h"

static NSString * const kKFStreamView = @"kKFStreamView";
static NSString * const kKFStreamsGroup = @"kKFStreamsGroup";
static NSString * const kKFStreamsCollection = @"kKFStreamsCollection";

@interface KFDemoViewController ()
@property (nonatomic, strong, readwrite) UIButton *broadcastButton;
@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@end

@implementation KFDemoViewController

- (void) dealloc {
    self.pullToRefreshView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) broadcastButtonPressed:(id)sender {
    [Kickflip presentBroadcasterFromViewController:self ready:^(NSURL *streamURL) {
        if (streamURL) {
            DDLogInfo(@"Stream is ready at URL: %@", streamURL);
        }
    } completion:^(BOOL success, NSError* error){
        if (!success) {
            DDLogError(@"Error setting up stream: %@", error);
        } else {
            DDLogInfo(@"Done broadcasting");
        }
    }];
}


- (TTTTimeIntervalFormatter*) timeIntervalFormatter {
    static TTTTimeIntervalFormatter *timeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
    });
    return timeFormatter;
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void) setupDatabase {
    NSString *docs = [self applicationDocumentsDirectory];
    NSString *dbPath = [docs stringByAppendingPathComponent:@"kickflip.sqlite"];
    self.database = [[YapDatabase alloc] initWithPath:dbPath];
    self.uiConnection = [self.database newConnection];
    self.bgConnection = [self.database newConnection];
    [self setupDatabaseView];
}

- (void) setupDatabaseView {
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        if ([object isKindOfClass:[KFStream class]])
            return kKFStreamsGroup;
        return nil; // exclude from view
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
        if ([group isEqualToString:kKFStreamsGroup]) {
            KFStream *stream1 = obj1;
            KFStream *stream2 = obj2;
            return [stream2.startDate compare:stream1.startDate];
        }
        return NSOrderedSame;
    };
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType];
    [self.database registerExtension:databaseView withName:kKFStreamView];
    

}


- (void) setupNavigationBarAppearance {
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) setupTableView {
    self.streamsTableView = [[UITableView alloc] init];
    self.streamsTableView.dataSource = self;
    self.streamsTableView.delegate = self;
    [self.streamsTableView registerClass:[KFStreamTableViewCell class] forCellReuseIdentifier:[KFStreamTableViewCell cellIdentifier]];
    [self.view addSubview:self.streamsTableView];
    self.streamsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *constraint = [self.streamsTableView autoPinToTopLayoutGuideOfViewController:self withInset:0.0f];
    [self.view addConstraint:constraint];
    NSArray *constraints = [self.streamsTableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.view addConstraints:constraints];
}

- (void) setupPullToRefresh {
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.streamsTableView delegate:self];
    self.pullToRefreshView.contentView = [[SSPullToRefreshSimpleContentView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupDatabase];

    [self setupNavigationBarAppearance];

    self.title = @"Kickflip";
    
    UIBarButtonItem *broadcastBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"broadcast.png"] style:UIBarButtonItemStylePlain target:self action:@selector(broadcastButtonPressed:)];
    self.navigationItem.rightBarButtonItem = broadcastBarButton;
    
    [self setupViewMappings];
    
    [self setupTableView];
    [self setupPullToRefresh];
}

- (void) setupViewMappings {
    [self.uiConnection beginLongLivedReadTransaction];

    NSArray *groups = @[ kKFStreamsGroup ];
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:groups view:kKFStreamView];
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        // One-time initialization
        [self.mappings updateWithTransaction:transaction];
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.database];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshStreams];
}

- (void) refreshStreams {
    [self.pullToRefreshView startLoading];
    [[KFAPIClient sharedClient] requestAllStreams:^(NSArray *streams, NSError *error) {
        if (error) {
            DDLogError(@"Error fetching all streams: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pullToRefreshView finishLoading];
            });
            return;
        }
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            for (KFStream *stream in streams) {
                KFStream *newStream = [[transaction objectForKey:stream.streamID inCollection:kKFStreamsCollection] copy];
                if (!newStream) {
                    newStream = stream;
                } else {
                    [newStream mergeValuesForKeysFromModel:stream];
                }
                [transaction setObject:newStream forKey:stream.streamID inCollection:kKFStreamsCollection];
            }
        } completionBlock:^{
            [self.pullToRefreshView finishLoading];
        } completionQueue:dispatch_get_main_queue()];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.mappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.mappings numberOfItemsInSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [KFStreamTableViewCell defaultHeight];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [KFStreamTableViewCell defaultHeight];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KFStream *stream = nil;
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        stream = [[transaction extension:kKFStreamView] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    
    KFStreamTableViewCell *cell = [sender dequeueReusableCellWithIdentifier:[KFStreamTableViewCell cellIdentifier]];
    [cell setStream:stream];
    [cell setActionBlock:^{
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"Cancel"];
        RIButtonItem *shareItem = [RIButtonItem itemWithLabel:@"Share" action:^{
            NSLog(@"Share it");
        }];
        RIButtonItem *flagItem = [RIButtonItem itemWithLabel:@"Flag" action:^{
            NSLog(@"Flag it");
        }];
        RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"Delete" action:^{
            NSLog(@"Delete it");
        }];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:flagItem otherButtonItems:shareItem, nil];
        [actionSheet showInView:self.view];
    }];
    return cell;
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    
    NSArray *notifications = [self.uiConnection beginLongLivedReadTransaction];
    
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.uiConnection ext:kKFStreamView] getSectionChanges:&sectionChanges
                                                  rowChanges:&rowChanges
                                            forNotifications:notifications
                                                withMappings:self.mappings];
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
    [self.streamsTableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.streamsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.streamsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            default:
                break;
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.streamsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.streamsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.streamsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.streamsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.streamsTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.streamsTableView endUpdates];
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    __block KFStream *stream = nil;
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        stream = [[transaction extension:kKFStreamView] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MPMoviePlayerViewController *movieView = [[MPMoviePlayerViewController alloc] initWithContentURL:stream.streamURL];
    [self presentViewController:movieView animated:YES completion:nil];
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view {
    [self refreshStreams];
}


@end
