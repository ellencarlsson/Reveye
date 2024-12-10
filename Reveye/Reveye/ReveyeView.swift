//
//  ReveyeView.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-12-10.
//

import SwiftUI

struct ReveyeView: View {
    @State private var batteryLevel: Double = 80
    @State private var temp: Int = 60
    
    @State var currentMiniView: AnyView = AnyView(powerView())
    
    var body: some View {
        VStack {
            HStack{
                VStack {
                    Text("Reveye Device")
                        .foregroundColor(textColor)
                        .font(.system(size: 30, weight: .semibold))
                    Spacer()
                }
                Spacer()
                
                
                VStack {
                    Text("\(temp)°C")
                        .foregroundColor(getTemperatureColor(for: temp))
                        .font(.system(size: 30, weight: .semibold))
                        .padding(.bottom, -10)
                    
                    Text("\(getValue(for: temp))")
                        .foregroundColor(getTemperatureColor(for: temp))
                    Spacer()
                }
                
            }
            Spacer()
            
            
            ZStack {
                
                
                
                Circle()
                    .trim(from: 0, to: batteryLevel / 100)
                    .stroke(getBatteryColor(for: Int(batteryLevel)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // Start from the top
                    .frame(width: 350, height: 350)
                
                Circle()
                    .trim(from: 0, to: 360)
                    .stroke(getBatteryColor(for: Int(batteryLevel)).opacity(0.2), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // Start from the top
                    .frame(width: 350, height: 350)
                
                
                
                Image("ReveyeDevice")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 260)
                    .shadow(color: Color.white.opacity(0.2), radius: 80)
                    .shadow(color: Color.black.opacity(0.5), radius: 10)
                    .padding()
            }
            .padding(.bottom, 30)
            
           
            
            
            HStack(spacing: 30) {
                            icon(iconName: "power", isActive: true, currentMiniView: $currentMiniView, newMiniView: AnyView(powerView()))
                            icon(iconName: "chat", isActive: false, currentMiniView: $currentMiniView, newMiniView: AnyView(textView()))
                            icon(iconName: "bluetooth-filled", isActive: false, currentMiniView: $currentMiniView, newMiniView: AnyView(bluetoothView()))
                            icon(iconName: "settings-filled", isActive: false, currentMiniView: $currentMiniView, newMiniView: AnyView(settingsView()))
                        }
            .padding(.bottom, 10)
                        
            
            currentMiniView
                .frame(height: 150)
            
            
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkGray)
        
    }
}

struct icon: View {
    let iconName: String
    let isActive: Bool
    @Binding var currentMiniView: AnyView
    let newMiniView: AnyView // The view to display when this icon is tapped

    var body: some View {
        VStack {
            Button {
                currentMiniView = newMiniView // Update the mini view
            } label: {
                Image(iconName)
                    .resizable()
                    .colorMultiply(isActive ? textColor : notSelected)
                    .scaledToFit()
                    .frame(height: 25)
                    .padding()
            }
        }
    }
}

struct settingsView: View {
    var body: some View {
        Text("A man with a hat to the right")
            .foregroundColor(textColor)
            .font(.system(size: 20, weight: .semibold))
    }
}

struct bluetoothView: View {
    var body: some View {
        VStack {
            HStack {
                Image("bluetooth")
                    .resizable()
                    .colorMultiply(notSelected)
                    .scaledToFit()
                    .frame(height: 30)
                
                Text("Connected to: Reveye Device")
                    .foregroundColor(textColor)
                    .font(.system(size: 20))
                Spacer()
            }
            
            Spacer()
            
            
            Button(action: {
                    
            }, label: {
                
                    Text("Disconnect")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                
                .padding(.vertical, 15)
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(grayButton)
                .cornerRadius(15)
            })
        }
            
        }
        
    
}

struct textView: View {
    var body: some View {
            
                Text("A man with a hat to the right")
                    .foregroundColor(textColor)
                    .font(.system(size: 20))
            
    }
}


struct powerView: View {
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        
            startStopButton()
        
              
    }
}

let darkGray = Color(red: 22/255, green: 23/255, blue: 25/255)
let textColor = Color(red: 243/255, green: 243/255, blue: 243/255)
let notSelected = Color(red: 139/255, green: 139/255, blue: 139/255)
let grayButton = Color(red: 51/255, green: 51/255, blue: 51/255)


struct startStopButton: View {
    @State var isRunning = false
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        Button(action: {
                if !isRunning {
                    //bluetoothManager.sendStartCommand()
                } else {
                   // bluetoothManager.sendStopCommand()
                }
            
            
            isRunning.toggle()
        }, label: {
            HStack {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
                Text(isRunning ? "Stop" : "Start")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
            }
            .padding(.vertical, 15)
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .background(isRunning ? Color.red : .green )
            .cornerRadius(15)
        })
    }
}

private func getBatteryColor(for battery: Int) -> Color {
        switch battery {
        case ..<20:
            return .red // Low
        case 20...70:
            return .yellow // Normal
        default:
            return .green // High
        }
    }

private func getTemperatureColor(for temperature: Int) -> Color {
        switch temperature {
        case ..<50:
            return .yellow // Low
        case 50...70:
            return .green // Normal
        default:
            return .red // High
        }
    }

private func getValue(for temperature: Int) -> String {
        switch temperature {
        case ..<50:
            return "low"// Low
        case 50...70:
            return "normal" // Normal
        default:
            return "high" // High
        }
    }

#Preview {
    ReveyeView()
}
