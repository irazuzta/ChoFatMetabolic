# Funcionament de l'app CHO/FAT Metabòlic

Aquest document explica com està implementat el data field, fent referència a la base
teòrica descrita a [`01-base-teorica.md`](01-base-teorica.md) i al codi font a
[`source/CHOFATView.mc`](../source/CHOFATView.mc). No repeteix la justificació
científica de cada fórmula (això ja és al document 01) — se centra en com s'organitza
el codi i per què s'ha pres cada decisió d'enginyeria.

## 1. Què és i com s'integra a Garmin

És un **Data Field** de Connect IQ (no una app ni un widget): només es pot afegir com a
camp dins d'una pantalla de dades d'una activitat (Córrer, Bici, etc.), no apareix a la
llista d'apps del rellotge. Està escrit en Monkey C i implementat íntegrament a la
classe `CHOFATView`, que Garmin instancia un cop en començar l'activitat i actualitza
en dos moments diferents:

- `compute(info)`: cridat ~1 cop per segon amb les dades actuals de l'activitat
  (FC, temps de cronòmetre...). Aquí es fa **tot el càlcul**.
- `onUpdate(dc)`: cridat cada cop que cal redibuixar la pantalla. Aquí **només es
  dibuixa** el que ja s'ha calculat a `compute()` — no s'hi fa cap càlcul fisiològic.

## 2. Resolució del perfil fisiològic (`carregarPerfil()`)

En crear-se el data field, es resolen els 5 paràmetres físiologics que alimenten el
model (pes, FC de repòs, FC màxima, LT2, VO2max). Per a cadascun, la prioritat és:

1. **Valor manual** (`Properties`, a `resources/settings/properties.xml`) si l'usuari
   n'ha introduït un > 0.
2. Si no, **estimació automàtica** a partir del perfil de Garmin (`UserProfile`).
3. Si tampoc hi ha dada de Garmin, es queda amb un valor per defecte raonable
   codificat a la classe.

Nota important (documentada perquè costa de trobar): els valors manuals només es
poden editar des de la pantalla de configuració de la Connect IQ Store, que **no
funciona per a apps carregades per sideload** (veure §7) — la interfície de settings es
descarrega dinàmicament segons l'ID de l'app registrat a la Store, i un sideload no hi
té accés. Per tant, a la pràctica, mentre l'app no es publiqui, sempre funcionarà en
mode automàtic.

Per a `FCmax` i `LT2`, com que Garmin no els exposa directament (veure §5 del document
teòric), es dedueixen del `getHeartRateZones()` del rellotge: sostre de zona 5 → FCmax,
sostre de zona 4 → LT2. Al final de `carregarPerfil()` hi ha una comprovació de
coherència: si `FCmax` no queda per sobre de `FCrepòs`, o si `LT2` no queda entremig,
es corregeix automàticament (mai es deixa que valors absurds trenquin silenciosament
el càlcul de HRR/RER més endavant).

El punt de "sortida del repòs" $I_{onset}$ (document teòric §6) es calcula sempre com
a fracció de `lt2`, amb la constant `PCT_ACTIVACIO_CHO = 0.70` — no té equivalent de
laboratori, així que no s'ofereix com a valor manual (§6 del document teòric).

$LT_1$, en canvi, sí és un llindar fisiològic real que un esportista pot conèixer
d'una prova pròpia, així que segueix el mateix patró que la resta del perfil: si
l'usuari en introdueix un valor manual (`lt1Manual`, propietat > 0) i queda coherent
(entre `fcRepos` i `lt2`), es fa servir directament; si no, es descarta en silenci i
es torna a l'estimació `PCT_LT1 * lt2` (`PCT_LT1 = 0.85`).

## 3. Cicle de càlcul (`compute()`)

Per cada mostra vàlida (amb FC disponible):

1. **Control de temps**: es calcula `dtMs` des de l'última mostra. Si `dtMs <= 0`
   (activitat en pausa) o `dtMs` supera `DT_MAX_MS` (5000 ms — típicament un tall de
   sensor òptic), es descarta la mostra en comptes d'acumular-hi res. Això evita que un
   tall de sensor de, per exemple, 90 segons, s'apliqui retroactivament amb la taxa
   instantània del moment de reconnexió sobre tot el forat (bug real detectat i
   corregit durant el desenvolupament, i validat contra un fitxer `.FIT` real amb un
   tall de sensor genuí).
