//
//  BluetoothManager.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-11-30.
//

import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()
    
    private var cbManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var uartRXCharacteristic: CBCharacteristic?
    private var uartTXCharacteristic: CBCharacteristic?
    
    private let serviceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")  // UART Service UUID
    private let uartRXUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")   // RX Characteristic UUID
    private let uartTXUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")   // TX Characteristic UUID
    
    @Published var peripherals: [CBPeripheral] = []
    @Published var isConnected = false
    @Published var isScanning = false
    
    @Published var device_UUID = ""
    @Published var device_name = ""
    @Published var device_temp = 0.0
    @Published var device_wifi = ""

    
    private var connectCompletion: ((Bool) -> Void)?
    
    private override init() {
        super.init()
        cbManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Start scanning for peripherals that match the service UUID
    func startScanning() {
        guard cbManager.state == .poweredOn else {
            print("Bluetooth is not powered on.")
            return
        }
        cbManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        print("Scanning for peripherals...")
        isScanning = true
    }
    
    // Stop scanning
    func stopScanning() {
        peripherals = []
        cbManager.stopScan()
        print("Stopped scanning.")
        isScanning = false
    }
    
    // Connect to a discovered peripheral
    func connectToPeripheral(_ peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        cbManager.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
        peripheral.delegate = self
        print("Connecting to peripheral: \(peripheral.name ?? "Unknown")")
        self.connectCompletion = completion
    }

    func sendCommand(command: String) {
        guard let uartRXCharacteristic = uartRXCharacteristic else {
            print("RX Characteristic not found.")
            return
        }
        let text = command
        let data = text.data(using: .utf8)!
        connectedPeripheral?.writeValue(data, for: uartRXCharacteristic, type: .withResponse)
        print("Sent start command")
    }
    
    func sendStartCommand() {
        sendCommand(command: "start")
    }
    
    func sendStopCommand() {
        sendCommand(command: "stop")
    }
    
    func sendConnectedCommand() {
        sendCommand(command: "connected")
    }
    
    // Disconnect from the peripheral
    func disconnectFromPeripheral() {
        if let peripheral = connectedPeripheral {
            cbManager.cancelPeripheralConnection(peripheral)
            print("Disconnected from peripheral.")
            isConnected = false
            startScanning()
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on.")
            startScanning()
        case .poweredOff:
            print("Bluetooth is powered off.")
        case .resetting:
            print("Bluetooth is resetting.")
        case .unauthorized:
            print("Bluetooth is unauthorized.")
        case .unsupported:
            print("Bluetooth is unsupported on this device.")
        default:
            print("Bluetooth state is unknown.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        // Add peripheral to list if it's not already added
        if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            peripherals.append(peripheral)
            print("Discovered peripheral: \(peripheral.name ?? "Unknown")")
            isScanning = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        peripheral.discoverServices([serviceUUID])
        self.isConnected = true
        
        device_name = "\(peripheral.name!)"
        device_UUID = "\(String(describing: peripheral.identifier))"
        
        connectCompletion?(true)  // Notify success
        connectCompletion = nil
        
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.name ?? "Unknown"). Error: \(error?.localizedDescription ?? "Unknown error")")
        connectCompletion?(false)  // Notify failure
        connectCompletion = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown"). Error: \(error?.localizedDescription ?? "No error")")
        self.isConnected = false
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        if let services = peripheral.services {
            for service in services where service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([uartRXUUID, uartTXUUID], for: service)
                print("Discovered UART service and characteristics.")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        if service.uuid == serviceUUID {
            for characteristic in service.characteristics ?? [] {
                if characteristic.uuid == uartRXUUID {
                    uartRXCharacteristic = characteristic
                    print("Found RX characteristic.")
                } else if characteristic.uuid == uartTXUUID {
                    uartTXCharacteristic = characteristic
                    print("Found TX characteristic.")
                }
            }
            
            // Enable notifications for the TX characteristic if it's found
            if let uartTX = uartTXCharacteristic {
                peripheral.setNotifyValue(true, for: uartTX)
                print("Enabled notifications for TX characteristic.")
                sendConnectedCommand()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error updating value for characteristic: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        if characteristic.uuid == uartTXUUID, let data = characteristic.value, let receivedText = String(data: data, encoding: .utf8) {
            if receivedText.starts(with: "Temp:") {
                let temp = receivedText.dropFirst(5).trimmingCharacters(in: .whitespaces)
                device_temp = Double(temp) ?? 0.0
                
            } else if receivedText.starts(with: "Wifi:") {
                let wifi = receivedText.dropFirst(5).trimmingCharacters(in: .whitespaces)
                device_wifi = wifi
                
            }  else {
                print("Received data: \(receivedText)")
            }
            
        }
    }
}
