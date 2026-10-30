import SwiftUI
import WidgetKit

/// I dati finti della galleria (nessuna rete) e la tabella «widget -> misure -> vista». I nomi sono quelli della lega dimostrativa.
enum DatiGalleria {
    // id, nome, ruolo, punti attesi, probabilita di voto, avversario, in casa, ora (minuti da adesso)
    private static let titolari: [(Int, String, String, Double, Double, String, Bool, Int)] = [
        (101, "Yann Sommer", "P", 6.1, 0.98, "roma", true, 300),
        (102, "Alessandro Bastoni", "D", 6.4, 0.96, "roma", true, 300),
        (103, "Gleison Bremer", "D", 6.0, 0.95, "lazio", false, 420),
        (104, "Federico Dimarco", "D", 6.8, 0.70, "roma", true, 300),
        (105, "Nicolo Barella", "C", 6.5, 0.97, "roma", true, 300),
        (106, "Hakan Calhanoglu", "C", 6.6, 0.93, "roma", true, 300),
        (107, "Tijjani Reijnders", "C", 6.3, 0.94, "napoli", false, 1500),
        (108, "Piotr Zielinski", "C", 6.2, 0.80, "roma", true, 300),
        (109, "Lautaro Martinez", "A", 7.4, 0.55, "roma", true, 300),
        (110, "Marcus Thuram", "A", 7.0, 0.90, "roma", true, 300),
        (111, "Rafael Leao", "A", 7.2, 0.88, "napoli", false, 1500),
    ]

    private static func data(_ minuti: Int) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/Rome")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date().addingTimeInterval(Double(minuti) * 60))
    }

    private static func giocatore(_ t: (Int, String, String, Double, Double, String, Bool, Int), conPartita: Bool = false) -> [String: Any] {
        var g: [String: Any] = ["id": t.0, "nome": t.1, "ruolo": t.2, "punti_attesi": t.3, "p_voto": t.4]
        if conPartita {
            g["avversario"] = t.5
            g["in_casa"] = t.6
            g["data_partita"] = data(t.7)
            g["stato"] = t.4 < 0.9 ? "dubbio" : "disponibile"
            g["percentuale"] = (t.4 * 100).rounded()
            g["dubbio"] = t.4 < 0.9
            g["diffidato"] = t.0 == 110
            g["titolare"] = true
            g["rigorista"] = t.0 == 109
        }
        return g
    }

    /// Il testo JSON come lo manda `/api/widget`. `parziali` = un server che non ha ancora scambio, svincolo e diario.
    static func json(parziali: Bool) -> Data {
        var corpo: [String: Any] = [
            "giornata": 11, "prima_partita": data(320), "scadenza": data(320), "ore_mancanti": 5.3, "iniziata": false, "con_probabili": true,
            "squadra": "Undici FC", "crediti_residui": 12,
            "formazione": ["modulo": "3-4-3", "punti_attesi": 73.7, "titolari": titolari.map { giocatore($0) }, "panchina": [201, 202, 203, 204, 205, 206, 207]],
            "avvisi": titolari.filter { $0.4 < 0.9 }.map { (t) -> [String: Any] in var g = giocatore(t); g["tipo"] = "dubbio"; g["in_formazione"] = true; return g },
            "rosa": titolari.map { giocatore($0, conPartita: true) },
            "squalificati": [], "diffidati": [110], "rigoristi": [109],
            "osservati": [],
            "dati": ["ultimo_aggiornamento": "2026-10-30T14:32:00"],
        ]
        if !parziali {
            corpo["diario"] = [["giornata": 10, "attesi": 66.0, "fatti": 63.5], ["giornata": 9, "attesi": 67.0, "fatti": 71.0],
                               ["giornata": 8, "attesi": 69.0, "fatti": 69.5], ["giornata": 7, "attesi": 70.0, "fatti": 64.5],
                               ["giornata": 6, "attesi": 68.5, "fatti": 71.0]]
            corpo["scambio"] = ["mia": "Undici FC", "altra": "Real Madrink",
                                "do": [["id": 112, "nome": "Nicolo Zaniolo", "ruolo": "C"], ["id": 113, "nome": "Marco Carnesecchi", "ruolo": "P"]],
                                "ricevo": [["id": 114, "nome": "Mattia Zaccagni", "ruolo": "A"]], "guadagno_mio": 3.4, "guadagno_loro": 1.1, "valido": true]
            corpo["svincolato"] = ["esce": ["id": 115, "nome": "Luca Pellegrini", "ruolo": "D"],
                                   "entra": ["id": 130, "nome": "Filippo Terracciano", "ruolo": "D", "quotazione": 8], "guadagno": 1.9, "fattibile": true]
        } else {
            corpo["diario"] = []
            corpo["mancano"] = ["scambio", "svincolato"]
        }
        return (try? JSONSerialization.data(withJSONObject: corpo)) ?? Data()
    }

    static func voce(_ tipo: String) -> Voce {
        if tipo == "vuoto" {
            return Voce(date: Date(), riassunto: nil, datiSalvati: false, indirizzoMancante: true, diagnostica: "Gruppo condiviso: non disponibile (prova)")
        }
        let w = RiassuntoWidget.leggi(json(parziali: tipo == "parziali"))
        return Voce(date: Date(), riassunto: w?.comeRiassuntoOggi(), datiSalvati: tipo == "salvati", widget: w)
    }

    static func famiglie(_ widget: String) -> [WidgetFamily] {
        let blocco: [WidgetFamily] = [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        switch widget {
        case "oggi": return [.systemSmall, .systemMedium] + blocco
        case "formazione": return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge] + blocco
        case "cruscotto": return [.systemLarge, .systemExtraLarge]
        case "dubbi": return [.systemMedium, .systemLarge, .accessoryRectangular]
        case "rosa": return [.systemMedium, .systemLarge, .systemExtraLarge, .accessoryRectangular, .accessoryInline]
        case "punti": return [.systemSmall, .systemMedium, .systemLarge] + blocco
        case "scambio": return [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline]
        case "crediti": return [.systemSmall, .systemMedium] + blocco
        case "stato": return [.systemSmall] + blocco
        default: return [.systemLarge]
        }
    }

    @ViewBuilder
    static func vista(_ widget: String, voce: Voce) -> some View {
        switch widget {
        case "oggi": VistaWidget(voce: voce)
        case "formazione": VistaFormazione(voce: voce)
        case "dubbi": VistaDubbi(voce: voce)
        case "rosa": VistaRosa(voce: voce)
        case "punti": VistaPunti(voce: voce)
        case "scambio": VistaScambio(voce: voce)
        case "crediti": VistaCrediti(voce: voce)
        case "stato": VistaStato(voce: voce)
        default: VistaCruscotto(voce: voce)
        }
    }
}
