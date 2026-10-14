# drEEM toolbox: guide for AI agents

This file is for AI coding agents (Claude Code, Codex, Copilot, Cursor, ...) that help
a user **analyse their data with drEEM 2** in MATLAB. It is not a guide to developing
the toolbox itself.

drEEM imports, processes and models UV-Vis absorbance and fluorescence data, in particular
excitation-emission matrices (EEMs) of dissolved organic matter, with a focus on PARAFAC.
Requires MATLAB R2024b or newer. The Parallel Computing Toolbox is optional (speeds up PARAFAC).

## Ground rules

1. **Write a script, not ad-hoc commands.** Users need a reproducible `.m` file they can rerun.
   Start it with `tbx = drEEMtoolbox;` and call every method as `tbx.<method>(...)`.
2. **Always assign the output.** Methods return a new dataset; nothing is modified in place:
   `samples = tbx.subtractblanks(samples, blanks);`
   Calling a processing method *without* an output argument runs it in **diagnostic mode**
   (prints "Diagnostic mode, no output will be assigned", shows plots, data unchanged).
   The intended pattern is: run in diagnostic mode, check the result with the user, then
   rerun with an output and `plot=false`.
3. **Never edit dataset fields directly** (`samples.X = ...`, `samples.status.x = ...`).
   Use toolbox methods so the change is validated and logged in `samples.history`.
   If the user made a manual decision, record it: `samples = tbx.addcomment(samples, "why");`
4. **Read the help before guessing arguments.** `help drEEMtoolbox.<method>` shows the
   signature, all name-value options with defaults and examples. Trust the `arguments`
   block in `toolbox/@drEEMtoolbox/<method>.m` over any other listing.
5. **Do not overstate results.** A PARAFAC model is not "validated" unless split-half
   validation passed (see below). Say which component number you are reporting and why.
6. **Leave scientific choices to the user.** Number of components, which samples are
   outliers, scatter widths and whether to scale samples are judgement calls. Propose
   and explain; don't silently decide.

## Interactive windows (important for agents)

Several methods open windows and **block MATLAB until a human closes them**. In a
non-interactive or agent-driven session, avoid them or tell the user to run them:

| Blocks until closed | Non-blocking alternative |
|---|---|
| `tbx.handlescatter(samples)` with no options object (opens a GUI) | pass a `handlescatterOptions` object with `opt.plot = false` |
| `handlescatterOptions` with `plot = true` (steps through samples) | set `opt.plot = false` |
| `tbx.rmspikes(..., details=true)`, `tbx.pickpeaks(..., details=true)`, `tbx.fitslopes(..., details=true)` | keep `details=false` (default) |
| `tbx.changestatus`, `tbx.importwizard`, `tbx.murea` | `drEEMstatus(...)` passed at import (see below) |
| `tbx.view*` apps (`vieweems`, `viewmodels`, `viewdmr`, `viewscatter`, ...) | let the user open them; inspect fields in code |
| Update prompt from `drEEMtoolbox` constructor (only if outdated) | user answers once per day |

Most processing methods take `plot=false` to suppress figures and `figurefile="name.png"`
to save a figure instead of showing it.

## The dataset object

Data live in a `drEEMdataset` (value class). Key fields:

| Field | Meaning |
|---|---|
| `X` | EEMs, size `nSample × nEm × nEx` |
| `Ex`, `Em` | excitation / emission wavelengths (column vectors) |
| `abs`, `absWave` | absorbance spectra (`nSample × nWave`) and wavelengths |
| `XBlank`, `absBlank` | blanks, if merged in |
| `i`, `filelist` | numeric sample index and unique sample identifiers |
| `metadata` | table, one row per sample (use `tbx.associatemetadata`) |
| `status` | processing state (`drEEMstatus`): what has been applied, by whom |
| `history` | log of every operation (`tbx.displayhistory(samples)`) |
| `models(f)` | PCA/PARAFAC model with `f` components (`drEEMmodel`, see below) |
| `split` | sub-datasets created by `splitdataset` for validation |

Check consistency at any time with `tbx.validatedataset(samples)`.

