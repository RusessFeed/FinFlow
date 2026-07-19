import Foundation

struct ReceiptScanResult: Equatable {
    let merchant: String?
    let total: Decimal?
    let date: Date?
    let recognizedLines: [String]
}

enum ReceiptParser {
    static func parse(lines: [String], calendar: Calendar = .current) -> ReceiptScanResult {
        let cleanLines = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return ReceiptScanResult(
            merchant: merchant(from: cleanLines),
            total: total(from: cleanLines),
            date: receiptDate(from: cleanLines, calendar: calendar),
            recognizedLines: cleanLines
        )
    }

    private static func merchant(from lines: [String]) -> String? {
        lines.first { line in
            let hasLetter = line.rangeOfCharacter(from: .letters) != nil
            let digitCount = line.filter(\.isNumber).count
            let lowercased = line.lowercased()
            return hasLetter
                && digitCount < 3
                && !lowercased.contains("receipt")
                && !lowercased.contains("invoice")
                && !lowercased.contains("total")
        }
    }

    private static func total(from lines: [String]) -> Decimal? {
        let priorityLines = lines.filter { line in
            let value = line.lowercased()
            return value.contains("grand total")
                || value.contains("amount due")
                || value.contains("total")
                || value.contains("итого")
                || value.contains("сумма")
        }
        let priorityValues = priorityLines.flatMap(amounts(in:))
        if let value = priorityValues.last { return value }
        return lines.flatMap(amounts(in:)).max()
    }

    private static func amounts(in line: String) -> [Decimal] {
        let pattern = #"(?:[$€£₽]\s*)?(\d{1,3}(?:(?:[\s,]\d{3})+)?(?:[.,]\d{2})|\d+[.,]\d{2})"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(line.startIndex..., in: line)
        return expression.matches(in: line, range: range).compactMap { match in
            guard let valueRange = Range(match.range(at: 1), in: line) else { return nil }
            return decimal(from: String(line[valueRange]))
        }
    }

    private static func decimal(from value: String) -> Decimal? {
        var normalized = value.replacingOccurrences(of: " ", with: "")
        let lastComma = normalized.lastIndex(of: ",")
        let lastDot = normalized.lastIndex(of: ".")

        if let lastComma, let lastDot {
            if lastComma > lastDot {
                normalized = normalized.replacingOccurrences(of: ".", with: "")
                normalized = normalized.replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = normalized.replacingOccurrences(of: ",", with: "")
            }
        } else if lastComma != nil {
            normalized = normalized.replacingOccurrences(of: ",", with: ".")
        }
        return Decimal(string: normalized)
    }

    private static func receiptDate(from lines: [String], calendar: Calendar) -> Date? {
        let patterns = [
            (#"\b\d{4}[-/.]\d{1,2}[-/.]\d{1,2}\b"#, ["yyyy-MM-dd", "yyyy/MM/dd", "yyyy.MM.dd"]),
            (#"\b\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}\b"#, ["dd-MM-yyyy", "dd/MM/yyyy", "dd.MM.yyyy", "MM/dd/yyyy", "dd/MM/yy"])
        ]

        for line in lines {
            for (pattern, formats) in patterns {
                guard let expression = try? NSRegularExpression(pattern: pattern) else { continue }
                let range = NSRange(line.startIndex..., in: line)
                guard let match = expression.firstMatch(in: line, range: range),
                      let dateRange = Range(match.range, in: line) else { continue }
                let value = String(line[dateRange])
                for format in formats {
                    let formatter = DateFormatter()
                    formatter.calendar = calendar
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = calendar.timeZone
                    formatter.dateFormat = format
                    if let date = formatter.date(from: value) { return date }
                }
            }
        }
        return nil
    }
}
