//
//  ConnectView.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-12-10.
//

import SwiftUI

struct ConnectView: View {
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    @State var showLoading = false
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(alignment: .center, spacing: 8) {
                Text("Reveye")
                    .foregroundColor(textColor)
                    .font(.system(size: 70, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Select a Reveye Device to get started")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                    .multilineTextAlignment(.center)
            }
            
            VStack {
                if bluetoothManager.peripherals.isEmpty {
                    if bluetoothManager.isScanning {
                        VStack {
                            Text("Scanning...")
                                .foregroundColor(.gray)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white.opacity(0.7)))
                        }
                        
                    } else {
                        HStack {
                            Image("bluetooth")
                                .resizable()
                                .colorMultiply(notSelected)
                                .scaledToFit()
                                .frame(height: 25)
                            
                            Text("No devices found")
                                .foregroundColor(.gray)
                        }
                            
                    }
                    
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(bluetoothManager.peripherals.enumerated()), id: \.element.identifier) { index, peripheral in
                                Button(action: {
                                    showLoading = true
                                    bluetoothManager.connectToPeripheral(peripheral, completion: {success in
                                        
                                        if success {
                                            bluetoothManager.stopScanning()
                                            
                                            showLoading = false
                                        } else {
                                            // could not connect
                                        }
                                        
                                    })
                                    
                                }) {
                                    HStack {
                                        
                                        Text(peripheral.name ?? "Unknown Device")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(textColor)
                                        
                                        if showLoading {
                                            Spacer()
                                            
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white.opacity(0.7)))
                                            
                                            
                                        } else {
                                            Spacer()
                                        }
                                        
                                    }
                                    .padding(.vertical, 5)
                                    
                                }
                                
                                if index < bluetoothManager.peripherals.count - 1 {
                                    Divider()
                                        .background(Color.white)
                                        .padding(.horizontal, 3)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(grayButton)
                        .cornerRadius(15)
                    }
                }
            }

            
            
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkGray.ignoresSafeArea())

    }
}

#Preview {
    ConnectView()
}
