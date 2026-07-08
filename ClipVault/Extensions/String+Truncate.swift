import Foundation

extension String {
    func truncated(to length: Int, trailing: String = "…") -> String {
        guard count > length else { return self }
        return String(prefix(length)) + trailing
    }
}

extension Date {
    func relativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
