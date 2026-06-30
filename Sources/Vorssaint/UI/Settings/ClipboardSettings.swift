// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct ClipboardSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var history = ClipboardHistoryService.shared
    @ObservedObject private var permissions = Permissions.shared
    @AppStorage(DefaultsKey.clipboardHistoryEnabled) private var enabled = false
    @AppStorage(DefaultsKey.clipboardHistoryLimit) private var limit = 50
    @AppStorage(DefaultsKey.clipboardHistorySkipSensitive) private var skipSensitive = true
    @AppStorage(DefaultsKey.clipboardHistoryShortcutEnabled) private var shortcutEnabled = true
    @AppStorage(DefaultsKey.clipboardHistoryActivationMode)
    private var activationModeRaw = ClipboardHistoryActivationMode.shortcut.rawValue
    @AppStorage(DefaultsKey.panelUtilityClipboard) private var showInPanel = true

    private var text: ClipboardFeatureStrings {
        FeatureStrings.clipboard(l10n.language)
    }

    var body: some View {
        Form {
            Section {
                Toggle(text.enable, isOn: $enabled)
                    .onChange(of: enabled) { _, _ in
                        ClipboardHistoryService.shared.syncWithPreferences()
                    }
                Text(text.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(text.localNote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if enabled, history.isRunning {
                    Label(text.active, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Section {
                Toggle(text.skipSensitive, isOn: $skipSensitive)
                Text(text.skipSensitiveCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker(text.limit, selection: $limit) {
                    ForEach(Defaults.allowedClipboardHistoryLimits, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                Toggle(text.showInPanel, isOn: $showInPanel)
            }

            Section(text.activation) {
                Toggle(text.activation, isOn: $shortcutEnabled)
                    .onChange(of: shortcutEnabled) { _, _ in
                        ClipboardHistoryService.shared.syncHotkey()
                    }
                Picker(text.activationMode, selection: $activationModeRaw) {
                    Text(text.activationModeShortcut).tag(ClipboardHistoryActivationMode.shortcut.rawValue)
                    Text(text.activationModeDoubleControl).tag(ClipboardHistoryActivationMode.doubleControl.rawValue)
                }
                .disabled(!enabled || !shortcutEnabled)
                .onChange(of: activationModeRaw) { _, value in
                    activationModeRaw = Defaults.sanitizedClipboardHistoryActivationMode(value).rawValue
                    ClipboardHistoryService.shared.syncHotkey()
                }

                if activationMode == .shortcut {
                    ShortcutPreferenceRow(role: .clipboard,
                                          isEnabled: enabled && shortcutEnabled,
                                          label: text.shortcut,
                                          additionalConflict: WindowLayoutService.shared.shortcutConflictTitle) {
                        ClipboardHistoryService.shared.syncHotkey()
                    }
                    if enabled, shortcutEnabled, history.shortcutRegistrationFailed {
                        Text(l10n.s.shortcutUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(text.shortcutCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    if enabled, shortcutEnabled, history.doubleControlNeedsAccessibility || !permissions.accessibility {
                        Text(text.doubleControlPermission)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if enabled, shortcutEnabled, history.doubleControlRegistrationFailed {
                        Text(text.doubleControlUnavailable)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text(text.doubleControlCaption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button {
                    ClipboardHistoryService.shared.showHistoryWindow()
                } label: {
                    Label(text.openNow, systemImage: "doc.on.clipboard")
                }
                .disabled(history.entries.isEmpty)
            }

            Section {
                HStack {
                    Text("\(history.pinnedEntries.count)")
                    Text(text.pinned)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(history.recentEntries.count)")
                    Text(text.recent)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(text.clearRecent) {
                        history.clearRecent()
                    }
                    .disabled(history.recentEntries.isEmpty)
                    Button(text.clearAll) {
                        history.clearAll()
                    }
                    .disabled(history.recentEntries.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            limit = Defaults.sanitizedClipboardHistoryLimit(limit)
            activationModeRaw = Defaults.sanitizedClipboardHistoryActivationMode(activationModeRaw).rawValue
        }
        .onChange(of: limit) { _, value in
            limit = Defaults.sanitizedClipboardHistoryLimit(value)
        }
    }

    private var activationMode: ClipboardHistoryActivationMode {
        Defaults.sanitizedClipboardHistoryActivationMode(activationModeRaw)
    }
}
