// CHO/FAT Metabolic - Garmin Connect IQ data field for real-time CHO/FAT
// oxidation estimation from heart rate.
// Copyright (C) 2026 Jordi Irazuzta
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Activity;
using Toybox.UserProfile;
using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.Math;

// ============================================================================
// CHOFATView
//
// Data Field de Connect IQ que calcula en temps real, segon a segon,
// l'oxidació de carbohidrats (CHO) i greixos (FAT) a partir de la FC,
// seguint el mateix model (RER interpolat per zones de FC) que la versió
// d'escriptori en Python que analitza fitxers .FIT.
//
// Totes les dades es mostren en UNA SOLA pantalla de Data Field, en 3
// franges horitzontals iguals:
//   - CHO acumulat (g)
//   - Mitjana mòbil exponencial (EMA) de CHO (g/h), acolorida segons consum
//   - FAT acumulat (g)
// ============================================================================
class CHOFATView extends WatchUi.DataField {

    // --- Estat acumulat de la sessió ---
    hidden var totalChoGrams as Lang.Float = 0.0;
    hidden var totalFatGrams as Lang.Float = 0.0;
    hidden var lastTimerTimeMs as Lang.Number = 0;
    hidden var hasStarted as Lang.Boolean = false;

    // --- Valors instantanis a mostrar ---
    hidden var choRateGH as Lang.Float = 0.0;   // g/h instantani
    hidden var choAvgGH as Lang.Float = 0.0;    // mitjana acumulada g/h (tota la sessió)

    // --- Mitjana mòbil exponencial (EMA) de CHO, per a la mitjana que es
    //     mostra. Constant de temps ~15 min (es comporta aproximadament
    //     com una mitjana mòbil d'uns 30 min, però sense el salt sobtat
    //     que fa una finestra fixa quan una mostra antiga "cau" de cop).
    const TAU_EMA_MIN = 15.0;
    hidden var choAvgEmaGH as Lang.Float = 0.0;
    hidden var emaInicialitzada as Lang.Boolean = false;

    // --- Llindars de fueling de CHO (g/h), basats en guies esportives
    //     habituals (Jeukendrup): les bandes recomanades pugen amb la
    //     durada de l'esforç, perquè el dipòsit de glicogen encara és ple
    //     als primers minuts i no cal amoïnar-se pel consum encara.
    const FUELING_FASE1_MIN = 45.0;   // abans d'això, no s'acolareix (dipòsits plens)
    const FUELING_FASE2_MIN = 120.0;  // llindar de pas a esforços llargs

    const CHO_VERD_FASE2 = 30.0;      // esforços d'1h-2h: guia habitual 30-60 g/h
    const CHO_TARONJA_FASE2 = 60.0;
    const CHO_VERD_FASE3 = 60.0;      // esforços >2h: guia habitual 60-90 g/h
    const CHO_TARONJA_FASE3 = 90.0;

    // --- Estat per al petit indicador de zona de FC (Z1..Z5) ---
    hidden var zonesFC as Lang.Array = [];
    hidden var zonaFCActual as Lang.Number = 1;
    hidden var minutsTranscorreguts as Lang.Float = 0.0;

    // --- Perfil fisiològic (es resol un cop, a l'inici de l'activitat) ---
    hidden var pesKg as Lang.Float = 70.0;
    hidden var fcRepos as Lang.Number = 50;
    hidden var fcMax as Lang.Number = 185;
    hidden var lt2 as Lang.Number = 165;
    hidden var vo2max as Lang.Float = 50.0;
    hidden var lt1Fixat as Lang.Number = 0; // 0 = no fixat, s'estima com a PCT_LT1*lt2

    // --- Paràmetres del model metabòlic (calibrats per a esportistes de fons,
    //     mateixos valors que la versió d'escriptori) ---
    const PCT_ACTIVACIO_CHO = 0.70; // Inici Zona 2
    const PCT_LT1 = 0.85;           // Llindar Aeròbic (% del LT2)
    const RER_BASAL = 0.72;
    const RER_LT1 = 0.82;
    const RER_LT2 = 0.98;
    const RER_MAX = 1.00;

    // Si el sensor de FC talla més d'aquest temps (ms), descartem la mostra
    // en comptes d'extrapolar la taxa instantània sobre tot el forat.
    const DT_MAX_MS = 5000;

