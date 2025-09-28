//
//  ContentView.swift
//  SensorGyroMac
//
//  Created by Ramiro Nehuen Sanabria on 20/09/2025.
//

//
//  ContentView.swift
//  SensorGyroMac
//
//  Created by Ramiro Nehuen Sanabria on 20/09/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sensorManager = SPUSensorManager()
    @State private var isMonitoring = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sensores Mac M4")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(sensorManager.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if sensorManager.sensorFound {
                VStack(spacing: 15) {
                    // Sección Acelerómetro
                    GroupBox(label: Label("Acelerómetro (g)", systemImage: "move.3d")) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("X:")
                                    .frame(width: 20, alignment: .leading)
                                Text("\(sensorManager.accelX, specifier: "%.4f")")
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Indicador visual
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: max(1, abs(sensorManager.accelX) * 100), height: 8)
                                    .animation(.easeInOut(duration: 0.1), value: sensorManager.accelX)
                            }
                            
                            HStack {
                                Text("Y:")
                                    .frame(width: 20, alignment: .leading)
                                Text("\(sensorManager.accelY, specifier: "%.4f")")
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: max(1, abs(sensorManager.accelY) * 100), height: 8)
                                    .animation(.easeInOut(duration: 0.1), value: sensorManager.accelY)
                            }
                            
                            HStack {
                                Text("Z:")
                                    .frame(width: 20, alignment: .leading)
                                Text("\(sensorManager.accelZ, specifier: "%.4f")")
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: max(1, abs(sensorManager.accelZ) * 100), height: 8)
                                    .animation(.easeInOut(duration: 0.1), value: sensorManager.accelZ)
                            }
                        }
                        .font(.system(size: 14, design: .monospaced))
                    }
                    
                    // Sección Giroscopio
                    GroupBox(label: Label("Giroscopio (rad/s)", systemImage: "gyroscope")) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("X:")
                                    .frame(width: 20, alignment: .leading)
                                Text("\(sensorManager.gyroX, specifier: "%.4f")")
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: max(1, abs(sensorManager.gyroX) * 200), height: 8)
                                    .animation(.easeInOut(duration: 0.1), value: sensorManager.gyroX)
                            }
                            
                            HStack {
                                Text("Y:")
                                    .frame(width: 20, alignment: .leading)
                                Text("\(sensorManager.gyroY, specifier: "%.4f")")
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Rectangle()
                                    .fill(Color.purple)
                                    .frame(width: max(1, abs(sensorManager.gyroY) * 200), height: 8)
                                    .animation(.easeInOut(duration: 0.1), value: sensorManager.gyroY)
                            }
                            
                            HStack {
                                Text("Z:")
                                    .frame(width: 20, alignment: .leading)
                                Text("\(sensorManager.gyroZ, specifier: "%.4f")")
                                    .monospacedDigit()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Rectangle()
                                    .fill(Color.cyan)
                                    .frame(width: max(1, abs(sensorManager.gyroZ) * 200), height: 8)
                                    .animation(.easeInOut(duration: 0.1), value: sensorManager.gyroZ)
                            }
                        }
                        .font(.system(size: 14, design: .monospaced))
                    }
                    
                    // Controles
                    HStack(spacing: 20) {
                        Button(action: {
                            if isMonitoring {
                                sensorManager.stopMonitoring()
                            } else {
                                sensorManager.startMonitoring()
                            }
                            isMonitoring.toggle()
                        }) {
                            Label(isMonitoring ? "Detener" : "Iniciar",
                                  systemImage: isMonitoring ? "stop.circle" : "play.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Buscar Sensores") {
                            // Reinicializar búsqueda de sensores
                            _ = SPUSensorManager()
                            // Aquí podrías reemplazar el manager actual si fuera necesario
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "sensor.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("Buscando sensores...")
                        .font(.title2)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Asegúrate de que la opción de sensor de movimiento\nestá habilitada en Configuración del Sistema")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 500)
        .onAppear {
            // Auto-iniciar monitoreo si se encuentran sensores
            if sensorManager.sensorFound {
                sensorManager.startMonitoring()
                isMonitoring = true
            }
        }
        .onDisappear {
            sensorManager.stopMonitoring()
        }
    }
}

#Preview {
    ContentView()
}
