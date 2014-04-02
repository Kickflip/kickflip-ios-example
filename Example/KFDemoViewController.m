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

@interface KFDemoViewController ()
@property (nonatomic, strong, readwrite) UIButton *broadcastButton;
@end

@implementation KFDemoViewController

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

- (void) setupNavigationBarAppearance {
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupNavigationBarAppearance];

    self.title = @"Kickflip";
    
    UIBarButtonItem *broadcastBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"broadcast.png"] style:UIBarButtonItemStylePlain target:self action:@selector(broadcastButtonPressed:)];
    self.navigationItem.rightBarButtonItem = broadcastBarButton;
    
    UIBarButtonItem *testButton = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(testButtonPressed:)];
    self.navigationItem.leftBarButtonItem = testButton;
}

- (void) testButtonPressed:(id)sender {
    KFUser *activeUser = [KFUser activeUser];
    [[KFAPIClient sharedClient] requestStreamsForUsername:activeUser.username user:activeUser callbackBlock:^(NSArray *streams, NSError *error) {
        if (error) {
            DDLogError(@"Error fetching user streams: %@", error);
            return;
        }
        DDLogInfo(@"Fetched streams: %@", streams);
    }];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
