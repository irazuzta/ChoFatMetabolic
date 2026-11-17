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

## Llançament 0.4.0

- **Verificat (14/11/2026):** amb una activitat real de trail run a l'Epix 2 Pro (versió de
  l'Store), Garmin Connect mostra les tres gràfiques i les tres dades de resum (CHO total,
  FAT total, CHO mitjà).
- Una caminada feta abans amb una versió anterior del rellotge no tenia cap camp de
  desenvolupador al `.fit` (ni al del rellotge ni a l'original de Connect). Probablement
  corria una versió d'abans de la 0.4.0; pendent de repetir-la amb la versió actual per
  descartar que caminar no els escrigui. Una sessió de força tampoc va mostrar res a
  Connect; no s'ha confirmat que Garmin deixi camps de Connect IQ en aquest tipus d'activitat.
- Memòria: Edge 130 Plus no s'ha mesurat al simulador (FR55 i Instinct 2S, sí: pic ~16 kB
  sobre 28,5 kB).

## Altres idees descartades de moment

- Camps per volta (LAP) per al fueling per etapes.
- Multisport: el perfil es llegeix un cop i a `onTimerReset()`; en un multisport els trams
  mantindrien el VO2max i les zones del primer esport.

## Model (després de la 0.5.0)

- **Sense terme de durada:** el RER real baixa uns 0,0004-0,0006 per minut a mesura que
  avança l'esforç; el CHO es va sobreestimant a la segona hora i després (~10-15% a la
  segona hora, més endavant). Descartat de moment per mantenir l'app simple; si es fa,
  seria un únic factor suau, no un model nou.
- **Sense ajust per sexe** (les dones tenen un RER ~0,03 més baix de mitjana): descartat,
  la dispersió individual és més gran que l'efecte.
- **Script de Python d'escriptori** (`tools/analitzador_fit.py`, fet el 17/11/2026): ja té
  les mateixes constants que l'app 0.5.0 i l'escala de colors del CHO. Si es canvia el model
  de l'app, cal canviar també l'script. Amb 4 activitats de prova (perfil per defecte) el
  model dona entre un +4 % i un +24 % més de kcal que Garmin: coincideix a les voltes suaus
  i se'n separa a les intenses.
- **Referències no verificades en línia** (la cita coincideix amb la memòria, però no s'han
  pogut obrir): Frayn 1983, Brooks & Mercier 1994, Hunter 1986, Karvonen 1957, i el text
  original de Jeukendrup & Wallis 2005 (el rang de validesa 50-75% VO2max ve de cites
  secundàries). Els valors de RER de Martínez-Noguera 2020 s'han retrobat a partir de les
  taxes d'oxidació publicades, no estan escrits tal qual a l'article.
- Comprovar amb una activitat real que el CHO nou té sentit comparat amb la teva experiència
  de fueling.
