//
//  HomeView.swift
//  sms-sender
//
//  Created by Артем Гаврилов on 9.01.26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var registrationViewModel: RegistrationViewModel
    @State private var showDestinationPicker = false
    @State private var showSettings = false
    @State private var hasForwardedFirstMessage = StorageService.hasForwardedFirstMessage()
    @State private var editingRule: ForwardingRule?
    
    var body: some View {
        NavigationStack{
            ZStack{
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    if !hasForwardedFirstMessage {
                        setupWarningBanner
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    Spacer()
                    Group{
                        if viewModel.rules.isEmpty{
                            emptyStateView
                        }
                        else{
                            rulesStateView
                        }
                    }
                    Spacer()
                }
                VStack{
                    Spacer()
                    Button(action: {
                        showDestinationPicker = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
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
             }
             .sheet(item: $editingRule) { rule in
                 NavigationStack {
                     SetupRuleView(
                         destinationType: rule.type,
                         homeViewModel: viewModel,
                         editingRule: rule
                     )
                     .environmentObject(registrationViewModel)
                 }
             }
             .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button(action: {
                         showSettings = true
                     }) {
                         Image(systemName: "gearshape.fill")
                             .resizable()
                             .frame(width: 30, height: 30)
                             .foregroundColor(.secondary)
                     }
                 }
             }
             .onReceive(NotificationCenter.default.publisher(for: .firstMessageForwarded)) { _ in
                 hasForwardedFirstMessage = true
             }
             .onAppear {
                 hasForwardedFirstMessage = StorageService.hasForwardedFirstMessage()
                 viewModel.loadRules()
             }
        }
    }
    
    // MARK: - Setup Warning Banner
    private var setupWarningBanner: some View {
        SetupWarningBannerView()
    }
    
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
    
    private var rulesStateView: some View {
        ScrollView{
            VStack(spacing: 12){
                ForEach(viewModel.rules) { rule in
                    RuleRow(rule: rule) {
                        editingRule = rule
                    }
                }
            }
            .padding()
        }
    }
}

private struct SetupWarningBannerView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var bannerBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.22, green: 0.2, blue: 0.18)
            : Color(red: 0.98, green: 0.96, blue: 0.94)
    }

    private var bannerBorder: Color {
        colorScheme == .dark
            ? Color(red: 0.45, green: 0.38, blue: 0.3)
            : Color(red: 0.85, green: 0.75, blue: 0.65)
    }

    private var warningIconColor: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.75, blue: 0.45)
            : Color(red: 0.8, green: 0.6, blue: 0.4)
    }

    var body: some View {
        Button(action: {
            NotificationCenter.default.post(name: .showOnboarding, object: nil)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Finish Setup to Start Forwarding")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(warningIconColor)
                        .font(.system(size: 20))

                    Text("This warning will disappear after you forward your first message.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(bannerBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(bannerBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RuleRow: View {
    let rule: ForwardingRule
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                        .foregroundColor(.primary)
                    Text(rule.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}
