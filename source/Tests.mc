// Tests unitaris de la 1.0 (només s'inclouen compilant amb --unit-test).
// Perfil fix: LT2 166, FCmàx 180, FC repòs 38, pes 66, VO2max 54.
//
//   monkeyc -o bin\CHOFAT_test.prg -f monkey.jungle -y keys\developer_key.der
//           -d epix2pro47mm --unit-test
//   monkeydo bin\CHOFAT_test.prg epix2pro47mm /t      (amb el simulador obert)
using Toybox.Test;
using Toybox.Lang;
using Toybox.Math;

(:debug)
function aprox(a as Lang.Float, b as Lang.Float, tol as Lang.Float) as Lang.Boolean {
    var d = a - b;
    if (d < 0.0) { d = -d; }
    return d <= tol;
}

(:debug)
function nouCamp() as CHOFATView {
    var v = new CHOFATView(false);
    v.tPerfil();
    return v;
}

// 1. RER per trams
(:test)
function t01_rer(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    var fcs = [116.2, 147.74, 166.0, 180.0, 190.0, 150.0];
    var esp = [0.86, 0.91, 0.98, 1.00, 1.00, 0.9187];
    for (var i = 0; i < fcs.size(); i++) {
        var r = v.tRer(fcs[i]);
        logger.debug("FC " + fcs[i] + " -> RER " + r);
        Test.assertMessage(aprox(r, esp[i], 0.001), "RER a FC " + fcs[i]);
    }
    return true;
}

// 3. Exemple: 12 increments d'1 kcal cada 5 s a FC 150
(:test)
function t03_exemple(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, 150);          // referència de temps
    v.processa(1000, 0, 150);       // base
    for (var i = 1; i <= 60; i++) {
        v.processa(1000 + 1000 * i, i / 5, 150);
    }
    var c = v.tCho();
    var f = v.tFat();
    logger.debug("CHO " + c + " FAT " + f + " kcal " + (4.1 * c + 9.3 * f));
    Test.assertMessage(aprox(c, 2.198, 0.002), "CHO");
    Test.assertMessage(aprox(f, 0.321, 0.002), "FAT");
    Test.assertMessage(aprox(4.1 * c + 9.3 * f, 12.0, 0.001), "conservacio");
    Test.assertMessage(!v.tReserva(), "mode Garmin");
    return true;
}

// 4. Conservació amb seqüència pseudoaleatòria (FC 100-185, increments 0-3)
(:test)
function t04_conservacio(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    var llavor = 12345;
    var kc = 100;
    v.processa(0, kc, 120);
    v.processa(1000, kc, 120);      // base = 100
    for (var i = 2; i <= 3600; i++) {
        llavor = (llavor * 1103515245 + 12345) & 0x7FFFFFFF;
        // Bits alts: els baixos d'un LCG tenen un període molt curt
        var fc = 100 + ((llavor >> 16) % 86);
        llavor = (llavor * 1103515245 + 12345) & 0x7FFFFFFF;
        if (((llavor >> 16) % 3) == 0) { kc += 1 + ((llavor >> 20) % 3); }   // 0-3 kcal
        v.processa(1000 * i, kc, fc);
    }
    var e = 4.1 * v.tCho() + 9.3 * v.tFat();
    logger.debug("kcal repartides " + e + " de " + (kc - 100));
    Test.assertMessage(!v.tReserva(), "sense reserva");
    Test.assertMessage(kc - 100 > 500, "prou energia");
    Test.assertMessage(aprox(e, (kc - 100).toFloat(), 0.01), "conservacio");
    return true;
}

// 5. Base: primer tick amb kc = 250 -> 0 g
(:test)
function t05_base(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 250, 140);
    v.processa(1000, 250, 140);
    v.processa(2000, 250, 140);
    Test.assertMessage(v.tCho() == 0.0 && v.tFat() == 0.0, "no reparteix la base");
    return true;
}

