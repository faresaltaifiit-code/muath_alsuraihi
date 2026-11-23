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
    var previous: Prayer? = nil
}

private func arabicPrayerTime(_ date: Date) -> String {
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    let hour = components.hour ?? 0
    let minute = components.minute ?? 0
    let displayHour = hour % 12 == 0 ? 12 : hour % 12
    let digits = String(format: "%d:%02d", locale: Locale(identifier: "en_US_POSIX"), displayHour, minute)
    return "\u{2066}\(digits)\u{2069} \(hour < 12 ? "ص" : "م")"
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
            if date < adhan { return PrayerEntry(date: date, prayer: prayer, target: adhan, isIqama: false, previous: prayers.last { $0.adhan < date.timeIntervalSince1970 }) }
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
                    Text((entry.isIqama ? "إقامة " : "أذان ") + arabicPrayerTime(Date(timeIntervalSince1970: entry.isIqama ? prayer.iqama : prayer.adhan)))
                        .font(.caption2).lineLimit(1).environment(\.layoutDirection, .rightToLeft)
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

private struct PrayerCountdownView: View {
    let entry: PrayerEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let prayer = entry.prayer, let target = entry.target, target > entry.date {
            if family == .accessoryCircular {
                VStack(spacing: 1) {
                    Text(entry.isIqama ? "إقامة" : "أذان").font(.caption2)
                    Text(timerInterval: entry.date...target, countsDown: true, showsHours: true)
                        .monospacedDigit().font(.caption2).lineLimit(1).minimumScaleFactor(0.5)
                    Text(prayer.name).font(.caption2).lineLimit(1)
                }
            } else {
                VStack(spacing: 1) {
                    Text("\u{2067}\(entry.isIqama ? "إقامة" : "أذان") \(prayer.name)\u{2069}")
                        .font(.system(size: 13, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                        .environment(\.layoutDirection, .rightToLeft)
                    Text(timerInterval: entry.date...target, countsDown: true, showsHours: true)
                        .monospacedDigit().font(.system(size: 24, weight: .bold)).lineLimit(1).minimumScaleFactor(0.55)
                        .environment(\.layoutDirection, .leftToRight)
                    Text(arabicPrayerTime(target)).font(.system(size: 11)).lineLimit(1)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        } else {
            Text("افتح التطبيق لتحديث المواقيت").font(.caption2)
        }
    }
}

private struct DuaEntry: TimelineEntry {
    let date: Date
    let text: String
    let source: String
}

private struct DuaProvider: TimelineProvider {
    // Quranic excerpts, verified against quran.ksu.edu.sa.
    private let duas = [
        ("رَبِّ زِدْنِي عِلْمًا", "طه: ١١٤"),
        ("رَبِّ اشْرَحْ لِي صَدْرِي", "طه: ٢٥"),
        ("رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ", "نوح: ٢٨"),
        ("رَبَّنَا تَقَبَّلْ مِنَّا", "البقرة: ١٢٧"),
        ("رَبِّ اغْفِرْ وَارْحَمْ", "المؤمنون: ١١٨"),
        ("رَبَّنَا لَا تُزِغْ قُلُوبَنَا", "آل عمران: ٨"),
        ("رَبِّ لَا تَذَرْنِي فَرْدًا", "الأنبياء: ٨٩"),
        ("وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا", "الفرقان: ٧٤"),
    ]
    private func makeEntry(_ date: Date) -> DuaEntry {
        let hour = Int(date.timeIntervalSince1970 / 3600)
        let index = ((hour % duas.count) + duas.count) % duas.count
        return DuaEntry(date: date, text: duas[index].0, source: duas[index].1)
    }
    func placeholder(in context: Context) -> DuaEntry { makeEntry(.now) }
    func getSnapshot(in context: Context, completion: @escaping (DuaEntry) -> Void) {
        completion(makeEntry(.now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DuaEntry>) -> Void) {
        let now = Date()
        let nextHour = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / 3600) + 1) * 3600)
        let entries = [makeEntry(now)] + (0..<24).map { makeEntry(nextHour.addingTimeInterval(Double($0) * 3600)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private struct DuaWidgetView: View {
    let entry: DuaEntry
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(entry.text).font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.65)
            Text(entry.source).font(.caption2).lineLimit(1)
        }
        .environment(\.layoutDirection, .rightToLeft)
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

struct PrayerCountdownWidget: Widget {
    let kind = "PrayerCountdownWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PrayerCountdownView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { PrayerCountdownView(entry: entry).padding() }
        }.configurationDisplayName("الصلاة القادمة - الوقت الكبير")
            .description("الوقت المتبقي للأذان أو الإقامة")
            .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

struct DuaWidget: Widget {
    let kind = "DuaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DuaProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                DuaWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { DuaWidgetView(entry: entry).padding() }
        }.configurationDisplayName("دعاء متجدد").description("أدعية قصيرة من القرآن الكريم")
            .supportedFamilies([.accessoryRectangular])
    }
}

// The complete wording is kept in each entry, including longer selections.
private enum RotatingContent {
    case supplications, remembrance, verses

    var items: [(String, String)] {
        switch self {
        case .supplications:
            return [
                ("اللهم اغفر لي، وارحمني، واهدني، وعافني، وارزقني", "صحيح مسلم"),
                ("اللهم إني أسألك الهدى، والتقى، والعفاف، والغنى", "صحيح مسلم"),
                ("يا مقلب القلوب، ثبت قلبي على دينك", "الترمذي"),
                ("اللهم إنك عفو تحب العفو، فاعف عني", "الترمذي"),
                ("اللهم أعني على ذكرك، وشكرك، وحسن عبادتك", "أبو داود والنسائي"),
                ("اللهم إني أسألك العفو والعافية في الدنيا والآخرة", "أبو داود وابن ماجه • جزء من دعاء"),
                ("اللهم إني أعوذ بك من الهم والحزن، والعجز والكسل، والجبن والبخل، وضَلَع الدَّين وغَلَبة الرجال", "صحيح البخاري")
            ]
        case .remembrance:
            return [
                ("سبحان الله وبحمده", "متفق عليه"),
                ("سبحان الله العظيم", "متفق عليه"),
                ("لا حول ولا قوة إلا بالله", "متفق عليه"),
                ("أستغفر الله وأتوب إليه", "صحيح البخاري"),
                ("اللهم صلِّ على محمد", "الصلاة على النبي ﷺ")
            ]
        case .verses:
            return [
                ("إِنَّ مَعَ الْعُسْرِ يُسْرًا", "الشرح: ٦"),
                ("وَاللَّهُ خَيْرُ الرَّازِقِينَ", "الجمعة: ١١ • مقتطف"),
                ("وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ", "الحديد: ٤ • مقتطف"),
                ("وَكَانَ اللَّهُ غَفُورًا رَحِيمًا", "النساء: ٩٦ • مقتطف")
            ]
        }
    }
}

private struct SelectedContentProvider: TimelineProvider {
    let content: RotatingContent
    private func entry(_ date: Date) -> DuaEntry {
        let items = content.items
        let hour = Int(date.timeIntervalSince1970 / 3600)
        let item = items[((hour % items.count) + items.count) % items.count]
        return DuaEntry(date: date, text: item.0, source: item.1)
    }
    func placeholder(in context: Context) -> DuaEntry { entry(.now) }
    func getSnapshot(in context: Context, completion: @escaping (DuaEntry) -> Void) {
        completion(entry(.now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DuaEntry>) -> Void) {
        let now = Date()
        let nextHour = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / 3600) + 1) * 3600)
        let entries = [entry(now)] + (0..<24).map { entry(nextHour.addingTimeInterval(Double($0) * 3600)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private struct SelectedContentView: View {
    let entry: DuaEntry
    var body: some View {
        VStack(spacing: 1) {
            Text(entry.text)
                .font(.system(size: entry.text.count > 55 ? 11 : 15, weight: .semibold))
                .multilineTextAlignment(.center).lineLimit(4).minimumScaleFactor(0.55)
            Text(entry.source).font(.system(size: 9)).lineLimit(1).minimumScaleFactor(0.7)
        }.environment(\.layoutDirection, .rightToLeft)
    }
}

struct SelectedDuaWidget: Widget {
    let kind = "SelectedDuaWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SelectedContentProvider(content: .supplications)) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                SelectedContentView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { SelectedContentView(entry: entry).padding() }
        }.configurationDisplayName("أدعية مختارة").description("أدعية نبوية متجددة")
            .supportedFamilies([.accessoryRectangular])
    }
}

struct DhikrWidget: Widget {
    let kind = "DhikrWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SelectedContentProvider(content: .remembrance)) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                SelectedContentView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { SelectedContentView(entry: entry).padding() }
        }.configurationDisplayName("أذكار قصيرة").description("أذكار مختارة متجددة")
            .supportedFamilies([.accessoryRectangular])
    }
}

struct VerseWidget: Widget {
    let kind = "VerseWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SelectedContentProvider(content: .verses)) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                SelectedContentView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { SelectedContentView(entry: entry).padding() }
        }.configurationDisplayName("آيات قرآنية").description("آيات ومقتطفات قرآنية مختارة")
            .supportedFamilies([.accessoryRectangular])
    }
}

