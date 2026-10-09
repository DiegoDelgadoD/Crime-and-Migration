# Scoping report: Venezuelan immigration and crime in Peru

Date: 2026-09-24. Prepared with Claude Code from five research agents (web searches in English and Spanish) and a first pass through the data in `data/`.

**Errata (2026-09-29).** A full-text reading pass found errors in this report. The reading pass is documented in `2026-09-29_literature_review.md`, which supersedes section 2.
- **Bahar, Ibáñez & Rozo (2021), *JDE* 151: 102652.** This citation belongs to a different paper, on the amnesty program itself. The crime-reports paper is Ibáñez, Rozo, Bahar & Urbina (2026), *JDE* 179: 103667. That paper's estimate for crimes committed by migrants is imprecise, with a first-stage F of 7.7–8.5.
- **Spenkuch (2014).** The 0.12 figure is the all-immigrant OLS property elasticity. The Mexican fixed-effects OLS figure is 0.066.
- **Marques (2025).** It could not be read in full, so its findings in section 2.2 are unverified.

Citation status: every paper below was checked by a research agent against a publisher, RePEc/IDEAS, NBER or institutional page. The note after each entry says what the agent read: FT = full text or the relevant sections, AB = abstract, SN = search snippet only. Treat SN entries as unverified in content. Re-check page numbers before any citation goes into a paper.

---

## 1. Research question and gap

**Question.** Did the Venezuelan inflow (about 1.2–1.6 million people in Peru by 2025) raise homicides and other crime in Peruvian districts, as public narratives claim?

**Gap.** The agents found no causal study of Venezuelan immigration and homicides in Peru. The closest work:

- **Groeger, León-Ciliotta & Stillman (2024)**, "Immigration, labor markets and discrimination: Evidence from the Venezuelan Exodus in Perú," *World Development* 174: 106437. [FT, WB WP version]
  - Design: 198 provinces; Venezuelan location from PTP registrations, 2015–2020; outcomes from ENAHO plus administrative counts of reported crime.
  - Instrument: 2007-census Venezuelan share × year dummies.
  - Results: employment and income rise. Doubling the Venezuelan share cuts reported non-violent crime by 42%; violent crime shows no significant effect.
  - **This is the paper to position against.**
- **Castro & Mejía (2020)**, *Una mirada a la migración venezolana y seguridad ciudadana en Perú*, Equilibrium CenDE. [FT] Fixed-effects panel on 50 Lima/Callao districts, 2017–2018. No significant effects. Not causal.
- **Bendezú-Jiménez et al. (2024)**, *Rev. Científica Gral. José María Córdova* 22(47). [AB] Crime panel for 2018–2023, reporting a "modest" effect. Not yet read in full.

**Possible contributions relative to Groeger et al.:**
- Homicides from vital registration (SINADEF) rather than police reports.
- District rather than province level.
- The 2025 census stock rather than registration flows.
- Coverage of the 2023–2025 extortion and sicariato wave, which their data (to 2020) miss.
- A direct test of the "imported methods" claim: extortion and sicariato modalities in SIDPOL for 2024–2025.

---

## 2. Literature map

### 2.1 Immigration and crime outside Latin America

