//
//  ConnectView.swift
//  Reveye
//
//  Created by Ellen Carlsson on 2024-12-10.
//

import SwiftUI

struct ConnectView: View {
    var body: some View {
        VStack(spacing: 40) { // Add consistent spacing between elements
                    // Header Text
                    VStack(alignment: .center, spacing: 8) {
                        Text("Reveye")
                            .foregroundColor(textColor)
                            .font(.system(size: 32, weight: .bold)) // Use bold for the header
                            .multilineTextAlignment(.center)

                        Text("Connect to a Reveye Device to get started")
                            .foregroundColor(.gray)
                            .font(.system(size: 18)) // Slightly smaller and lighter font for secondary text
                            .multilineTextAlignment(.center)
                    }

                    // Connect Button
                    Button(action: {
                        // Your connection action here
                    }) {
                        Text("Connect")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 30)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(darkGray.ignoresSafeArea())
    }
}

#Preview {
    ConnectView()
}
