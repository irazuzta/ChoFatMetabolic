# Revisions futures

Coses detectades que no s'han fet encara. Només com a recordatori: no afegir
funcionalitat nova, només ajustar el que ja hi ha.

## Ajustos visuals en diferents models

Detectat a la 0.4.1 en proves al simulador (14/11/2026), sense dades reals encara:

- **Forerunner 55:** l'etiqueta "CHO avg (g/h)" es talla pel costat esquerre
  ("HO avg (g/h)") i, a la fila de FAT, la "g)" de l'etiqueta se superposa al número.
- **Instinct 2S:** les etiquetes també queden apretades (el subscreen rodó de dalt a la
  dreta té text superposat); cal mirar què es dibuixa allà.
- En general: pantalles petites / de resolució baixa. La mida de font de l'etiqueta
  (`filaFontEtiqueta`) i l'amplada segura de fila (`amplaSeguraFila`) es calculen per a
  pantalles grans; potser cal una font d'etiqueta més petita o una etiqueta més curta
  ("CHO avg" en comptes de "CHO avg (g/h)") quan l'ample disponible és baix.

Per fer-ho bé:

1. Provar al simulador, amb valors reals en marxa (Simulation > Activity Data), i fer
   captura per cada model de la llista: fr55, fr165, instinct2s, instinct3solar45mm,
   venusq, vivoactive4, fenix6s, edge130plus, edge540, fenix8pro47mm.
2. Els valors petits (0) amaguen problemes: mirar també amb valors de 3 i 4 xifres
   (p. ex. CHO total de 150 g).
3. Si cal canviar-ho, que sigui un ajust de la geometria existent, no un disseny nou.

## Pendent del llançament 0.4.0

- Comprovar amb una activitat real que Garmin Connect mostra les tres gràfiques i el
  resum (CHO total, FAT total, CHO mitjà). Fins ara només s'ha verificat el `.FIT` al
  simulador.
- Memòria: Edge 130 Plus no s'ha mesurat al simulador (FR55 i Instinct 2S, sí: pic ~16 kB
  sobre 28,5 kB).

## Altres idees descartades de moment

- Camps per volta (LAP) per al fueling per etapes.
- Multisport: el perfil es llegeix un cop i a `onTimerReset()`; en un multisport els trams
  mantindrien el VO2max i les zones del primer esport.