| Paper | Setting | Identification | Finding | Read |
|---|---|---|---|---|
| Bianchi, Buonanno & Pinotti (2012), *JEEA* 10(6): 1318–1347 | Italian provinces, 1990–2003 | Supply-push shift-share (inflows to other European destinations) | Only robberies rise; no effect on total crime | AB + WP |
| Bell, Fasani & Machin (2013), *REStat* 95(4): 1278–1290 | England and Wales, 2002–2009 | Asylum dispersal policy; A8 shift-share | Asylum wave: modest rise in property crime; A8 wave: small fall; no effect on violent crime | FT |
| Spenkuch (2014), *ALER* 16(1): 177–219 | US counties, 1980–2000 | Enclave shift-share | Property-crime elasticity about 0.12, for Mexicans only; no effect on violent crime | FT (WP) |
| Chalfin (2014), *ALER* 16(1): 220–268 | US cities | Mexican rainfall shocks × migration networks | No change in violent or property crime | AB |
| Butcher & Piehl (1998), *JPAM* 17(3): 457–493 | US metros, 1980s | Cross-section and first differences | Null once demographics are controlled | AB |
| Light & Miller (2018), *Criminology* 56(2): 370–401 | US states, 1990–2014 | Two-way fixed effects | Undocumented immigration does not raise violence | SN |
| Mastrobuoni & Pinotti (2015), *AEJ: Applied* 7(2): 175–206 | Italy, 2006 pardon | DiD, EU enlargement | Legal status cuts recidivism by about 50% | AB |
| Pinotti (2017), *AER* 107(1): 138–168 | Italy, click days | RD on application timing | Legalization lowers crime by 0.6 pp on a 1.1% base | AB |
| Baker (2015), *AER P&P* 105(5): 210–213 | US, IRCA | Timing × intensity | Crime falls 3–5%, mainly property | AB |
| Freedman, Owens & Bohn (2018), *AEJ: Policy* 10(2): 117–151 | San Antonio | Triple difference, IRCA employer sanctions | Losing legal work raises felony charges | AB |
| Couttenier, Petrencu, Rohner & Thoenig (2019), *AER* 109(12): 4378–4425 | Swiss asylum seekers, 2009–2016 | Childhood conflict exposure by cohort; quota-based cantonal assignment | Exposed men 35% more prone to violent crime, mostly against co-nationals; labor-market access removes about two-thirds | FT (intro) |
| Piopiunik & Ruhose (2017), *EER* 92: 258–282 | Ethnic Germans | Exogenous allocation | Crime rises, more where unemployment is high | AB |
| Dehos (2021), *RSUE* 88: 103640 | German counties | Dispersal plus shift-share | Recognized refugees: more property crime and fraud | AB |
| Gehrsitz & Ungerer (2022), *Economica* 89(355): 592–626 | Germany, 2014–2015 | Housing-driven allocation | Very small increases (drugs, fare-dodging) | AB |
| Masterson & Yasenov (2021), *APSR* 115(3): 1066–1073 | US refugee ban | DiD | Null | SN |
| Kırdar, López Cruz & Türküm (2022), *JEBO* 194: 568–582 | Syrians in Turkey | (instrument not read) | Crime falls | SN |
| Özden, Testaverde & Wagner (2018), *WBER* 32(1): 183–202 | Malaysia | IV (instrument not read) | Crime falls | SN |

**Reviews:**
- Marie & Pinotti (2024), *JEP* 38(1): 181–200. [FT] Immigrants are overrepresented among prisoners, yet local immigration has no significant effect on crime. Homicide is the least under-reported outcome.
- Ousey & Kubrin (2018), *Annual Review of Criminology* 1: 63–84. [FT intro] Meta-analysis of 51 studies: the association is weakly negative.
- Bell (2019), *IZA World of Labor* 33v2. [FT]
- Fasani, Mastrobuoni, Owens & Pinotti (2019), *Does Immigration Increase Crime?*, Cambridge UP. [blurb only]

**Perceptions and reporting:**
- Nunziata (2015), *J. Population Economics* 28(3): 697–736. [AB] Immigration leaves victimization unchanged but raises fear of crime.
- Couttenier, Hatte, Thoenig & Vlachos (2024), *REStat*. [SN; volume and pages not verified] Media over-reporting of immigrant crime raised support for the Swiss minaret ban.
- Comino, Mastrobuoni & Nicolò (2020), *JPAM* 39(4): 1214–1245. [SN] Undocumented immigrants report about 11% of the crimes against them.
- Jácome (2022), *J. Urban Economics* 128: 103395. [SN] Immigration enforcement affects crime reporting (Dallas).

### 2.2 The Venezuelan exodus and crime in Latin America

