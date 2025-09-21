//  SensorGyroMac
//
//  Created by Ramiro Nehuen Sanabria on 20/09/2025.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDDevice.h>
#import <IOKit/hid/IOHIDElement.h>
#import <IOKit/hid/IOHIDValue.h>

// Explicitly define the HID usage constants from the Swift file,
// which are based on the HID Usage Tables specification for sensors.
#define kHIDPage_Sensor                     0x20 // Usage Page for Sensors
#define kHIDUsage_Sens_Motion_Accelerometer3D 0x73 // Usage ID for a 3D Accelerometer sensor (corregido)
#define kHIDUsage_Sens_Data_Motion_AccelerationX 0x04 // Data Usage ID for X-axis acceleration
#define kHIDUsage_Sens_Data_Motion_AccelerationY 0x05 // Data Usage ID for Y-axis acceleration
#define kHIDUsage_Sens_Data_Motion_AccelerationZ 0x06 // Data Usage ID for Z-axis acceleration

// Forward declarations
@class GyroManager;

// Declare C functions required by IOKit callbacks.
// These will be implemented in the .m file.
void inputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value);
void deviceMatchingCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device);
void deviceRemovalCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device);

@interface GyroManager : NSObject

// Properties for accelerometer data, exposed as KVO-compliant.
@property (nonatomic, assign) double x;
@property (nonatomic, assign) double y;
@property (nonatomic, assign) double z;
@property (nonatomic, assign) BOOL sensorFound;

// IOKit related properties
@property (nonatomic, assign) IOHIDManagerRef hidManager;
@property (nonatomic, assign) IOHIDDeviceRef currentDevice;

// HID element cookies to identify X, Y, Z axes for input value callbacks
@property (nonatomic, assign) IOHIDElementCookie xAxisCookie;
@property (nonatomic, assign) IOHIDElementCookie yAxisCookie;
@property (nonatomic, assign) IOHIDElementCookie zAxisCookie;

// Methods to start and stop sensor monitoring
- (void)startSensorMonitoring;
- (void)stopSensorMonitoring;

// Internal methods called by C callbacks
- (void)deviceMatched:(IOHIDDeviceRef)device;
- (void)deviceRemoved:(IOHIDDeviceRef)device;

@end
