//
//  STPCustomer.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCustomer.h"
#import "StripeError.h"
#import "STPCard.h"

@interface STPCustomer()

@property(nonatomic, copy)NSString *stripeID;
@property(nonatomic) id<STPSource> defaultSource;
@property(nonatomic) NSArray<id<STPSource>> *sources;

@end

@implementation STPCustomer
@end

@interface STPCustomerDeserializer()

@property(nonatomic, nullable)STPCustomer *customer;
@property(nonatomic, nullable)NSError *error;

@end

@implementation STPCustomerDeserializer

- (instancetype)initWithData:(nullable NSData *)data
                 urlResponse:(nullable __unused NSURLResponse *)urlResponse
                       error:(nullable NSError *)error {
    self = [super init];
    if (self) {
        if (error) {
            _error = error;
            return self;
        }
        NSError *jsonError;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            _error = jsonError;
            return self;
        }
        if (![json isKindOfClass:[NSDictionary class]] || ![json[@"id"] isKindOfClass:[NSString class]]) {
            _error = [NSError stp_genericFailedToParseResponseError];
            return self;
        }
        STPCustomer *customer = [STPCustomer new];
        customer.stripeID = json[@"id"];
        NSString *defaultSourceId;
        if ([json[@"default_source"] isKindOfClass:[NSString class]]) {
            defaultSourceId = json[@"default_source"];
        }
        NSMutableArray *sources = [NSMutableArray array];
        if ([json[@"sources"] isKindOfClass:[NSDictionary class]] && [json[@"sources"][@"data"] isKindOfClass:[NSArray class]]) {
            for (id contents in json[@"sources"][@"data"]) {
                if ([contents isKindOfClass:[NSDictionary class]]) {
                    // TODO support other source types
                    STPCard *card = [STPCard decodedObjectFromAPIResponse:contents];
                    if (card) {
                        [sources addObject:card];
                        if (defaultSourceId && [card.stripeID isEqualToString:defaultSourceId]) {
                            customer.defaultSource = card;
                        }
                    }
                }
            }
        }
        customer.sources = sources;
        _customer = customer;
    }
    return self;
}

@end