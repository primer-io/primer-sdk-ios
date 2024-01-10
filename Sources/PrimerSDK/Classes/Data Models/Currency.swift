// MARK: - Currency
public struct Currency: Codable {
    public let code: String
    private let decimalDigits: Int
    
    enum CodingKeys: String, CodingKey {
        case code = "c"
        case decimalDigits = "m"
    }
    
    internal var symbol: String? {
        let locale = NSLocale(localeIdentifier: code)
        return locale.displayName(forKey: NSLocale.Key.currencySymbol, value: code)
    }
    
    internal var isZeroDecimal: Bool {
        decimalDigits == 0
    }
}

// MARK: - Currency Loader
public struct CurrencyLoader {
    
    private static let jsonParser = JSONParser()
    private static let fileName = "currencies"
    
    private static var isFirstLaunch: Bool {
        get {
            if let value = UserDefaults.standard.value(forKey: "isFirstLaunch"), let boolValue = value as? Bool {
                return boolValue
            }
            return true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isFirstLaunch")
        }
    }
    
    public static func getCurrencyFor(_ code: String) -> Currency? {
        updateCurrenciesFromAPI()
        return loadCurrenciesFromDisk()?.first { $0.code == code }
    }
    
    internal static func updateCurrenciesFromAPI() {
        let urlString = "https://assets.dev.core.primer.io/currency-information/latest/data.json"
        guard let url = URL(string: urlString) else {
            return
        }
        
        if isFirstLaunch {
            // Load from bundle and save to disk if it's the first launch
            copyCurrenciesFromBundle()
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching currencies from API: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                _ = try jsonParser.parse([Currency].self, from: data)
                try saveJsonData(data, fileName: fileName + ".json")
                isFirstLaunch = false
            } catch {
                print("Error parsing or saving currencies from API: \(error)")
            }
        }
        task.resume()
    }
    
    // Load currencies from the local disk
    private static func loadCurrenciesFromDisk() -> [Currency]? {
        guard let url = getLocalFileURL(fileName: fileName + ".json"), let data = try? Data(contentsOf: url) else {
            copyCurrenciesFromBundle()
            if let currencies = loadCurrenciesFromDisk() {
                return currencies
            }
            return nil
        }
        return try? jsonParser.parse([Currency].self, from: data)
    }
    
    // Load currencies from the bundle
    private static func copyCurrenciesFromBundle() {
        isFirstLaunch = false
        guard let data = jsonParser.loadJsonData(fileName: fileName) else {
            return
        }
        
        do {
            try saveJsonData(data, fileName: fileName + ".json")
        } catch {
            print("Error encoding or saving currencies from bundle: \(error)")
            return
        }
    }
    
    private static func saveJsonData(_ data: Data, fileName: String) throws {
        guard let url = getLocalFileURL(fileName: fileName) else {
            throw NSError(domain: "CurrencyLoader", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to get file URL"])
        }
        try data.write(to: url)
    }
    
    private static func getLocalFileURL(fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentDirectory.appendingPathComponent(fileName)
    }
}
