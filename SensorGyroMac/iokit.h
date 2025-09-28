//
//  iokit.h
//  SensorGyroMac
//
//  Created by Ramiro Nehuen Sanabria on 20/09/2025.
//
/*
#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import <IOKit/hid/IOHIDDevice.h>
#import <IOKit/hid/IOHIDElement.h>
#import <IOKit/hid/IOHIDValue.h>

// Constantes HID corregidas para sensores
#define kHIDPage_Sensor                          0x20  // Página de uso para sensores
#define kHIDUsage_Sens_Motion_Accelerometer3D    0x73  // ID de uso para acelerómetro 3D

// Constantes para datos de movimiento (basadas en el estándar HID)
#define kHIDUsage_Sens_Data_Motion_AccelerationAxisX  0x0453  // Aceleración eje X
#define kHIDUsage_Sens_Data_Motion_AccelerationAxisY  0x0454  // Aceleración eje Y
#define kHIDUsage_Sens_Data_Motion_AccelerationAxisZ  0x0455  // Aceleración eje Z

// Constantes alternativas más simples
#define kHIDUsage_Sens_Acceleration_X            0x53  // Aceleración X simplificada
#define kHIDUsage_Sens_Acceleration_Y            0x54  // Aceleración Y simplificada
#define kHIDUsage_Sens_Acceleration_Z            0x55  // Aceleración Z simplificada

// Forward declarations
@class GyroManager;

// Declare C functions required by IOKit callbacks.
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

*/
