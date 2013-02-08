//
//  NetworkKit.m
//  NetworkKit
//
//  Created by Max Kramer on 08/02/2013.
//  Copyright (c) 2013 Max Kramer. All rights reserved.
//

#import "NetworkKit.h"
#import "Reachability.h"

#import <CommonCrypto/CommonDigest.h>
#import <CFNetwork/CFNetwork.h>

static double NETWORK_KIT_VERSION = 1.0;

@interface NetworkKit ()

@property (nonatomic, retain) NSOperationQueue *_networkQueue, *_notificationQueue;
@property (nonatomic, retain) Reachability *_currReachability;

@end

@implementation NetworkKit
/* @private property synthesizing */
@synthesize _networkQueue, _currReachability;
/* @public property synthesizing */
@synthesize requestErrorBlock, requestSuccessBlock, reachabilityChangedBlock, useStubbedResponseAsDefault;

- (id) init {
   
    if ((self = [super init])) {
        
        [self set_notificationQueue:[[NSOperationQueue alloc] init]];
        [self._notificationQueue setMaxConcurrentOperationCount:10];
        [self._notificationQueue setSuspended:NO];
        
        [self set_networkQueue:[[NSOperationQueue alloc] init]];
        [self._networkQueue setMaxConcurrentOperationCount:1];
        
        self._currReachability = [Reachability reachabilityForInternetConnection];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:self._currReachability queue:self._notificationQueue usingBlock:^(NSNotification *note) {
            
            [self._networkQueue setSuspended:(self._currReachability.currentReachabilityStatus == NotReachable)];
            
            if (self.reachabilityChangedBlock) {
                
                self.reachabilityChangedBlock(self._currReachability.currentReachabilityStatus == NotReachable ? NKReachabilityStatusNotReachable : self._currReachability.currentReachabilityStatus == ReachableViaWiFi ? NKReachabilityStatusViaWiFi : NKReachabilityStatusViaMobileNetwork, self._currReachability.currentReachabilityStatus != NotReachable);
                
            }
            
        }];
        
        [self._currReachability startNotifier];
        
        if (self._currReachability) {
            [self._networkQueue setSuspended:(self._currReachability.currentReachabilityStatus == NotReachable)];
        }
        else {
            [self._networkQueue setSuspended:YES];
        }
        
        [self setUseStubbedResponseAsDefault:NO];
        
    }
    
    return self;
    
}

+ (NetworkKit *) sharedNetworkKit {
    static dispatch_once_t onceToken;
    static NetworkKit *_sharedInstance;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void) sendAsynchronousRequestToURL:(NSURL *) url {
    [self sendAsynchronousRequestToURL:url withParameters:nil andHeaders:nil useStubbedResponse:self.useStubbedResponseAsDefault];
}

- (void) sendAsynchronousRequestToURL:(NSURL *) url withParameters:(NSDictionary *) parameters useStubbedResponse:(BOOL)useStub {
    [self sendAsynchronousRequestToURL:url withParameters:parameters andHeaders:nil useStubbedResponse:useStub];
}

- (void) sendAsynchronousRequestToURL:(NSURL *) url withParameters:(NSDictionary *) parameters andHeaders:(NSDictionary *) headers useStubbedResponse:(BOOL)useStub {
    
    NSParameterAssert(url);
    
    if (useStub == YES) {
                
        BOOL containsStub = [self _containsStubForURL:url];
        
        NSAssert1(containsStub, @"Your NetworkKitStubs.plist file does not contain a value for the key (url): %@", [url absoluteString]);
        
        if (containsStub == NO) return;
        
        if (self.requestSuccessBlock) {
            self.requestSuccessBlock([self _stubForURL:url], url);
        }
        
        return;
                
    }
        
    [self._networkQueue addOperationWithBlock:^{
       
        [self _performRequest:[self _buildRequestWithURL:url parameters:parameters andHeaders:headers] withCompletion:^(NSData *__strong responseData, NSError *__strong error) {
                        
            if (self.requestErrorBlock && error) {
                
                self.requestErrorBlock(error, url);
            }
            
            else if (self.requestSuccessBlock && responseData) {
                
                self.requestSuccessBlock(responseData, url);
                
            }
            
        }];
        
    }];
    
}

- (BOOL) _containsStubForURL:(NSURL *) url {
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"NetworkKitStubs" ofType:@"plist"];
    
    if (plistPath == nil)
        return NO;
    
    NSDictionary *stubs = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:plistPath] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
    return [[stubs allKeys] containsObject:[url absoluteString]];
    
}

