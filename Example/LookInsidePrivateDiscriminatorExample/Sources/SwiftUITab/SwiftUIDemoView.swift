import SwiftUI

struct SwiftUIDemoView: View {
    @State private var title = "Private discriminator"
    @State private var isEnabled = true
    @State private var confidence = 0.72
    @State private var retryCount = 2
    @State private var selectedMode = Mode.imported
    @State private var selectedDate = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("SwiftUI Primitive Views")
                    .font(.title2.weight(.semibold))

                TextField("Module name", text: $title)
                    .textFieldStyle(.roundedBorder)

                Toggle("Enable module", isOn: $isEnabled)
                    .toggleStyle(.switch)

                Picker("Mode", selection: $selectedMode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence")
                        .font(.subheadline.weight(.medium))
                    Slider(value: $confidence, in: 0...1)
                    ProgressView(value: confidence)
                }

                Stepper("Retries: \(retryCount)", value: $retryCount, in: 0...5)

                DatePicker("Updated", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])

                Button {
                    isEnabled.toggle()
                } label: {
                    Label("Toggle Preview State", systemImage: "bolt.horizontal")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("SwiftUI")
    }
}

private enum Mode: String, CaseIterable, Identifiable {
    case imported
    case autosaved
    case fallback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .imported:
            "Imported"
        case .autosaved:
            "Autosaved"
        case .fallback:
            "Fallback"
        }
    }
}
