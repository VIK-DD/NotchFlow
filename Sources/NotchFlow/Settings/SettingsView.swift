//
//  SettingsView.swift
//  NotchFlow
//
//  Preferences UI. Built with custom "cards" (rather than `Form`, whose styling
//  is limited on Monterey) so it looks clean in both light and dark mode.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var registry: WidgetRegistry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                SettingsCard(title: "General") {
                    SettingsToggleRow(
                        title: "Launch at Login",
                        subtitle: "Open NotchFlow automatically when you sign in.",
                        isOn: $settings.launchAtLogin
                    )
                }

                SettingsCard(title: "Playback") {
                    statusRow
                    Divider().opacity(0.4)
                    SettingsToggleRow(
                        title: "Expand on Track Change",
                        subtitle: "Briefly reveal the player when a new song starts.",
                        isOn: $settings.expandOnTrackChange
                    )
                }

                SettingsCard(title: "Appearance") {
                    SettingsToggleRow(
                        title: "Tint from Album Art",
                        subtitle: "Use a colour sampled from the artwork as the accent.",
                        isOn: $settings.useAlbumAccent
                    )
                }

                SettingsCard(title: "Visibility") {
                    SettingsToggleRow(
                        title: "Always Show on Desktop",
                        subtitle: "Keep the notch visible when Finder is active.",
                        isOn: $settings.alwaysShowOnDesktop
                    )
                    Divider().opacity(0.4)
                    SettingsSliderRow(
                        title: "Idle Opacity",
                        subtitle: "How visible the notch is when inactive (\(Int(settings.idleOpacity))%).",
                        value: $settings.idleOpacity,
                        range: 0...100,
                        step: 1
                    )
                    Divider().opacity(0.4)
                    SettingsSliderRow(
                        title: "Auto-hide Delay",
                        subtitle: "Wait \(String(format: "%.1f", settings.hideDelay))s before fading out.",
                        value: $settings.hideDelay,
                        range: 0...30,
                        step: 0.5
                    )
                }

                footer
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 440, height: 740)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Sections

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.black, Color(white: 0.18)],
                        startPoint: .top, endPoint: .bottom))
                Image(systemName: "rectangle.topthird.inset.filled")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text("NotchFlow").font(.system(size: 20, weight: .bold, design: .rounded))
                Text("A Dynamic Island for your Mac · v\(AppInfo.version)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var statusRow: some View {
        let playing = registry.primaryWidget != nil
        return HStack(spacing: 10) {
            Circle()
                .fill(playing ? Color.green : Color.orange)
                .frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 1) {
                Text(playing ? "Media detected" : "Nothing playing")
                    .font(.system(size: 13, weight: .medium))
                Text(playing
                     ? "Showing the current Now Playing source."
                     : "Play in Spotify, Music, YouTube, or any app.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var footer: some View {
        HStack {
            Text("Tip: hover the notch to open the player.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Text("Quit NotchFlow")
            }
        }
    }
}

// MARK: - Building blocks

private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.6)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }
}

private struct SettingsSliderRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary)
            }
            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
        }
    }
}
