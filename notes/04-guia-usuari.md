# Guia d'usuari

Aquest document explica, en llenguatge senzill i sense entrar en fórmules, què
mostra el data field a la pantalla, què vol dir cada paràmetre del teu perfil i
com els pots configurar. Si vols saber com es calcula tot per dins, mira
[`01-base-teorica.md`](01-base-teorica.md) (el model científic) o
[`02-funcionament-app.md`](02-funcionament-app.md) (com està implementat).

> **Per a qui és?** Les estimacions estan calibrades per a esportistes de fons
> aficionats-entrenats (aproximadament VO2max 45-60) que fan una dieta mixta normal i
> entrenen havent menjat. Si entrenes en dejú, fas una dieta baixa en carbohidrats o
> cetogènica, o ets un esportista d'elit, l'app tendirà a **sobreestimar** el consum de
> carbohidrats; si ets poc entrenat, tendirà a **subestimar-lo**. Les sessions llargues,
> la calor i la deshidratació també fan pujar l'estimació. Pren els números com una
> bona indicació de l'ordre de magnitud i de les tendències, no com una mesura de
> laboratori.

## 1. Què veus a la pantalla

```
[ CHO (g)        | 123    ]
[ CHO avg (g/h)  | 45  Z3 ]
[ FAT (g)        | 67     ]
```

- **CHO (g)** — total de carbohidrats que has cremat des que vas començar
  l'activitat.
- **CHO avg (g/h)** — a quin ritme estàs cremant carbohidrats ara mateix (una
  mitjana suavitzada, no el valor instantani sec). Es pinta d'un color segons si
  aquest ritme és baix, mitjà o alt (veure §4).
- **FAT (g)** — total de greix que has cremat des que vas començar l'activitat.
- **Z1..Z5** (a la dreta de la fila central) — la teva zona de freqüència
  cardíaca actual, amb els mateixos colors que fa servir Garmin Connect per a
  les zones.

## 2. Com afegir el camp a una activitat

1. Al rellotge, entra a l'activitat que vulguis (Córrer, Bici...) sense
   començar-la encara.
2. Mantén premut el botó de "Menu" / llisca per accedir a les opcions de
   l'activitat.
3. Busca **"Edit Data Screens"** o similar, i tria una pantalla.
4. Selecciona el camp que vulguis substituir i, dins la categoria de camps de
   **Connect IQ**, tria **"CHO/FAT Metabolic Pro"**.

## 3. Els paràmetres del teu perfil

L'app fa servir 6 valors per personalitzar el càlcul. Per defecte tots estan en
**mode automàtic** (el rellotge els estima sol); només cal tocar-los si en
coneixes el valor real i vols més precisió.

| Paràmetre | Què és, en paraules senzilles | Com s'estima si el deixes en automàtic |
|---|---|---|
| **Weight** | El teu pes corporal | Es llegeix del teu perfil de Garmin |
| **Resting HR** | La teva freqüència cardíaca en repòs total | Es llegeix del teu perfil de Garmin |
| **Max HR** | La teva freqüència cardíaca màxima | S'agafa el sostre de la zona 5 configurada per al teu esport actual (córrer, ciclisme...) |
| **LT2 Threshold** | El teu llindar anaeròbic (la intensitat a partir de la qual comences a acumular fatiga ràpidament) | S'agafa el sostre de la zona 4 configurada per al teu esport actual |
| **LT1 Threshold** | El teu llindar aeròbic (una mica per sota de l'anterior) | Es calcula com el 89% del LT2 |
| **VO2max** | La teva capacitat aeròbica màxima | Es llegeix del teu perfil de Garmin — l'estimació de córrer o de ciclisme, segons l'activitat actual |

En un rellotge Garmin, l'"esport actual" sol ser Córrer; en una **bicicleta
computadora Edge**, és Ciclisme — el camp fa servir automàticament les teves
zones i l'estimació de VO2max de ciclisme en aquest cas, sense cap configuració
addicional.

## 4. Com editar-los manualment

1. Obre directament l'app **Connect IQ Store** — o, igual de vàlid, obre l'app
   **Garmin Connect** i ves al teu rellotge → **Connect IQ Store** (o
   **My Apps**).
2. Busca "CHO/FAT Metabolic Pro" i entra-hi.
3. Toca **Settings/Configure** i introdueix els valors que coneguis.
4. Deixa a **0** qualsevol paràmetre que vulguis que es continuï estimant
   automàticament.

**Per què LT2 és el més important — sobretot per a ciclistes**: dels 6 valors,
`LT2 Threshold` és el que té més impacte en la precisió — `LT1` i el punt on
comença a pujar el consum de carbohidrats es calculen tots dos com a
percentatge d'aquest, no de forma independent. Si només en pots afinar un, que
sigui aquest. Això és encara més rellevant si fas servir un Edge: Garmin
detecta automàticament el llindar de lactat per córrer, però no per a
ciclisme — l'equivalent automàtic de ciclisme és l'FTP, un valor de potència,
no de freqüència cardíaca. Per tant, si ets ciclista, val la pena introduir
`LT2 Threshold` a mà: fes servir la FC del teu test d'FTP (l'esforç sostingut,
no els watts en si), o la teva FC de llindar de lactat de ciclisme de les
Mètriques Fisiològiques de Garmin Connect si ja en tens una configurada.

