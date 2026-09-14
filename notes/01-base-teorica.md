# Estimació de l'oxidació de carbohidrats i greixos a partir de la freqüència cardíaca: un model pràctic

Aquest document descriu, de manera autocontinguda, un model per estimar la taxa
d'oxidació de carbohidrats (CHO) i de greix (FAT) durant l'exercici a partir d'una
única variable mesurable de forma no invasiva: la freqüència cardíaca (FC). Es
presenten la fisiologia i les matemàtiques del model amb les seves referències
científiques, deduint-lo pas a pas des de l'objectiu fins a la seva forma final.

## 1. Objectiu

Volem conèixer, en qualsevol instant $t$ d'una activitat, la **taxa d'oxidació** de
carbohidrats i de greix del cos:

$$CHO(t),\ FAT(t) \quad \text{[g/min]}$$

i, a partir d'aquestes taxes instantànies, el **total acumulat** al llarg de tota
l'activitat (de $0$ fins a la durada total $T$):

$$CHO_{total}(T) = \int_0^T CHO(t)\,dt \qquad\qquad FAT_{total}(T) = \int_0^T FAT(t)\,dt$$

Tota la resta del document consisteix a introduir els conceptes previs necessaris
(§2), i després respondre, en ordre, dues preguntes: **com es calcula
$CHO(t)$/$FAT(t)$** (§3-7), i **com es relaciona aquesta taxa instantània amb un
total acumulat** (§8).

## 2. Conceptes previs

Abans d'entrar en el model, val la pena definir amb claredat les variables
fisiològiques que s'hi faran servir contínuament.

### 2.1. Consum d'oxigen ($VO_2$) i producció de CO2 ($VCO_2$)

$VO_2$ és el volum d'oxigen que el cos consumeix per unitat de temps. Es mesura en
litres/minut (valor absolut) o en ml·kg⁻¹·min⁻¹ (valor relatiu al pes corporal, útil
per comparar persones de mides diferents). $VCO_2$ és, anàlogament, el volum de
diòxid de carboni produït per unitat de temps. Totes dues són la base de la
**calorimetria indirecta**: com que oxidar greix o oxidar carbohidrat consumeix O2 i
produeix CO2 en proporcions diferents (per la diferent composició química d'ambdues
molècules), mesurar $VO_2$ i $VCO_2$ permet deduir quin combustible s'està cremant,
sense haver de mesurar-lo directament.

### 2.2. Consum màxim d'oxigen ($VO_{2max}$)

$VO_{2max}$ és el valor més alt de $VO_2$ que una persona pot assolir en un esforç
màxim — la mesura clàssica de referència de la forma física cardiorespiratòria
(quanta sang/oxigen pot bombejar i utilitzar el sistema cardiovascular i muscular per
unitat de temps). Es fa servir com a extrem superior de l'escala en aquest model
(§4):

> Bassett DR Jr, Howley ET. **Limiting factors for maximum oxygen uptake and
> determinants of endurance performance.** *Medicine & Science in Sports & Exercise*.
> 2000;32(1):70-84.

### 2.3. Quocient respiratori (RER)

$$RER(t) = \displaystyle\frac{VCO_2(t)}{VO_2(t)}$$

Un únic número, típicament entre $\sim 0{,}7$ i $\sim 1{,}0$ en repòs/exercici
submàxim, que indica la barreja de substrats que s'estan oxidant: $RER=0{,}7$
correspon a oxidació gairebé exclusiva de greix; $RER=1{,}0$, a oxidació gairebé
exclusiva de carbohidrat. És la variable central del model, ja que relaciona
directament amb el percentatge d'energia que prové de cada substrat (§5).

### 2.4. Freqüència cardíaca relativa: %FCmàx i Reserva de FC (%HRR)

La freqüència cardíaca (FC) absoluta (batecs/min) no és comparable entre persones —
cal expressar-la de forma relativa. Dues maneres habituals:

- **%FCmàx**, la més simple, però menys precisa fisiològicament:

$$\%FC_{màx} = \displaystyle\frac{FC}{FC_{màxima}}$$

- **%HRR** (reserva de freqüència cardíaca), que relativitza la FC respecte al
  **rang complet** disponible (de repòs a màxim), no només respecte al màxim:

$$\%HRR = \displaystyle\frac{FC - FC_{repòs}}{FC_{màxima} - FC_{repòs}}$$

  És la que fa servir aquest model (§4.1). L'origen conceptual del "mètode de la
  reserva" es troba a:

