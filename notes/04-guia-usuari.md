# Guia d'usuari

Aquest document explica, en llenguatge senzill i sense entrar en fórmules, què
mostra el data field a la pantalla, què vol dir cada paràmetre del teu perfil i
com els pots configurar. Si vols saber com es calcula tot per dins, mira
[`01-base-teorica.md`](01-base-teorica.md) (el model científic) o
[`02-funcionament-app.md`](02-funcionament-app.md) (com està implementat).

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
   **Connect IQ**, tria **"CHO/FAT Metabolic"**.

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
| **LT1 Threshold** | El teu llindar aeròbic (una mica per sota de l'anterior) | Es calcula com el 85% del LT2 |
| **VO2max** | La teva capacitat aeròbica màxima | Es llegeix del teu perfil de Garmin — l'estimació de córrer o de ciclisme, segons l'activitat actual |

En un rellotge Garmin, l'"esport actual" sol ser Córrer; en una **bicicleta
computadora Edge**, és Ciclisme — el camp fa servir automàticament les teves
zones i l'estimació de VO2max de ciclisme en aquest cas, sense cap configuració
addicional.

## 4. Com editar-los manualment

1. Obre directament l'app **Connect IQ Store** — o, igual de vàlid, obre l'app
   **Garmin Connect** i ves al teu rellotge → **Connect IQ Store** (o
   **My Apps**).
2. Busca "CHO/FAT Metabolic" i entra-hi.
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

## 5. Què signifiquen els colors

### Color del CHO avg (consell de fueling)

| Temps transcorregut | Verd | Taronja | Vermell |
|---|---|---|---|
| Menys de 45 min | (sempre verd, els dipòsits encara són plens) | — | — |
| Entre 45 min i 2h | menys de 30 g/h | 30-60 g/h | més de 60 g/h |
| Més de 2h | menys de 60 g/h | 60-90 g/h | més de 90 g/h |

El vermell no vol dir "alarma" — només que, segons guies esportives habituals,
et podries estar quedant curt de carbohidrats per a la durada de l'esforç.

### Color de la zona (Z1..Z5)

Mateix esquema que Garmin Connect: gris (Z1), blau (Z2), verd (Z3), taronja
(Z4), vermell (Z5). És independent del color del CHO — un indica intensitat de
l'esforç, l'altre consum de carbohidrats.
