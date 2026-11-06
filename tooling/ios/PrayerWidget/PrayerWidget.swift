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
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let prayer = entry.prayer, let target = entry.target {
                Text(entry.isIqama ? "الإقامة · \(prayer.name)" : "الصلاة القادمة · \(prayer.name)")
                    .font(.caption).lineLimit(1)
                HStack {
                    Text(target, style: .time).font(.caption2)
                    Spacer(minLength: 2)
                    Text(timerInterval: entry.date...target, countsDown: true, showsHours: true)
                        .monospacedDigit().font(.caption2)
                }
            } else {
                Text("مواقيت الصلاة").font(.caption)
                Text("افتح التطبيق لتحديث المواقيت").font(.caption2)
            }
        }.environment(\.layoutDirection, .rightToLeft)
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
    var body: some View { VStack(spacing: 0) { Text(day).font(.headline); Text(month).font(.system(size: 9)).lineLimit(1).minimumScaleFactor(0.6) } }
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
            .supportedFamilies([.accessoryCircular])
    }
}

@main struct PrayerWidgets: WidgetBundle {
    var body: some Widget { PrayerWidget(); HijriWidget() }
}
