//
//  ViewController.m
//  PeripheralDemo
//
//  Created by Mac on 2018/2/11.
//  Copyright © 2018年 BeiJingXiaoMenTong. All rights reserved.
//

#import "ViewController.h"
#import "Masonry.h"
#import "UIView+Toast.h"





#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;
#define THEME_COLOR   [UIColor colorWithRed:25.0f/255.0 green:94.0f/255.0 blue:196.0f/255.0 alpha:0.9f]
#define SCREEN_WIDTH  [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT  [[UIScreen mainScreen] bounds].size.height
#define PIX (SCREEN_WIDTH/375.0f)

#define WTOAST(msg) UIWindow *window= [UIApplication sharedApplication].keyWindow; [window hideToasts];  [window makeToast:msg duration:1.5 position:CSToastPositionBottom];
#define CWTOAST(msg) UIWindow *window= [UIApplication sharedApplication].keyWindow; [window hideToasts];  [window makeToast:msg duration:3.0 position:CSToastPositionCenter];



static NSString *const ServiceUUID = @"FFE0";
static NSString *const ServiceUUID2 = @"FFF0";
static NSString *const notiyCharacteristicUUID = @"FFE1";
static NSString *const readwriteCharacteristicUUID = @"FFE2";
static NSString *const readCharacteristicUUID = @"FFE3";
static NSString *const LocalNameKey = @"XMT_APP";

@interface ViewController ()<CBPeripheralManagerDelegate>

@property (nonatomic, strong) NSArray * perArray;
@property (nonatomic, assign) NSInteger   serviceNum;
@property (nonatomic, strong) CBMutableCharacteristic* notiyCharacteristic;
@property (nonatomic, strong) CBCharacteristic * writeCharacteristic;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"外设模式";
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _perManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
    
    [self addPeripheralUI];
    
    [self setPeripheralServiceAndCharacteristic];
    
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)addPeripheralUI{
    WS(weakSelf)
    CGFloat width = (SCREEN_WIDTH-80)/2.0f;
    
    _textField = [[UITextField alloc]init];
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    _textField.placeholder = @"随便填";
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:_textField];
    [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.view);
        make.centerY.equalTo(weakSelf.view).offset(-50);
        make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH-60, 38));
    }];
    
    for (NSInteger i = 0; i<self.perArray.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:self.perArray[i] forState:UIControlStateNormal];
        [button setBackgroundColor:THEME_COLOR];
        button.tag = 10+i;
        button.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        button.layer.cornerRadius = 8.0f;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakSelf.view).offset(500+i/2*80);
            make.left.equalTo(weakSelf.view).offset(25+i%2*(width+30));
            make.size.mas_equalTo(CGSizeMake(width, 50));
        }];
    }
}

-(void)btnClick:(UIButton *)button{
    if (button.tag==10) {
        [self setPeripheralServiceAndCharacteristic];
    }else if (button.tag==11){
        [self.perManager stopAdvertising];
        CWTOAST(@"stopAdvertising");
    }
    
}

-(void)setPeripheralServiceAndCharacteristic{
    _serviceNum = 0;
    [_perManager removeAllServices];//防止多次重复添加
    /*
     可以通知的Characteristic
     properties：CBCharacteristicPropertyNotify
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *notiyCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    // 可读写的characteristics
    
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readwriteCharacteristicUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    //设置description
    //characteristics字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    CBMutableDescriptor *readwriteCharacteristicDescription1 = [[CBMutableDescriptor alloc]initWithType: CBUUIDCharacteristicUserDescriptionStringUUID value:@"name"];
    [readwriteCharacteristic setDescriptors:@[readwriteCharacteristicDescription1]];
    
    /*
     只读的Characteristic
     properties：CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID] primary:YES];
    [service1 setCharacteristics:@[notiyCharacteristic,readwriteCharacteristic]];
    
    CBMutableService *service2 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID2] primary:YES];
    [service2 setCharacteristics:@[readCharacteristic]];
    [self.perManager addService:service1];
    [self.perManager addService:service2];
}



#pragma mark PeripheralManager Delegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"PoweredOn");
            break;
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"PoweredOff");
            break;
        case CBPeripheralManagerStateUnknown :
            NSLog(@"StateUnknown");
            break;
        case CBPeripheralManagerStateResetting:
           NSLog(@"StateResetting");
            break;
        case CBPeripheralManagerStateUnsupported:
            NSLog(@"Unsupported");
            break;
        case CBPeripheralManagerStateUnauthorized:
            NSLog(@"StateUnauthorized");
            break;
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (!error) {
        _serviceNum++;
    }
    if (_serviceNum ==2) {
       CWTOAST(@"StartAdvertising");
        [_perManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:ServiceUUID]], CBAdvertisementDataLocalNameKey : LocalNameKey}];
    }
}
//订阅characteristics
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"订阅了 %@的数据",characteristic.UUID);
    self.notiyCharacteristic = (CBMutableCharacteristic *)characteristic;
}
//取消订阅characteristics
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"取消订阅 %@的数据",characteristic.UUID);
    //取消回应
}
//写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *request = requests[0];
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        NSString *string = [[NSString alloc]initWithData:c.value encoding:NSUTF8StringEncoding];
        CWTOAST(string);
        NSString *notiyString = [self getTimeString];
        [self notiyCharacteristicString:notiyString];
        [_perManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_perManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

//读characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"didReceiveReadRequest");
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [_perManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_perManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}

-(void)notiyCharacteristicString:(NSString *)string{
    string = self.textField.text.length>0?self.textField.text:string;
    for (int i= 0; i<(string.length-1)/20 +1; i++) {
        if (i==(string.length-1)/20) {
            NSString *dataString =[string substringWithRange:NSMakeRange(i*20, string.length-i*20)];
            NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            [self.perManager updateValue:data forCharacteristic:self.notiyCharacteristic onSubscribedCentrals:nil];
        }else{
            NSString *dataString = [string substringWithRange:NSMakeRange(i*20, 20)];
            NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            [self.perManager updateValue:data forCharacteristic:self.notiyCharacteristic onSubscribedCentrals:nil];
        }
    }
    
}

-(NSString *)getTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    //现在时间,你可以输出来看下是什么格式
    NSDate *datenow = [NSDate date];
    return[formatter stringFromDate:datenow];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}


#pragma mark GET
-(NSArray *)perArray{
    if (!_perArray) {
        _perArray = @[@"开启广播",@"停止广播"];
    }
    return _perArray;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