| Paper | Setting | Identification | Finding | Read |
|---|---|---|---|---|
| Knight & Tribin (2023), *JDE* 162 (NBER WP 27620) | Colombian municipalities, monthly, 2010–2019 | Distance to border crossings × 2015 closure and 2016 reopening | Homicides up about 25% within 100 miles; driven by Venezuelan victims; no significant effect on Colombian victims | FT (WP) |
| Ajzenman, Dominguez & Undurraga (2023), *AEJ: Applied* 15(4): 142–76 | Chilean municipalities, 2008–2017 | Bartik: 2008 shares × emigration to other destinations | No effect on crime; fear and preventive spending rise, more where media presence is stronger | FT (2021) |
| Marques (2025), *J. Development Studies* 61(2): 210–232 | Brazil, 5,570 municipalities; SIM mortality data | Exposure around Pacaraima (IV not confirmed) | No effect on natives; violence against Venezuelan victims rises | AB |
| Bahar, Ibáñez & Rozo (2021), *JDE* 151: 102652 | Colombia, PEP amnesty | DiD on PEP intensity | Negligible labor effects | AB |
| Ibáñez, Rozo, Bahar & Urbina (2025), *JDE* 179 | Colombia, PEP | Variation in RAMV registration time | Crimes by migrants fall; reports by migrant women rise (reporting margin) | AB |
| Franco Mora (2020), Documentos CEDE | Colombia, 2016–2018 | FE and IV (instrument not in abstract) | Small rise in thefts; no effect on violent crime | AB |
| Rey, Schulze & Zakharov (2024), CESifo WP 10953 | Colombian transit corridors | 2016 reopening × routes; DiD with PSM | Property crime rises along corridors; violent crime unchanged | AB |
| Bahar (2025), CGD policy note | Ecuador | Descriptive | Venezuelans are 1.3% of detentions and 2.5% of the population | AB |

**Labor-market papers with transferable instruments:**
- Caruso, Gómez Cañón & Mueller (2021), *OEP* 73(2): 771–795. Distance × pre-crisis enclaves.
- Bonilla-Mejía et al. (2024), *IMR* 58(2): 764–799. 2005 share × Venezuelan CPI.
- Delgado-Prieto (JMP 2026; *J. Pop. Econ.* 2024). Distance to border bridges, plus 2005 share.
- Lebow (2022, *IZA JODM*; 2024, *JDE* 166). Historical location instruments.
- Rozo & Vargas (2021), *JDE* 150. Prior settlement.
- Peru: Boruchowicz, Martinelli & Parker (2024), *Economía LACEA* 23(1): 107–136 (synthetic control, Lima). Morales & Pierola (2020), IDB WP-1146 (full text not opened). Vera & Jiménez (2022), CEDLAS WP 0304 (skill-cell design).

**Peru descriptive and policy work:**
- OIM Perú (2024), *Migración e incidencia delictiva en el Perú*. [FT] The main information gap it names is the nationality of homicide victims and perpetrators.
- CIUP (2021), Propuesta de Política Pública 19 (Freier & Rosales). [FT] Venezuelans were named in 1.45% of 2019 police reports.
- Pérez Guadalupe & Nuñovero (2024), *Anthropologica* 42(52): 143–197. [FT] Venezuelan inmates: 3.4% of the prison population in January 2024; 74.5% of them in pretrial detention.
- Freier & Pérez (2021), *EJCPR* 27(1): 113–133. [AB] Qualitative evidence on criminalization.
- Amaya López & Elguera Quispe (2023), CIES. [AB] Xenophobic opinion.
- Bahar, Dooley & Selee (2020), MPI/Brookings. [AB]

### 2.3 Instrument methodology

- Altonji & Card (1991), NBER volume. Card (2001), *JOLE* 19(1): 22–64.
- Jaeger, Ruist & Stuhler (2018), NBER w24285. Dynamics bias; their fix needs changes in the origin mix, which is impossible with a single origin.
- Goldsmith-Pinkham, Sorkin & Swift (2020), *AER* 110(8): 2586–2624. With one origin, Bartik is the initial share, so identification rests on share exogeneity.
- Borusyak, Hull & Jaravel (2022), *REStud* 89(1): 181–213, and their 2025 *JEP* guide. The shock-based route is closed with one national shock.
- Adão, Kolesár & Morales (2019), *QJE* 134(4): 1949–2010. Correlated residuals across units with similar shares.
- Borusyak & Hull (2023), *Econometrica* 91(6): 2155–2185. Recentering formula instruments, relevant for a Tumbes gravity instrument.
- On geography: Dell (2010), *Econometrica* 78: 1863–1903 (elevation and the mita). Nunn & Puga (2012), *REStat* 94(1): 20–36 (terrain acts through several channels).
- No paper found uses altitude as an instrument for migrant location.