A `drEEMmodel` (`m = samples.models(f)`) holds what the `viewmodels` app shows, so
agents can read it without a GUI:
`m.loads{1}` scores, `m.loads{2}` emission and `m.loads{3}` excitation loadings;
`m.leverages{1..3}`, `m.sse{1..3}` (residuals per mode); `m.percentExplained`, `m.core`
(core consistency), `m.percentUnconverged` (share of starts that hit `maxIteration`),
`m.componentContribution`, plus the fit settings (`starts`, `convergence`, `constraints`).

## Canonical workflow

Order follows the drEEM tutorials (`toolbox/doc/*tutorial*.html`, `toolbox/examples/*.mlx`).
Before each correction step check `samples.status`: do not repeat a correction the
instrument software already applied.

```matlab
tbx = drEEMtoolbox;

%% 1. Import (declare what the instrument already did)
st      = drEEMstatus("spectralCorrection","applied by instrument software", ...
                      "blankSubtraction","not applied");
samples = tbx.importeems('*SampleEEM.dat', st);        % see help for columnWave/rowWave etc.
blanks  = tbx.importeems('*BlankEEM.dat', st);
absorb  = tbx.importabsorbance('*Abs.dat', st, waveColumn=1, absColumn=10);
samples = tbx.associatemetadata(samples, "metadata.xlsx", "sampleId");

%% 2. Match samples between datasets, then move absorbance into the sample dataset
[samples, blanks, absorb] = tbx.alignsamples(samples, blanks, absorb);
samples = tbx.mergemeasurements(samples, absorb, "absorbance");
tbx.validatedataset(samples);

%% 3. Corrections (skip any step the status says is already done)
samples = tbx.processabsorbance(samples, baseWave=600, extrapolate=true, plot=false);
samples = tbx.ifecorrection(samples, plot=false);       % inner-filter effect, needs absorbance
samples = tbx.subtractblanks(samples, blanks, plot=false);
samples = tbx.ramancalibration(samples, blanks, plot=false);  % Raman units
% samples = tbx.spectralcorrection(samples, XCor=xcor, MCor=mcor);  % only if not done by instrument

%% 4. Scatter, noise, trimming
load("scatterOptions.mat", "scatteroptions")   % saved from viewscatter by the user, or:
% scatteroptions = handlescatterOptions;       % defaults; adjust opt.ray1, opt.ram1, ...
scatteroptions.plot = false;
samples  = tbx.handlescatter(samples, scatteroptions);
samples  = tbx.rmspikes(samples, thresholdFactor=30, plot=false);
samples  = tbx.subdataset(samples, outEx=samples.Ex < 250);   % trim noisy edges
% samples = tbx.zapnoise(samples, samples.i==4, [], [340 360]); % remove a local artefact

%% 5. Optional: absorbance slopes and fluorescence peaks/indices
samples = tbx.fitslopes(samples, plot=false);
samples = tbx.pickpeaks(samples, plot=false);

%% 6. Exploratory PARAFAC (fast settings), then refine
samples = tbx.fitparafac(samples, "fitoverall", f=2:7, convergence=1e-4, starts=2);
samples = tbx.fitparafac(samples, "fitoverall", f=4:6, convergence=1e-8, starts=30);

%% 7. Split-half validation
samples = tbx.splitdataset(samples, "blind");            % or "byMetadata", metadataColumn="..."
samples = tbx.fitparafac(samples, "fitsplits", f=5:6, convergence=1e-8, starts=50);
% fitsplits already prints the validation verdict to the console;
% tbx.viewsplitvalidation(samples, 5) only adds the figure.

%% 8. Export
tbx.exportresults(samples, 5, 'modelExport');
tbx.export2openfluor(samples, 5, 'model2openfluor.txt');
tbx.export2zip(samples, 'dataset.zip');                  % FAIR archive of data + history
```

Save intermediate states (`save processed.mat samples`) so expensive steps aren't repeated.
Suggest `export2zip` right after import as well: a raw-data archive plus the final
archive (which contains the full history) lets anyone reconstruct the analysis.

## Processing: things the methods do on their own

- `ifecorrection` **deletes EEM wavelengths not covered by the absorbance spectra**
  (logged as an automatic `subdataset`). To avoid this for CDOM-type data, run
  `processabsorbance(..., extrapolate=true)` first; better still, measure absorbance
  across the full EEM range.
