import Foundation

struct IngredientCategorizer {

    /// Ordered list of all categories (used for section display order).
    static let allCategories: [String] = [
        "Gemüse",
        "Obst",
        "Milchprodukte & Eier",
        "Fleisch & Fisch",
        "Getreide & Nudeln",
        "Backzutaten",
        "Gewürze & Öle",
        "Konserven & Saucen",
        "Getränke",
        "Sonstiges",
    ]

    /// Returns the best-matching category for a given ingredient name.
    static func category(for name: String) -> String {
        let normalized = normalize(name)
        for (category, keywords) in keywords {
            if keywords.contains(where: { normalized.contains($0) }) {
                return category
            }
        }
        return "Sonstiges"
    }

    /// Normalises an ingredient name for matching:
    /// lowercased, common filler words removed, singular/plural unified where possible.
    static func normalize(_ name: String) -> String {
        var s = name.lowercased()
        // Remove common German adjectives that don't affect categorisation
        let fillers = ["frisch", "getrocknet", "tiefgekühlt", "gehackt", "klein",
                       "groß", "mittel", "bio", "gereift", "gewürfelt", "geschält",
                       "fein", "grob", "jung", "reif"]
        for filler in fillers {
            s = s.replacingOccurrences(of: " \(filler)", with: "")
            s = s.replacingOccurrences(of: "\(filler) ", with: "")
        }
        // Unify common German plural → singular forms
        let pluralMap: [(String, String)] = [
            ("tomaten",   "tomate"),
            ("zwiebeln",  "zwiebel"),
            ("karotten",  "karotte"),
            ("möhren",    "möhre"),
            ("äpfel",     "apfel"),
            ("eier",      "ei"),
            ("knoblauchzehen", "knoblauch"),
        ]
        for (plural, singular) in pluralMap {
            s = s.replacingOccurrences(of: plural, with: singular)
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Keyword table

    private static let keywords: [String: [String]] = [
        "Gemüse": [
            "tomate", "zwiebel", "knoblauch", "paprika", "karotte", "möhre",
            "zucchini", "gurke", "salat", "spinat", "brokkoli", "blumenkohl",
            "kohlrabi", "sellerie", "lauch", "porree", "fenchel", "rote bete",
            "kürbis", "aubergine", "champignon", "pilz", "erbse", "grüne bohne",
            "mais", "kohl", "wirsing", "rosenkohl", "artischocke", "spargel",
            "süßkartoffel", "kartoffel", "ingwer",
        ],
        "Obst": [
            "apfel", "birne", "banane", "orange", "mandarine", "zitrone",
            "limette", "erdbeere", "himbeere", "heidelbeere", "kirsche",
            "pflaume", "pfirsich", "aprikose", "mango", "ananas", "traube",
            "melone", "kiwi", "avocado", "feige", "granatapfel",
        ],
        "Milchprodukte & Eier": [
            "milch", "butter", "sahne", "joghurt", "käse", "quark",
            "frischkäse", "mozzarella", "parmesan", "ricotta", "feta",
            "creme fraiche", "crème fraîche", "schmand", "sauerrahm",
            "kondensmilch", "schlagsahne", "ei",
        ],
        "Fleisch & Fisch": [
            "hackfleisch", "rindfleisch", "schweinefleisch", "hühnchen",
            "hähnchen", "pute", "lamm", "rind", "schwein", "steak",
            "speck", "wurst", "salami", "schinken", "chorizo",
            "lachs", "thunfisch", "garnelen", "fisch", "filet", "kabeljau",
            "forelle", "makrele", "muschel", "tintenfisch",
        ],
        "Getreide & Nudeln": [
            "nudeln", "spaghetti", "penne", "fusilli", "tagliatelle",
            "lasagne", "reis", "risotto", "brot", "brötchen", "toast",
            "couscous", "quinoa", "bulgur", "polenta", "haferflocken",
            "müsli", "cornflakes", "wraps", "tortilla",
        ],
        "Backzutaten": [
            "mehl", "zucker", "puderzucker", "backpulver", "natron",
            "hefe", "stärke", "speisestärke", "vanille", "vanillezucker",
            "kakao", "schokolade", "kuvertüre", "mandeln", "walnuss",
            "haselnuss", "nüsse", "paniermehl", "semmelbrösel",
        ],
        "Gewürze & Öle": [
            "salz", "pfeffer", "öl", "olivenöl", "rapsöl", "essig",
            "balsamico", "senf", "ketchup", "mayonnaise", "sojasoße",
            "sojasauce", "worcester", "tabasco", "sambal", "harissa",
            "oregano", "basilikum", "thymian", "rosmarin", "petersilie",
            "schnittlauch", "dill", "koriander", "minze", "salbei",
            "paprikapulver", "curry", "kurkuma", "kreuzkümmel", "zimt",
            "muskat", "lorbeer", "nelken", "chili", "cayenne",
        ],
        "Konserven & Saucen": [
            "dosentomaten", "tomatenmark", "passierte tomaten", "tomatensauce",
            "kokosmilch", "brühe", "gemüsebrühe", "hühnerbrühe", "fond",
            "dose", "konserve", "bohnen dose", "linsen dose", "kichererbsen",
            "linse", "kidneybohnen",
        ],
        "Getränke": [
            "wasser", "saft", "wein", "rotwein", "weißwein", "bier",
            "kaffee", "tee", "orangensaft", "apfelsaft", "limonade",
        ],
    ]
}
