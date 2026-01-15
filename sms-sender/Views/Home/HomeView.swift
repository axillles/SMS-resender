//
//  HomeView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showDestinationPicker = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                Group{
                    if viewModel.rules.isEmpty{
                        emptyStateView
                    }
                    else{
                        rulesStateView
                    }
                }
                VStack{
                    Spacer()
                    Button(action: {
                        showDestinationPicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.black)
                            .background(Color.white.clipShape(Circle()))
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 30)
                }
            }.navigationTitle("Forward To")
             .navigationBarTitleDisplayMode(.inline)
             .navigationDestination(isPresented: $showDestinationPicker) {
                 DestinationPicker(homeViewModel: viewModel)
             }
             .navigationDestination(isPresented: $showSettings){
                 SettingsView()
             }             .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button(action: {
                         showSettings = true
                     }) {
                         Image(systemName: "gearshape.fill")
                             .resizable()
                             .foregroundColor(.black)
                             .frame(width: 30, height: 30)
                             .foregroundColor(.primary)
                     }
                 }
             }
        }
    }
    
    // Appears when No rules
    private var emptyStateView: some View {
        VStack(spacing: 20){
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.primary)
            Text("YOU HAVEN'T ADDED A DESTINATION YET")                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            Text("Add a destination to begin forwarding\nyour text messages.")
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }.padding()
    }
    
    // Appears when Some rules
    private var rulesStateView: some View {
        ScrollView{
            VStack(spacing: 12){
                ForEach(viewModel.rules) { rule in
                    RuleRow(rule : rule)
                    
                }
            }
            .padding()
        }
    }
}

struct RuleRow: View {
    let rule : ForwardingRule
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: rule.type.iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 45, height: 45)
                .background(Color.gray)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(rule.type.rawValue.capitalized)
                    .font(.headline)
                Text(rule.destination)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    HomeView()
}