- `ifecorrection` sets correction factors to NaN where absorbance > 2 per cm, which leaves
  gaps in the EEMs. The fix is diluting the samples, not changing the code.
- Absorbance units are converted automatically if the status was set correctly at import.
- `ramancalibration`: the integration window (`iStart`, `iEnd`, default 378–424 nm at
  Ex 350) must be checked against the plot; it directly scales all reported intensities.
- `subtractblanks`: fluorescent blanks show up as signal between the scatter lines in the
  diagnostic plot. Negative values near scatter lines only mean the blanks had more scatter.
- **`subdataset` and `zapnoise` delete existing models** from the dataset. Refit afterwards.
- `zapnoise` removes a region from selected samples only (`[]` = whole range);
  `subdataset` removes wavelengths or samples from all samples.
- `rmspikes` needs a dataset-specific `thresholdFactor`: compare a few values in diagnostic
  mode (e.g. 15, 20, 30) and prefer conservative settings that only remove the worst spikes.

## PARAFAC: decisions and pitfalls

- **Explore fast, then refine:** first `f=2:7, convergence=1e-4, starts=2` (formerly the
  "outlier test"), then narrower `f` with `1e-6` and a few starts, finally `1e-8` and 30+ starts.
- **Fix the data, not the model.** If extra components look noisy or a single sample has
  high leverage, look for the cause (short-UV noise, leftover scatter, a bubble or particle
  in one sample) and fix it with `subdataset`/`zapnoise`. Don't settle for the last
  "clean-looking" model. Log every change with `addcomment`.
- **Choosing the number of components** weighs several lines of evidence. Present them;
  the user decides:
  - core consistency (`m.core`) stays high, then drops
  - explained variance (`m.percentExplained`) stops improving meaningfully
  - loadings are smooth and spectrally plausible, not noisy or rising sharply toward the UV
  - scores of different components are not strongly correlated (`viewcompcorr`)
  - residuals (`m.sse`, `viewdmr`) lose their spectral structure
  - most starts converge (`m.percentUnconverged`). Rerun with a higher `maxIteration`; if
    starts still hit the limit, the model is probably too large
  - a refit with `constraints="unconstrained"` still gives near-nonnegative loadings
    (well-behaved data shouldn't need the constraint)
- **Split validation:** `splitdataset(...,"blind")` alternates samples between two halves.
  Use `"byMetadata"` only if every group has enough samples.
- **Validation passes** only if the console says *"Overall Result= Validated for all
  comparisons"* (Tucker congruence ≥ 0.95 between splits). A failed validation is a
  result to report, not an error to hide.
- **Runtime:** with final settings (`starts=30+`, `convergence=1e-8`) fits can take minutes
  to hours. Use quick settings for exploration. `fitparafac` starts a parallel pool if the
  Parallel Computing Toolbox is present (`parallelization=false` to disable).
- Non-default `constraints` or `initialization` silently switch the engine from `parafac3w`
  to N-way (a notice is printed). That is expected.
- **Scaling:** `tbx.scalesamples` changes what the model fits. Use only when sample
  intensities span orders of magnitude, and reverse it before reporting Fmax.
  `tbx.scalesamples(samples,'help')` explains the options.
- Report concentrations as Fmax: `fmax = tbx.scores2fmax(samples, f);`

## Getting more help

- `doc drEEMtoolbox` or `drEEMtoolbox.doc('<method>')`: full documentation pages
- `toolbox/doc/function_overview.html`: list of all methods by purpose
- `toolbox/doc/processing_tutorial_01.html`, `prepare4Parafac_tutorial.html`,
  `parafac_tutorial_01.html`: the reasoning behind each step (read these before advising
  on processing or component selection)
- `toolbox/examples/*.mlx`: the same tutorials as live scripts with example data
  (`tutorial_*.mat`)
- Citation (ask users to cite): Wünsch, U., Murphy, K., Esmaeeli, A., & Bro, R. (2025).
  drEEM toolbox version 2. Zenodo. https://doi.org/10.5281/zenodo.17182160, and
  Murphy et al. (2013), Anal. Methods 5, 6557, https://doi.org/10.1039/c3ay41160e