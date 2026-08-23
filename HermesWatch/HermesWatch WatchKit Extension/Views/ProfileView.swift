// ProfileView.swift
//
// Shows a scrollable list of Hermes profiles.
// Rotate the crown to scroll; press the crown to select and confirm.
// Selected profile becomes active for all Hermes interactions.

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileService: HermesProfileService
    
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Hermes Profiles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                // Scrollable profile list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(profileService.profiles.enumerated()), id: \.element.id) { index, profile in
                            ProfileRow(profile: profile, isSelected: index == selectedIndex)
                                .onTapGesture {
                                    selectProfile(at: index)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)
                
                // Confirm button
                if profileService.selectedProfile != nil {
                    Button(action: {
                        if let profile = profileService.selectedProfile {
                            profileService.activateProfile(profile)
                        }
                    }) {
                        Text("Activate \(profileService.selectedProfile?.name ?? "")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            profileService.connect()
        }
    }
    
    private func selectProfile(at index: Int) {
        selectedIndex = index
        if index < profileService.profiles.count {
            profileService.selectedProfile = profileService.profiles[index]
            HermesHapticService.shared.play(.approval)
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: HermesProfile
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // Profile icon
            Circle()
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 30, height: 30)
                .overlay {
                    Text(profile.name.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            
            // Profile name
            Text(profile.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Status indicator
            if profile.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if isSelected {
                Image(systemName: "circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(HermesProfileService())
            .previewDisplayName("Profile")
    }
}
