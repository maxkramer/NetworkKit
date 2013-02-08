//
//  NetworkKit.h
//  NetworkKit
//
//  Created by Max Kramer on 08/02/2013.
//  Copyright (c) 2013 Max Kramer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Reachability;

typedef enum {
    
    NKReachabilityStatusNotReachable = 0,
    NKReachabilityStatusViaWiFi = 1,
    NKReachabilityStatusViaMobileNetwork = 2
    
} NKReachabilityStatus;

typedef void(^NKRequestSuccessBlock)(NSData *receivedData, NSURL *requestedURL);
typedef void(^NKRequestErrorBlock)(NSError *error, NSURL *requestedURL);
typedef void(^NKChangedNetworkStatusBlock)(NKReachabilityStatus reachStatus, BOOL isConnectedToInternet);

/*
 * +sharedNetworkKit provides the NetworKit Singleton allowing you to use the class without having to use a property or iVar
 * -setReachabilityChangedBlock will be called when there is a change in internet access i.e. WiFi to Mobile Data or the reverse, or WiFi/Mobile Data to No Internet
 * -setRequestSuccessBlock will be called when a request succeeds and returns a response from the remote server
 * -setRequestErrorBlock will be called when a request does not succeed and fails returning an error from your application - a CFNetwork Error
 * -setUseStubbedResponseAsDefault - set this to use a stubbed response when you do not specify whether or not you would like to use a stubbed response or not via the @param useStub
 * -sendAsynchronousRequestToURL:
 * @param URL - the request URI to receive the response from
 * @param parameters - the POST parameters to send to the server
 * @param headers - user specified HTML headers that will be added to the headers already used by NetworkKit
 */

@interface NetworkKit : NSObject

+ (NetworkKit *) sharedNetworkKit;

- (void) sendAsynchronousRequestToURL:(NSURL *) url;
- (void) sendAsynchronousRequestToURL:(NSURL *) url withParameters:(NSDictionary *) parameters useStubbedResponse:(BOOL) useStub;
- (void) sendAsynchronousRequestToURL:(NSURL *) url withParameters:(NSDictionary *) parameters andHeaders:(NSDictionary *) headers useStubbedResponse:(BOOL) useStub;

@property (nonatomic, readwrite, assign) BOOL useStubbedResponseAsDefault;

@property (nonatomic, readwrite, copy) NKRequestSuccessBlock requestSuccessBlock;
@property (nonatomic, readwrite, copy) NKRequestErrorBlock requestErrorBlock;

@property (nonatomic, readwrite, copy) NKChangedNetworkStatusBlock reachabilityChangedBlock;

@end
