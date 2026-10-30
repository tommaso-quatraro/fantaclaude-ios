import Foundation

/// La fascia dei punti attesi (campo `intervallo` del server): «tra 62 e 84, 8 volte su 10».
/// Tollerante: se il campo è sbagliato o incompleto resta vuoto, senza rompere la schermata che lo contiene.
struct IntervalloPunti: Decodable, Equatable {
    var basso: Double?
    var alto: Double?
    /// Quota dei casi dentro la fascia, per esempio 0,8.
    var confidenza: Double?
    /// true se la fascia è ancora poco provata: va detto.
    var indicativo: Bool?

    private enum Chiavi: String, CodingKey { case basso, alto, confidenza, indicativo }

    init(basso: Double? = nil, alto: Double? = nil, confidenza: Double? = nil, indicativo: Bool? = nil) {
        self.basso = basso; self.alto = alto; self.confidenza = confidenza; self.indicativo = indicativo
    }

    init(from decoder: Decoder) throws {
        guard let k = try? decoder.container(keyedBy: Chiavi.self) else { return }
        basso = (try? k.decodeIfPresent(Double.self, forKey: .basso)) ?? nil
        alto = (try? k.decodeIfPresent(Double.self, forKey: .alto)) ?? nil
        confidenza = (try? k.decodeIfPresent(Double.self, forKey: .confidenza)) ?? nil
        indicativo = (try? k.decodeIfPresent(Bool.self, forKey: .indicativo)) ?? nil
    }

    /// I due estremi ci sono e sono numeri veri, in ordine.
    var valido: Bool {
        guard let basso, let alto, basso.isFinite, alto.isFinite else { return false }
        return basso <= alto
    }

    /// «8 volte su 10» (o «19 volte su 20»); nil se la confidenza manca o non è tra 0 e 1.
    var quanteVolte: String? {
        guard let c = confidenza, c.isFinite, c > 0, c < 1 else { return nil }
        for base in [10, 20, 100] {
            let n = c * Double(base)
            if abs(n - n.rounded()) < 0.001 { return "\(Int(n.rounded())) volte su \(base)" }
        }
        return "\(Formato.intero(c * 100)) volte su 100"
    }

    /// «tra 62 e 84 · 8 volte su 10» (+ « (indicativo)»), o nil se la fascia non è valida.
    var testo: String? {
        guard valido else { return nil }
        var t = "tra \(Formato.intero(basso)) e \(Formato.intero(alto))"
        if let v = quanteVolte { t += " · \(v)" }
        if indicativo == true { t += " (indicativo)" }
        return t
    }

    /// Il testo da mostrare accanto ai punti attesi: la fascia, oppure «oscilla di ±N» se manca (server vecchio).
    static func frase(_ intervallo: IntervalloPunti?, dev: Double?) -> String? {
        if let t = intervallo?.testo { return t }
        guard let dev, dev.isFinite, dev >= 0 else { return nil }
        return "oscilla di ±\(Formato.intero(dev))"
    }
}
