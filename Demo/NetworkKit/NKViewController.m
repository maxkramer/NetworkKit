//
//  NKViewController.m
//  NetworkKit
//
//  Created by Max Kramer on 08/02/2013.
//  Copyright (c) 2013 Max Kramer. All rights reserved.
//

#import "NKViewController.h"
#import "NetworkKit.h"

@interface NKViewController ()

@end

@implementation NKViewController

- (void)viewDidLoad

{
    
    /* 
     * See NetworkKit.h for information about each of the methods / properties used below. Alternatively, see the readme file provided along with this class.
     */
    
    NetworkKit *nk = [NetworkKit sharedNetworkKit];
    
    [nk setReachabilityChangedBlock:^(NKReachabilityStatus status, BOOL isConnected) {
        
        NSLog(@"New Status: %d Device is%@ connected to the internet.", status, (isConnected == YES ? @"" : @"n't"));
        
    }];
    
    [nk setRequestSuccessBlock:^(NSData *responseData, NSURL *url) {
        
        NSLog(@"Request to [%@] succeeded with response: %@", url, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        
    }];
    
    [nk setRequestErrorBlock:^(NSError *error, NSURL *url) {
        
        NSLog(@"Request to [%@] failed because %@", url, [error description]);
        
    }];
    
    [nk setUseStubbedResponseAsDefault:YES];
    
    [nk sendAsynchronousRequestToURL:[NSURL URLWithString:@"http://some.com/api"] withParameters:@{@"username": @"john", @"password" : @"password"} andHeaders:@{@"X-ALTERNATE-HEADER" : @"some info", @"other header" : @"other info"} useStubbedResponse:NO];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
