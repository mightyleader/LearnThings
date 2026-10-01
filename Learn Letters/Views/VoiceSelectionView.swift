//
//  VoiceSelectionView.swift
//  Learn Letters
//
//  Created by Rob Stearn on 25/09/2026.
//

import SwiftUI

struct VoiceSelectionView: View {
    @ObservedObject var speaker: LetterSpeaker
    @Binding var selectedVoiceIdentifier: String
    var onDone: () -> Void = {}

    var body: some View {
        List {
            Section {
                if let selected = speaker.voiceOption(for: selectedVoiceIdentifier) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current voice")
                            .font(.headline)
                        Text(selected.name)
                            .font(.title3.weight(.semibold))
                        Text(selected.subtitle)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("No voice selected yet.")
                }
            }

            Section {
                Text("Tap the speaker icon to hear each voice. Availability and sound depend on the voices installed on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(speaker.voiceOptions) { voice in
                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            selectedVoiceIdentifier = voice.identifier
                            speaker.selectVoice(identifier: voice.identifier)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(voice.name)
                                        .foregroundStyle(.primary)
                                    Text(voice.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if voice.identifier == speaker.recommendedVoiceIdentifier {
                                    Text("Recommended")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }

                                if selectedVoiceIdentifier == voice.identifier {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        Button {
                            speaker.previewVoice(identifier: voice.identifier)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Play sample for \(voice.name)")
                    }
                }
            } header: {
                Text("Available on this device (\(speaker.voiceOptions.count))")
            }
        }
        .navigationTitle("Voice")
        .onExitCommand(perform: onDone)
    }
}
