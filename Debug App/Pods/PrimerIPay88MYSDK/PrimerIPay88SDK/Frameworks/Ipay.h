//
//  Ipay.h
//  ipay88sdk
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IpayPayment.h"
#import <WebKit/WebKit.h>

@protocol PaymentResultDelegate <NSObject>

- (void)paymentSuccess:(NSString *)refNo withTransId:(NSString *)transId withAmount:(NSString *)amount withRemark:(NSString *)remark withAuthCode:(NSString *)authCode withTokenId:(NSString *)tokenId withCCName:(NSString *)ccName withCCNo:(NSString *)ccNo withS_bankname:(NSString *)s_bankname withS_country:(NSString *)s_country;

- (void)paymentFailed:(NSString *)refNo withTransId:(NSString *)transId withAmount:(NSString *)amount withRemark:(NSString *)remark  withTokenId:(NSString *)tokenId withCCName:(NSString *)ccName withCCNo:(NSString *)ccNo withS_bankname:(NSString *)s_bankname withS_country:(NSString *)s_country withErrDesc:(NSString *)errDesc;

- (void)paymentCancelled:(NSString *)refNo withTransId:(NSString *)transId withAmount:(NSString *)amount withRemark:(NSString *)remark  withTokenId:(NSString *)tokenId withCCName:(NSString *)ccName withCCNo:(NSString *)ccNo withS_bankname:(NSString *)s_bankname withS_country:(NSString *)s_country withErrDesc:(NSString *)errDesc;

- (void)requerySuccess:(NSString *)refNo withMerchantCode:(NSString *)merchantCode withAmount:(NSString *)amount withResult:(NSString *)result;

- (void)requeryFailed:(NSString *)refNo withMerchantCode:(NSString *)merchantCode withAmount:(NSString *)amount withErrDesc:(NSString *)errDesc;
@end

@interface Ipay : UIViewController <NSURLConnectionDelegate, UIScrollViewDelegate,WKNavigationDelegate,WKUIDelegate> {
    __weak id <PaymentResultDelegate> delegate;
}
@property (nonatomic,weak) id <PaymentResultDelegate> delegate;

- (UIView *)checkout:(IpayPayment *)payment;

- (void)requery:(IpayPayment *)payment;

- (void)handleLinkFromCustomSchemeURL:(NSURL*)url;

+ (id)sharedManager;

@end
