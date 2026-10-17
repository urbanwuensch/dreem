# drEEM toolbox: guide for AI agents

This file is for AI coding agents (Claude Code, Codex, Copilot, Cursor, ...) that help
a user **analyse their data with drEEM 2** in MATLAB. It is not a guide to developing
the toolbox itself.

drEEM imports, processes and models UV-Vis absorbance and fluorescence data, in particular
excitation-emission matrices (EEMs) of dissolved organic matter, with a focus on PARAFAC.
Requires MATLAB R2024b or newer. The Parallel Computing Toolbox is optional (speeds up PARAFAC).

**Read this file completely before running anything.** It ships inside the toolbox
(`fullfile(drEEMtoolbox.rootfolder,"AGENTS.md")`, printed by `drEEMtoolbox.agentguide`), so an
agent working in the user's project folder does not load it automatically. Suggest
`drEEMtoolbox.agentguide("install")` to the user: it copies this guide into the project folder.

## Ground rules

1. **Write a script, not ad-hoc commands.** Users need a reproducible `.m` file they can rerun.
   Start it with `tbx = drEEMtoolbox;` and call every method as `tbx.<method>(...)`.
2. **Always assign the output.** Methods return a new dataset; nothing is modified in place:
   `samples = tbx.subtractblanks(samples, blanks);`
   Calling a processing method *without* an output argument runs it in **diagnostic mode**
   (prints "Diagnostic mode, no output will be assigned", shows plots, data unchanged).
   The intended pattern is: run in diagnostic mode, check the result with the user, then
   rerun with an output and `plot=false`.
3. **Look at the diagnostics, also without a screen.** Pass `figurefile="diag_<step>.png"` and
   open the saved image. `processabsorbance`, `ifecorrection`, `subtractblanks`,
   `ramancalibration`, `rmspikes`, `fitslopes`, `pickpeaks` and all `view*` methods accept it
   (`handlescatter` does not; use `viewscatter(samples, figurefile=...)`). The toolbox appends
   the name of the outermost calling script (and a counter if the file exists), so search for
   files starting with the name you gave. Skipping straight to `plot=false` without ever
   looking is the easiest way to carry a problem into the model.
4. **Never edit dataset fields directly** (`samples.X = ...`, `samples.status.x = ...`).
   Use toolbox methods so the change is validated and logged in `samples.history`.
   If the user made a manual decision, record it: `samples = tbx.addcomment(samples, "why");`
5. **Read the help before guessing arguments.** `help drEEMtoolbox.<method>` shows the
   signature, all name-value options with defaults and examples. Trust the `arguments`
   block in `toolbox/@drEEMtoolbox/<method>.m` over any other listing.
6. **Do not overstate results.** A PARAFAC model is validated only if the toolbox says so:
   `samples.models(f).status` is `'validated'`, `'not validated'` or `'not yet validated'`.
   Never replace this verdict with your own metric, and never report or export a model
   that is not `'validated'` as the final result. Say which component number you report and why.
7. **Leave scientific choices to the user.** Number of components, outliers (including blanks
   or duplicates imported as samples), scatter widths, trimming, extrapolating absorbance and
   scaling are judgement calls. Propose and explain; ask before applying. If you must use a
   default to keep going, say so in your report and log it with `addcomment`.
8. **Read the whole console output** of every run. Verdicts (`Successful validation`,
   `Failed validation`), `% missing numbers` and warnings are easily lost by filtering for
   "error" or "done".

## Running MATLAB from an agent session

- Run scripts non-interactively: `matlab -batch "run('analysis.m')"`. On macOS the binary is
  `/Applications/MATLAB_<release>.app/bin/matlab` and usually not on the `PATH`. In batch mode,
  `tbx = drEEMtoolbox` prints a one-line pointer to this guide.
- Check that the toolbox is found: `which drEEMtoolbox`. If it is not (seen after installing
  in one `-batch` session and starting another), `addpath(genpath(<toolbox folder>))` works;
  the warning "package root folders ... not installed" can then be ignored.
- **Don't name your scripts like MATLAB functions** (`days.m`, `plot3.m`, `fit.m`, ...):
  they shadow built-ins and break the toolbox in unexpected places.
- **Long fits:** fit one component number per `fitparafac` call, use `consoleoutput="all"`,
  and `save` after each. Run in the background and watch the log. If the log stops growing
  and the CPU is idle for minutes, the run has hung: stop it and rerun smaller.
## Interactive windows (important for agents)

Some methods open a window and wait until a person closes it. In `matlab -batch` they
raise the error `drEEM:needsInteractiveSession` instead; its message names the alternative:

| Waits for a person | Use instead |
|---|---|
| `handlescatter` without options (GUI), or with `opt.plot = true` | a `handlescatterOptions` object with `opt.plot = false`; inspect with `viewscatter(..., figurefile=...)` |
| `rmspikes`, `pickpeaks`, `fitslopes` with `details=true` | `details=false` (default) with `plot=true, figurefile=...` |
| `changestatus`; any import whose status has `unknown` entries | a complete `drEEMstatus(...)` passed at import (see below) |

In batch mode the diagnostic modes of `rmspikes`, `pickpeaks` and `fitslopes` skip the
sample-by-sample view and still plot, and an available update is only announced.
Other sessions (e.g. `matlab -nodesktop`, or MATLAB driven through an MCP server) are
treated as interactive: there these calls still wait for a person, so avoid them.

