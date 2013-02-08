//
//  NKAppDelegate.h
//  NetworkKit
//
//  Created by Max Kramer on 08/02/2013.
//  Copyright (c) 2013 Max Kramer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NKViewController;

@interface NKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NKViewController *viewController;

@end