private struct PrayerProgressView: View {
    let entry: PrayerEntry
    var body: some View {
        if let prayer = entry.prayer, let target = entry.target, target > entry.date {
            VStack(spacing: 1) {
                HStack(spacing: 3) {
                    Text(prayer.name).font(.system(size: 16, weight: .bold)).lineLimit(1)
                    Spacer(minLength: 2)
                    Text(timerInterval: entry.date...target, countsDown: true, showsHours: true)
                        .monospacedDigit().font(.system(size: 19, weight: .bold))
                        .lineLimit(1).minimumScaleFactor(0.65)
                        .environment(\.layoutDirection, .leftToRight)
                }
                if entry.isIqama {
                    ProgressView(timerInterval: Date(timeIntervalSince1970: prayer.adhan)...target, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                    Text("المتبقي للإقامة • \(arabicPrayerTime(target))")
                        .font(.system(size: 10)).lineLimit(1).minimumScaleFactor(0.65)
                } else {
                    if let previous = entry.previous, previous.adhan < target.timeIntervalSince1970 {
                        ProgressView(timerInterval: Date(timeIntervalSince1970: previous.adhan)...target, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                    }
                    Text("المتبقي للأذان").font(.system(size: 9)).lineLimit(1)
                    Text("\(prayer.name): \(arabicPrayerTime(target))")
                        .font(.system(size: 10)).lineLimit(1).minimumScaleFactor(0.7)
                }
            }.environment(\.layoutDirection, .rightToLeft)
        } else { Text("افتح التطبيق لتحديث المواقيت").font(.caption2) }
    }
}

struct PrayerProgressWidget: Widget {
    let kind = "PrayerProgressWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PrayerProgressView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { PrayerProgressView(entry: entry).padding() }
        }.configurationDisplayName("الصلاة السابقة والقادمة").description("شريط للوقت المتبقي والأذان والإقامة")
            .supportedFamilies([.accessoryRectangular])
    }
}

