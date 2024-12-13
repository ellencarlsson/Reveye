//
//  ContentView.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-11-30.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetoothManager = BluetoothManager.shared

    var body: some View {
        if bluetoothManager.isConnected {
            ReveyeView()
        } else {
            ConnectView()
        }
    }
}

#Preview {
    ContentView()
}
