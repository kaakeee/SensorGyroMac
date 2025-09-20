//
//  ContentView.swift
//  SensorGyroMac
//
//  Created by Ramiro Nehuen Sanabria on 20/09/2025.
//

import SwiftUI
import Combine

// Un ViewModel que observa los datos del GyroManager y los publica para la UI.
class MotionViewModel: ObservableObject {
    @Published var x: Double = 0.0
    @Published var y: Double = 0.0
    @Published var z: Double = 0.0
    @Published var sensorFound: Bool = false

    private let gyroManager = GyroManager()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Usamos Combine para suscribirnos a los cambios en las propiedades KVO de GyroManager.
        gyroManager.publisher(for: \.x)
            .receive(on: DispatchQueue.main)
            .assign(to: \.x, on: self)
            .store(in: &cancellables)

        gyroManager.publisher(for: \.y)
            .receive(on: DispatchQueue.main)
            .assign(to: \.y, on: self)
            .store(in: &cancellables)

        gyroManager.publisher(for: \.z)
            .receive(on: DispatchQueue.main)
            .assign(to: \.z, on: self)
            .store(in: &cancellables)
        
        gyroManager.publisher(for: \.sensorFound)
            .receive(on: DispatchQueue.main)
            .assign(to: \.sensorFound, on: self)
            .store(in: &cancellables)

        // Iniciar el monitoreo del sensor
        gyroManager.startSensorMonitoring()
    }

    deinit {
        // Detener el monitoreo cuando el ViewModel se destruye
        gyroManager.stopSensorMonitoring()
    }
}

// La vista principal que muestra los datos del sensor.
struct ContentView: View {
    @StateObject private var viewModel = MotionViewModel()

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.sensorFound {
                Text("Datos del Acelerómetro")
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("X: \(viewModel.x, specifier: "%.4f")")
                    Text("Y: \(viewModel.y, specifier: "%.4f")")
                    Text("Z: \(viewModel.z, specifier: "%.4f")")
                }
                .font(.title)
                .monospacedDigit()
                
            } else {
                Text("Buscando acelerómetro...")
                    .font(.title)
                ProgressView()
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 200)
    }
}

#Preview {
    ContentView()
}