> Karvonen MJ, Kentala E, Mustala O. **The effects of training on heart rate; a
> longitudinal study.** *Annales Medicinae Experimentalis et Biologiae Fenniae*.
> 1957;35(3):307-315.

### 2.5. Consum d'oxigen relatiu i Reserva de VO2 (%VO2R)

De manera anàloga a §2.4, $VO_2$ es pot expressar relativament al seu propi rang,
entre el valor de repòs i $VO_{2max}$ (§2.2):

$$\%VO_2R = \displaystyle\frac{VO_2 - VO_{2,repòs}}{VO_{2max} - VO_{2,repòs}}$$

Aquest model estima $\%VO_2R$ a partir de $\%HRR$ (§2.4), gràcies a l'equivalència
empírica entre totes dues que es discuteix amb detall a §4.2.

## 3. El punt de partida: les equacions de Jeukendrup & Wallis

La relació entre consum d'oxigen, producció de CO2, i grams de substrat oxidat per
minut és coneguda a la fisiologia de l'exercici des de les equacions clàssiques de
calorimetria indirecta (no-proteiques, és a dir, que ignoren la petita contribució de
l'oxidació de proteïnes) de:

> Frayn KN. **Calculation of substrate oxidation rates in vivo from gaseous exchange.**
> *Journal of Applied Physiology*. 1983;55(2):628-634.

Aquest model fa servir, en concret, la **modificació d'aquestes equacions per a
exercici** (Frayn les va derivar pensant en repòs, assumint glucosa com a substrat de
CHO; durant l'exercici el substrat predominant és glicogen, cosa que canvia
lleugerament els coeficients):

> Jeukendrup AE, Wallis GA. **Measurement of substrate oxidation during exercise by
> means of gas exchange measurements.** *International Journal of Sports Medicine*.
> 2005;26(Suppl 1):S28-S37.

$$CHO(t) = 4.210\ VCO_2(t) - 2.962\ VO_2(t)$$

$$FAT(t) = 1.695\ VO_2(t) - 1.701\ VCO_2(t)$$

**Què necessitem per fer servir aquesta equació?** Les dues variables contínues
definides a §2.1: $VO_2(t)$ i $VCO_2(t)$. Cap de les dues es pot mesurar sense un
analitzador de gasos de laboratori, així que calen mètodes indirectes d'estimar-les
(§4-7).

### 3.1. Reescrivint l'equació en termes de RER

En comptes d'estimar $VO_2$ i $VCO_2$ per separat, és més pràctic estimar $VO_2$ i el
quocient respiratori $RER$ (§2.3). Substituint $VCO_2(t) = RER(t)\cdot VO_2(t)$:

$$CHO(t) = VO_2(t)\cdot\big(4.210\cdot RER(t) - 2.962\big)$$

$$FAT(t) = VO_2(t)\cdot\big(1.695 - 1.701\cdot RER(t)\big)$$

Ara calen dues estimacions independents: $VO_2(t)$ (§4) i $RER(t)$ (§5-6).

## 4. Estimació de $VO_2(t)$ a partir de la freqüència cardíaca

### 4.1. Reserva de freqüència cardíaca (%HRR)

$$\%HRR(t) = \displaystyle\frac{FC(t) - FC_{repòs}}{FC_{màxima} - FC_{repòs}}$$

(definició introduïda a §2.4).

### 4.2. De %HRR a %VO2 de reserva

L'estimació es basa en l'equivalència empírica $\%HRR \approx \%VO_2R$ (§2.5; reserva
de $VO_2$, no $\%VO_{2max}$, que és menys precisa):

> Swain DP, Leutholtz BC. **Heart rate reserve is equivalent to %VO2 reserve, not to
> %VO2max.** *Medicine & Science in Sports & Exercise*. 1997;29(3):410-414.

$$VO_{2,relatiu}(t) = VO_{2,repòs} + \%HRR(t)\cdot\big(VO_{2max} - VO_{2,repòs}\big)$$

on $VO_{2,repòs} = 3{,}5\ \text{ml}\cdot\text{kg}^{-1}\cdot\text{min}^{-1}$ (1 MET, el
consum d'oxigen estàndard en repòs).

### 4.3. De relatiu a absolut

$$VO_2(t)\ [\text{L/min}] = \displaystyle\frac{VO_{2,relatiu}(t)\cdot pes\ (\text{kg})}{1000}$$

**Limitacions del model**: $\%HRR\approx\%VO_2R$ és una aproximació estadística (de
mitjana poblacional, amb variabilitat individual). El resultat depèn directament de
la qualitat de $FC_{repòs}$, $FC_{màxima}$ i $VO_{2max}$ com a entrades del model —
en la pràctica, aquests tres valors sovint també són ells mateixos estimacions (no
mesures directes de laboratori), cosa que introdueix una font addicional
d'incertesa acumulada sobre el resultat final.

## 5. Estimació de $RER(t)$: llindars metabòlics

El RER real no és constant: puja de manera no lineal amb la intensitat, sobretot al
voltant dels **llindars metabòlics** ($LT_1$, llindar aeròbic; $LT_2$, llindar
anaeròbic/de lactat). Aquest comportament general està documentat a:

> Faude O, Kindermann W, Meyer T. **Lactate threshold concepts: how valid are they?**
> *Sports Medicine*. 2009;39(6):469-490.

$LT_1$ es defineix, fisiològicament, com el punt on el lactat en sang comença a pujar
per sobre del nivell de repòs. En aquest punt, un esportista de fons ben entrenat
encara crema majoritàriament greix (el metabolisme continua sent molt eficient
aeròbicament), no un 50%/50%. El punt on la contribució energètica és exactament
50% greix / 50% CHO és un concepte relacionat però **diferent**, conegut a la
literatura com el **"crossover point"**:

> Brooks GA, Mercier J. **Balance of carbohydrate and lipid utilization during
> exercise: the "crossover" concept.** *Journal of Applied Physiology*.
> 1994;76(6):2253-2261.

Segons la taula clàssica de quocient respiratori no-proteic (Lusk 1924; actualitzada
per Péronnet & Massicotte 1991, ja citada a §3), el 50%/50% es correspon amb
$RER\approx 0{,}85$, mentre que a $LT_1$ (una mica abans, a intensitat més baixa) el
RER sol ser una mica inferior — consistent amb que el greix encara predomini
lleugerament en aquest punt. $LT_2$, en canvi, marca el **màxim estat estacionari de
lactat**: la intensitat límit on el cos encara pot eliminar el lactat al mateix ritme
que el produeix; en aquest punt el RER sol estar entre $0{,}95$ i $1{,}00$ (encara
queda una petita oxidació residual de greix, típicament un $6$-$10\%$ de l'energia).
Per sobre de $LT_2$, el RER pot arribar a superar $1{,}00$ (fins a $1{,}05$-$1{,}10$ en
esforços gairebé màxims), per l'efecte tampó del bicarbonat sanguini sobre l'àcid
làctic acumulat, que allibera CO2 addicional pels pulmons.

### 5.1. Model d'interpolació

Com que no es pot mesurar lactat ni gasos sense equipament de laboratori, es pot
**aproximar** aquesta corba amb una interpolació lineal per trams, en funció de
quatre punts de referència de la FC: repòs, un punt de **sortida del repòs**
($I_{onset}$, §6), $LT_1$, $LT_2$, i $FC_{màxima}$:

$$
RER(t) =
\begin{cases}
R_{basal} & \text{si } FC(t) \le I_{onset} \\[6pt]
R_{basal} + \displaystyle\frac{FC(t) - I_{onset}}{LT_1 - I_{onset}}\big(R_{LT_1}-R_{basal}\big) & \text{si } I_{onset} < FC(t) \le LT_1 \\[10pt]
R_{LT_1} + \displaystyle\frac{FC(t) - LT_1}{LT_2 - LT_1}\big(R_{LT_2}-R_{LT_1}\big) & \text{si } LT_1 < FC(t) \le LT_2 \\[10pt]
R_{LT_2} + \displaystyle\frac{FC(t) - LT_2}{FC_{màxima} - LT_2}\big(R_{max}-R_{LT_2}\big) & \text{si } LT_2 < FC(t) \le FC_{màxima}
\end{cases}
$$

amb els valors de referència triats per a aquest model:

| Punt | RER de referència | Consistència amb la literatura (§5) |
|---|---|---|
| $R_{basal}$ (repòs/molt suau) | $0{,}72$ | Per sota de la mitjana poblacional ($\sim 0{,}80$), però dins del rang observat en atletes de fons entrenats ($0{,}718$-$0{,}927$) |
| $R_{LT_1}$ | $0{,}82$ | Una mica per sota del rang més citat per a $LT_1$ ($0{,}85$-$0{,}87$); coherent amb un perfil de fons on el greix encara predomina en aquest punt (§5) |
| $R_{LT_2}$ | $0{,}98$ | Molt proper al consens de la literatura ($\approx 1{,}00$ a $LT_2$) |
| $R_{max}$ (a $FC_{màxima}$) | $1{,}00$ | Sostre conservador: el model no arriba a representar el RER $>1{,}00$ real que es dona en esforços gairebé màxims (§5) |

**Limitacions del model**: aquesta interpolació assumeix que $RER(t)$ respon
instantàniament a la FC. Fisiològicament, a l'inici de l'exercici la mobilització i
oxidació de greix triguen uns minuts a activar-se plenament (típicament $10$-$20$
min), de manera que el RER real puja una mica més ràpid a l'inici del que prediu
aquest model basat només en FC. Aquest retard s'escurça si l'esportista ha fet un
escalfament o activitat física prèvia recent, ja que la mobilització d'àcids grassos
i el flux sanguini al teixit adipós ja estan parcialment activats:

> Andersson Hall U, Edin F, Pedersen A, Madsen K. **Whole-body fat oxidation
> increases more by prior exercise than overnight fasting in elite endurance
> athletes.** *Applied Physiology, Nutrition, and Metabolism*. 2016;41(4):430-437.

## 6. Estimació dels paràmetres del model

El model necessita quatre punts de referència de FC ($I_{onset}$, $LT_1$, $LT_2$,
$FC_{màxima}$, §5.1) i el $VO_{2max}$ (§2.2). Sovint, un esportista que s'ha fet
proves específiques (una prova de llindar de lactat, una prova d'esforç màxima amb
analitzador de gasos) ja coneix directament els valors reals de $LT_1$, $LT_2$,
$FC_{màxima}$ i $VO_{2max}$, i en aquest cas simplement s'utilitzen tal qual — no cal
cap aproximació. Quan aquestes dades directes no estan disponibles, cal estimar els
paràmetres de forma indirecta; hi ha diverses maneres raonables de fer-ho, però no
són objecte d'aquest document (dependrà de quina informació indirecta es tingui a
l'abast en cada cas concret).

**Cas particular — $LT_1$ com a fracció de $LT_2$**: quan no es coneix $LT_1$
directament però sí (una estimació de) $LT_2$, és habitual aproximar-lo com una
fracció d'aquest, ja que $LT_1$ sol situar-se per sota de $LT_2$ (§5). Aquesta
fracció depèn del nivell d'entrenament: en població general els dos llindars
solen quedar més separats, mentre que en un esportista de fons amb bona base
aeròbica s'apropen més. Aquest model assumeix aquest segon perfil (consistent
amb els valors de referència de RER triats a §5.1):

$$LT_1 \approx 0{,}85 \cdot LT_2$$

**Cas particular — $I_{onset}$ (sortida del repòs)**: aquest punt és diferent dels
altres tres perquè **no és quelcom que es pugui mesurar directament ni amb una prova
de laboratori** — no hi ha cap test que reveli "el punt on el RER comença a pujar
gradualment abans de $LT_1$", perquè no és un esdeveniment fisiològic discret sinó un
recurs de suavitzat del propi model (§5.1: cap sistema biològic canvia de règim
metabòlic amb un esglaó net, així que el model introdueix aquesta transició gradual en
comptes d'un canvi brusc de pendent exactament a $LT_1$). Per això $I_{onset}$ és
**més arbitrari** que la resta de paràmetres: fins i tot un esportista amb totes les
seves dades de laboratori conegudes no tindria un valor "real" per a aquest punt. Es
fa servir la relació:

$$I_{onset} \approx 0{,}70 \cdot LT_2$$

on el $0{,}70$ concret **no prové de cap article científic** — és una tria de
disseny del model perquè la transició sigui gradual, no el valor d'una mesura.

## 7. Model puntual complet

Ajuntant §3-6: donada la FC en un instant $t$ i els paràmetres personals (pes, FC
repòs, FC màxima, $LT_2$, $VO_{2max}$), el model calcula, en aquest ordre:

$$\%HRR(t) \;\xrightarrow{\text{§4.1}}\; VO_2(t) \;\xrightarrow{\text{§4.2-4.3}}\; \Big(VO_2(t),\ RER(t)\Big) \;\xrightarrow{\text{§3.1}}\; CHO(t),\ FAT(t)$$

on $RER(t)$ s'obté en paral·lel a partir de la FC, per interpolació per trams (§5-6).

Aquest és el **model puntual**: donat un instant $t$ aïllat (i només la FC en aquest
instant), calcula una taxa d'oxidació — no un total, ni res que depengui del que hagi
passat abans. El resultat, $CHO(t)$ i $FAT(t)$, s'expressa sempre en **g/min** (§3),
amb independència de cada quant es faci servir aquest càlcul en la pràctica: el model
no sap ni li importa si s'avalua un cop per segon, un cop per minut, o una sola
vegada de forma aïllada — sempre respon la mateixa pregunta ("a quin ritme s'oxidaria
CHO/FAT si la FC es mantingués constant en aquest valor"), en la mateixa unitat.

La pregunta de com **enllaçar** aquesta taxa (g/min) amb mesures reals preses a
qualsevol altra freqüència (per segon, per minut...) sense necessitat de convertir la
pròpia taxa és, precisament, el que resol la discretització de §8: en comptes de
canviar les unitats de $CHO(t)$/$FAT(t)$, s'expressa l'interval transcorregut
$\Delta t$ en minuts (la mateixa unitat que la taxa), sigui quin sigui l'interval
real entre mostres.

## 8. De la taxa instantània a l'acumulat: la integral i la seva discretització

### 8.1. Plantejament continu

Com es va dir a §1, el que realment interessa és el total acumulat, no només la taxa
d'un instant:

$$CHO_{total}(T) = \int_0^T CHO(t)\,dt \qquad\qquad FAT_{total}(T) = \int_0^T FAT(t)\,dt$$

Aquesta integral no es pot resoldre analíticament perquè $CHO(t)$ depèn de $FC(t)$,
que és una funció arbitrària (el que faci realment el cor de la persona durant
l'activitat) — no una fórmula matemàtica tancada.

### 8.2. Discretització: suma de Riemann

Amb dades disponibles només en **mostres discretes** ($t_0=0, t_1, t_2, \ldots, t_n$),
l'aproximació numèrica més senzilla d'una integral és la **suma de Riemann**: mantenir
la taxa constant des de l'última mostra fins a l'actual i multiplicar-la per
l'interval transcorregut:

$$\Delta t_i = t_i - t_{i-1} \quad \text{(en minuts, ja que } CHO(t)/FAT(t) \text{ són en g/min)}$$

$$CHO_{total}(t_n) \approx \sum_{i=1}^{n} CHO(t_i)\cdot \Delta t_i \qquad\qquad FAT_{total}(t_n) \approx \sum_{i=1}^{n} FAT(t_i)\cdot \Delta t_i$$

És una integració numèrica de primer ordre (rectangular), vàlida quan $\Delta t$ és
molt més petit que la velocitat a la qual canvia l'estat fisiològic real. Si
$\Delta t_i$ fos gran, la suma de Riemann aplicaria la taxa *instantània del moment
de la mostra* retroactivament sobre tot aquell interval — un error d'integració real,
que creix amb la mida del forat.

### 8.3. Taxa instantània vs. taxa suavitzada

El total acumulat (§8.2) és, per definició, una suma exacta sense cap suavitzat —
dona la millor estimació possible de quants grams s'han oxidat en total. Però com a
**valor de referència puntual** per prendre decisions durant l'esforç (per exemple,
de fueling), $CHO(t)$ instantani i el total acumulat donen dos tipus d'informació molt
diferents:

- **El càlcul puntual** $CHO(t)$ respon "a quin ritme estic oxidant CHO *ara mateix*?"
  — és molt sensible a fluctuacions momentànies de FC (una pujada curta, un revolt,
  un ensurt), i per tant sorollós d'interpretar a cop d'ull, però és l'únic que
  reacciona instantàniament a un canvi real d'intensitat.
- **El total acumulat** respon "quant he oxidat en total fins ara?" — útil per al
  balanç final de la sessió, però no diu res sobre el ritme *actual*.

Hi ha un terme mitjà entre els dos: una **mitjana mòbil** de $CHO(t)$, que respon "a
quin ritme he estat oxidant CHO *últimament*?" — més estable que la taxa instantània
(perquè integra diverses mostres recents), però encara sensible a canvis reals
d'intensitat sostinguts (a diferència del total acumulat, que els dilueix cada cop
més com passa el temps).

Una manera habitual de calcular aquesta mitjana mòbil, quan les mostres arriben a
intervals no necessàriament regulars, és la **mitjana mòbil exponencial (EMA)**, amb
una constant de temps $\tau$ que determina quant "pesen" les mostres recents enfront
de les antigues:

$$\alpha_i \approx \displaystyle\frac{\Delta t_i}{\tau} \quad \left(\text{aproximació de primer ordre de } 1-e^{-\Delta t_i/\tau}\right)$$

$$CHO_{avg}(t_i) = CHO_{avg}(t_{i-1}) + \alpha_i\cdot\big(CHO(t_i) - CHO_{avg}(t_{i-1})\big)$$

> Hunter JS. **The exponentially weighted moving average.** *Journal of Quality
> Technology*. 1986;18(4):203-210.

Com més gran és $\tau$, més s'assembla $CHO_{avg}$ al total acumulat (molt estable,
poc reactiu); com més petit, més s'assembla a la taxa instantània (molt reactiu,
més sorollós). La tria concreta de $\tau$ és un compromís entre estabilitat i
reactivitat, no una propietat fisiològica del model.

## 9. Guies de reposició de carbohidrats durant l'exercici (fueling)

Existeixen recomanacions pràctiques d'ingesta de carbohidrats durant l'exercici de
resistència, que **depenen de la durada** de l'esforç (i no directament del pes
corporal, ja que el factor limitant és la capacitat d'absorció intestinal
—transportadors SGLT1/GLUT5— més que la massa corporal):

