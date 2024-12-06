//
//  BluetoothManager.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-11-30.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BluetoothManager()
    
    @Published var peripherals: [CBPeripheral] = []
    @Published var isBluetoothOn: Bool = false
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)

    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothOn = true
            print("Bluetooth is powered on.")
            startScanning()
        case .poweredOff:
            isBluetoothOn = false
            print("Bluetooth is powered off.")
        case .unauthorized:
            isBluetoothOn = false
            print("Bluetooth is unauthorized.")
        case .unsupported:
            isBluetoothOn = false
            print("Bluetooth is unsupported.")
        case .unknown:
            isBluetoothOn = false
            print("Bluetooth state is unknown.")
        case .resetting:
            isBluetoothOn = false
            print("Bluetooth is resetting.")
        @unknown default:
            isBluetoothOn = false
            print("Unknown Bluetooth state.")
        }
    }


    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on.")
            return
        }
        peripherals = []
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Filter peripherals by name
        if let name = peripheral.name, name.contains("Reveye") {
            // Add the peripheral only if it's not already in the list
            if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                peripherals.append(peripheral)
                print("Discovered Reveye device: \(name)")
            }
        }
    }


    func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        self.connectedPeripheral = peripheral
        print("connected peripehral is: \(connectedPeripheral?.name)")
        peripheral.delegate = self
        print("Connecting to \(self.connectedPeripheral?.name ?? "Unknown Device")...")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unknown device")")
        peripheral.discoverServices(nil) // Discover services
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")

            // Check if the characteristic is writable
            if characteristic.properties.contains(.write) {
                writeCharacteristic = characteristic
                print("Writable characteristic found: \(characteristic.uuid)")
            }
        }
    }


    func sendStartCommand() {
        print("try to send")
        let command: String = "start"
        print("connected är: \(self.connectedPeripheral?.name): \(self.connectedPeripheral?.identifier)")
        guard let characteristic = writeCharacteristic, let peripheral = self.connectedPeripheral else {
            print("No connected peripheral or writable characteristic.")
            return
        }
        let data = command.data(using: .utf8)!
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent command: \(command)")
    }
}