---

## 3. Context facts (with sources)

- **Stock.** Migraciones-based INEI figures give 1,226,525 Venezuelan residents in 2025 (as reported by PerúCheck/Infobae, 7 Sep 2026; primary INEI document not located). R4V gives 1.63 million (cut 31 May 2026). The 2025 census enumerated 909,692 Venezuela-born (census platform API, national ranking indicator), so it captures well below the administrative stock.
- **Census 2025.** Fieldwork 4 Aug–31 Oct 2025. District results carry "datos al 15 de julio de 2026". Foreign-born = mother's residence at birth abroad (country of birth).
- **Entry.** 89.8% of registered entrants in ENPOVE 2018 came through CEBAF Tumbes; 84.5% travelled only by bus (INEI, ENPOVE 2018, ch. 3).
- **Location.** Migraciones (Jan 2016–Jun 2023): Lima department 59.64%, Callao 4.27%. Outside Lima and Callao: La Libertad 22.84%, Ica 12.68%, Arequipa 12.27%, Piura 12.09%.
- **Policy dates:**
  - PTP decrees: DS 002-2017-IN; DS 007-2018-IN (entry cutoff 31 Oct 2018).
  - Humanitarian visa: 15 Jun 2019.
  - CPP: DS 010-2020-IN; DS 003-2023-IN.
  - Fast-track expulsion: DL 1582 (Nov 2023).
  - States of emergency in Lima and Callao: DS 035-2025-PCM, DS 124-2025-PCM and DS 140-2025-PCM, with later extensions.
- **Homicides.** INEI/CEIC "Informe técnico … 2022–2025" (Jan 2026), p. 7. Rate per 100,000: 7.4 (2019), 8.6 (2021), 9.3 (2023), 10.1 (2024), 10.7 (2025, preliminary). Department rates for 2025 (p. 8): Madre de Dios 24.6, Callao 23.6, Región Lima 23.1, Tumbes 20.6, Puno 14.8.
- **Extortion complaints** (same report, p. 9): 16,346 (2022), 22,675 (2023), 22,361 (2024), 26,585 (2025). The jump from 4,735 in 2021 to 16,346 in 2022 should be checked for a recording change.
- **Prisons.** INPE Informe Estadístico, Sep 2025, p. 20 and Anexo 16: 4,328 Venezuelan inmates of 103,342 (about 4.2%). Compare with the 2.7% Venezuela-born census share; the two shares are not standardized for age or sex.
- **Perceptions.** IOP-PUCP/IDEHPUCP: agreement that "many Venezuelans engage in crime" rose from 55% (2018) to 80% (2019), Lima-Callao.

---

## 4. Data diagnostic (from files in `data/`)

- **SINADEF** (`data/SINADEF_DATOS_ABIERTOS.csv`), own tabulation:
  - 2017–2026, 1,578,149 deaths.
  - `MUERTE_VIOLENTA == "HOMICIDIO"`: 677 (2017), 926 (2018), 1,141 (2019), 1,019 (2020), 1,416 (2021), 1,539 (2022), 1,512 (2023), 2,082 (2024), 2,253 (2025).
  - Of the 2,253 homicides in 2025, 89.1% of victims are male and 2,245 had an autopsy.
  - `PAIS_DOMICILIO == "VENEZUELA"` for only 15 victims in 2025. This is country of residence, not nationality, so the field cannot identify Venezuelan victims.
  - Residence ubigeo is RENIEC-coded (`92-33-DD-PP-dd-000`).
  - Coverage relative to CEIC: 2,253 vs 3,675 in 2025 (about 61%). Coverage also changes over time: medically certified deaths rose from 57.65% (2016) to 71.6% (2019) (Vargas-Herrera et al., *An Fac Med* 83(2), 2022).
