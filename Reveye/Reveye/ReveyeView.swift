//
//  ReveyeView.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-12-10.
//

import SwiftUI

struct ReveyeView: View {
    @State var currentIcon = 1
    @State var currentMiniView: AnyView = AnyView(powerView())
    
    var body: some View {
        VStack {
            HStack{
                VStack {
                    Text("My Reveye Device")
                        .foregroundColor(textColor)
                        .font(.system(size: 30, weight: .semibold))
                    
                    Spacer()
                }
                Spacer()
                
            
                
                
            }
            
            Image("ReveyeDevice")
                .resizable()
                .scaledToFit()
                .frame(height: 260)
                .shadow(color: Color.white.opacity(0.2), radius: 80)
                .shadow(color: Color.black.opacity(0.5), radius: 10)
                .padding()
                .padding(.bottom, 30)
            
            
            
            
            HStack(spacing: 30) {
                icon(iconName: "power", iconIndex: 1, currentIcon: $currentIcon, currentMiniView: $currentMiniView, newMiniView: AnyView(powerView()))
                icon(iconName: "chat", iconIndex: 2, currentIcon: $currentIcon, currentMiniView: $currentMiniView, newMiniView: AnyView(textView()))
                icon(iconName: "speedometer", iconIndex: 3, currentIcon: $currentIcon, currentMiniView: $currentMiniView, newMiniView: AnyView(performanceView()))
                icon(iconName: "settings-filled", iconIndex: 4, currentIcon: $currentIcon, currentMiniView: $currentMiniView, newMiniView: AnyView(settingsView()))
            }
            .padding(.bottom, 10)
            
            
            currentMiniView
                .frame(height: 200)
            
            
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkGray)
        
    }
}

struct icon: View {
    let iconName: String
    let iconIndex: Int
    @Binding var currentIcon: Int
    @Binding var currentMiniView: AnyView
    let newMiniView: AnyView // The view to display when this icon is tapped
    
    var body: some View {
        VStack {
            Button {
                currentMiniView = newMiniView
                currentIcon = iconIndex
            } label: {
                Image(iconName)
                    .resizable()
                    .colorMultiply(currentIcon == iconIndex ? textColor : notSelected)
                    .scaledToFit()
                    .frame(height: 25)
                    .padding()
            }
        }
    }
}

struct settingsView: View {
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

struct performanceView: View {
    var body: some View {
        HStack {
            tempIndicator(temp: 20)
            FPSIndicator(FPS: 12)
        }
        
        
    }
    
    
}

struct textView: View {
    let textArray = ["A man with a hat to the right", "Sheep herd to the left"]
    
    var body: some View {
        
        VStack(spacing: 10) {
            ForEach(0..<textArray.count, id: \.self) { index in
                Text(textArray[index])
                    .foregroundColor(.white)
                    .font(.system(size: index == textArray.count - 1 ? 30 : 20, weight: index == textArray.count - 1 ? .semibold : .regular))
            }

                }
        
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
let darkGreen = Color(red: 0.0, green: 110/255, blue: 0.0)



struct startStopButton: View {
    @State var isRunning = false
    @ObservedObject var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        VStack {
            
            
            Button(action: {
                if !isRunning {
                    //bluetoothManager.sendStartCommand()
                } else {
                    // bluetoothManager.sendStopCommand()
                }
                
                
                isRunning.toggle()
            }, label: {
                VStack {
                    Image(systemName: isRunning ? "stop.fill" : "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(textColor)
                    
                    
                    
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(grayButton)
                .cornerRadius(15)
                .padding(.all, 20)
            })
            
            
            Text(isRunning ? "Stop" : "Start reveal surroundings")
                .foregroundColor(textColor)
                .font(.system(size: 23, weight: .regular))
                .padding(.top, 10)

        }
        
    }
}

struct FPSIndicator: View {
    let FPS: Double
    let minFPS: Double = 5.0
    let maxFPS: Double = 60.0
    
    var color: Color {
            if FPS < 15 {
                return .red
            } else if FPS >= 15 && FPS <= 40 {
                return .green
            } else {
                return darkGreen
            }
        }
    
    var body: some View {
        VStack {
            
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.78)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(130))
                
                
                Circle()
                    .trim(from: 0.0, to: CGFloat((FPS - minFPS) / (maxFPS - minFPS)) * 0.78)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(color)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(130))
                
                Text("\(Int(FPS))")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("FPS")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.top, 80)

            }
        }
        .padding()
    }
    
    
}

struct tempIndicator: View {
    let temp: Double
    let minTemp: Double = 10.0
    let maxTemp: Double = 90.0
    
    var color: Color {
            if temp < 28 {
                return .blue
            } else if temp >= 28 && temp <= 80 {
                return .green
            } else {
                return .red
            }
        }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.72)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(140))
                
                
                Circle()
                    .trim(from: 0.0, to: CGFloat((temp - minTemp) / (maxTemp - minTemp)) * 0.72)
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(color)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(140))
                
                Text("\(Int(temp))°")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("CPU °C")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .padding(.top, 80)

            }
        }
        .padding()
    }
}

#Preview {
    ReveyeView()
}
