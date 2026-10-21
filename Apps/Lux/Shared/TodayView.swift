import LuxCore
import LuxDesignSystem
import SwiftUI

/// Today: what the day is, and the way into its offices.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let date = model.today
        let colors = LuxColors(scheme)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(date.formatted).font(TypeRole.caption.font).foregroundStyle(colors.textSecondary)
                        if let day = model.describe(date) {
                            Text(day.title).font(TypeRole.title.font).foregroundStyle(colors.textPrimary)
                        }
                    }
                    offices(suggested: model.suggestedOffice())
                    if let error = model.loadError {
                        Text(error).font(TypeRole.caption.font).foregroundStyle(colors.notice)
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Today")
            .navigationDestination(for: Office.self) { office in
                ReaderView(office: office, date: date)
            }
        }
    }

    /// The two offices as cards: side by side where there is room.
    private func offices(suggested: Office) -> some View {
        let cards = ForEach([Office.morningPrayer, .eveningPrayer], id: \.self) { office in
            NavigationLink(value: office) {
                OfficeCard(office: office, isSuggested: office == suggested)
            }
            .buttonStyle(.plain)
        }
        #if os(watchOS)
        return VStack(spacing: Spacing.s) { cards }
        #else
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.m) { cards }.frame(minWidth: 520)
            VStack(spacing: Spacing.m) { cards }
        }
        #endif
    }
}

/// A daily office as a card under its sky: dawn for Morning Prayer, dusk for
/// Evening Prayer.
private struct OfficeCard: View {
    let office: Office
    let isSuggested: Bool
    @Environment(\.colorScheme) private var scheme

    private var sky: Sky.Gradient {
        office == .morningPrayer ? Sky.dawn(dark: scheme == .dark) : Sky.dusk(dark: scheme == .dark)
    }

    var body: some View {
        let text = sky.text.color
        // The title sits at the top of the sky, where its contrast is
        // tested (SkyTests); the sun sits low, on the horizon.
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(office.displayName)
                    .font(TypeRole.heading.font)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if isSuggested {
                    Text("Now")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(text.opacity(0.16)))
                }
            }
            Spacer(minLength: Spacing.l)
            Image(systemName: office == .morningPrayer ? "sunrise.fill" : "sunset.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.title2)
                .accessibilityHidden(true)
        }
        .foregroundStyle(text)
        .padding(Spacing.m)
        #if os(watchOS)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        #else
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        #endif
        .background(sky.linear, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.primary.opacity(scheme == .dark ? 0.12 : 0.06)))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isSuggested ? "\(office.displayName), the office for now" : office.displayName)
        .accessibilityAddTraits(.isButton)
    }
}
