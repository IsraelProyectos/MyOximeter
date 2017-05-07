//
//  HRMViewController.h
//  HeartMonitor
//
//  Created by Main Account on 12/13/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreBluetooth;
@import QuartzCore;

#define JUMPER_DEVICE_INFO_SERVICE_UUID @"180A"
#define JUMPER_HEART_RATE_SERVICE_UUID @"CDEACB80-5235-4C07-8846-93A37EE6B86D"
#define JUMPER_MEASUREMENT_CHARACTERISTIC_UUID @"CDEACB81-5235-4C07-8846-93A37EE6B86D"
#define JUMPER_BODY_LOCATION_CHARACTERISTIC_UUID @"2A38"
#define JUMPER_MANUFACTURER_NAME_CHARACTERISTIC_UUID @"2A29"
#define JUMPER_BATTERY_SERVICE_CHARACTERISTIC_UUID @"2A19"

@interface ViewController : UIViewController

// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error;

// Instance methods to grab device Manufacturer Name, Body Location
- (void) getManufacturerName:(CBCharacteristic *)characteristic;
- (void) getBodyLocation:(CBCharacteristic *)characteristic;

// Instance method to perform heart beat animations
- (void) doHeartBeat;
@end