> Jeukendrup AE. **A step towards personalized sports nutrition: carbohydrate intake
> during exercise.** *Sports Medicine*. 2014;44(Suppl 1):S25-S33.
> DOI: 10.1007/s40279-014-0148-z

Aquesta font estableix, a grans trets:
- Esforços curts ($<45$-$60$ min): no cal ingesta significativa de CHO.
- Esforços d'1 a 2-3 hores: $\sim 30$-$60$ g/h.
- Esforços llargs ($>2{,}5$-$3$h): fins a $\sim 90$ g/h, sempre que es facin servir
  **carbohidrats de transport múltiple** (barreges de glucosa + fructosa), ja que una
  sola font de carbohidrat no es pot absorbir a un ritme tan alt.

## 10. Taula resum de referències

| Ref. | Ús al model | Citació |
|---|---|---|
| Bassett & Howley (2000) | Definició/context de $VO_{2max}$ | *Med Sci Sports Exerc* 32(1):70-84 |
| Frayn (1983) | Base conceptual de les equacions no-proteiques d'oxidació de CHO/FAT | *J Appl Physiol* 55(2):628-634 |
| Jeukendrup & Wallis (2005) | Equació objectiu: coeficients exactes $CHO(t)$/$FAT(t)$ (modificació de Frayn per a exercici) | *Int J Sports Med* 26(Suppl 1):S28-S37 |
| Swain & Leutholtz (1997) | $\%HRR \approx \%VO_2R$ per estimar $VO_2(t)$ des de la FC | *Med Sci Sports Exerc* 29(3):410-414 |
| Faude, Kindermann & Meyer (2009) | Concepte de llindars de lactat ($LT_1$/$LT_2$) per al model de $RER(t)$ | *Sports Med* 39(6):469-490 |
| Brooks & Mercier (1994) | "Crossover concept": punt de creuament 50/50 greix/CHO | *J Appl Physiol* 76(6):2253-2261 |
| Karvonen, Kentala & Mustala (1957) | Origen conceptual del mètode de zones de FC / reserva de FC | *Ann Med Exp Biol Fenn* 35(3):307-315 |
| Jeukendrup (2014) | Guies d'ingesta de CHO durant l'exercici (fueling) | *Sports Med* 44(Suppl 1):S25-S33 |
| Hunter (1986) | Mitjana mòbil exponencial (EMA) com a tècnica de suavitzat | *J Quality Technology* 18(4):203-210 |
| Andersson Hall et al. (2016) | Escalfament/exercici previ escurça el retard de mobilització de greix | *Appl Physiol Nutr Metab* 41(4):430-437 |
