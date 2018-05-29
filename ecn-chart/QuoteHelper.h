//
//  QuoteHelper.h
//  ecn-terminal
//
//  Created by Stas Buldakov on 31.01.18.
//  Copyright © 2018 Galament. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QuoteHelper : NSObject

+(int)precisionForFloat:(float)number;
+(int)lengthForFloat:(float)number;
+(NSString *)stringFromDecimalNumber:(NSDecimalNumber *)number;


+(NSDecimalNumber *)decimalNumberFromDouble:(double)num;

/**
 @brief This method returns symbol for currency
 
 @b Example: $ for USD, R for RUR
 
 @param currency Currency for which need to get symbol
 
 @return NSString symbol for currency
 */
+(NSString *)symbolForCurrency:(NSString *)currency;
@end
