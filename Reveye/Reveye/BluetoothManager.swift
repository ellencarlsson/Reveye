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
    
    private let SERVICE_UUID = "DA306E46-ADF7-B422-7C7E-D7335D84ADCE"
    private let CHARACTERISTIC_UUID = "DA306E46-ADF7-B422-7C7E-D7335D84ADCF"
    
    var pairingInProgress = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    // MARK: - Handles changes to the Bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isBluetoothOn = true
            print("Bluetooth is powered on.")
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

    // MARK: - Start scanning for bluetooth devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on.")
            return
        }
        
        peripherals = []
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    // MARK: - Stop bluetooth scanning
    func stopScanning() {
        centralManager.stopScan()
    }

    // MARK: - Is called when a perihperal is discovered during scanning
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, name.contains("Reveye") {
            // Add the peripheral only if it's not already in the list
            if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                peripherals.append(peripheral)
                print("Discovered Reveye device: \(name)")
            }
        }
    }
    
    // MARK: - Initiates a connection to a discovered peripheral
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        self.connectedPeripheral = peripheral
        
        print("Connecting to \(self.connectedPeripheral?.name ?? "Unknown Device")...")
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.name ?? "Unknown Device") with peripheral ID: \(peripheral.identifier)")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: SERVICE_UUID)])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics([CBUUID(string: CHARACTERISTIC_UUID)], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == CBUUID(string: CHARACTERISTIC_UUID) {
                writeCharacteristic = characteristic
                print("Found characteristic to write: \(characteristic)")
            }
        }
    }

    
    // MARK: - Write a command to the Raspberry Pi
    func sendStartCommand() {
        let command = "start"
        
        guard let peripheral = connectedPeripheral else {
            print("No connected peripheral available.")
            return
        }
        
        guard let characteristic = writeCharacteristic else {
            print("No write characteristic available.")
            return
        }
        
        
        let data = command.data(using: .utf8)!
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent command: \(command)")
    }

    
    
    
}