    // --- Geometria de les 3 files, calculada un sol cop (namés es recalcula
    //     si canvia la mida de pantalla, cosa que no passa durant una
    //     activitat) per no repetir aquests càlculs a cada onUpdate(). ---
    hidden var geomCalculada as Lang.Boolean = false;
    hidden var geomWidth as Lang.Number = -1;
    hidden var geomHeight as Lang.Number = -1;
    hidden var esRodona as Lang.Boolean = true;

    hidden var filaCY as Lang.Array = [0, 0, 0];
    hidden var filaRowH as Lang.Array = [0, 0, 0];
    hidden var filaColEtiquetaCX as Lang.Array = [0, 0, 0];
    hidden var filaColValorCX as Lang.Array = [0, 0, 0];
    hidden var filaAmplaValorMax as Lang.Array = [0, 0, 0];
    hidden var filaAlcadaMax as Lang.Array = [0, 0, 0];
    hidden var filaFontEtiqueta as Lang.Array = [Graphics.FONT_XTINY, Graphics.FONT_XTINY, Graphics.FONT_XTINY];
    hidden var filaZonaDretaX as Lang.Number = 0;

    // Cache de la font del valor per fila: només es recalcula quan canvia
    // la llargada del text (no cada frame, ja que el número quasi sempre
    // manté el mateix nombre de xifres d'un frame al següent).
    hidden var filaValorLenCache as Lang.Array = [-1, -1, -1];
    hidden var filaValorFontCache as Lang.Array = [Graphics.FONT_XTINY, Graphics.FONT_XTINY, Graphics.FONT_XTINY];

    const ETIQUETES = ["CHO (g)", "CHO avg (g/h)", "FAT (g)"];
    const FILA_ACOLORIR = [false, true, false];
    const FONTS_VALOR = [
        Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD,
        Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY
    ];

    function initialize() {
        DataField.initialize();
        carregarPerfil();
    }

    // ------------------------------------------------------------------
    // Resol el perfil fisiològic combinant dades del rellotge/Garmin
    // Connect amb els valors manuals opcionals de l'usuari (propietats).
    // Un valor manual > 0 sempre té prioritat sobre l'estimació automàtica.
    // ------------------------------------------------------------------
    function carregarPerfil() as Void {
        var profile = UserProfile.getProfile();

        // 1) Pes
        var pesManual = Application.Properties.getValue("pesManualKg") as Lang.Float?;
        if (pesManual != null && pesManual > 0.0) {
            pesKg = pesManual;
        } else if (profile != null) {
            var pesPerfil = profile.weight;
            if (pesPerfil != null) {
                pesKg = pesPerfil.toFloat() / 1000.0; // grams -> kg
            }
        }

        // 2) FC de repòs
        var fcReposManual = Application.Properties.getValue("fcReposManual") as Lang.Number?;
        if (fcReposManual != null && fcReposManual > 0) {
            fcRepos = fcReposManual;
        } else if (profile != null) {
            var fcReposPerfil = profile.restingHeartRate;
            if (fcReposPerfil != null) {
                fcRepos = fcReposPerfil;
            }
        }

        // 3) VO2max (estimat pel rellotge, si no hi ha manual). Garmin guarda
        //    per separat el VO2max de córrer i el de ciclisme — cal triar el
        //    que correspongui a l'esport actual (rellevant sobretot en
        //    dispositius Edge, on el de córrer sempre seria null).
        var sport = UserProfile.getCurrentSport();
        var vo2Manual = Application.Properties.getValue("vo2maxManual") as Lang.Float?;
        if (vo2Manual != null && vo2Manual > 0.0) {
            vo2max = vo2Manual;
        } else if (profile != null) {
            var vo2Perfil = (sport == Activity.SPORT_CYCLING) ? profile.vo2maxCycling : profile.vo2maxRunning;
            if (vo2Perfil != null) {
                vo2max = vo2Perfil.toFloat();
            }
        }

        // 4) FCmax i LT2: Garmin no exposa aquests camps directament, però sí
        //    les zones de FC configurades/estimades pel rellotge. Fem servir
        //    el sostre de zona 5 com a FCmax i el sostre de zona 4 com a LT2.
        //    (Array retornat per getHeartRateZones: [min1,max1,max2,max3,max4,max5])
        var zones = UserProfile.getHeartRateZones(sport);
        if (zones != null) {
            zonesFC = zones;
        }

        var fcMaxManual = Application.Properties.getValue("fcMaxManual") as Lang.Number?;
        if (fcMaxManual != null && fcMaxManual > 0) {
            fcMax = fcMaxManual;
        } else if (zones != null && zones.size() >= 6) {
            var z5 = zones[5];
            if (z5 != null) {
                fcMax = z5;
            }
        }

        var lt2Manual = Application.Properties.getValue("lt2Manual") as Lang.Number?;
        if (lt2Manual != null && lt2Manual > 0) {
            lt2 = lt2Manual;
        } else if (zones != null && zones.size() >= 6) {
            var z4 = zones[4];
            if (z4 != null) {
                lt2 = z4;
            }
        }

        // 5) Coherència del perfil: valors manuals mal introduïts (o dades de
        //    rellotge inconsistents) no han de trencar en silenci el càlcul
        //    de HRR/RER. Si fcMax no queda per sobre de fcRepos, tornem als
        //    valors per defecte; si lt2 no queda entre fcRepos i fcMax,
        //    l'aproximem a un 85% de la reserva de FC.
        if (fcMax <= fcRepos) {
            fcRepos = 50;
            fcMax = 185;
        }
        if (lt2 <= fcRepos || lt2 >= fcMax) {
            lt2 = (fcRepos + 0.85 * (fcMax - fcRepos)).toNumber();
        }

        // 6) LT1 manual (opcional): només es fa servir si queda coherent
        //    entre FC repòs i LT2; si no, es torna a l'estimació automàtica
        //    PCT_LT1*lt2 (veure compute()).
        var lt1Manual = Application.Properties.getValue("lt1Manual") as Lang.Number?;
        if (lt1Manual != null && lt1Manual > fcRepos && lt1Manual < lt2) {
            lt1Fixat = lt1Manual;
        } else {
            lt1Fixat = 0;
        }
    }

