//
//  GraphicParam.h
//  ecn-chart
//
//  Created by Stas Buldakov on 8/17/18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum GraphicParamType : NSInteger {
    GraphicParamTypeNumber = 0
} GraphicParamType;


NS_ASSUME_NONNULL_BEGIN

@interface GraphicParam : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *value;
@property (assign, nonatomic) GraphicParamType type;

@end

NS_ASSUME_NONNULL_END
