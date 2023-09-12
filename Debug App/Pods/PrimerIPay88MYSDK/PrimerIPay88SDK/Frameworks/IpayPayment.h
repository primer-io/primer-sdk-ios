//
//  IpayPayment.h
//  ipay88sdk
//

#import <Foundation/Foundation.h>
@interface IpayPayment : NSObject {
    NSString *merchantCode;
    NSString *paymentId;
    NSString *refNo;
    NSString *amount;
    NSString *currency;
    NSString *prodDesc;
    NSString *userName;
    NSString *userEmail;
    NSString *remark;
    NSString *lang;
    NSString *country;
    NSString *backendPostURL;
    NSString *ActionType;
    NSString *TokenId;
    NSString *xfield1;
    NSString *xfield2;
    NSString *xfield3;
    NSString *xfield4;
    NSString *xfield5;
    NSString *promoCode;
    NSString *fixPaymentId;
    NSString *appdeeplink;
    
}

@property (nonatomic, retain) NSString *merchantCode;
@property (nonatomic, retain) NSString *paymentId;
@property (nonatomic, retain) NSString *refNo;
@property (nonatomic, retain) NSString *amount;
@property (nonatomic, retain) NSString *currency;
@property (nonatomic, retain) NSString *prodDesc;
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *userEmail;
@property (nonatomic, retain) NSString *remark;
@property (nonatomic, retain) NSString *lang;
@property (nonatomic, retain) NSString *country;
@property (nonatomic, retain) NSString *backendPostURL;
@property (nonatomic, retain) NSString *ActionType;
@property (nonatomic, retain) NSString *TokenId;
@property (nonatomic, retain) NSString *xfield1;
@property (nonatomic, retain) NSString *xfield2;
@property (nonatomic, retain) NSString *xfield3;
@property (nonatomic, retain) NSString *xfield4;
@property (nonatomic, retain) NSString *xfield5;
@property (nonatomic, retain) NSString *promoCode;
@property (nonatomic, retain) NSString *fixPaymentId;
@property (nonatomic, retain) NSString *appdeeplink;

@end