    // ------------------------------------------------------------------
    // Es crida aproximadament un cop per segon amb les dades d'activitat
    // actuals. Aquí acumulem grams de CHO/FAT i calculem taxes instantànies.
    // ------------------------------------------------------------------
    function compute(info as Activity.Info) as Void {
        if (info.timerTime == null || info.currentHeartRate == null) {
            return;
        }

        var timerTimeMs = info.timerTime as Lang.Number;

        if (!hasStarted) {
            // Primera mostra: només guardem la referència de temps.
            lastTimerTimeMs = timerTimeMs;
            hasStarted = true;
            return;
        }

        var dtMs = timerTimeMs - lastTimerTimeMs;
        lastTimerTimeMs = timerTimeMs;

        // timerTime no avança mentre l'activitat està en pausa, així que
        // aquest control també evita acumular durant les pauses.
        if (dtMs <= 0) {
            return;
        }

        // Tall de sensor de FC massa llarg (p.ex. òptic de canell que perd
        // el senyal uns segons): no extrapolem la taxa actual sobre tot el
        // forat, simplement descartem aquesta mostra i esperem la següent.
        if (dtMs > DT_MAX_MS) {
            return;
        }

        var dtMin = dtMs / 60000.0;
        var fcActual = (info.currentHeartRate as Lang.Number).toFloat();

        minutsTranscorreguts = timerTimeMs / 60000.0;

        // --- Zona de FC actual (per a l'indicador petit Z1..Z5) ---
        if (zonesFC.size() >= 6) {
            if (fcActual <= (zonesFC[1] as Lang.Number).toFloat()) {
                zonaFCActual = 1;
            } else if (fcActual <= (zonesFC[2] as Lang.Number).toFloat()) {
                zonaFCActual = 2;
            } else if (fcActual <= (zonesFC[3] as Lang.Number).toFloat()) {
                zonaFCActual = 3;
            } else if (fcActual <= (zonesFC[4] as Lang.Number).toFloat()) {
                zonaFCActual = 4;
            } else {
                zonaFCActual = 5;
            }
        }

        // --- Heart Rate Reserve i VO2 estimat ---
        var hrr = (fcActual - fcRepos) / (fcMax - fcRepos).toFloat();
        if (hrr < 0.0) { hrr = 0.0; }
        if (hrr > 1.0) { hrr = 1.0; }

        var vo2ReposRelatiu = 3.5;
        var vo2RelatiuActual = vo2ReposRelatiu + hrr * (vo2max - vo2ReposRelatiu);
        var vo2LMin = (vo2RelatiuActual * pesKg) / 1000.0;

        // --- RER interpolat per zones de FC (mateix model que l'app d'escriptori) ---
        var lt1Bpm = (lt1Fixat > 0) ? lt1Fixat.toFloat() : PCT_LT1 * lt2;
        var puntActivacioCho = PCT_ACTIVACIO_CHO * lt2;
        var rer;

        if (fcActual <= puntActivacioCho) {
            rer = RER_BASAL;
        } else if (fcActual <= lt1Bpm) {
            var ratio = (fcActual - puntActivacioCho) / (lt1Bpm - puntActivacioCho);
            rer = RER_BASAL + ratio * (RER_LT1 - RER_BASAL);
        } else if (fcActual <= lt2) {
            var ratio2 = (fcActual - lt1Bpm) / (lt2 - lt1Bpm).toFloat();
            rer = RER_LT1 + ratio2 * (RER_LT2 - RER_LT1);
        } else {
            var denom = (fcMax - lt2).toFloat();
            var ratio3 = denom > 0.0 ? (fcActual - lt2) / denom : 1.0;
            if (ratio3 > 1.0) { ratio3 = 1.0; }
            rer = RER_LT2 + ratio3 * (RER_MAX - RER_LT2);
        }

        // --- Oxidació de substrats (g/min): equacions de Jeukendrup & Wallis
        //     (2005), modificació per a exercici de les de Frayn (1983) ---
        var choGMin = 4.210 * vo2LMin * rer - 2.962 * vo2LMin;
        var fatGMin = 1.695 * vo2LMin - 1.701 * vo2LMin * rer;
        if (choGMin < 0.0) { choGMin = 0.0; }
        if (fatGMin < 0.0) { fatGMin = 0.0; }

        var choIncrement = choGMin * dtMin;

        // --- Acumulació de la sessió ---
        totalChoGrams += choIncrement;
        totalFatGrams += fatGMin * dtMin;

        // --- Valor per mostrar (taxa instantània de CHO) ---
        choRateGH = choGMin * 60.0;

        var horesTotals = timerTimeMs / 3600000.0;
        choAvgGH = horesTotals > 0.0 ? totalChoGrams / horesTotals : 0.0;

        // --- Mitjana mòbil exponencial (EMA) ---
        // alpha_tick = dtMin / TAU_EMA_MIN és l'aproximació de primer ordre
        // de 1 - exp(-dtMin/TAU_EMA_MIN), vàlida perquè dtMin sempre és molt
        // més petit que la constant de temps (els ticks són ~1 s, i ja
        // descartem forats grans amb DT_MAX_MS). S'adapta sola encara que
        // l'interval entre mostres no sigui exactament regular.
        if (!emaInicialitzada) {
            choAvgEmaGH = choRateGH;
            emaInicialitzada = true;
        } else {
            var alphaTick = dtMin / TAU_EMA_MIN;
            if (alphaTick > 1.0) { alphaTick = 1.0; }
            choAvgEmaGH = choAvgEmaGH + alphaTick * (choRateGH - choAvgEmaGH);
        }
    }