- **Census 2025 tables.** 1,893 districts; 1,052,977 foreign-born. Lima Metropolitana plus Callao hold 70.5% of the foreign-born (own name-matched tabulation). The immigrant share has median 0.09%, 90th percentile 1.7%, 99th percentile 9.0% and maximum 21.7%.
- **First descriptive pattern.** Own tabulation, name-matching SINADEF residence to census districts; 2,013 of 2,244 homicides with known residence were matched in 2025, and Callao needs a fix. Homicide rates per 100,000 by quintile of foreign-born share:

  | Quintile of foreign-born share | Mean share | Pop. (m) | 2017–18 | 2024–25 |
  |---|---|---|---|---|
  | 1 (lowest) | 0.00% | 0.82 | 1.90 | 2.51 |
  | 2 | 0.02% | 2.07 | 1.21 | 3.02 |
  | 3 | 0.09% | 2.72 | 1.95 | 3.29 |
  | 4 | 0.32% | 4.58 | 1.67 | 4.33 |
  | 5 (highest) | 4.60% | 22.52 | 2.50 | 7.06 |

  Levels were similar across quintiles before the inflow; the increase since then is concentrated in the top quintile, which is essentially urban Lima and the northern coast. This is descriptive only and confounded by the coastal-urban crime wave.

---

## 5. Assessment of the proposed design (altitude IV)

- **Relevance.** Strong. Venezuelans are concentrated on the coast.
- **Exclusion in a 2025 cross-section.** Not credible.
  - Altitude separates coast from sierra, and the two differ in economic density, poverty, urbanization, indigenous share, police presence and SINADEF coverage, all of which affect crime directly.
  - The migration channel itself (jobs, networks in Lima) is also a direct channel to crime.
  - Altitude also predicts internal migration of Peruvians.
  - High-altitude hotspots (Pataz illegal mining, reported at 92 per 100,000 in 2025 per RPP/Infobae [SN]; La Rinconada; VRAEM) make the relationship non-monotonic.
- **Panel version (altitude × year, district FE).** Weaker assumption: no differential crime trends by altitude absent migration. Still exposed to the coastal-urban extortion wave of 2023–2025. The same threat applies to the 2007-share instrument, because pre-2017 Venezuelans also lived in Lima.
- **Construction if used.** Population-weighted altitude from the INEI Directorio de Centros Poblados 2017, or a DEM weighted by GHSL. Do not weight by WorldPop, whose model uses elevation. Do not use area-weighted mean elevation.
- **Alternatives:**
  1. 2007-census share × year (Groeger et al. template), with GPSS diagnostics.
  2. Road distance or travel time from CEBAF Tumbes × national inflow, as a gravity prediction recentered following Borusyak & Hull (2023).
  3. The 2019 visa as a time shifter.

  Using two instruments with different exclusion threats allows overidentification tests.
- **Outcomes:**
  - Restrict to homicides. "Violent deaths" include suicides, which rise with altitude (Ortiz-Prado et al. 2024, *BJPsych Open*, Ecuador).
  - Add SIDPOL extortion, robbery and sicariato.
  - Consider splitting victims by nationality, which Knight & Tribin and Marques find to be decisive, but SINADEF cannot do this.
- **Measurement of the regressor.** The census undercounts Venezuelans relative to administrative records (about 0.91 million vs 1.2–1.6 million), and the undercount is probably non-random. Check against Migraciones province stocks.

---

## 6. Next steps (proposed, pending Diego's decisions)

1. Build the district crosswalk: RENIEC → INEI, and the 2017 → 2025 district changes.
2. Build the SINADEF district × year homicide panel (residence and place of death), and benchmark it against CEIC department totals.
3. Merge the Venezuelan-born counts from the census API into the 2025 district file.
4. Export 2007 and 2017 REDATAM district counts of Venezuelan-born.
5. Build the instruments: population-weighted altitude (Centros Poblados 2017), and distance from Tumbes (MTC roads).
6. Build the SIDPOL district × month panel (extortion, robbery, homicide, sicariato).
7. Run first stages and reduced forms, including pre-trend and placebo checks (suicides, traffic deaths, non-violent deaths).
8. Decide on the analysis language and the git policy for large data files.