The `view*` apps (`vieweems`, `viewmodels`, `viewdmr`, `viewsplitvalidation`, ...) do **not**
wait: with `figurefile` they save the figure and return (10-20 s in batch mode). The fields
they display can also be read in code (see *The dataset object*).

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
`m.componentContribution`, `m.status` (validation verdict), plus the fit settings
(`starts`, `convergence`, `constraints`).

## Importing data

- **Text exports** (e.g. Aqualog `* - Waterfall Plot Sample.dat`, `* - Abs Spectra Graphs.dat`, csv):
  `importeems` and `importabsorbance`, as in the canonical workflow below. Passing a complete
  `drEEMstatus` avoids the status dialog.
- **Horiba Aqualog Origin projects (`.opj`/`.ogw`):** `[samples,blanks] = tbx.importaqualog(folder)`.
  It re-processes the raw data exactly like the Aqualog software and returns samples (with
  absorbance in `samples.abs`) and their blanks. Before calling it:
  - On first use it downloads the `aqualog2nc` helper program from Zenodo into the user's
    MATLAB folder (`userpath`). Ask the user first. Apple silicon Macs only on macOS.
  - It writes `NetCDF_rawdata.nc` into the data folder. Tell the user.
  - `bucket=N` selects among groups of measurements with different instrument settings.
  - Afterwards check `samples.filelist` for entries that are not real samples (names with
    `blk`/`blank`), duplicates and re-measurements (`(02)`, `P2`), and confirm `samples.status`.

## Canonical workflow

Order follows the drEEM tutorials: `toolbox/examples/*.m` (plain-text live scripts, readable
as text) and their pages `toolbox/doc/*tutorial*.html`. Before each correction step check
`samples.status`: do not repeat a correction the instrument software already applied.

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
% Compare max(samples.Em) with max(samples.absWave) first: if absorbance ends before the
% emission range, ifecorrection DELETES the uncovered emission wavelengths. Ask the user
% and use extrapolate=true in processabsorbance BEFORE ifecorrection.
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
samples = tbx.fitparafac(samples, "fitoverall", f=5, convergence=1e-8, starts=30);   % one f per call

%% 7. Split-half validation (splitdataset first, then fitsplits)
samples = tbx.splitdataset(samples, "blind");            % or "byMetadata", metadataColumn="..."
samples = tbx.fitparafac(samples, "fitsplits", f=5, convergence=1e-8, starts=50);
% prints "Successful validation (5-component model)" or "Failed validation ..." and sets
% samples.models(5).status; viewsplitvalidation(samples,5,figurefile=...) adds the figure

%% 8. Export (only models whose status is 'validated')
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
  "outlier test"), then single component numbers with `1e-6` and a few starts, finally
  `1e-8` and 30+ starts.
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
  Use `"byMetadata"` only if every group has enough samples. `fitsplits` needs the split
  first.
- **The validation verdict** comes from `fitparafac(...,"fitsplits",...)`: it prints
  `Successful validation (N-component model)` or `Failed validation (N-component model)` and
  stores it in `samples.models(N).status`. Each `fitsplits` call reprints the verdict for every
  model already in the dataset. `viewsplitvalidation` only adds the figure (and prints
  "Overall Result= Validated for all comparisons", Tucker congruence ≥ 0.95, when N passes).
  A failed validation is a result to report, not an error to hide. Removing samples or
  wavelengths deletes the models: validate again for every dataset version you report.
- **Runtime:** with final settings (`starts=30+`, `convergence=1e-8`) fits can take minutes
  to hours. Use quick settings for exploration. `fitparafac` starts a parallel pool if the
  Parallel Computing Toolbox is present (`parallelization=false` to disable).
- Non-default `constraints` or `initialization` silently switch the engine from `parafac3w`
  to N-way (a notice is printed). That is expected.
- **Scaling:** `tbx.scalesamples` changes what the model fits. Use only when sample
  intensities span orders of magnitude. `exportresults` reverses it automatically;
  before `scores2fmax` or `export2openfluor`, use `tbx.scalesamples(samples,'reverse')`.
  `tbx.scalesamples(samples,'help')` explains the options.
- Report concentrations as Fmax: `fmax = tbx.scores2fmax(samples, f);` (raw scores are not Fmax).
- Prefer the toolbox exports (`exportresults`, `export2openfluor`, `export2zip`). If the user
  wants plain CSV for R/Python, add them, and label every file with the component number, the
  validation status, the sample set (list removed samples) and the Ex/Em range used.

## What to include when you report back

The sample set and every removal with its reason; the `status` of the final dataset; Ex/Em
ranges and trimming; scatter settings and who chose them; for each candidate number of
components the explained variance, core consistency, unconverged share and
`models(N).status`; outliers found; and the citation. Keep conclusions at the strength the
evidence supports.

## Getting more help

- `doc drEEMtoolbox` or `drEEMtoolbox.doc('<method>')`: full documentation pages
- `toolbox/doc/function_overview.html`: list of all methods by purpose
- `toolbox/examples/processing_tutorial_01.m`, `prepare4Parafac_tutorial.m`,
  `parafac_tutorial_01.m`: the reasoning behind each step, as readable text (read these
  before advising on processing or component selection); example data in `tutorial_*.mat`
- `toolbox/doc/*tutorial*.html`: the same tutorials with their output and figures
- Citation (ask users to cite): Wünsch, U., Murphy, K., Esmaeeli, A., & Bro, R. (2025).
  drEEM toolbox version 2. Zenodo. https://doi.org/10.5281/zenodo.17182160, and
  Murphy et al. (2013), Anal. Methods 5, 6557, https://doi.org/10.1039/c3ay41160e
