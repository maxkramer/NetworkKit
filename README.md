NetworkKit - iOS Async Network Library with Stubbed Requests
======================================

NetworkKit is a super simple and easy to install class for creating asynchronous requests to various websites. 

##tl;dr
###Why should you be using NetworkKit?

- **Fast**. It directly uses CFNetwork without any interference from NSURLConnection.
- **Modern**. MKNetwokKit uses **block callbacks** for notifying the developer of successful and unsuccessful requests
- Internet Access Responsive. NetworkKit is automatically notified when there has 	been a **change in internet access** and stops any queued requests from sending 	until reconnection
	- **Developer Intuitive**. NetworkKit provides the user with a block callback for 	responding to the change in internet connection elsewhere in your application
- NetworkKit provides **response stubbing** useful for testing your applications on 	the go without the need for internet connection

##Requirements
- Apple LLVM compiler
- iOS 5.0 or higher
- ARC

If you are not using ARC in your project, add `-fobjc-arc` as a compiler flag for the file `NetworkKit.m`.


##Installation
###via CocoaPods

NetworkKit is on **cocoapods** - the easiest method whereby you can add NetworkKit to your application. All you need to do is edit your `Podfile`:

	$ nano Podfile
	platform :ios, '5.0'
	pod 'NetworkKit', '~> 1.0'
	
###Old Skool Approach

Drag and drop the NetworkKit directory into your Xcode Project, and then import the `CFNetwork` and `SystemConfiguration` frameworks.

##Usage

###Sending a request
    
    // Implement the requestSuccessBlock in order to be notified if the request was successful.
    [[NetworkKit sharedNetworkKit] setRequestSuccessBlock:^(NSData *responseData, NSURL *url) {
        
        NSLog(@"Request to [%@] succeeded with response: %@", url, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        
    }];
    
    // Implement the requestSuccessBlock in order to be notified if the request was not successful.
    
    [[NetworkKit sharedNetworkKit] setRequestErrorBlock:^(NSError *error, NSURL *url) {
        
        NSLog(@"Request to [%@] failed because %@", url, [error description]);
        
    }];
    
    /*
    * Send the actual request.
    * @param URL: the URL to send the request to [required]
    * @param parameters: the POST body in NSDictionary form [not required]
    * @param headers: an NSDictionary of HTTP headers to use [not required]
    * @param useStubbedResponse: whether or not you want to use the stubbed 	
    * response stored in the NetworkKitStubs.plist file
    */
        
    [[NetworkKit sharedNetworkKit] sendAsynchronousRequestToURL:[NSURL URLWithString:@"some_api"] withParameters:@{@"username": @"john", @"password" : @"password"} andHeaders:@{@"X-ALTERNATE-HEADER" : @"some info", @"other header" : @"other info"} useStubbedResponse:NO];
    
###Adding a Stubbed Response

Open the `NetworkKitStubs.plist` file, and add a row setting the `key` as the URL of the request, and the value as the expected response.


##Issues

If you come across any issues or feel like a chat, please open an issue here, on Github, or you can contact me using the following methods.

Twitter: [@_max_k](http://twitter.com/_max_k)

Website: [http://maxkramer.co](http://maxkramer.co)

Email: [hello@maxkramer.co](mailto:hello@maxkramer.co)

##License

This project complies with the [MIT license](https://github.com/MaxKramer/NetworkKit/blob/master/LICENSE).
 