    // ------------------------------------------------------------------
    // Codi de colors segons la taxa de consum de CHO (g/h), amb bandes
    // que pugen amb la durada de l'esforç (guies esportives tipus
    // Jeukendrup): als primers 45 min no cal amoïnar-se (glicogen ple);
    // d'1h a 2h la banda de fueling habitual és 30-60 g/h; per sobre de
    // 2h puja a 60-90 g/h.
    // ------------------------------------------------------------------
    function colorPerCho(valorGH as Lang.Float, minutsSessio as Lang.Float) as Graphics.ColorType {
        if (minutsSessio < FUELING_FASE1_MIN) {
            return Graphics.COLOR_GREEN;
        }

        var verd;
        var taronja;
        if (minutsSessio < FUELING_FASE2_MIN) {
            verd = CHO_VERD_FASE2;
            taronja = CHO_TARONJA_FASE2;
        } else {
            verd = CHO_VERD_FASE3;
            taronja = CHO_TARONJA_FASE3;
        }

        if (valorGH < verd) {
            return Graphics.COLOR_GREEN;
        } else if (valorGH < taronja) {
            return Graphics.COLOR_ORANGE;
        } else {
            return Graphics.COLOR_RED;
        }
    }

    // ------------------------------------------------------------------
    // Colors estàndard de Garmin Connect per a les zones de FC (Z1..Z5).
    // El gris de Z1 s'adapta al fons (gris fosc sobre negre és invisible).
    // ------------------------------------------------------------------
    function colorPerZona(zona as Lang.Number, bg as Graphics.ColorType) as Graphics.ColorType {
        if (zona <= 1) {
            return (bg == Graphics.COLOR_BLACK) ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
        } else if (zona == 2) {
            return Graphics.COLOR_BLUE;
        } else if (zona == 3) {
            return Graphics.COLOR_GREEN;
        } else if (zona == 4) {
            return Graphics.COLOR_ORANGE;
        } else {
            return Graphics.COLOR_RED;
        }
    }

