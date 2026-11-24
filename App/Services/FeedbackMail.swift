import UIKit

/// Feedback by email: the player's own mail app, no server, nothing sent unless they press Send.
/// The draft carries the app version and device so a report is useful without back-and-forth.
enum FeedbackMail {
    static let address = "hello@utkuacikgoz.com"

    /// `mood` is the face the player picked in "How's your gremlin?", if any.
    static func url(mood: String? = nil) -> URL? {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let subject = ["Little Menace feedback", mood].compactMap { $0 }.joined(separator: " ")
        let body = "\n\n\n—\nLittle Menace \(version) (\(build)) · \(deviceModel) · iOS \(UIDevice.current.systemVersion)"
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = address
        c.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: body)]
        return c.url
    }

    /// The hardware identifier, such as "iPhone17,2".
    private static var deviceModel: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
