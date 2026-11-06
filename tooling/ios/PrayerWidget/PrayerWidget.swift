import SwiftUI
import WidgetKit

private let appGroup = "group.com.faresaltaifi.muathalsuraihi.widgets"

private struct Prayer: Decodable {
    let name: String
    let adhan: Double
    let iqama: Double
}

private struct PrayerSnapshot: Decodable {
    let prayers: [Prayer]
}

private struct PrayerEntry: TimelineEntry {
    let date: Date
    let prayer: Prayer?
    let target: Date?
    let isIqama: Bool
}

private struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: .now, prayer: nil, target: nil, isIqama: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(entry(at: .now, prayers: load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let prayers = load()
        let now = Date()
        var dates = [now]
        for prayer in prayers {
            let adhan = Date(timeIntervalSince1970: prayer.adhan)
            let iqama = Date(timeIntervalSince1970: prayer.iqama)
            if adhan > now { dates.append(adhan) }
            if iqama > now { dates.append(iqama) }
        }
        let entries = dates.sorted().map { entry(at: $0, prayers: prayers) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
    }

    private func load() -> [Prayer] {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: "prayer_widget_snapshot"),
              let snapshot = try? JSONDecoder().decode(PrayerSnapshot.self, from: data) else { return [] }
        return snapshot.prayers.sorted { $0.adhan < $1.adhan }
    }

    private func entry(at date: Date, prayers: [Prayer]) -> PrayerEntry {
        for prayer in prayers {
            let adhan = Date(timeIntervalSince1970: prayer.adhan)
            let iqama = Date(timeIntervalSince1970: prayer.iqama)
            if date < adhan { return PrayerEntry(date: date, prayer: prayer, target: adhan, isIqama: false) }
            if date < iqama { return PrayerEntry(date: date, prayer: prayer, target: iqama, isIqama: true) }
        }
        return PrayerEntry(date: date, prayer: nil, target: nil, isIqama: false)
    }
}

private struct PrayerWidgetView: View {
    let entry: PrayerEntry

    private func symbol(for name: String) -> String {
        switch name {
        case "الفجر": return "sunrise.fill"
        case "الظهر": return "sun.max.fill"
        case "العصر": return "sun.haze.fill"
        case "المغرب": return "sunset.fill"
        case "العشاء": return "moon.stars.fill"
        default: return "clock"
        }
    }

    private func prayerTime(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, minute, hour < 12 ? "ص" : "م")
    }

    var body: some View {
        if let prayer = entry.prayer, let target = entry.target {
            HStack(spacing: 6) {
                Image(systemName: symbol(for: prayer.name))
                    .font(.system(size: 23))
                    .frame(width: 30)
                    .accessibilityHidden(true)
                Rectangle().fill(.primary.opacity(0.25)).frame(width: 1)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(prayer.name).font(.headline).lineLimit(1)
                    Text("أذان " + prayerTime(prayer.adhan))
                        .font(.caption2).lineLimit(1)
                    HStack(spacing: 3) {
                        Text(timerInterval: entry.date...target, countsDown: true, showsHours: true)
                            .monospacedDigit()
                            .environment(\.layoutDirection, .leftToRight)
                        Text(entry.isIqama ? "للإقامة" : "متبقّي")
                    }
                    .font(.caption2).lineLimit(1).minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .environment(\.layoutDirection, .leftToRight)
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                Text("مواقيت الصلاة").font(.caption)
                Text("افتح التطبيق لتحديث المواقيت").font(.caption2)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

private struct HijriEntry: TimelineEntry { let date: Date }
private struct HijriProvider: TimelineProvider {
    func placeholder(in context: Context) -> HijriEntry { HijriEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (HijriEntry) -> Void) { completion(HijriEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HijriEntry>) -> Void) {
        let now = Date()
        let next = Calendar.current.startOfDay(for: now).addingTimeInterval(86400)
        completion(Timeline(entries: [HijriEntry(date: now)], policy: .after(next)))
    }
}

private struct HijriWidgetView: View {
    let entry: HijriEntry
    @Environment(\.widgetFamily) private var family
    private var day: String {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.locale = Locale(identifier: "ar_SA"); f.dateFormat = "d"
        return f.string(from: entry.date)
    }
    private var month: String {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.locale = Locale(identifier: "ar_SA"); f.dateFormat = "MMM"
        return f.string(from: entry.date)
    }
    var body: some View {
        if family == .accessoryInline {
            Text("\(day) \(month)")
        } else {
            VStack(spacing: 0) {
                Text(day).font(.headline)
                Text(month).font(.system(size: 9)).lineLimit(1).minimumScaleFactor(0.6)
            }
        }
    }
}

struct PrayerWidget: Widget {
    let kind = "PrayerWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PrayerWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { PrayerWidgetView(entry: entry).padding() }
        }.configurationDisplayName("الصلاة القادمة").description("وقت الأذان والإقامة")
            .supportedFamilies([.accessoryRectangular])
    }
}

struct HijriWidget: Widget {
    let kind = "HijriWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HijriProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                HijriWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { HijriWidgetView(entry: entry).padding() }
        }.configurationDisplayName("التاريخ الهجري").description("تاريخ أم القرى")
            .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

@main struct PrayerWidgets: WidgetBundle {
    var body: some Widget { PrayerWidget(); HijriWidget() }
}
