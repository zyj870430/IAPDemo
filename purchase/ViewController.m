//
//  ViewController.m
//  purchase
//
//  Created by Hiteam on 16/5/24.
//  Copyright © 2016年 hiteam.com. All rights reserved.
//
////此Demo需要用申请下来的测试环境的AppID:346336011@qq.com  Li3695266
#import "ViewController.h"
#import <StoreKit/StoreKit.h>

@interface ViewController () <SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property (nonatomic, strong) UITextField *productID;
@property (nonatomic, strong) UIButton *purchase;
@end

#define SYSTEM_IS_IOS7 (floor(NSFoundationVersionNumber)>NSFoundationVersionNumber_iOS_6_1)

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addUI];
    //监听
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)addUI {
    
    _productID = [[UITextField alloc]initWithFrame:CGRectMake(50, 100, self.view.frame.size.width-100, 50)];
    _productID.placeholder = @"请输入产品id";
    _productID.text = @"com.hiteamtech.greateU02";
    [self.view addSubview:_productID];
    
    _purchase = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_purchase setTitle:@"购买" forState:UIControlStateNormal];
    _purchase.frame = CGRectMake(100, 200, 100, 50);
    _purchase.backgroundColor = [UIColor greenColor];
    [self.view addSubview:_purchase];
    [_purchase addTarget:self action:@selector(purchase:) forControlEvents:UIControlEventTouchUpInside];
    
}

// 购买的点击事件
- (void)purchase:(id)sender {

    NSString *procuct =  self.productID.text;
    if ([SKPaymentQueue canMakePayments]) {//允许付款
        [self requestProductData:procuct];
    }else{
        NSLog(@"不允许程序内付费");
    }
    
}

//请求商品
- (void)requestProductData:(NSString *)type {
    NSLog(@"----请求对应的产品信息----");
    NSArray *product = [[NSArray alloc]initWithObjects:type, nil];
    
    NSSet *nsset = [NSSet setWithArray:product];
    SKProductsRequest *request = [[SKProductsRequest alloc]initWithProductIdentifiers:nsset];
    request.delegate = self;
    [request start];
    
}

//收到产品返回信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    NSLog(@"----收到产品反馈消息----");
    NSArray *product = response.products;
    if ([product count] == 0) {
        NSLog(@"----没有商品----");
        return;
    }
    NSLog(@"产品ID-productID:%@",response.invalidProductIdentifiers);
    NSLog(@"产品付费数量:%ld",[product count]);
    
    SKProduct *p = nil;
    for (SKProduct *pro in product) {
        NSLog(@"SKProduct描述信息---:%@",[pro description]);
        NSLog(@"产品标题---:%@",[pro localizedTitle]);
        NSLog(@"产品描述信息---:%@",[pro localizedDescription]);
        NSLog(@"价格---:%@",[pro price]);
        NSLog(@"Product id---:%@",[pro productIdentifier]);
        
        if ([pro.productIdentifier isEqualToString:self.productID.text]) {
            p = pro;
        }
    }
    
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    NSLog(@"发送购买请求");
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"----错误----:%@",error);
}

- (void)requestDidFinish:(SKRequest *)request {
    NSLog(@"----反馈信息结束----");
}


//监听购买结果 (每次购买行为创建一个 SKPaymentTransaction， 这个transaction会记录用户购买行为的状态)
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
    /*
     SKPaymentTransactionStatePurchasing,    正在购买
     SKPaymentTransactionStatePurchased,     已经购买
     SKPaymentTransactionStateFailed,        购买失败
     SKPaymentTransactionStateRestored,      回复购买中
     SKPaymentTransactionStateDeferred       交易还在队列里面，但最终状态还没有决定
     */
    
    for (SKPaymentTransaction *tran in transactions) {
        
        switch (tran.transactionState) {
                //已经购买
            case SKPaymentTransactionStatePurchased:
                NSLog(@"交易完成");
                [self completeTransaction:tran];
                break;
                //正在购买
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                break;
                //已经购买过该商品
            case SKPaymentTransactionStateRestored:
                NSLog(@"已经购买过商品");
                [self restoreTransaction:tran];
                
                break;
                //购买失败
            case SKPaymentTransactionStateFailed:
                NSLog(@"交易失败");
                [self failedTransaction:tran];
                break;
                
            default:
                break;
        }
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
      NSLog(@"移除");
    
}

// 如果是等于SKPaymentTransactionStatePurchased，就调用另外一个函数：completeTransaction
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"成功支付");
    
    //NSString *productIdentifer =  transaction.payment.productIdentifier;
    NSString *transactionReceiptString = nil;
    
    //系统iOS7以上需要支付验证凭着的方式应该改变，且验证返回的数据结构也不一样了
    if (SYSTEM_IS_IOS7) {
        NSURLRequest *appstoreRequest = [NSURLRequest requestWithURL:[[NSBundle mainBundle] appStoreReceiptURL]];
        NSError *error = nil;
        NSData *receiptData = [NSURLConnection sendSynchronousRequest:appstoreRequest returningResponse:nil error:&error]
        ;
        transactionReceiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    }else{
        NSData * receiptData = transaction.transactionReceipt;
        transactionReceiptString = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];

        //或者
//        NSString* jsonObjectString = [self encode:(uint8_t *)transaction.transactionReceipt.bytes
//                                           length:transaction.transactionReceipt.length];
//        NSString* varStr = [[NSString alloc] initWithFormat:
//                            @"your_url?receipt=%@",
//                            jsonObjectString];
    }
    //NSLog(@"需要给服务器的receipt:%@",transactionReceiptString);
    // transactionReceiptString
    // 将receipt发送到我的服务器 (post) 向自己的服务器验证购买凭证
    //Remove the transaction from the payment queue
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];

}

//重复支付
-(void)restoreTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"重复支付");
    [self completeTransaction:transaction];
}

//失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"失败支付");
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

// encode 操作， 这段操作是对transactionReceipt做了一次base64的编码
- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length {
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t *)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
