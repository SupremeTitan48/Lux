import SwiftUI

@main
struct LuxApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView().environment(model).readingStyleFromSettings()
        }
        #if os(macOS)
        Settings {
            SettingsView().environment(model).readingStyleFromSettings()
        }
        #endif
    }
}

struct RootView: View {
    var body: some View {
        #if os(macOS)
        MacRootView()
        #else
        TabView {
            TodayView().tabItem { Label("Today", systemImage: "sun.max") }
            CalendarView().tabItem { Label("Calendar", systemImage: "calendar") }
            LibraryView().tabItem { Label("Library", systemImage: "books.vertical") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        #endif
    }
}

#if os(macOS)
/// macOS: a sidebar of destinations, with Settings in the app menu.
struct MacRootView: View {
    enum Destination: String, CaseIterable, Identifiable {
        case today = "Today", calendar = "Calendar", library = "Library"
        var id: String { rawValue }
        var symbol: String { self == .today ? "sun.max" : self == .calendar ? "calendar" : "books.vertical" }
    }

    @State private var selection: Destination? = .today

    var body: some View {
        NavigationSplitView {
            List(Destination.allCases, selection: $selection) { destination in
                Label(destination.rawValue, systemImage: destination.symbol).tag(destination)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 200)
            .safeAreaInset(edge: .bottom) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
        } detail: {
            switch selection ?? .today {
            case .today: TodayView()
            case .calendar: CalendarView()
            case .library: LibraryView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Settings")
            }
        }
    }
}
#endif