**Com trobar el teu LT1 (opcional)**: si deixes `LT1 Threshold` a 0, l'app fa servir el
89% del teu LT2, que és la mitjana dels estudis publicats en corredors i ciclistes
aficionats — però els valors individuals varien aproximadament ±9 ppm al voltant
d'aquest. Si en vols un de millor, per ordre de fiabilitat:

1. Una **prova de laboratori** (test de lactat per esglaons o de gasos): introdueix la
   FC al primer augment de lactat, o al primer llindar ventilatori (VT1).
2. Una **prova a casa amb banda de pit i un mètode basat en HRV** (la rampa "DFA-alpha1 =
   0,75", que ofereixen algunes apps d'entrenament): fes-la descansat, repeteix-la dos
   dies diferents i contrasta-la amb la FC més alta a la qual encara pots parlar en
   frases completes. La fatiga fa que aquest mètode doni un valor massa baix.
3. Si no n'estàs segur, **deixa-ho a 0**. Sisplau, no facis servir "180 menys l'edat":
   no té validació per a aquest ús.

## 5. Què signifiquen els colors

### Color del CHO avg (consell de fueling)

Durant els primers 45 minuts sempre és verd (els dipòsits de glicogen encara són
plens). Després:

| Verd | Taronja | Vermell |
|---|---|---|
| menys de 60 g/h | 60-90 g/h | 90 g/h o més |

Aquests límits segueixen la quantitat de carbohidrats que una persona pot absorbir de
manera realista mentre fa exercici: uns 60 g/h d'una sola font, fins a uns 90 g/h amb
barreges de glucosa + fructosa.

El vermell no vol dir "alarma" — vol dir que cremes carbohidrats més de pressa del que
pots reposar mentre fas exercici, així que la diferència surt dels dipòsits de
glicogen. Això és normal a intensitat moderada-alta. És una pista per alimentar-te
d'hora i continuar menjant en esforços llargs.

### Color de la zona (Z1..Z5)

Mateix esquema que Garmin Connect: gris (Z1), blau (Z2), verd (Z3), taronja
(Z4), vermell (Z5). És independent del color del CHO — un indica intensitat de
l'esforç, l'altre consum de carbohidrats.

## 6. Les dades després de l'activitat

L'app desa els resultats dins de l'activitat, de manera que pots revisar-los quan
acabes. Un cop el rellotge sincronitza, obre l'activitat a Garmin Connect:

- **Gràfiques**: CHO acumulat (g), FAT acumulat (g) i taxa de CHO (g/h, suavitzada)
  al llarg de tota l'activitat.
- **Resum**: CHO total (g), FAT total (g) i CHO mitjà (g/h) de l'activitat.

No cal configurar res: es registra automàticament quan el camp és en pantalla
durant una activitat. Els serveis que ignoren els camps de dades propis (com
Strava) potser no els mostren, però els valors queden al fitxer `.FIT`.
