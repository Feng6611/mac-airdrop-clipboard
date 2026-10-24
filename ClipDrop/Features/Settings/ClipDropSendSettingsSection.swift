import KikiSettings
import SwiftUI

struct ClipDropSendSettingsSection: View {
    @AppStorage(ClipDropPreferenceKeys.textFileFormat)
    private var textFileFormat = ClipDropSendPreferences.defaultTextFileFormat.rawValue
    @AppStorage(ClipDropPreferenceKeys.urlSendFormat)
    private var urlSendFormat = ClipDropSendPreferences.defaultURLSendFormat.rawValue
    @AppStorage(ClipDropPreferenceKeys.keepsFormatting)
    private var keepsFormatting = ClipDropSendPreferences.defaultKeepsFormatting
    @AppStorage(ClipDropPreferenceKeys.editBeforeSending)
    private var editBeforeSending = ClipDropSendPreferences.defaultEditBeforeSending

    var body: some View {
        Section("File Formats") {
            KikiSettingsHelperText("Links are sent directly by default. Choose a file format as a fallback.")

            KikiSettingsSegmentedPickerRow(
                "Copied text",
                selection: $textFileFormat,
                options: ClipDropTextFileFormat.allCases.map(\.rawValue),
                systemImage: "doc.text",
                controlWidth: 180
            ) { rawValue in
                ClipDropTextFileFormat(rawValue: rawValue)?.title ?? rawValue
            }

            KikiSettingsSegmentedPickerRow(
                "Copied link",
                selection: $urlSendFormat,
                options: ClipDropURLSendFormat.allCases.map(\.rawValue),
                systemImage: "link",
                controlWidth: 180
            ) { rawValue in
                ClipDropURLSendFormat(rawValue: rawValue)?.title ?? rawValue
            }
        }

        Section("Sending") {
            KikiSettingsToggleRow("Keep formatting", isOn: $keepsFormatting, systemImage: "textformat")
            KikiSettingsHelperText("Rich text is sent as RTF. RTFD attachments may be simplified.")
            KikiSettingsToggleRow("Edit before sending", isOn: $editBeforeSending, systemImage: "square.and.pencil")
            KikiSettingsHelperText("Open an editor before sending text or links.")
        }
    }
}
