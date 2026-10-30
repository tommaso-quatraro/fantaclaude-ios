import Foundation

/// Un elemento di un elenco letto senza far fallire tutto: se è sbagliato o ha il tipo diverso, `valore` resta nil
/// e gli altri elementi si leggono lo stesso (un campo nuovo o strano del server non deve rompere una schermata).
struct Tollerante<T: Decodable>: Decodable {
    let valore: T?
    init(from decoder: Decoder) throws {
        valore = try? T(from: decoder)
    }
}
