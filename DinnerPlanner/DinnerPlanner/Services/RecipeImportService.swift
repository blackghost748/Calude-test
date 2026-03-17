import Foundation

/// Parses recipe data from a URL (JSON-LD schema.org/Recipe) or free-text paste.
struct RecipeImportService {

    // MARK: - URL Import

    /// Fetches a webpage and attempts to extract a Recipe from JSON-LD structured data.
    static func importFromURL(_ urlString: String) async throws -> RecipeImportResult {
        guard let url = URL(string: urlString) else {
            throw ImportError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ImportError.encodingError
        }

        if let result = extractJSONLD(from: html) {
            return result
        }
        // Fallback: return raw text for manual editing
        throw ImportError.noStructuredDataFound
    }

    private static func extractJSONLD(from html: String) -> RecipeImportResult? {
        // Find all <script type="application/ld+json"> blocks
        let pattern = #"<script[^>]*type=["\']application/ld\+json["\'][^>]*>([\s\S]*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)

        for match in matches {
            guard let jsonRange = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[jsonRange])
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            else { continue }

            if let result = parseSchemaRecipe(json) { return result }

            // Handle @graph arrays
            if let graph = json["@graph"] as? [[String: Any]] {
                for node in graph {
                    if let result = parseSchemaRecipe(node) { return result }
                }
            }
        }
        return nil
    }

    private static func parseSchemaRecipe(_ json: [String: Any]) -> RecipeImportResult? {
        let type = json["@type"] as? String ?? ""
        guard type.lowercased().contains("recipe") else { return nil }

        let name = json["name"] as? String ?? "Importiertes Rezept"
        let yieldRaw: String
        if let s = json["recipeYield"] as? String { yieldRaw = s }
        else if let n = json["recipeYield"] as? Int { yieldRaw = String(n) }
        else { yieldRaw = "" }
        let servings = Int(yieldRaw.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 4

        var ingredients: [RawIngredient] = []
        if let rawList = json["recipeIngredient"] as? [String] {
            ingredients = rawList.compactMap { parseIngredientLine($0) }
        }

        return RecipeImportResult(name: name, defaultServings: servings, ingredients: ingredients)
    }

    // MARK: - Text Paste Import

    /// Parses free-text (one ingredient per line) into structured ingredients.
    static func importFromText(_ text: String, recipeName: String) -> RecipeImportResult {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let ingredients = lines.compactMap { parseIngredientLine($0) }
        return RecipeImportResult(name: recipeName, defaultServings: 4, ingredients: ingredients)
    }

    // MARK: - Ingredient Line Parsing

    /// Parses a line like "200 g Mehl" or "3 Eier" into a RawIngredient.
    static func parseIngredientLine(_ line: String) -> RawIngredient? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Pattern: optional number, optional unit, then ingredient name
        let pattern = #"^(\d+(?:[.,]\d+)?)\s*([a-zA-ZäöüÄÖÜg]+(?:\.|))?\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           match.numberOfRanges >= 4 {
            let amountStr = rangeString(match, 1, in: trimmed)?.replacingOccurrences(of: ",", with: ".") ?? "1"
            let unit = rangeString(match, 2, in: trimmed) ?? ""
            let name = rangeString(match, 3, in: trimmed) ?? trimmed
            let amount = Double(amountStr) ?? 1.0
            return RawIngredient(name: name, amount: amount, unit: unit)
        }

        return RawIngredient(name: trimmed, amount: 1, unit: "")
    }

    private static func rangeString(_ match: NSTextCheckingResult, _ idx: Int, in str: String) -> String? {
        guard let range = Range(match.range(at: idx), in: str) else { return nil }
        let s = String(str[range]).trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? nil : s
    }
}

// MARK: - Supporting Types

struct RecipeImportResult {
    let name: String
    let defaultServings: Int
    let ingredients: [RawIngredient]
}

struct RawIngredient {
    let name: String
    let amount: Double
    let unit: String
}

enum ImportError: LocalizedError {
    case invalidURL
    case encodingError
    case noStructuredDataFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige URL"
        case .encodingError: return "Seite konnte nicht gelesen werden"
        case .noStructuredDataFound: return "Keine strukturierten Rezeptdaten gefunden. Bitte Text manuell einfügen."
        }
    }
}
