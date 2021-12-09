import Foundation

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from filename: String) -> T {
        guard let url = self.url(forResource: filename, withExtension: nil) else {
            fatalError("Failed to locate: \(filename)")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load: \(url)")
        }

        let decoder = JSONDecoder()

        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Fail to decode: \(data)")
        }

        return loaded
    }
}
