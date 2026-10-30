import WidgetKit
import SwiftUI

/// Widget «Cruscotto»: tutto quello che serve prima di una giornata, in un colpo d'occhio.
/// Grande (iPhone, iPad): scadenza con conto alla rovescia, formazione sul campo, dubbi, scambio e svincolo, punti attesi e fatti, crediti.
/// Extra large (iPad): le stesse cose in due colonne, con i cognomi sul campo.
/// Ogni blocco e' un tocco: scadenza -> Oggi, modulo -> Formazione, volti -> scheda del giocatore, scambio -> Scambi,
/// svincolo e crediti -> Mercato, grafico -> Lega.
struct WidgetCruscotto: Widget {
    let kind = "FantaclaudeCruscotto"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurazioneWidget.self, provider: Fornitore()) { voce in
            VistaCruscotto(voce: voce)
        }
        .configurationDisplayName("Cruscotto")
        .description("Scadenza, formazione, dubbi, scambio e svincolo, punti attesi e fatti, crediti: ogni blocco apre la sua schermata.")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}

struct VistaCruscotto: View {
    @Environment(\.widgetFamily) private var famiglia
    @Environment(\.widgetRenderingMode) private var modo
    let voce: Voce

    var body: some View {
        Group {
            if let w = voce.completo, let f = w.formazione, let tit = f.titolari, !tit.isEmpty {
                if famiglia == .systemExtraLarge { largo(w, f, tit) } else { alto(w, f, tit) }
            } else {
                SenzaDatiWidget(voce: voce)
            }
        }
        .sfondoWidget(accessorio: false)
        .widgetURL(Vai.url("oggi"))
    }

    // MARK: blocchi

    /// Scadenza: il numero grande e' il tempo che manca.
    private func scadenza(_ w: RiassuntoWidget, grande: CGFloat) -> some View {
        Link(destination: Vai.url("oggi")) {
            VStack(alignment: .leading, spacing: 0) {
                TitoloBlocco(testo: w.giornata.map { "Giornata \($0)" } ?? "Giornata", icona: "calendar")
                ContoWidget(inizio: w.inizio, adesso: voce.date)
                    .font(.system(size: grande, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(sottoscadenza(w)).font(.caption2).foregroundStyle(w.conProbabili == false ? TintaWidget.attenzione : TintaWidget.testo2).lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func sottoscadenza(_ w: RiassuntoWidget) -> String {
        guard let inizio = w.inizio else { return "scadenza non nota" }
        let quando = inizio > voce.date ? "alla prima partita, \(Quando.leggibile(inizio))" : "la giornata e' iniziata"
        return w.conProbabili == false ? "probabili non uscite · \(quando)" : quando
    }

    /// Modulo e punti attesi.
    private func formazione(_ f: FormazioneWidget, allineato: HorizontalAlignment = .trailing) -> some View {
        Link(destination: Vai.url("formazione")) {
            VStack(alignment: allineato, spacing: 0) {
                TitoloBlocco(testo: "Formazione", icona: "sportscourt")
                Text(f.modulo ?? "—").font(.system(size: 30, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.6)
                HStack(spacing: 3) {
                    Text(Formato.punti(f.puntiAttesi)).font(.footnote.weight(.bold)).monospacedDigit()
                        .foregroundStyle(TintaWidget.accento(modo)).widgetAccentable()
                    Text("punti attesi").font(.caption2).foregroundStyle(TintaWidget.testo2)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// I dubbi, gli infortuni e le squalifiche tra i titolari.
    private func dubbi(_ w: RiassuntoWidget, massimo: Int, lato: CGFloat = 24) -> some View {
        let elenco = w.daControllare
        return VStack(alignment: .leading, spacing: 3) {
            TitoloBlocco(testo: elenco.isEmpty ? "Titolari a posto" : "Da controllare (\(elenco.count))",
                         icona: elenco.isEmpty ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                         colore: elenco.isEmpty ? TintaWidget.testo2 : TintaWidget.attenzione)

            if elenco.isEmpty {
                Text(w.conProbabili == false ? "Le probabili non sono ancora uscite." : "Nessun dubbio in formazione.")
                    .font(.caption2).foregroundStyle(TintaWidget.testo2)
            } else {
                ForEach(elenco.prefix(massimo)) { g in RigaGiocatoreWidget(g: g, lato: lato) }
                if elenco.count > massimo {
                    Text("e altri \(elenco.count - massimo)").font(.caption2).foregroundStyle(TintaWidget.testo2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scambioESvincolo(_ w: RiassuntoWidget) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Link(destination: Vai.url("scambi")) { ScambioCompatto(scambio: w.scambio) }
            Link(destination: Vai.url("mercato")) { SvincoloCompatto(svincolo: w.svincolato) }
        }
    }

    private func punti(_ w: RiassuntoWidget, altezza: CGFloat) -> some View {
        Link(destination: Vai.url("lega")) {
            VStack(alignment: .leading, spacing: 3) {
                TitoloBlocco(testo: "Attesi e fatti", icona: "chart.bar.fill")
                if w.giornateGiocate.isEmpty {
                    Text("Compare dopo la prima giornata giocata.").font(.caption2).foregroundStyle(TintaWidget.testo2)
                } else {
                    GraficoPunti(giornate: w.giornateGiocate, altezza: altezza)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func crediti(_ w: RiassuntoWidget) -> some View {
        Link(destination: Vai.url("mercato")) {
            VStack(alignment: .trailing, spacing: 0) {
                TitoloBlocco(testo: "Crediti", icona: "eurosign.circle")
                Text(w.creditiResidui.map { String(Formato.intero($0)) } ?? "—")
                    .font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                    .foregroundStyle(TintaWidget.accento(modo)).widgetAccentable()
                Text("residui").font(.caption2).foregroundStyle(TintaWidget.testo2)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: grande (iPhone, iPad)

    private func alto(_ w: RiassuntoWidget, _ f: FormazioneWidget, _ tit: [GiocatoreWidget]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                scadenza(w, grande: 30)
                Spacer(minLength: 8)
                formazione(f)
            }
            HStack(alignment: .top, spacing: 10) {
                CampoMini(titolari: tit, lato: 24)
                    .frame(width: 150)
                dubbi(w, massimo: 3)
            }
            scambioESvincolo(w)
            HStack(alignment: .bottom, spacing: 12) {
                punti(w, altezza: 34)
                crediti(w)
            }
            PiedeDati(voce: voce)
        }
    }

    // MARK: extra large (iPad)

    private func largo(_ w: RiassuntoWidget, _ f: FormazioneWidget, _ tit: [GiocatoreWidget]) -> some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    scadenza(w, grande: 34)
                    Spacer(minLength: 8)
                    formazione(f)
                }
                CampoMini(titolari: tit, lato: 40, conNomi: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                dubbi(w, massimo: 3, lato: 28)
                scambioESvincolo(w)
                HStack(alignment: .bottom, spacing: 12) {
                    punti(w, altezza: 44)
                    crediti(w)
                }
                Spacer(minLength: 0)
                PiedeDati(voce: voce)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
