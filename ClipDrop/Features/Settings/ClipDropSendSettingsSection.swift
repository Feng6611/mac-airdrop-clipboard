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
        Section {
            KikiSettingsSegmentedPickerRow(
                "Text",
                selection: $textFileFormat,
                options: ClipDropTextFileFormat.allCases.map(\.rawValue),
                systemImage: "doc.text",
                controlWidth: ClipDropDesignToken.Settings.segmentedWidth
            ) { rawValue in
                ClipDropTextFileFormat(rawValue: rawValue)?.title ?? rawValue
            }

            KikiSettingsSegmentedPickerRow(
                "Links",
                selection: $urlSendFormat,
                options: ClipDropURLSendFormat.allCases.map(\.rawValue),
                systemImage: "link",
                controlWidth: ClipDropDesignToken.Settings.segmentedWidth
            ) { rawValue in
                ClipDropURLSendFormat(rawValue: rawValue)?.title ?? rawValue
            }

            KikiSettingsToggleRow("Keep formatting", isOn: $keepsFormatting, systemImage: "textformat")
        } header: {
            Text("Send Format")
        } footer: {
            Text("Links open on the other device as links. Formatted text is sent as an RTF file.")
        }

        Section {
            KikiSettingsToggleRow("Edit before sending", isOn: $editBeforeSending, systemImage: "square.and.pencil")
        } header: {
            Text("Before Sending")
        } footer: {
            Text("An editor opens so you can change text or a link before the AirDrop sheet appears.")
        }
    }
}