private struct PrayerTimesView: View {
    let entry: PrayerEntry
    var body: some View {
        if let prayer = entry.prayer {
            VStack(spacing: 1) {
                Text(prayer.name).font(.caption).lineLimit(1)
                HStack {
                    VStack {
                        Text("الأذان").font(.system(size: 10))
                        Text(arabicPrayerTime(Date(timeIntervalSince1970: prayer.adhan)))
                            .font(.system(size: 16, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
                    }
                    Spacer(minLength: 2)
                    VStack {
                        Text("الإقامة").font(.system(size: 10))
                        Text(arabicPrayerTime(Date(timeIntervalSince1970: prayer.iqama)))
                            .font(.system(size: 16, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
                    }
                }
            }.environment(\.layoutDirection, .rightToLeft)
        } else { Text("افتح التطبيق لتحديث المواقيت").font(.caption2) }
    }
}

struct PrayerTimesWidget: Widget {
    let kind = "PrayerTimesWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PrayerTimesView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else { PrayerTimesView(entry: entry).padding() }
        }.configurationDisplayName("الأذان والإقامة").description("وقت الأذان والإقامة التقريبي")
            .supportedFamilies([.accessoryRectangular])
    }
}

@main struct PrayerWidgets: WidgetBundle {
    var body: some Widget {
        PrayerWidget(); HijriWidget(); PrayerCountdownWidget(); DuaWidget()
        SelectedDuaWidget(); DhikrWidget(); VerseWidget(); PrayerProgressWidget(); PrayerTimesWidget()
    }
}
