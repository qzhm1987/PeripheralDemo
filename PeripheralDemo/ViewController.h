//
//  ViewController.h
//  PeripheralDemo
//
//  Created by Mac on 2018/2/11.
//  Copyright © 2018年 BeiJingXiaoMenTong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) CBPeripheralManager * perManager;
@property (nonatomic, strong) UITextField * textField;
@end

