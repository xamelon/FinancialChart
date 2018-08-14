//
//  BaseIndicator.m
//  ecn-chart
//
//  Created by Stas Buldakov on 8/14/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import "BaseIndicator.h"
#import <UIKit/UIKit.h>

@implementation BaseIndicator

-(id)init {
    self = [super init];
    if(self) {
        self.backgroundColor = [UIColor clearColor].CGColor;
        self.contentsScale = [UIScreen mainScreen].scale;
        self.shouldRasterize = NO;
        self.rasterizationScale = [UIScreen mainScreen].scale;
    }
    
    return self;
}

-(id<CAAction>)actionForKey:(nonnull NSString *)aKey
{
    return nil;
}

@end
