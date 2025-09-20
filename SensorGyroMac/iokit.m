//
//  iokit.m
//  SensorGyroMac
//
//  Created by Ramiro Nehuen Sanabria on 20/09/2025.
//

#import "iokit.h"

// Callbacks de C que se comunican con los métodos de la instancia de Objective-C
void inputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
    GyroManager *manager = (__bridge GyroManager *)context;
    
    // El 'sender' para un callback registrado a un dispositivo es el IOHIDDeviceRef.
    if (sender != manager.currentDevice) {
        return;
    }
    
    IOHIDElementRef element = IOHIDValueGetElement(value);
    IOHIDElementCookie cookie = IOHIDElementGetCookie(element);
    
    // Usamos el valor físico escalado para los datos del acelerómetro.
    double valued = IOHIDValueGetScaledValue(value, kIOHIDValueScaleTypePhysical);
    
    if (cookie == manager.xAxisCookie) {
        manager.x = valued;
    } else if (cookie == manager.yAxisCookie) {
        manager.y = valued;
    } else if (cookie == manager.zAxisCookie) {
        manager.z = valued;
    }
}

void deviceMatchingCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    GyroManager *manager = (__bridge GyroManager *)context;
    [manager deviceMatched:device];
}

void deviceRemovalCallback(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    GyroManager *manager = (__bridge GyroManager *)context;
    [manager deviceRemoved:device];
}

@implementation GyroManager

- (instancetype)init {
    self = [super init];
    if (self) {
        // Inicializar propiedades
        _x = 0.0;
        _y = 0.0;
        _z = 0.0;
        _sensorFound = NO;
        _hidManager = NULL;
        _currentDevice = NULL;
        _xAxisCookie = 0;
        _yAxisCookie = 0;
        _zAxisCookie = 0;
    }
    return self;
}

- (void)dealloc {
    [self stopSensorMonitoring];
}

- (void)startSensorMonitoring {
    if (self.hidManager) {
        return; // Ya está en ejecución
    }

    self.hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (!self.hidManager) {
        NSLog(@"Error al crear IOHIDManager");
        return;
    }

    // Crear un diccionario para encontrar acelerómetros 3D
    NSDictionary *matchingDict = @{
        (NSString *)kIOHIDDeviceUsagePageKey: @(kHIDPage_Sensor),
        (NSString *)kIOHIDDeviceUsageKey: @(kHIDUsage_Sens_Motion_Accelerometer3D)
    };

    IOHIDManagerSetDeviceMatching(self.hidManager, (__bridge CFDictionaryRef)matchingDict);

    // Registrar callbacks
    IOHIDManagerRegisterDeviceMatchingCallback(self.hidManager, deviceMatchingCallback, (__bridge void *)self);
    IOHIDManagerRegisterDeviceRemovalCallback(self.hidManager, deviceRemovalCallback, (__bridge void *)self);
    
    // Agendar con el run loop principal para recibir eventos
    IOHIDManagerScheduleWithRunLoop(self.hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);

    // Abrir el IOHIDManager
    IOReturn result = IOHIDManagerOpen(self.hidManager, kIOHIDOptionsTypeNone);
    if (result != kIOReturnSuccess) {
        NSLog(@"Error al abrir IOHIDManager: %d", result);
        [self stopSensorMonitoring]; // Limpiar en caso de error
    } else {
        NSLog(@"IOHIDManager abierto correctamente.");
    }
}

- (void)stopSensorMonitoring {
    if (self.hidManager) {
        IOHIDManagerUnscheduleFromRunLoop(self.hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        IOHIDManagerClose(self.hidManager, kIOHIDOptionsTypeNone);
        CFRelease(self.hidManager);
        self.hidManager = NULL;
        NSLog(@"IOHIDManager detenido.");
    }
}

- (void)deviceMatched:(IOHIDDeviceRef)device {
    if (self.currentDevice) {
        NSLog(@"Ya se está monitoreando un dispositivo. Ignorando el nuevo.");
        return;
    }
    
    self.currentDevice = device;

    // Encontrar los elementos para los ejes X, Y, y Z y guardar sus cookies
    NSArray *elements = (__bridge_transfer NSArray *)IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone);
    for (NSDictionary *element in elements) {
        uint32_t usagePage = [element[(NSString *)kIOHIDElementUsagePageKey] unsignedIntValue];
        if (usagePage != kHIDPage_Sensor) {
            continue;
        }

        uint32_t usage = [element[(NSString *)kIOHIDElementUsageKey] unsignedIntValue];
        IOHIDElementCookie cookie = [element[(NSString *)kIOHIDElementCookieKey] unsignedIntValue];

        if (usage == kHIDUsage_Sens_Data_Motion_AccelerationX) {
            self.xAxisCookie = cookie;
        } else if (usage == kHIDUsage_Sens_Data_Motion_AccelerationY) {
            self.yAxisCookie = cookie;
        } else if (usage == kHIDUsage_Sens_Data_Motion_AccelerationZ) {
            self.zAxisCookie = cookie;
        }
    }
    
    if (self.xAxisCookie && self.yAxisCookie && self.zAxisCookie) {
        self.sensorFound = YES;
        NSLog(@"Dispositivo acelerómetro encontrado y configurado.");
        // Registrar el callback de valores de entrada para este dispositivo específico
        IOHIDDeviceRegisterInputValueCallback(device, inputValueCallback, (__bridge void*)self);
    } else {
        NSLog(@"No se pudieron encontrar todos los elementos de los ejes en el dispositivo.");
        self.currentDevice = NULL; // Reiniciar porque la configuración falló
    }
}

- (void)deviceRemoved:(IOHIDDeviceRef)device {
    if (device == self.currentDevice) {
        NSLog(@"Dispositivo acelerómetro desconectado.");
        self.currentDevice = NULL;
        self.sensorFound = NO;
        self.x = 0;
        self.y = 0;
        self.z = 0;
        self.xAxisCookie = 0;
        self.yAxisCookie = 0;
        self.zAxisCookie = 0;
    }
}

@end
