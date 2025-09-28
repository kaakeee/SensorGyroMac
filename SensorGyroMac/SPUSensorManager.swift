//  SPUSensorManager.swift
//  SensorGyroMac
//
//  Created by Ramiro Nehuen Sanabria on 20/09/2025.
//

import Foundation
import IOKit
import IOKit.pwr_mgt
import Combine

class SPUSensorManager: NSObject, ObservableObject {
    @Published var accelX: Double = 0.0
    @Published var accelY: Double = 0.0
    @Published var accelZ: Double = 0.0
    
    @Published var gyroX: Double = 0.0
    @Published var gyroY: Double = 0.0
    @Published var gyroZ: Double = 0.0
    
    @Published var sensorFound: Bool = false
    @Published var statusMessage: String = "Inicializando..."
    
    private var timer: Timer?
    private var spuService: io_service_t = 0
    
    override init() {
        super.init()
        findSPUSensors()
    }
    
    deinit {
        stopMonitoring()
        if spuService != 0 {
            IOObjectRelease(spuService)
        }
    }
    
    func startMonitoring() {
        guard sensorFound else {
            statusMessage = "No se encontraron sensores"
            return
        }
        
        // Iniciar timer para leer sensores cada 16ms (~60 FPS)
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.readSensorData()
        }
        
        statusMessage = "Monitoreando sensores..."
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        statusMessage = "Monitoreo detenido"
    }
    
    private func findSPUSensors() {
        statusMessage = "Buscando sensores SPU..."
        
        // Buscar el servicio AppleSPUHIDInterface
        spuService = IOServiceGetMatchingService(kIOMainPortDefault,
                                               IOServiceMatching("AppleSPUHIDInterface"))
        
        if spuService != 0 {
            statusMessage = "AppleSPUHIDInterface encontrado"
            print("✅ Encontrado AppleSPUHIDInterface")
            
            // Intentar encontrar los sensores AOP
            if findAOPSensors() {
                sensorFound = true
                statusMessage = "Sensores AOP detectados"
            } else {
                statusMessage = "No se pudieron acceder a los sensores AOP"
            }
        } else {
            statusMessage = "AppleSPUHIDInterface no encontrado"
            print("❌ No se encontró AppleSPUHIDInterface")
            
            // Intentar métodos alternativos
            tryAlternativeMethods()
        }
    }
    
    private func findAOPSensors() -> Bool {
        guard spuService != 0 else { return false }
        
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(spuService, &properties, kCFAllocatorDefault, 0)
        
        if result == KERN_SUCCESS, let props = properties?.takeRetainedValue() as? [String: Any] {
            print("📊 Propiedades del SPU:")
            printDictionary(props, level: 0)
            
            // Buscar sensores AOP
            if findAOPSensorsInProperties(props) != nil {
                print("✅ Sensores AOP encontrados")
                return true
            }
        } else {
            print("❌ No se pudieron obtener propiedades del SPU: \(result)")
        }
        
        return false
    }
    
    private func findAOPSensorsInProperties(_ properties: [String: Any]) -> [String: Any]? {
        // Buscar recursivamente por "AOP Sensors" o claves relacionadas
        for (key, value) in properties {
            if key.contains("AOP") || key.contains("Sensor") || key.contains("accel") || key.contains("gyro") {
                print("🔍 Clave interesante encontrada: \(key)")
                
                if let dict = value as? [String: Any] {
                    return dict
                } else {
                    print("   Valor: \(value)")
                }
            }
            
            // Búsqueda recursiva en diccionarios anidados
            if let nestedDict = value as? [String: Any] {
                if let result = findAOPSensorsInProperties(nestedDict) {
                    return result
                }
            }
        }
        
        return nil
    }
    
    private func tryAlternativeMethods() {
        statusMessage = "Probando métodos alternativos..."
        
        // Método 1: Buscar por clase IOHIDDevice
        let hidMatching = IOServiceMatching("IOHIDDevice")
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, hidMatching, &iterator)
        
        if result == KERN_SUCCESS && iterator != 0 {
            var service: io_object_t = 0
            repeat {
                service = IOIteratorNext(iterator)
                if service != 0 {
                    checkServiceForSensors(service)
                    IOObjectRelease(service)
                }
            } while service != 0
            IOObjectRelease(iterator)
        }
        
        // Método 2: Buscar servicios relacionados con sensores
        let sensorServices = [
            "AppleEmbeddedAccel",
            "AppleEmbeddedGyro",
            "AppleSMC",
            "IOHIDDevice",
            "AppleHSSPIController"
        ]
        
        for serviceName in sensorServices {
            let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                    IOServiceMatching(serviceName))
            if service != 0 {
                print("✅ Encontrado servicio: \(serviceName)")
                checkServiceForSensors(service)
                IOObjectRelease(service)
            }
        }
    }
    
    private func checkServiceForSensors(_ service: io_service_t) {
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
        
        if result == KERN_SUCCESS, let props = properties?.takeRetainedValue() as? [String: Any] {
            // Buscar propiedades relacionadas con sensores
            for (key, value) in props {
                if key.lowercased().contains("accel") ||
                   key.lowercased().contains("gyro") ||
                   key.lowercased().contains("sensor") {
                    print("🎯 Sensor relacionado: \(key) = \(value)")
                }
            }
        }
    }
    
    private func readSensorData() {
        // Esta función necesitaría implementar la lectura real de los sensores
        // Por ahora, simularemos datos para testing
        
        // Datos simulados para prueba (deberías reemplazar esto con la lectura real)
        let time = Date().timeIntervalSince1970
        accelX = sin(time) * 0.1
        accelY = cos(time * 1.2) * 0.1
        accelZ = sin(time * 0.8) * 0.1 + 1.0 // +1.0 para simular gravedad
        
        gyroX = sin(time * 2) * 0.05
        gyroY = cos(time * 1.5) * 0.05
        gyroZ = sin(time * 3) * 0.05
    }
    
    // Función auxiliar para imprimir diccionarios de forma legible
    private func printDictionary(_ dict: [String: Any], level: Int) {
        let indent = String(repeating: "  ", count: level)
        for (key, value) in dict {
            if let nestedDict = value as? [String: Any] {
                print("\(indent)\(key):")
                printDictionary(nestedDict, level: level + 1)
            } else if let array = value as? [Any] {
                print("\(indent)\(key): [\(array.count) elementos]")
                if array.count < 10 { // Solo mostrar arrays pequeños
                    for (index, item) in array.enumerated() {
                        print("\(indent)  [\(index)]: \(item)")
                    }
                }
            } else {
                print("\(indent)\(key): \(value)")
            }
        }
    }
}
