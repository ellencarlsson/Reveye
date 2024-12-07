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
        print("connected peripheral is: \(connectedPeripheral?.name ?? "Unknown Device")")
        peripheral.delegate = self
        peripheral.discoverServices(nil) // Start discovering services after connecting
        print("Connecting to \(self.connectedPeripheral?.name ?? "Unknown Device")...")
    }


    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unknown device")")
        peripheral.discoverServices(nil) // Discover services
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found.")
            return
        }
        
        print("Discovered services: \(services.map { $0.uuid })")
        // För varje tjänst, upptäck dess egenskaper
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics for service \(service.uuid): \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics found for service \(service.uuid).")
            return
        }
        
        print("Discovered characteristics for service \(service.uuid): \(characteristics.map { $0.uuid })")
        
        // För varje egenskap, kolla om den är skrivbar
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")

            // Kontrollera om egenskapen är skrivbar
            if characteristic.properties.contains(.write) {
                writeCharacteristic = characteristic
                print("Writable characteristic found: \(characteristic.uuid)")
                break  // Du kan bryta här om du har hittat en skrivbar egenskap
            }
        }

        if writeCharacteristic == nil {
            print("No writable characteristic found for service \(service.uuid).")
        }
    }




    func sendStartCommand() {
        let command: String = "start"
        print("connected är: \(self.connectedPeripheral?.name): \(self.connectedPeripheral?.identifier)")
        print("characters is: \(writeCharacteristic?.uuid)")
        guard let characteristic = writeCharacteristic, let peripheral = self.connectedPeripheral else {
            print("No connected peripheral or writable characteristic.")
            return
        }
        let data = command.data(using: .utf8)!
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent command: \(command)")
    }

}
