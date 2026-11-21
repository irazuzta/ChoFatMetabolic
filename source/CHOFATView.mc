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
using Toybox.FitContributor;

// ============================================================================
// CHOFATView
//
// Versió 1.0: l'energia ve de Garmin (Activity.Info.calories) i es
// reparteix entre carbohidrats (CHO) i greixos (FAT) amb el RER estimat per
// trams de FC (Jeukendrup & Wallis, 4,1 / 9,3 kcal/g). Si Garmin no dona
// energia, reserva automàtica: el model només de FC de la versió 0.5.
// Teoria: docs/04-theoretical-basis-garmin-energy.md (i 01 per a la reserva).
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
    hidden var tempsActiuMs as Lang.Number = 0; // temps realment acumulat (mostres vàlides)
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

    // --- Llindars de color del CHO (g/h). Comparen el ritme d'oxidació de
    //     CHO amb el que es pot absorbir realment durant l'exercici
    //     (Jeukendrup): ~60 g/h amb una sola font de carbohidrat i fins a
    //     ~90 g/h amb barreges de transport múltiple. Verd = es pot cobrir
    //     amb una ingesta normal; taronja = cal una ingesta alta; vermell =
    //     per sobre del que es pot absorbir (s'està gastant glicogen).
    //     Als primers minuts els dipòsits són plens i no s'acolareix.
    const FUELING_FASE1_MIN = 45.0;   // abans d'això, sempre verd (dipòsits plens)
    const CHO_VERD = 60.0;
    const CHO_TARONJA = 90.0;

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

    // --- Paràmetres del model metabòlic: esportistes aficionats-entrenats
    //     (VO2max ~45-60), dieta mixta normal, estat d'alimentat, esforç
    //     estable. Esportistes d'elit o adaptats al greix: el CHO es
    //     sobreestima; poc entrenats: se subestima (veure documentació). ---
    const PCT_ACTIVACIO_CHO = 0.70; // Inici Zona 2
    const PCT_LT1 = 0.89;           // Llindar Aeròbic (% del LT2)
    const RER_BASAL = 0.86;         // RER a baixa intensitat (alimentat)
    const RER_LT1 = 0.91;
    const RER_LT2 = 0.98;
    const RER_MAX = 1.00;

    // Si el sensor de FC talla més d'aquest temps (ms), descartem la mostra
    // en comptes d'extrapolar la taxa instantània sobre tot el forat.
    const DT_MAX_MS = 5000;

    // --- 0.6: energia de Garmin (Info.calories) ---
    const KCAL_G_CHO = 4.1;          // kcal per gram (coherent amb J&W)
    const KCAL_G_FAT = 9.3;
    const CAL_STALL_MS = 120000;     // Info.calories sense pujar aquest temps -> reserva
    const EMA_INIT_MS = 60000;       // temps actiu abans d'arrencar l'EMA (fins llavors, mitjana real)

    hidden var kcalPrev as Lang.Number? = null;     // últim Info.calories processat (base)
    hidden var enReserva as Lang.Boolean = true;    // true: energia del model 0.5.0
    hidden var msUltimIncrement as Lang.Number = 0; // timerTime de l'últim increment o de la base
    hidden var intMs as Lang.Number = 0;            // temps de cronòmetre de l'interval en curs
    hidden var intRerMin as Lang.Float = 0.0;       // suma RER*dtMin dels ticks amb FC vàlida
    hidden var intMinFc as Lang.Float = 0.0;        // suma dtMin amb FC vàlida
    hidden var rerUltim as Lang.Float = -1.0;       // últim RER vàlid; < 0 = encara cap FC


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

    // --- Camps propis escrits al fitxer .FIT de l'activitat (FitContributor).
    //     Es veuen a Garmin Connect (gràfica / resum) un cop sincronitzada
    //     l'activitat. Els ids han de coincidir amb fitcontributions.xml i
    //     NO s'han de canviar un cop publicats. ---
    const FIT_ID_CHO_ACUM = 0;
    const FIT_ID_FAT_ACUM = 1;
    const FIT_ID_CHO_RATE = 2;
    const FIT_ID_CHO_TOTAL = 3;
    const FIT_ID_FAT_TOTAL = 4;
    const FIT_ID_CHO_AVG = 5;

    hidden var fitChoAcum as FitContributor.Field?;
    hidden var fitFatAcum as FitContributor.Field?;
    hidden var fitChoRate as FitContributor.Field?;
    hidden var fitChoTotal as FitContributor.Field?;
    hidden var fitFatTotal as FitContributor.Field?;
    hidden var fitChoAvg as FitContributor.Field?;

    // ambFit = false només als tests unitaris (createField no funciona fora
    // d'una activitat i llança un error que no es pot capturar).
    function initialize(ambFit as Lang.Boolean) {
        DataField.initialize();
        carregarPerfil();
        if (ambFit) {
            crearCampsFit();
        }
    }

    // Escriu un valor en un camp FIT, tolerant que el camp no s'hagi pogut
    // crear (el càlcul i la pantalla no han de dependre del FIT).
    hidden function desaFit(camp as FitContributor.Field?, valor as Lang.Float) as Void {
        if (camp != null) {
            camp.setData(valor);
        }
    }

    // ------------------------------------------------------------------
    // Crea els 6 camps FIT: 3 de RECORD (valor cada segon, per a la gràfica)
    // i 3 de SESSION (un sol valor per a tota l'activitat, per al resum).
    // ------------------------------------------------------------------
    function crearCampsFit() as Void {
        var rec = FitContributor.MESG_TYPE_RECORD;
        var ses = FitContributor.MESG_TYPE_SESSION;
        var flt = FitContributor.DATA_TYPE_FLOAT;

        // Si el dispositiu no pot crear els camps (p.ex. límit de camps de
        // desenvolupador exhaurit), el Data Field segueix funcionant sense FIT.
        try {

        fitChoAcum  = createField("cho_acum_g",   FIT_ID_CHO_ACUM,  flt, {:mesgType => rec, :units => "g"});
        fitFatAcum  = createField("fat_acum_g",   FIT_ID_FAT_ACUM,  flt, {:mesgType => rec, :units => "g"});
        fitChoRate  = createField("cho_rate_gh",  FIT_ID_CHO_RATE,  flt, {:mesgType => rec, :units => "g/h"});
        fitChoTotal = createField("cho_total_g",  FIT_ID_CHO_TOTAL, flt, {:mesgType => ses, :units => "g"});
        fitFatTotal = createField("fat_total_g",  FIT_ID_FAT_TOTAL, flt, {:mesgType => ses, :units => "g"});
        fitChoAvg   = createField("cho_avg_gh",   FIT_ID_CHO_AVG,   flt, {:mesgType => ses, :units => "g/h"});

        desaFit(fitChoAcum, 0.0);
        desaFit(fitFatAcum, 0.0);
        desaFit(fitChoRate, 0.0);
        desaFit(fitChoTotal, 0.0);
        desaFit(fitFatTotal, 0.0);
        desaFit(fitChoAvg, 0.0);
        } catch (ex) {
            fitChoAcum = null;
            fitFatAcum = null;
            fitChoRate = null;
            fitChoTotal = null;
            fitFatTotal = null;
            fitChoAvg = null;
        }
    }

    // ------------------------------------------------------------------
    // Resol el perfil fisiològic combinant dades del rellotge/Garmin
    // Connect amb els valors manuals opcionals de l'usuari (propietats).
    // Un valor manual > 0 sempre té prioritat sobre l'estimació automàtica.
    // ------------------------------------------------------------------
    // Llegeix una propietat numèrica; si no és un número (p.ex. text
    // enviat per l'app del mòbil) retorna 0.0, que vol dir "no fixat".
    hidden function propNum(clau as Lang.String) as Lang.Float {
        var v = Application.Properties.getValue(clau);
        if (v instanceof Lang.Number || v instanceof Lang.Float) {
            return v.toFloat();
        }
        return 0.0;
    }

    function carregarPerfil() as Void {
        var profile = UserProfile.getProfile();

        // 1) Pes
        var pesManual = propNum("pesManualKg");
        if (pesManual > 0.0) {
            pesKg = pesManual;
        } else if (profile != null) {
            var pesPerfil = profile.weight;
            if (pesPerfil != null) {
                pesKg = pesPerfil.toFloat() / 1000.0; // grams -> kg
            }
        }

        // 2) FC de repòs
        var fcReposManual = propNum("fcReposManual").toNumber();
        if (fcReposManual > 0) {
            fcRepos = fcReposManual;
        } else if (profile != null) {
            var fcReposPerfil = profile.restingHeartRate;
            if (fcReposPerfil != null && fcReposPerfil > 0) {
                fcRepos = fcReposPerfil;
            }
        }

        // 3) VO2max (estimat pel rellotge, si no hi ha manual). Garmin guarda
        //    per separat el VO2max de córrer i el de ciclisme — cal triar el
        //    que correspongui a l'esport actual (rellevant sobretot en
        //    dispositius Edge, on el de córrer sempre seria null).
        var sport = UserProfile.getCurrentSport();
        var vo2Manual = propNum("vo2maxManual");
        if (vo2Manual > 0.0) {
            vo2max = vo2Manual;
        } else if (profile != null) {
            var enBici = (sport == UserProfile.HR_ZONE_SPORT_BIKING);
            var vo2Perfil = enBici ? profile.vo2maxCycling : profile.vo2maxRunning;
            if (vo2Perfil == null) {
                // Sense potenciòmetre molts usuaris no tenen VO2max de ciclisme:
                // millor fer servir l'altre valor que el per defecte (50).
                vo2Perfil = enBici ? profile.vo2maxRunning : profile.vo2maxCycling;
            }
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

        var fcMaxManual = propNum("fcMaxManual").toNumber();
        if (fcMaxManual > 0) {
            fcMax = fcMaxManual;
        } else if (zones != null && zones.size() >= 6) {
            var z5 = zones[5];
            if (z5 != null) {
                fcMax = z5;
            }
        }

        var lt2Manual = propNum("lt2Manual").toNumber();
        if (lt2Manual > 0) {
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
        //    També ha de quedar per sobre del punt d'activació de CHO (70% LT2),
        //    si no el RER faria un salt en interpolar.
        var lt1Manual = propNum("lt1Manual").toNumber();
        if (lt1Manual > fcRepos && lt1Manual > PCT_ACTIVACIO_CHO * lt2 && lt1Manual < lt2) {
            lt1Fixat = lt1Manual;
        } else {
            lt1Fixat = 0;
        }
    }

    // ------------------------------------------------------------------
    // L'activitat ha acabat (desada o descartada): tornem a zero perquè
    // l'activitat següent no hereti els grams, la mitjana ni l'EMA, i
    // rellegim el perfil (esport o ajustos poden haver canviat).
    // ------------------------------------------------------------------
    function onTimerReset() as Void {
        totalChoGrams = 0.0;
        totalFatGrams = 0.0;
        choRateGH = 0.0;
        choAvgGH = 0.0;
        choAvgEmaGH = 0.0;
        emaInicialitzada = false;
        hasStarted = false;
        lastTimerTimeMs = 0;
        tempsActiuMs = 0;
        minutsTranscorreguts = 0.0;
        carregarPerfil();
        kcalPrev = null;
        enReserva = true;
        msUltimIncrement = 0;
        rerUltim = -1.0;
        reiniciaInterval();
        desaFit(fitChoAcum, 0.0);
        desaFit(fitFatAcum, 0.0);
        desaFit(fitChoRate, 0.0);
        desaFit(fitChoTotal, 0.0);
        desaFit(fitFatTotal, 0.0);
        desaFit(fitChoAvg, 0.0);
    }

    // ------------------------------------------------------------------
    // RER interpolat per trams de FC (mateix model que la 0.5.0).
    // ------------------------------------------------------------------
    hidden function rerPerFc(fc as Lang.Float) as Lang.Float {
        var lt1Bpm = (lt1Fixat > 0) ? lt1Fixat.toFloat() : PCT_LT1 * lt2;
        var punt = PCT_ACTIVACIO_CHO * lt2;
        if (fc <= punt) {
            return RER_BASAL;
        }
        if (fc <= lt1Bpm) {
            return RER_BASAL + (fc - punt) / (lt1Bpm - punt) * (RER_LT1 - RER_BASAL);
        }
        if (fc <= lt2) {
            return RER_LT1 + (fc - lt1Bpm) / (lt2 - lt1Bpm).toFloat() * (RER_LT2 - RER_LT1);
        }
        var denom = (fcMax - lt2).toFloat();
        var ratio3 = denom > 0.0 ? (fc - lt2) / denom : 1.0;
        if (ratio3 > 1.0) { ratio3 = 1.0; }
        return RER_LT2 + ratio3 * (RER_MAX - RER_LT2);
    }

    // Model 0.5: %HRR -> VO2 (L/min). Només per a la reserva.
    hidden function vo2FcLMin(fc as Lang.Float) as Lang.Float {
        var hrr = (fc - fcRepos) / (fcMax - fcRepos).toFloat();
        if (hrr < 0.0) { hrr = 0.0; }
        if (hrr > 1.0) { hrr = 1.0; }
        return (3.5 + hrr * (vo2max - 3.5)) * pesKg / 1000.0;
    }

    hidden function reiniciaInterval() as Void {
        intMs = 0;
        intRerMin = 0.0;
        intMinFc = 0.0;
    }

    // ------------------------------------------------------------------
    // Es crida aproximadament un cop per segon. Només llegeix Activity.Info
    // i delega a processa(), que té tota la lògica.
    // ------------------------------------------------------------------
    function compute(info as Activity.Info) as Void {
        if (info.timerTime == null) {
            return;
        }
        processa(info.timerTime as Lang.Number, info.calories, info.currentHeartRate);
    }

    // ------------------------------------------------------------------
    // 0.6: l'energia ve de les kcal de Garmin (Info.calories, acumulat).
    // Cada increment de kcal es converteix en litres d'O2 amb el RER mitjà
    // de l'interval (equivalent energètic coherent amb 4,1 / 9,3 kcal/g) i
    // es reparteix en grams amb Jeukendrup & Wallis. Si Garmin no dona
    // calories (null o encallat > CAL_STALL_MS), reserva = model 0.5.0.
    // ------------------------------------------------------------------
    function processa(timerTimeMs as Lang.Number, kc as Lang.Number?, fcObj as Lang.Number?) as Void {
        // Primera crida: només referència de temps.
        if (!hasStarted) {
            lastTimerTimeMs = timerTimeMs;
            hasStarted = true;
            return;
        }

        var dtMs = timerTimeMs - lastTimerTimeMs;
        lastTimerTimeMs = timerTimeMs;

        // Pausa (o abans d'engegar): timerTime no avança. No s'acumula res;
        // l'energia que Garmin pugui comptar en pausa no es reparteix: només
        // es mou la base.
        if (dtMs <= 0) {
            if (kc != null && kcalPrev != null && !enReserva) {
                var dPausa = (kc as Lang.Number) - (kcalPrev as Lang.Number);
                if (dPausa > 0) {
                    kcalPrev = kc;
                    reiniciaInterval();
                }
            }
            return;
        }

        minutsTranscorreguts = timerTimeMs / 60000.0;
        var dtMin = dtMs / 60000.0;

        // --- FC i RER d'aquest tick (mateix criteri de validesa que la 0.5.0) ---
        var fcValida = (fcObj != null) && (dtMs <= DT_MAX_MS);
        var fcActual = 0.0;
        var rer = 0.0;
        if (fcValida) {
            fcActual = (fcObj as Lang.Number).toFloat();

            // Zona de FC actual (per a l'indicador petit Z1..Z5)
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

            rer = rerPerFc(fcActual);
            rerUltim = rer;
        }

        var choTick = 0.0;
        var fatTick = 0.0;
        var comptaTemps = false;

        // ---- Font d'energia ----
        if (kc == null) {
            // Sense calories de Garmin: reserva. En tornar, el primer valor serà base nova.
            enReserva = true;
            kcalPrev = null;
        } else if (kcalPrev == null || (enReserva && kc != kcalPrev)) {
            // Base nova: inici, recàrrega del camp, tornada d'un null o primer canvi
            // després d'un encallament. NO es reparteix el que Garmin ja porta comptat.
            kcalPrev = kc;
            enReserva = false;
            msUltimIncrement = timerTimeMs;
            reiniciaInterval();
        } else if (!enReserva) {
            // Mode Garmin: aquest tick forma part de l'interval que tancarà el proper increment.
            intMs += dtMs;
            if (fcValida) {
                intRerMin += rer * dtMin;
                intMinFc += dtMin;
            }
            comptaTemps = true;

            var kcN = kc as Lang.Number;
            var prevN = kcalPrev as Lang.Number;
            if (kcN > prevN) {
                var rerInt = (intMinFc > 0.0) ? intRerMin / intMinFc : rerUltim;
                if (rerInt > 0.0) {                       // < 0: encara no hi ha hagut mai FC
                    var dE = (kcN - prevN).toFloat();
                    var cL = 4.210 * rerInt - 2.962;
                    if (cL < 0.0) { cL = 0.0; }
                    var fL = 1.695 - 1.701 * rerInt;
                    if (fL < 0.0) { fL = 0.0; }
                    var litresO2 = dE / (KCAL_G_CHO * cL + KCAL_G_FAT * fL);
                    choTick = litresO2 * cL;
                    fatTick = litresO2 * fL;
                }
                kcalPrev = kcN;
                msUltimIncrement = timerTimeMs;
                reiniciaInterval();
            } else if (kcN < prevN) {
                // No hauria de passar: base nova, sense grams negatius.
                kcalPrev = kcN;
                msUltimIncrement = timerTimeMs;
                reiniciaInterval();
            } else if (timerTimeMs - msUltimIncrement > CAL_STALL_MS) {
                // Garmin no compta (valor encallat): reserva. kcalPrev es manté per
                // detectar el primer canvi, que serà base nova.
                enReserva = true;
                reiniciaInterval();
            }
        }

        // ---- Reserva: exactament el càlcul de la 0.5.0 ----
        if (enReserva) {
            if (!fcValida) {
                return;                                   // com la 0.5.0: sense FC no s'acumula
            }
            var vo2 = vo2FcLMin(fcActual);
            var choGMin = vo2 * (4.210 * rer - 2.962);
            if (choGMin < 0.0) { choGMin = 0.0; }
            var fatGMin = vo2 * (1.695 - 1.701 * rer);
            if (fatGMin < 0.0) { fatGMin = 0.0; }
            choTick = choGMin * dtMin;
            fatTick = fatGMin * dtMin;
            comptaTemps = true;
        }

        if (!comptaTemps) {
            return;
        }

        // ---- Acumulació, mitjanes i FIT: igual que la 0.5.0 ----
        tempsActiuMs += dtMs;   // en mode Garmin també compta els forats de FC (la seva energia hi és)
        totalChoGrams += choTick;
        totalFatGrams += fatTick;
        choRateGH = choTick / dtMin * 60.0;   // en mode Garmin: 0 o un pic; només alimenta l'EMA

        var horesTotals = tempsActiuMs / 3600000.0;
        choAvgGH = horesTotals > 0.0 ? totalChoGrams / horesTotals : 0.0;

        // EMA: durant el primer minut es mostra la mitjana real acumulada
        // (grams / temps). El primer increment de Garmin tanca un interval
        // parcial (el camp comença a mirar a mig interval) i arrencar l'EMA
        // amb aquesta taxa la inflava durant molts minuts. Passat
        // EMA_INIT_MS, l'EMA arrenca d'aquesta mitjana i segueix normalment.
        if (!emaInicialitzada) {
            choAvgEmaGH = choAvgGH;
            if (tempsActiuMs >= EMA_INIT_MS) {
                emaInicialitzada = true;
            }
        } else {
            var alphaTick = dtMin / TAU_EMA_MIN;
            if (alphaTick > 1.0) { alphaTick = 1.0; }
            choAvgEmaGH = choAvgEmaGH + alphaTick * (choRateGH - choAvgEmaGH);
        }

        desaFit(fitChoAcum, totalChoGrams);
        desaFit(fitFatAcum, totalFatGrams);
        desaFit(fitChoRate, choAvgEmaGH);
        desaFit(fitChoTotal, totalChoGrams);
        desaFit(fitFatTotal, totalFatGrams);
        desaFit(fitChoAvg, choAvgGH);
    }

    // ------------------------------------------------------------------
    // Accessos per als tests unitaris (source/Tests.mc). Amb (:debug) no entren
    // a la build de release (-r) que es puja a l'Store.
    // ------------------------------------------------------------------
    (:debug)
    function tPerfil() as Void {
        fcRepos = 38; fcMax = 180; lt2 = 166; pesKg = 66.0; vo2max = 54.0; lt1Fixat = 0;
    }
    (:debug)
    function tRer(fc as Lang.Float) as Lang.Float { return rerPerFc(fc); }
    (:debug)
    function tCho() as Lang.Float { return totalChoGrams; }
    (:debug)
    function tFat() as Lang.Float { return totalFatGrams; }
    (:debug)
    function tReserva() as Lang.Boolean { return enReserva; }
    (:debug)
    function tEma() as Lang.Float { return choAvgEmaGH; }

    // ------------------------------------------------------------------
    // Codi de colors segons la taxa d'oxidació de CHO (g/h): als primers
    // 45 min sempre verd (glicogen ple); després, verd fins a 60 g/h,
    // taronja fins a 90 g/h i vermell per sobre (veure CHO_VERD/CHO_TARONJA).
    // ------------------------------------------------------------------
    function colorPerCho(valorGH as Lang.Float, minutsSessio as Lang.Float) as Graphics.ColorType {
        if (minutsSessio < FUELING_FASE1_MIN) {
            return Graphics.COLOR_GREEN;
        }

        if (valorGH < CHO_VERD) {
            return Graphics.COLOR_GREEN;
        } else if (valorGH < CHO_TARONJA) {
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