2. **Zona de FC actual** (`zonaFCActual`): es determina comparant la FC contra els
   llindars de `zonesFC` (guardats a `carregarPerfil()`), per a l'indicador petit
   Z1-Z5.
3. **HRR → VO2** i **RER per zones** → grams de CHO/FAT per minut, seguint exactament
   les fórmules descrites al document teòric (§3-7).
4. **Acumulació**: `totalChoGrams` i `totalFatGrams` sumen els grams d'aquest tick
   (la discretització de la integral CHO_total/FAT_total, veure document teòric §8.2).
5. **Mitjana mòbil exponencial** (`choAvgEmaGH`): és la tècnica de suavitzat concreta
   que fa servir aquesta app per a la taxa mostrada (document teòric §8.3 — quina
   tècnica i amb quins paràmetres és una decisió d'implementació, no de model).
   S'actualitza amb `alpha_tick = dtMin / TAU_EMA_MIN` (τ=15 min). La primera mostra
   vàlida inicialitza l'EMA directament amb el valor instantani (no comença a 0 i puja
   lentament).

## 4. Interfície visual (`onUpdate()`)

### 4.1. Graella de 3 files × 2 columnes

La pantalla es divideix en 3 franges horitzontals iguals (1/3 d'alçada cadascuna):

```
[ CHO (g)        | 123    ]
[ CHO avg (g/h)  | 45  Z3 ]   <- acolorida + indicador de zona
[ FAT (g)        | 67     ]
```

Cada fila es divideix en columna d'etiqueta (40%) i columna de valor (60%), sense línia
vertical de separació (només línies horitzontals entre files). La fila central reserva,
a més, una petita franja addicional a la dreta de tot per a l'indicador de zona, perquè
mai quedi sota el número (es calcula l'amplada real del text "Z1".."Z5" i es descompta
abans de repartir les columnes 40/60).

### 4.2. Amplada segura en pantalla rodona (`amplaSeguraFila`)

En una pantalla rodona, l'amplada útil no és constant: és màxima al centre vertical i
es redueix cap a dalt/baix (és la corda d'una circumferència a una alçada donada). Si
es fessin servir columnes d'amplada fixa a totes les files per igual, les etiquetes de
les files de dalt/baix quedarien tallades pel bisell (bug real detectat visualment i
corregit). La funció `amplaSeguraFila()` calcula, per a cada fila, l'amplada realment
disponible a l'alçada més extrema d'aquella fila:

```
distancia_extrem = |cy - centre_Y| + alçada_fila/2
amplada_segura = 2 · √(radi² - distancia_extrem²)
```

i totes les columnes d'aquella fila es calculen sobre aquesta amplada seguraa, no sobre
l'amplada total de la pantalla.

### 4.3. Mida de font adaptativa (`ajustaFont`)

Per a cada text (etiqueta o valor), es prova una llista de fonts candidates de més
gran a més petita i es queda amb la primera que hi càpiga alhora en amplada **i**
alçada disponibles. Per als valors numèrics, la llista inclou les fonts grans
específiques per a xifres de Monkey C (`FONT_NUMBER_HOT/MEDIUM/MILD`), que es veuen
notablement més grans que les fonts de text genèriques per al mateix espai — són el
tipus de font que fan servir els data fields natius de Garmin per als seus números
principals.

### 4.4. Cache de geometria i de fonts (rendiment)

Com que `onUpdate()` es crida molt sovint (típicament ~1 cop/segon), la geometria de
les 3 files (posicions, amplada de columnes, font de les etiquetes) es calcula un sol
cop a `calcularGeometria()` i es guarda en camps de la classe, en comptes de
recalcular-la a cada crida — només es torna a calcular si la mida de pantalla canvia
respecte al valor en cache (a la pràctica, mai durant una activitat).

De la mateixa manera, la font del valor numèric de cada fila només es torna a buscar
(`ajustaFont`) quan canvia la **llargada** del text (p.ex. de 2 a 3 xifres), no cada
frame — la immensa majoria de crides reutilitzen la font ja calculada en comptes de
tornar a provar totes les candidates. Això evita treball repetit innecessari, tot i
que l'impacte real en bateria és petit comparat amb el consum del GPS o del sensor de
FC, que és el mateix independentment de quin data field es mostri.

## 5. Codi de colors

### 5.1. Consum de CHO (fueling)

El valor de `CHO avg (g/h)` s'acolora amb `colorPerCho(valor, minutsSessió)` seguint
les bandes esglaonades per temps descrites al document teòric (§9):

| Temps transcorregut | Verd | Taronja | Vermell |
|---|---|---|---|
| < 45 min | (sempre verd) | — | — |
| 45 min - 2h | < 30 g/h | 30-60 g/h | > 60 g/h |
| > 2h | < 60 g/h | 60-90 g/h | > 90 g/h |

### 5.2. Zona de FC

El text "Z1".."Z5" es pinta amb `colorPerZona(zona)`, reproduint l'esquema estàndard
de colors de zones de Garmin Connect: gris fosc (Z1), blau (Z2), verd (Z3), taronja
(Z4), vermell (Z5). És independent del color del valor de CHO — poden mostrar colors
diferents alhora (p.ex. "verd" de fueling i "Z4" de zona), i és intencionat: un
representa consum de carbohidrats i l'altre intensitat de l'esforç.

## 6. Eines de desenvolupament

[`tools/Run-Simulator.ps1`](../tools/Run-Simulator.ps1) automatitza compilar i llançar
l'app al simulador de Connect IQ: detecta l'SDK actiu automàticament (llegint
`current-sdk.cfg`), permet triar el dispositiu (menú interactiu o `-Device <id>`), i
reutilitza el simulador si ja n'hi ha un obert.

## 7. Desplegament al rellotge real (sideload)

Provat i confirmat funcionant a un Garmin Epix 2 Pro (47mm). Particularitat important
d'aquest model (i probablement d'altres dispositius amb firmware modern equivalent): el
mètode clàssic de sideload (copiar el `.prg` a una carpeta `GARMIN/APPS` en majúscules)
**no funciona**, perquè el dispositiu ja té una carpeta `GARMIN/Apps` (minúscules) d'ús
intern del firmware, i el sistema de fitxers del rellotge no distingeix
majúscules/minúscules — no es pot crear una carpeta separada amb un nom que només es
diferencia per la caixa de lletra.

**Mètode que funciona**: copiar el `.prg` directament dins la carpeta `GARMIN/Apps` ja
existent (sense crear-ne cap altra), connectant el rellotge per USB (apareix com a
dispositiu MTP, no com a unitat de disc — cal navegar-hi amb `Shell.Application` des de
PowerShell, no amb `Copy-Item`). En desconnectar el rellotge, el firmware detecta el
fitxer nou i el processa cap a la seva base de dades interna d'apps.

Camins descartats durant la investigació (documentats perquè no calgui tornar-los a
provar): el mode *native pairing* de `monkeydo` (`/n`) és per aparellar sensors
ANT/BLE amb l'app, no per instal·lar-la; el menú *adb Connection* del simulador és un
pont de depuració per a l'app mòbil companion (Android), no per al rellotge; Garmin
Express només permet gestionar/navegar la Connect IQ Store, no fer sideload manual des
d'un fitxer local.

## 8. Limitacions conegudes

- El model és una aproximació basada exclusivament en FC; no capta l'efecte de la
  durada sobre la despesa relativa de substrats (glicogen que es va esgotant a la
  mateixa intensitat relativa amb el pas del temps), ja que és inherentment un model
  instantani.
- `FCmax` i `LT2` són estimacions basades en zones de FC configurades, no mesures
  directes — la seva precisió depèn de com l'usuari (o Garmin) hagi configurat
  aquestes zones.
- Les dades no es desen de forma visible a Garmin Connect (no s'ha implementat
  `FitContributor`); per a anàlisi posterior cal reprocessar el `.FIT` estàndard de
  l'activitat amb una eina externa (l'app ja disposa d'un script de referència en
  Python fet servir durant el desenvolupament per validar l'algoritme contra dades
  reals).
