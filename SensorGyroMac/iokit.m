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

    // Buscar todos los dispositivos HID de sensores primero
    NSArray *matchingDictArray = @[
        @{
            (NSString *)kIOHIDDeviceUsagePageKey: @(kHIDPage_Sensor),
            (NSString *)kIOHIDDeviceUsageKey: @(kHIDUsage_Sens_Motion_Accelerometer3D)
        },
        @{
            (NSString *)kIOHIDDeviceUsagePageKey: @(kHIDPage_Sensor)
        }
    ];

    IOHIDManagerSetDeviceMatchingMultiple(self.hidManager, (__bridge CFArrayRef)matchingDictArray);

    // Registrar callbacks
    IOHIDManagerRegisterDeviceMatchingCallback(self.hidManager, deviceMatchingCallback, (__bridge void *)self);
    IOHIDManagerRegisterDeviceRemovalCallback(self.hidManager, deviceRemovalCallback, (__bridge void *)self);
    
    // Agendar con el run loop principal para recibir eventos
    IOHIDManagerScheduleWithRunLoop(self.hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);

    // Abrir el IOHIDManager
    IOReturn result = IOHIDManagerOpen(self.hidManager, kIOHIDOptionsTypeNone);
    if (result != kIOReturnSuccess) {
        NSLog(@"Error al abrir IOHIDManager: %d", result);
        [self stopSensorMonitoring];
    } else {
        NSLog(@"IOHIDManager abierto correctamente. Buscando sensores...");
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
    
    self.currentDevice = NULL;
    self.sensorFound = NO;
}

- (void)deviceMatched:(IOHIDDeviceRef)device {
    // Log información del dispositivo
    NSString *manufacturer = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDManufacturerKey));
    NSString *product = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
    NSNumber *usagePage = (__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDDeviceUsagePageKey));
    NSNumber *usage = (__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDDeviceUsageKey));
    
    NSLog(@"Dispositivo encontrado: %@ %@ (UsagePage: %@, Usage: %@)",
          manufacturer ?: @"Unknown", product ?: @"Unknown", usagePage, usage);

    // Solo procesar dispositivos de sensores
    if ([usagePage intValue] != kHIDPage_Sensor) {
        NSLog(@"Dispositivo ignorado: no es un sensor");
        return;
    }
    
    if (self.currentDevice) {
        NSLog(@"Ya se está monitoreando un dispositivo. Ignorando el nuevo.");
        return;
    }
    
    self.currentDevice = device;

    // Encontrar los elementos para los ejes X, Y, y Z
    NSArray *elements = (__bridge_transfer NSArray *)IOHIDDeviceCopyMatchingElements(device, NULL, kIOHIDOptionsTypeNone);
    NSLog(@"Elementos encontrados: %lu", (unsigned long)[elements count]);
    
    for (NSDictionary *element in elements) {
        uint32_t elementUsagePage = [element[(NSString *)kIOHIDElementUsagePageKey] unsignedIntValue];
        uint32_t elementUsage = [element[(NSString *)kIOHIDElementUsageKey] unsignedIntValue];
        IOHIDElementCookie cookie = [element[(NSString *)kIOHIDElementCookieKey] unsignedIntValue];
        
        NSLog(@"Elemento - UsagePage: 0x%02X, Usage: 0x%02X, Cookie: %u",
              elementUsagePage, elementUsage, cookie);

        if (elementUsagePage == kHIDPage_Sensor) {
            if (elementUsage == kHIDUsage_Sens_Data_Motion_AccelerationX) {
                self.xAxisCookie = cookie;
                NSLog(@"Eje X encontrado, cookie: %u", cookie);
            } else if (elementUsage == kHIDUsage_Sens_Data_Motion_AccelerationY) {
                self.yAxisCookie = cookie;
                NSLog(@"Eje Y encontrado, cookie: %u", cookie);
            } else if (elementUsage == kHIDUsage_Sens_Data_Motion_AccelerationZ) {
                self.zAxisCookie = cookie;
                NSLog(@"Eje Z encontrado, cookie: %u", cookie);
            }
        }
    }
    
    if (self.xAxisCookie && self.yAxisCookie && self.zAxisCookie) {
        self.sensorFound = YES;
        NSLog(@"Dispositivo acelerómetro configurado correctamente.");
        IOHIDDeviceRegisterInputValueCallback(device, inputValueCallback, (__bridge void*)self);
    } else {
        NSLog(@"No se encontraron todos los ejes. X:%u Y:%u Z:%u",
              self.xAxisCookie, self.yAxisCookie, self.zAxisCookie);
        self.currentDevice = NULL;
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
