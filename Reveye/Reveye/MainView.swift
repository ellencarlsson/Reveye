//
//  MainView.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-11-30.
//

import SwiftUI

struct MainView: View {
    @State private var isBluetoothConnected = false
        @State private var isRunning = false
    
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
                BluetoothButton(isBluetoothConnected: $isBluetoothConnected)
                    .padding(.bottom, 20)
                
                StartStopButton(isRunning: $isRunning, isBluetoothConnected: isBluetoothConnected)
                
                
            }
            .padding(.bottom, 40)
            .padding(.horizontal)
            
        }
    }
}

struct StartStopButton: View {
    @Binding var isRunning: Bool
    var isBluetoothConnected: Bool
    
    var body: some View {
        Button(action: {
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
            .background(isRunning ? Color.red.opacity(0.7) : natureGreen.opacity(0.7))
            .cornerRadius(15)
        })
        .disabled(!isBluetoothConnected)
        .opacity(isBluetoothConnected ? 1 : 0.6)
    }
}

struct BluetoothButton: View {
    @Binding var isBluetoothConnected: Bool
    
    var body: some View {
        Button(action: {
            isBluetoothConnected.toggle()
        }, label: {
            HStack {
                Image("bluetooth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                Text(isBluetoothConnected ? "Reveye device connected" : "No Reveye device connected")
                    .font(.system(size: 20, weight: .semibold))
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

let natureGreen = Color(red: 169/255, green: 233/255, blue: 76/255).opacity(0.6)


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
