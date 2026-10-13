import LuxCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(ReaderSettingKey.orthography) private var orthography: Orthography = .modernLetterforms
    @AppStorage(ReaderSettingKey.showRubrics) private var showRubrics = true
    @AppStorage(ReaderSettingKey.showProvenance) private var showProvenance = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Letterforms", selection: $orthography) {
                        ForEach(Orthography.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    Toggle("Show rubrics", isOn: $showRubrics)
                    Toggle("Show source lines", isOn: $showProvenance)
                } header: {
                    Text("Reading")
                } footer: {
                    Text("Texts are kept as printed in 1762. Letterforms change only how the long s is shown.")
                }
                Section("About") {
                    Text("Lux is open source. The 1662 texts follow the Baskerville printing of 1762.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
