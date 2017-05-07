//
//  HRMViewController.m
//  HeartMonitor
//
//  Created by Main Account on 12/13/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import "ViewController.h"


@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *jumperPeripheral;

// Properties for your Object controls
@property (nonatomic, strong) IBOutlet UITextView *deviceInfo;

// Properties to hold data characteristics for the peripheral device
@property (nonatomic, strong) NSString *connected;
@property (nonatomic, strong) NSString *bodyData;
@property (nonatomic, strong) NSString *manufacturer;
@property (nonatomic, strong) NSString *jumperDeviceData;
@property (assign) uint16_t heartRate;
@property (assign) uint16_t heartOxigen;

// Properties to handle storing the BPM and heart beat
@property (nonatomic, strong) UILabel *heartRateBPM;
@property (weak, nonatomic) IBOutlet UILabel *lblHeart;
@property (weak, nonatomic) IBOutlet UILabel *lblHeartOxigen;

@property (nonatomic, retain) NSTimer *pulseTimer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.jumperDeviceData = nil;
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    
    // Clear out textView
    [self.deviceInfo setText:@""];
    [self.deviceInfo setTextColor:[UIColor whiteColor]];
    [self.deviceInfo setBackgroundColor:[UIColor grayColor]];
    [self.deviceInfo setFont:[UIFont fontWithName:@"Futura-CondensedMedium" size:25]];
    [self.deviceInfo setUserInteractionEnabled:NO];
    
    // Scan for all available CoreBluetooth LE devices
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    //comentario
    //comentario 2
}

- (void)didChangeValueForKey:(NSString *)key{



}

#pragma mark - CBCentralManagerDelegate

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    self.connected = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    NSLog(@"%@", self.connected);
}

// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0) {
        NSLog(@"Found the heart rate monitor: %@", localName);
        [self.centralManager stopScan];
        self.jumperPeripheral = peripheral;
        peripheral.delegate = self;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        NSArray *servicios = @[[CBUUID UUIDWithString:JUMPER_DEVICE_INFO_SERVICE_UUID], [CBUUID UUIDWithString:JUMPER_HEART_RATE_SERVICE_UUID], [CBUUID UUIDWithString:JUMPER_BATTERY_SERVICE_CHARACTERISTIC_UUID]];
        [self.centralManager scanForPeripheralsWithServices:servicios options:nil];
        [self.centralManager setDelegate:self];
    }
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown) {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported) {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
        
    }
}

#pragma mark - CBPeripheralDelegate

// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:JUMPER_HEART_RATE_SERVICE_UUID]])  {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            // Request heart rate notifications
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:JUMPER_MEASUREMENT_CHARACTERISTIC_UUID]]) {
                [self.jumperPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found heart rate measurement characteristic");
            }
            // Request body sensor location
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:JUMPER_BODY_LOCATION_CHARACTERISTIC_UUID]]) { // 3
                [self.jumperPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found body sensor location characteristic");
            }
        }
    }
    // Retrieve Device Information Services for the Manufacturer Name
    if ([service.UUID isEqual:[CBUUID UUIDWithString:JUMPER_DEVICE_INFO_SERVICE_UUID]])  {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:JUMPER_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
                [self.jumperPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found a device manufacturer name characteristic");
            }
        }
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Updated value for heart rate measurement received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:JUMPER_MEASUREMENT_CHARACTERISTIC_UUID]]) {
        // Get the Heart Rate Monitor BPM
        [self getHeartBPMData:characteristic error:error];
    }
    
    // Retrieve the characteristic value for manufacturer name received
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:JUMPER_MANUFACTURER_NAME_CHARACTERISTIC_UUID]]) {
        [self getManufacturerName:characteristic];
    }
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:JUMPER_BATTERY_SERVICE_CHARACTERISTIC_UUID]]) {
        [self getManufacturerName:characteristic];
    }
    // Retrieve the characteristic value for the body sensor location received
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:JUMPER_BODY_LOCATION_CHARACTERISTIC_UUID]]) {
        [self getBodyLocation:characteristic];
    }
    
    // Add your constructed device information to your UITextView
    self.deviceInfo.text = [NSString stringWithFormat:@"%@\n%@\n%@\n", self.connected, self.bodyData, self.manufacturer];
}

#pragma mark - CBCharacteristic helpers

// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Get the Heart Rate Monitor BPM
    NSData *data = [characteristic value];
    
    const uint8_t *reportData = [data bytes];
    
    uint16_t bpm = 0;
    uint16_t oxigen = 0;
    
    if ((reportData[0]) == 0x81) {
        // Retrieve the BPM value for the Heart Rate Monitor
        bpm = reportData[1];
        oxigen = reportData[2];
        // Display the heart rate value to the UI if no error occurred
        if( (characteristic.value)  || !error) {
            self.heartRate = bpm;
            self.heartOxigen = oxigen;
            self.lblHeart.text = [NSString stringWithFormat:@"%i", bpm];
            self.lblHeartOxigen.text = [NSString stringWithFormat:@"%i", oxigen];
            self.lblHeartOxigen.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:70 ];
            if (bpm > 75) {
                self.lblHeart.textColor = [UIColor redColor];
            }
            else {
                self.lblHeart.textColor = [UIColor blackColor];
                
            }
            self.lblHeart.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:70 ];
            [self doHeartBeat];
            self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeat) userInfo:nil repeats:NO];
        }
        
    }
    
    if ([self.lblHeart.text  isEqual: @"255"] || [self.lblHeartOxigen.text  isEqual: @"127"]) {
        self.lblHeart.text = @"Dispositivo desconectado o fuera de cobertura";
        self.lblHeartOxigen.text = @"Dispositivo desconectado o fuera de cobertura";
    }
    
    return;
}

// Instance method to get the manufacturer name of the device

- (void) getManufacturerName:(CBCharacteristic *)characteristic
{
    NSString *manufacturerName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    self.manufacturer = [NSString stringWithFormat:@"Manufacturer: %@", manufacturerName];
    return;
}
// Instance method to get the body location of the device
- (void) getBodyLocation:(CBCharacteristic *)characteristic
{
    NSData *sensorData = [characteristic value];
    uint8_t *bodyData = (uint8_t *)[sensorData bytes];
    if (bodyData ) {
        uint8_t bodyLocation = bodyData[0];
        self.bodyData = [NSString stringWithFormat:@"Body Location: %@", bodyLocation == 1 ? @"Chest" : @"Undefined"];
    }
    else {
        self.bodyData = [NSString stringWithFormat:@"Body Location: N/A"];
    }
    return;
}
// Helper method to perform a heartbeat animation
- (void) doHeartBeat
{
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.toValue = [NSNumber numberWithFloat:1.1];
    pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    
    pulseAnimation.duration = 60 / self.heartRate / 2.;
    pulseAnimation.repeatCount = 1;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeat) userInfo:nil repeats:NO];
}

- (IBAction)btnExitAplication:(id)sender {
    exit(0);
}

@end
