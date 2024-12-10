//
//  MainView.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-11-30.
//

import SwiftUI

struct MainView: View {
    @State private var isBluetoothConnected = false
    @State private var showBluetoothSearch = false
    @State private var selectedDevice = ""
    
    var body: some View {
        ZStack {
            Background()
            
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 280)
                    .edgesIgnoringSafeArea(.top)
                    
                    Spacer()
                }
                Spacer()
            }
            
            Header()
            
            
            
            VStack (){
                Spacer()
                BluetoothButton(isBluetoothConnected: $isBluetoothConnected, showBluetoothSearch: $showBluetoothSearch, selectedDevice: $selectedDevice)
                    .padding(.bottom, 20)
                
                StartStopButton()
                
                
            }
            .padding(.bottom, 40)
            .padding(.horizontal)
            
        }
        .sheet(isPresented: $showBluetoothSearch) {
            BluetoothSearchView(showBluetoothSearch: $showBluetoothSearch, selectedDevice: $selectedDevice)
        }
    }
}

struct BluetoothSearchView: View {
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    @Binding var showBluetoothSearch: Bool // State to dismiss the pop-up
    @Binding var selectedDevice: String
    @State var showLoading = false
    
    var body: some View {
        ZStack {
            Image("bluetooth-background")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Title
                Text("Find Reveye Device")
                    .font(.custom("Georgia", size: 30))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                    .padding(.top, 20)
                
                if bluetoothManager.peripherals.isEmpty {
                    if bluetoothManager.isScanning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.white.opacity(0.7)))

                    } else {
                        Text("No devices found")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(bluetoothManager.peripherals.enumerated()), id: \.element.identifier) { index, peripheral in
                                Button(action: {
                                    showLoading = true
                                    bluetoothManager.connectToPeripheral(peripheral, completion: {success in
                                        
                                        if success {
                                            showBluetoothSearch = false
                                            bluetoothManager.stopScanning()
                                            selectedDevice = peripheral.name ?? "Unknown Device"
                                            showLoading = false
                                        } else {
                                            // could not connect
                                        }
                                        
                                    })
                                                                                                
                                }) {
                                    HStack {
                                        
                                            Text(peripheral.name ?? "Unknown Device")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.white)
                                            
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
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(15)
                    }
                }
                
                
                Spacer()
                
                // Close Button
                Button(action: {
                    
                            showBluetoothSearch = false
                            showLoading = false
                    bluetoothManager.stopScanning()
                        
                    
                }, label: {
                    Text("Close")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .kerning(2)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(15)
                })
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            
        }
        
        
    }
    
}

struct StartStopButton: View {
    @State var isRunning = false
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        Button(action: {
                if !isRunning {
                    bluetoothManager.sendStartCommand()
                } else {
                    bluetoothManager.sendStopCommand()
                }
            
            
            isRunning.toggle()
        }, label: {
            HStack {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                Text(isRunning ? "Stop" : "Start")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(isRunning ? Color.red.opacity(0.7) : bluetoothManager.isConnected ? natureGreen.opacity(0.7) : .gray.opacity(0.7))
            .cornerRadius(15)
        })
        .disabled(!bluetoothManager.isConnected)
    }
}

struct BluetoothButton: View {
    @Binding var isBluetoothConnected: Bool
    @Binding var showBluetoothSearch: Bool
    @Binding var selectedDevice: String
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    
    
    var body: some View {
        Button(action: {
            showBluetoothSearch.toggle()
            bluetoothManager.startScanning()
            
        }, label: {
            HStack {
                Image("bluetooth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                Text(bluetoothManager.isConnected ? selectedDevice : "No Reveye device connected")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.6))
            .cornerRadius(15)
        })
    }
}

let natureGreen = Color(red: 169/255, green: 233/255, blue: 76/255)

let darkGreen = Color(red: 34/255, green: 51/255, blue: 26/255)


struct Background: View {
    var body: some View {
        Image("reveye-background")
            .resizable()
            .edgesIgnoringSafeArea(.all)
        
        LinearGradient(
            gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
            startPoint: .bottom,
            endPoint: .top
        )
        .edgesIgnoringSafeArea(.all)
    }
}

struct Header: View {
    var body: some View {
        VStack() {
            VStack(spacing: 10) {
                Text("Reveye")
                    .font(.custom("Georgia", size: 40))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                    .padding(.top, 50)
                
                Text("Reveal the world around you")
                    .font(.system(size: 20, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            
            Spacer()
        }
    }
}
#Preview {
    MainView()
}