// 6. Pausa: timerTime congelat mentre kc puja 3 -> 0 g en pausa
(:test)
function t06_pausa(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, 140);
    v.processa(1000, 0, 140);                       // base 0
    for (var i = 2; i <= 31; i++) { v.processa(1000 * i, (i - 1) / 5, 140); }   // kc = 6
    var eAbans = 4.1 * v.tCho() + 9.3 * v.tFat();
    for (var j = 0; j < 60; j++) { v.processa(31000, 6 + j / 20, 140); }        // pausa: kc 6 -> 8
    v.processa(31000, 9, 140);                                                  // encara pausa: 9
    var ePausa = 4.1 * v.tCho() + 9.3 * v.tFat();
    for (var k = 1; k <= 30; k++) { v.processa(31000 + 1000 * k, 9 + k / 5, 140); } // kc = 15
    var eFinal = 4.1 * v.tCho() + 9.3 * v.tFat();
    logger.debug("abans " + eAbans + " pausa " + ePausa + " final " + eFinal);
    Test.assertMessage(aprox(eAbans, ePausa, 0.0001), "res en pausa");
    Test.assertMessage(aprox(eFinal, 12.0, 0.001), "conservacio sense la pausa (15 - 3)");
    return true;
}

// 7. Forat de FC: ticks sense FC, kc pujant -> tota l'energia assignada
(:test)
function t07_foratFc(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, 150);
    v.processa(1000, 0, 150);
    for (var i = 2; i <= 11; i++) { v.processa(1000 * i, (i - 1) / 5, 150); }   // kc = 2
    for (var i = 12; i <= 31; i++) { v.processa(1000 * i, (i - 1) / 5, null); }// kc = 6, sense FC
    var e = 4.1 * v.tCho() + 9.3 * v.tFat();
    Test.assertMessage(aprox(e, 6.0, 0.001), "energia del forat assignada");
    return true;
}

// 8. Sense FC mai i kc pujant -> 0 g
(:test)
function t08_senseFc(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, null);
    for (var i = 1; i <= 60; i++) { v.processa(1000 * i, i / 5, null); }
    Test.assertMessage(v.tCho() == 0.0 && v.tFat() == 0.0, "sense FC no s'assigna res");
    return true;
}

// 9. kc sempre null -> idèntic a la 0.5 (referència calculada aquí, amb el
//    perfil de tPerfil: FC repòs 38, FCmàx 180, pes 66, VO2max 54)
(:test)
function t09_reserva05(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    var choRef = 0.0;
    var fatRef = 0.0;
    v.processa(0, null, 120);
    for (var i = 1; i <= 600; i++) {
        var fc = 110 + (i % 70);
        v.processa(1000 * i, null, fc);
        var hrr = (fc - 38) / 142.0;
        if (hrr < 0.0) { hrr = 0.0; }
        if (hrr > 1.0) { hrr = 1.0; }
        var vo2 = (3.5 + hrr * (54.0 - 3.5)) * 66.0 / 1000.0;
        var rer = v.tRer(fc.toFloat());
        var c = vo2 * (4.210 * rer - 2.962);
        var f = vo2 * (1.695 - 1.701 * rer);
        if (c > 0.0) { choRef += c / 60.0; }
        if (f > 0.0) { fatRef += f / 60.0; }
    }
    logger.debug("CHO " + v.tCho() + " ref " + choRef);
    Test.assertMessage(v.tReserva(), "en reserva");
    Test.assertMessage(aprox(v.tCho(), choRef, 0.0001), "CHO = 0.5");
    Test.assertMessage(aprox(v.tFat(), fatRef, 0.0001), "FAT = 0.5");
    return true;
}

// 10. null 300 s al mig i, en tornar, salt de +40 -> el salt no s'assigna
(:test)
function t10_tornadaNull(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, 140);
    v.processa(1000, 0, 140);
    for (var i = 2; i <= 31; i++) { v.processa(1000 * i, (i - 1) / 5, 140); }   // kc = 6
    var eGarmin = 4.1 * v.tCho() + 9.3 * v.tFat();
    for (var i = 32; i <= 331; i++) { v.processa(1000 * i, null, 140); }        // 300 s reserva
    var eReserva = 4.1 * v.tCho() + 9.3 * v.tFat() - eGarmin;
    v.processa(332000, 46, 140);                                                // torna amb +40
    var eDesp = 4.1 * v.tCho() + 9.3 * v.tFat();
    logger.debug("Garmin " + eGarmin + " reserva " + eReserva + " despres " + eDesp);
    Test.assertMessage(eReserva > 0.0, "la reserva acumula");
    Test.assertMessage(aprox(eDesp, eGarmin + eReserva, 0.0001), "el salt no s'assigna");
    Test.assertMessage(!v.tReserva(), "torna a mode Garmin");
    return true;
}