- (NSData *) _stubForURL:(NSURL *) url {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"NetworkKitStubs" ofType:@"plist"];
    NSDictionary *stubs = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:plistPath] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
    NSString *stub = [stubs objectForKey:[url absoluteString]];
    return [stub dataUsingEncoding:NSUTF8StringEncoding];
}

- (CFHTTPMessageRef) _buildRequestWithURL:(NSURL *) url parameters:(NSDictionary *) parameters andHeaders:(NSDictionary *) headers {
        
    NSMutableString *body = nil;
    
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (parameters == nil || (parameters != nil && parameters.count == 0)) ? CFSTR("GET") : CFSTR("POST"), (__bridge CFURLRef) url, kCFHTTPVersion1_1);
    
    if (parameters != nil) {
        
        body = [NSMutableString string];
        
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            NSUInteger idx = [[parameters allKeys] indexOfObject:key];
            [body appendFormat:@"%@%@=%@", (idx == 0) ? @"" : @"&", key, obj];
            
        }];
        
        NSData *postData = [body dataUsingEncoding:NSUTF8StringEncoding];
        
        CFHTTPMessageSetBody(request, (__bridge CFDataRef) postData);
        CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Content-Length"), (__bridge CFStringRef) [NSString stringWithFormat:@"%d", [postData length]]);
        CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Content-MD5"), (__bridge CFStringRef) [self _MD5Encrypt:body]);
        CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Content-Type"), CFSTR("application/x-www-form-urlencoded"));
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss z"];
    
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("HOST"), CFURLCopyHostName((__bridge CFURLRef) url));
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Accept-Charset"), CFSTR("utf-8"));
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Date"), (__bridge CFStringRef) [dateFormatter stringFromDate:[NSDate date]]);
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("X-Requested-With"), CFSTR("com.maxkramerco.NetworkKit"));
    
    if (headers != nil && [[headers allKeys] count] > 0) {
        
        [headers enumerateKeysAndObjectsUsingBlock:^(id key, NSString *value, BOOL *stop) {
           
            CFHTTPMessageSetHeaderFieldValue(request, (__bridge CFStringRef)key, (__bridge CFStringRef)value);
            
        }];
        
    }
    
    NSDictionary *setHeaders = (__bridge NSDictionary *)CFHTTPMessageCopyAllHeaderFields(request);
    
    if (![[setHeaders allKeys] containsObject:@"User-Agent"]) {
        
        CFHTTPMessageSetHeaderFieldValue(request, CFSTR("User-Agent"), (__bridge CFStringRef) [NSString stringWithFormat:@"NetworkKit/iOS/%.2f", NETWORK_KIT_VERSION]);
        
    }
        
    CFRelease((__bridge CFTypeRef)(setHeaders));
        
    return request;

}

- (void) _performRequest:(CFHTTPMessageRef) request withCompletion:(void (^) (NSData *responseData, NSError *responseError)) _completion {

    CFReadStreamRef requestStream = CFReadStreamCreateForHTTPRequest(NULL, request);
    CFReadStreamOpen(requestStream);
        
    CFMutableDataRef responseData = CFDataCreateMutable(NULL, 0);
    
    CFIndex bytesRead = 1;
    int idx = 1;
    
    CFErrorRef error = nil;
    
    while (bytesRead > 0) {
                
        if (idx == 1) {
            bytesRead = 0;
            --idx;
        }
        
        UInt8 buf[1024];
        bytesRead = CFReadStreamRead(requestStream, buf, sizeof(buf));
        
        if(bytesRead > 0) {
            
            CFDataAppendBytes(responseData, buf, bytesRead);
            
        }
        
        if (CFReadStreamGetStatus(requestStream) == kCFStreamStatusError) {
            error = CFReadStreamCopyError(requestStream);
            bytesRead = 0;
            break;
        }
        
    }
    
    CFReadStreamClose(requestStream);
    CFRelease(requestStream);
    
    if (error) {
        
        _completion(nil, (__bridge_transfer NSError *) error);
        return;
    }
    
    _completion((__bridge_transfer NSData *__autoreleasing) responseData, nil);
    
}

- (NSString *) _MD5Encrypt:(NSString *)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        
        [ret appendFormat:@"%02x",result[i]];
        
    }
    
    return ret;
}


@end
