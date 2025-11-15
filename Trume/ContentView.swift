//
//  ContentView.swift
//  Trume
//
//  Created by CM on 2025/11/2.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView(showSplash: $showSplash)
            } else {
                NavigationView {
                    HomeView(viewModel: viewModel)
                        #if os(iOS)
                        .navigationBarHidden(true)
                        #endif
                }
                #if os(iOS)
                .navigationViewStyle(StackNavigationViewStyle())
                #endif
            }
        }
        .toast(viewModel: viewModel)
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