    // ------------------------------------------------------------------
    // En una pantalla rodona, l'amplada útil no és constant: és màxima al
    // centre vertical i es va reduint cap a dalt/baix (corda del cercle).
    // Aquesta funció retorna quanta amplada hi ha realment disponible a
    // l'alçada més extrema d'una fila, perquè cap text hi quedi tallat
    // pel bisell.
    // ------------------------------------------------------------------
    function amplaSeguraFila(width as Lang.Number, height as Lang.Number, cy as Lang.Number, rowH as Lang.Number) as Lang.Number {
        if (!esRodona) {
            // Pantalla rectangular (p.ex. Edge): no hi ha bisell corbat que
            // talli res — es fa servir tota l'amplada, amb un marge petit.
            return (width * 0.96).toNumber();
        }
        var radi = width / 2.0;
        var centreY = height / 2.0;
        var distanciaExtrem = (cy - centreY).abs() + (rowH / 2.0);
        if (distanciaExtrem >= radi) {
            return (width * 0.5).toNumber();
        }
        var mitjaAmplada = Math.sqrt((radi * radi) - (distanciaExtrem * distanciaExtrem));
        return (mitjaAmplada * 2).toNumber();
    }

    // ------------------------------------------------------------------
    // Retorna la font més gran d'una llista de candidates (ordenades de
    // més gran a més petita) que faci cabre el text dins d'una amplada
    // màxima donada. Així el text sempre hi cap, independentment de la
    // mida de pantalla del dispositiu o de la llargada del número.
    // ------------------------------------------------------------------
    function ajustaFont(dc as Graphics.Dc, text as Lang.String, amplaMax as Lang.Number, alcadaMax as Lang.Number, candidates as Lang.Array<Graphics.FontType>) as Graphics.FontType {
        for (var i = 0; i < candidates.size(); i += 1) {
            var f = candidates[i];
            if (dc.getTextWidthInPixels(text, f) <= amplaMax && dc.getFontHeight(f) <= alcadaMax) {
                return f;
            }
        }
        return candidates[candidates.size() - 1];
    }