// 11. kc encallat 130 s amb FC -> reserva a partir de 120 s
(:test)
function t11_encallat(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 10, 140);
    v.processa(1000, 10, 140);                      // base
    for (var i = 2; i <= 115; i++) { v.processa(1000 * i, 10, 140); }
    Test.assertMessage(!v.tReserva(), "encara Garmin a 114 s");
    for (var i = 116; i <= 131; i++) { v.processa(1000 * i, 10, 140); }
    Test.assertMessage(v.tReserva(), "reserva despres de 120 s");
    var eRes = 4.1 * v.tCho() + 9.3 * v.tFat();
    v.processa(132000, 11, 140);                    // primer canvi: base nova, no s'assigna
    Test.assertMessage(!v.tReserva(), "torna a Garmin");
    Test.assertMessage(aprox(4.1 * v.tCho() + 9.3 * v.tFat(), eRes, 0.0001), "primer canvi = base");
    return true;
}

// 12. kc baixa -> cap gram negatiu
(:test)
function t12_baixa(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 50, 140);
    v.processa(1000, 50, 140);
    for (var i = 2; i <= 11; i++) { v.processa(1000 * i, 50 + (i - 1) / 5, 140); } // 52
    var e = 4.1 * v.tCho() + 9.3 * v.tFat();
    v.processa(12000, 20, 140);                     // baixa
    v.processa(13000, 20, 140);
    Test.assertMessage(aprox(4.1 * v.tCho() + 9.3 * v.tFat(), e, 0.0001), "cap gram negatiu");
    return true;
}

// 13. FC 179 (RER > 0,9965) -> FAT = 0 i CHO = dE / 4,1
(:test)
function t13_rerAlt(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, 179);
    v.processa(1000, 0, 179);
    for (var i = 2; i <= 6; i++) { v.processa(1000 * i, (i - 1) / 5, 179); }    // +1 kcal
    logger.debug("RER " + v.tRer(179.0) + " CHO " + v.tCho() + " FAT " + v.tFat());
    Test.assertMessage(v.tFat() == 0.0, "FAT 0");
    Test.assertMessage(aprox(v.tCho(), 1.0 / 4.1, 0.0001), "CHO = 1/4,1");
    return true;
}

// 14. EMA: base just abans d'un clic (interval parcial d'1 s) i després 1 kcal cada 5 s a FC 150
//     (12 kcal/min -> 131,9 g/h). L'EMA no s'ha d'inflar amb el primer interval.
(:test)
function t14_emaInici(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, 150);
    v.processa(1000, 0, 150);                       // base
    var kc = 0;
    var emaMax = 0.0;
    var ema61 = 0.0;
    for (var t = 2; t <= 600; t++) {
        if ((t - 2) % 5 == 0) { kc += 1; }          // clics a 2, 7, 12... s
        v.processa(1000 * t, kc, 150);
        if (t >= 61 && v.tEma() > emaMax) { emaMax = v.tEma(); }
        if (t == 61) { ema61 = v.tEma(); }
    }
    logger.debug("EMA 61 s " + ema61 + "  max " + emaMax + "  600 s " + v.tEma());
    Test.assertMessage(aprox(ema61, 131.9, 131.9 * 0.10), "EMA al minut 1 dins del 10 %");
    Test.assertMessage(emaMax < 131.9 * 1.10, "EMA mai per sobre del 10 %");
    Test.assertMessage(aprox(v.tEma(), 131.9, 131.9 * 0.05), "EMA als 10 min dins del 5 %");
    return true;
}

// 15. onTimerReset deixa l'estat a zero
(:test)
function t15_reset(logger as Test.Logger) as Lang.Boolean {
    var v = nouCamp();
    v.processa(0, 0, 150);
    v.processa(1000, 0, 150);
    for (var i = 2; i <= 30; i++) { v.processa(1000 * i, i / 5, 150); }
    v.onTimerReset();
    v.tPerfil();
    Test.assertMessage(v.tCho() == 0.0 && v.tFat() == 0.0 && v.tReserva(), "reset");
    return true;
}