    // ------------------------------------------------------------------
    // Calcula tota la geometria de les 3 files (posicions, columnes, font
    // de les etiquetes) un sol cop. Només es torna a cridar si la mida de
    // pantalla canvia respecte al que hi havia en cache (no passa durant
    // una activitat normal).
    // ------------------------------------------------------------------
    function calcularGeometria(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        var forma = System.getDeviceSettings().screenShape;
        esRodona = (forma == System.SCREEN_SHAPE_ROUND || forma == System.SCREEN_SHAPE_SEMI_ROUND);

        var topH = (height / 3.0).toNumber();
        var botH = (height / 3.0).toNumber();
        var midH = height - topH - botH;

        var cys = [topH / 2, topH + (midH / 2), topH + midH + (botH / 2)];
        var rowHs = [topH, midH, botH];

        var fontsEtiqueta = [Graphics.FONT_XTINY];

        var zonaText = "Z" + zonaFCActual.format("%d");
        var zonaAmpla = dc.getTextWidthInPixels(zonaText, Graphics.FONT_SMALL);

        for (var i = 0; i < 3; i += 1) {
            var cy = cys[i];
            var rowH = rowHs[i];
            var acolorir = FILA_ACOLORIR[i];

            var amplaSegura = amplaSeguraFila(width, height, cy, rowH);
            var marge = (width - amplaSegura) / 2;

            // A la fila de la mitjana reservem una petita franja a la dreta
            // de tot per a l'indicador de zona (Z1..Z5), perquè mai quedi
            // sota el número.
            var reservaZona = acolorir ? (zonaAmpla + (amplaSegura * 0.04).toNumber()) : 0;
            var amplaUtil = amplaSegura - reservaZona;

            var colEtiquetaW = (amplaUtil * 0.40).toNumber();
            var colValorW = amplaUtil - colEtiquetaW;

            var alcadaMax = (rowH - (rowH * 0.06)).toNumber();
            var amplaEtiquetaMax = (colEtiquetaW * 0.90).toNumber();

            filaCY[i] = cy;
            filaRowH[i] = rowH;
            filaColEtiquetaCX[i] = (marge + (colEtiquetaW / 2)).toNumber();
            filaColValorCX[i] = (marge + colEtiquetaW + (colValorW / 2)).toNumber();
            filaAmplaValorMax[i] = (colValorW * 0.92).toNumber();
            filaAlcadaMax[i] = alcadaMax;
            filaFontEtiqueta[i] = ajustaFont(dc, ETIQUETES[i], amplaEtiquetaMax, alcadaMax, fontsEtiqueta);

            if (acolorir) {
                filaZonaDretaX = (marge + amplaSegura).toNumber();
            }

            // La geometria ha canviat: invalidem la cache de font del valor.
            filaValorLenCache[i] = -1;
        }

        geomWidth = width;
        geomHeight = height;
        geomCalculada = true;
    }

    // ------------------------------------------------------------------
    // Dibuixa 3 franges horitzontals iguals (33% cadascuna):
    //   Graella de 3 files x 2 columnes (columna d'etiquetes al 40%,
    //   columna de valors al 60%, sense línia vertical de separació):
    //   [ CHO (g)        | 123 ]
    //   [ CHO avg (g/h)  | 45  ]  (acolorit segons consum)
    //   [ FAT (g)        | 67  ]
    // ------------------------------------------------------------------
    function onUpdate(dc as Graphics.Dc) as Void {
        var bg = getBackgroundColor();
        var fg = (bg == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(fg, bg);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();

        if (!geomCalculada || width != geomWidth || height != geomHeight) {
            calcularGeometria(dc, width, height);
        }

        var valors = [totalChoGrams.format("%.0f"), choAvgEmaGH.format("%.0f"), totalFatGrams.format("%.0f")];
        var zonaText = "Z" + zonaFCActual.format("%d");

        for (var i = 0; i < 3; i += 1) {
            var valor = valors[i];
            var cy = filaCY[i];
            var acolorir = FILA_ACOLORIR[i];

            // La font del valor només es recalcula si ha canviat la
            // llargada del text (p.ex. de 2 a 3 xifres), no cada frame.
            var fontValor;
            if (valor.length() == filaValorLenCache[i]) {
                fontValor = filaValorFontCache[i];
            } else {
                fontValor = ajustaFont(dc, valor, filaAmplaValorMax[i], filaAlcadaMax[i], FONTS_VALOR);
                filaValorLenCache[i] = valor.length();
                filaValorFontCache[i] = fontValor;
            }

            dc.setColor(fg, bg);
            dc.drawText(
                filaColEtiquetaCX[i], cy,
                filaFontEtiqueta[i], ETIQUETES[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

            if (acolorir) {
                dc.setColor(colorPerCho(choAvgEmaGH, minutsTranscorreguts), bg);
            }
            dc.drawText(
                filaColValorCX[i], cy,
                fontValor, valor,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            dc.setColor(fg, bg);

            if (acolorir) {
                dc.setColor(colorPerZona(zonaFCActual, bg), bg);
                dc.drawText(
                    filaZonaDretaX, cy,
                    Graphics.FONT_SMALL, zonaText,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
                );
                dc.setColor(fg, bg);
            }
        }

        // Línies divisòries horitzontals entre les 3 files (sense vertical)
        dc.drawLine(0, filaRowH[0], width, filaRowH[0]);
        dc.drawLine(0, filaRowH[0] + filaRowH[1], width, filaRowH[0] + filaRowH[1]);
    }
}
