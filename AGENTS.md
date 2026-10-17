# drEEM: guide for AI agents developing the toolbox

This file is for agents (and humans) changing drEEM's code, docs or packaging.
If you are helping someone **use** drEEM to analyse data, read `toolbox/AGENTS.md` instead.

drEEM 2 is a MATLAB toolbox (R2024b+) for UV-Vis absorbance and fluorescence (EEM)
data, centred on PARAFAC. Maintainer: Urban Wünsch (urban.wunsch@chalmers.se).

## Repository layout

| Path | What it is |
|---|---|
| `toolbox/` | Everything that ships in the `.mltbx` (package root) |
| `toolbox/@drEEMtoolbox/` | The user-facing API: one static method per file (`importeems.m`, `fitparafac.m`, ...) |
| `toolbox/@drEEMtoolbox/drEEMtoolbox.m` | Class definition: method declarations, version, options, update check |
| `toolbox/classes/` | Data classes: `@drEEMdataset`, `@drEEMmodel`, `drEEMstatus`, `drEEMhistory`, `drEEMbackup`, `handlescatterOptions`, `@horibaRawdata` |
| `toolbox/+dreemgui/` | App classes (`*_gui.m`) used by the `view*` methods, plus GUI helpers |
| `toolbox/doc/` | Shipped HTML help (**generated, see Documentation**), `helptoc.xml`, `GettingStarted.mlx`, images |
| `toolbox/examples/` | Tutorial live scripts (`.mlx`) and their data (`.mat`) |
| `toolbox/external resources/` | Third-party code (N-way toolbox, inpaint_nans, crameri). **Do not modify.** |
| `toolbox/package.ignore` | Files excluded from the `.mltbx` (paths relative to `toolbox/`) |
| `toolbox/AGENTS.md` | Guide for agents *using* the toolbox (ships to users) |
| `documentation/functions/`, `documentation/tutorials/` | **Markdown sources** of the HTML help pages |
| `documentation/drEEM-new.css` | Stylesheet embedded in every generated help page |
| `apps_mlapp/` | App Designer sources (`.mlapp`) for the GUIs in `+dreemgui` |
| `tests/` | `matlab.unittest` test suite (see Testing) |
| `tests/reference/` | Stored fingerprints for the processing regression tests |
| `tests/testdata/` | Real instrument files for import tests (Aqualog text export, Origin projects) |
| `buildfile.m` | Build plan: `check`, `test`, `docs`, `tutorials`, `pdf`, `package` |
| `buildUtilities/doc_template.html` | pandoc page template for the `docs` task |
| `buildUtilities/build_doc_pdf.py` | Builds the documentation PDF for the `pdf` task |
| `documentation/drEEM_toolbox_documentation.pdf` | All help pages and tutorials as one PDF (**generated** by `buildtool pdf`) |
| `matlab.toml` | MATLAB project + packaging config (version, folders, output file name) |

## Building

Open the project first (`openProject("matlab.toml")`), then from the repo root:

```matlab
buildtool check      % static code analysis (CodeIssuesTask), no errors allowed
buildtool test       % test suite in tests/
buildtool docs       % Markdown -> toolbox/doc/*.html (needs pandoc)
buildtool tutorials  % tutorial .mlx -> toolbox/doc/*.html
buildtool pdf        % all help pages -> documentation/drEEM_toolbox_documentation.pdf
buildtool            % default: package, after check, test, docs and tutorials
```

`docs`, `tutorials` and `pdf` declare inputs and outputs, so `buildtool` skips them when
nothing has changed. The package is written to `release/dreem.mltbx`.

`pdf` (needs Google Chrome and Python 3 with `pypdf`, ~2 min) runs `docs` and `tutorials`
first, then renders every page in `toolbox/doc` and merges them with a table of contents
and bookmarks: Overview and Tutorials in the order of `toolbox/doc/helptoc.xml`, then all
function pages from `documentation/functions/`. A new tutorial page must be added to the
lists in `build_doc_pdf.py`; new function pages are included automatically. The PDF is not
part of the package; don't edit it, rebuild it.

Agents usually can't drive MATLAB GUIs. When verifying, call methods with `plot=false`
and avoid anything that opens a blocking window (see `toolbox/AGENTS.md`).

## Testing

Run `buildtool test` before every commit. All tests must pass. A failing test after a
code change usually means the change affects results further down the processing chain.

| Test class | Covers |
|---|---|
| `ToolboxStructureTest` | every `@drEEMtoolbox` file is declared Static with the file's signature; public methods have help header, doc page and `doc.m` entry; version and identifier agree across `drEEMtoolbox.m`, `matlab.toml`, `Contents.m` |
| `ImportTest` | `importeems`, `importabsorbance`, `importscans` on generated csv files |
| `MergeMeasurementsTest` | `mergemeasurements`: transfer, missing samples, `noreplace`, IFE guard, model reset |
| `ProcessingContractTest` | rules each processing step must keep (e.g. blank subtraction is exactly samples − blanks, Raman calibration is one factor per sample, `rmspikes` only deletes, steps can't run twice) |
| `ProcessingRegressionTest` | ~40 option combinations of the processing methods, compared with stored fingerprints |
| `FittingTest` | PARAFAC, split validation, Fmax, OpenFluor export + `projectmodel`, PCA, on synthetic data with a known 3-component structure |
| `OpticalIndicesTest` | `fitslopes` (known slope) and `pickpeaks` (constant EEMs) |
| `ExportTest` | `exportresults`, `export2zip`, `export2openfluor`: files complete, exported values equal the dataset |
| `TutorialDataTest` | shipped tutorial `.mat` files validate; the processing chain reproduces `tutorial_01_processed.mat` |
| `UpdateCheckTest` | `updatecheck` never errors (offline, invalid record, unexpected response), decides correctly for newer/same/older versions, and the published Zenodo version has a `.mltbx` and a plain version number |
| `DiagnosticPlotTest` | diagnostic mode and `plot=true` of the processing methods run and open figures (smoke test) |
| `BatchModeTest` | with batch mode simulated (`drEEMtoolbox.isinteractive(false)`), calls that wait for a person raise `drEEM:needsInteractiveSession` and diagnostic modes return. New `uiwait`/`waitfor`/dialog calls need a `drEEMtoolbox.requireinteractive` guard and a test here |
| `WorkflowStepsTest` | `alignsamples`, `associatemetadata`, `addcomment` |
| `ViewerTest` | all `view*` apps open and save their figure under the requested name |
| `RealDataImportTest` | real instrument files in `tests/testdata`: Aqualog text export (dataset 2) through the tutorial chain incl. PARAFAC; Origin project via `importaqualog` (dataset 1) |
| `OriginVsTextImportTest` | the same measurements as `.opj` and as Aqualog text export give identical EEMs, blanks and absorbance (dataset 3) |

Writing tests:
- Inherit from `tests/DreemTestCase.m`. It checks that `drEEMtoolbox` resolves to this
  repository (i.e. the project is open), closes figures after each test, and provides
  `useTempFolder`, `knownStatus`, `writeEEMs`, `writeSpectra`, `examplesFile`.
- Call methods as `drEEMtoolbox.<method>(...)`, never via `tbx = drEEMtoolbox`: the
  constructor runs the online update check and may open dialogs.
- Pass `plot=false` and a complete `drEEMstatus` (`knownStatus`) so no window opens.
- Prefer data with a known answer: `tests/SyntheticData.m` builds exact trilinear
  EEMs, constant EEMs and valid datasets without file import. Otherwise use the shipped
  `toolbox/examples/*.mat`. Don't add large data files.
- Fits must be reproducible: `parallelization=false`, fixed `rng`, `consoleoutput="none"`.
- Tests that touch preferences (group `drEEM`, e.g. `lastUpdateCheck`) must restore them
  in a teardown, as `UpdateCheckTest` does.
- In `verifyEqual` and similar, the diagnostic text goes *before* `RelTol=`/`AbsTol=`;
  otherwise MATLAB can't parse the file and silently skips the whole test class.

**Processing regression references.** `ProcessingRegressionTest` compares each case in
`tests/ProcessingCases.m` with `tests/reference/processing_fingerprints.mat`
(sizes, missing values, sums, status, optical indices). When a result changes *on
purpose*, refresh the affected cases and commit the new reference with the code change:

```matlab
cd tests; updateProcessingReference("handlescatter_wide"); cd ..   % selected cases
cd tests; updateProcessingReference; cd ..                         % all cases
```

To cover a new option, add a line to `ProcessingCases.all()` and run the same command
for the new case name.

**Tutorial reference.** `TutorialDataTest/processingTutorialReproducesReference`
compares with `toolbox/examples/tutorial_01_processed.mat`. If an intended change makes
it fail, regenerate the tutorial data in order: re-run `import_tutorial_01`,
`processing_tutorial_01`, `prepare4Parafac_tutorial`, `parafac_tutorial_01`,
`tutorial_export_01` in the Live Editor and save each.

## Documentation

**Edit the Markdown in `documentation/`, never the HTML in `toolbox/doc/`.**
`buildtool docs` regenerates the HTML with pandoc (3.8.3, keep the version fixed so
output doesn't change between machines) and overwrites manual edits.

Markdown rules (pandoc reads ambiguous Markdown differently from Markdown previewers):
- blank line before every heading and before every `>` quote
- code in fenced blocks (` ``` `), not indented with tabs or spaces
- `<summary>`, `<i>` and `<a name>` lines inside `<details>` start at column 0
- copy the structure of an existing page, e.g. `documentation/functions/importabsorbance.md`

Tutorial pages are exported from the live scripts, which are binary: edit them in
MATLAB, **Run All, save**, then `buildtool tutorials`. The export uses the outputs
saved in the `.mlx`; it doesn't run the tutorials.

## How a public method is written

Follow the existing pattern exactly; users rely on its consistency. Use
`toolbox/@drEEMtoolbox/subtractblanks.m` as the reference.

1. **Help header** in this format (it drives `help` and the doc link):
   ```matlab
   function dataout = mymethod(data,options)
   % <a href = "matlab:drEEMtoolbox.doc('mymethod')">dataout = mymethod(data) (click to access documentation)</a>
   %
   % <strong>One-line description</strong> of what it does
   %
   % <strong>INPUTS - Required</strong>
   % data (1,1) {drEEMdataset.validate}
   %
   % <strong>INPUTS - Optional</strong>
   % plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
   % figurefile (1,:) {mustBeText} = "";
   %
   % <strong>EXAMPLE(S)</strong>
   %   samples = tbx.mymethod(samples);
   %
   % <a href = "matlab:drEEMtoolbox.doc('mymethod')"><strong>-> full documentation</strong></a>

   % Copyright (C) 2026 Urban J. Wuensch - wuensch@chalmers.se
   % ...
   ```
   Keep the INPUTS list identical to the `arguments` block.
2. **`arguments` block** with validators from `drEEMdataset`: always
   `drEEMdataset.validate(data)` and `drEEMdataset.mustContainSamples(data)`, plus the
   matching `sanityCheck*` (`Absorbance`, `IFE`, `Scatter`, `BlankSubtraction`, `PARAFAC`,
   `SignalCalibration`, `SpectralCorrection`) and range validators (`mustBeInRangeEm/Ex`,
   `mustBeModel`, `mustBeMetadataColumn`). Options are name-value (`options.x`).
   Plotting methods take `plot` (default `data.toolboxOptions.plotByDefault`) and `figurefile`.
   Text options may arrive as `string` or `char`; convert with `char(...)` before building
   field names or concatenating.
3. **Output handling.** Methods never modify the input; they return `dataout`.
   - Processing methods: no output argument means **diagnostic mode**: print
     `'<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).'`,
     force `plot=true`, and `clearvars dataout` at the end.
   - Fitting methods add a model; they must not change `X` or other measurements in the
     returned dataset. Work on a copy if the fit needs modified data (e.g. interpolation).
4. **Status.** If the method performs a processing step, update the status only through
   `dataout.status = drEEMstatus.change(dataout.status, "<field>", "applied by toolbox");`.
   Allowed values are enumerated in `toolbox/classes/drEEMstatus.m`. Every option of a
   method that changes the data must set the status (exports rely on it, e.g. to undo
   scaling when `signalScaling` contains "scaled to").
5. **History.** Every method that changes data appends exactly one entry, then validates:
   ```matlab
   idx = height(dataout.history)+1;
   dataout.history(idx,1) = drEEMhistory.addEntry(mfilename,'what happened',options,dataout);
   dataout.validate(dataout);
   ```
   Pass `options` as details so `viewhistory` can show the settings that were used.
6. **Models.** Methods that change `X`, `Ex`, `Em` or the samples must delete existing
   models and splits and say so in the console: `dataout.models = drEEMmodel;` and
   `dataout.split = drEEMdataset.empty;` (not `drEEMdataset`, which is one empty split).
7. **Figures.** Use `drEEMtoolbox.dreemfig` / `dreemuifig` and save via
   `dreemgui.saveAfterFunctionCall(fig, figurefile)`.
8. **Changing folders.** If a method `cd`s (e.g. exports), restore the folder with
   `onCleanup(@() cd(startFolder))` so an error doesn't leave the user elsewhere.

## Registering a new public method

A new file in `@drEEMtoolbox/` is not enough. Also:

- [ ] declare it in the `methods (Static = true, Access = public)` block of
      `drEEMtoolbox.m`, with the same signature as the file's `function` line
- [ ] add its name to the `mustBeMember` list in `@drEEMtoolbox/doc.m`
- [ ] write `documentation/functions/<name>.md` and run `buildtool docs`
      (function pages are not listed in `helptoc.xml`; no TOC entry needed)
- [ ] mention it in `documentation/tutorials/Whats new.md`
- [ ] add tests (and, for processing methods, cases in `tests/ProcessingCases.m`)
- [ ] if users will call it routinely, update the workflow in `toolbox/AGENTS.md`

`buildtool test` fails if any of the first three steps is missing, and whenever a
declaration differs from its file.

## Data classes and backward compatibility

- `drEEMdataset` is saved in users' `.mat` files and in `export2zip` archives. Adding,
  renaming or retyping a property breaks old files unless `upgradedataset` (and/or a
  `loadobj`) handles it. Don't change properties without a migration path.
- `drEEMstatus` property values are `mustBeMember` lists; adding a value is safe,
  renaming or removing one breaks saved datasets.
- `drEEMdataset.validate` defines what a consistent dataset is (e.g. no sample may have
  only missing numbers in a measurement). If you add a field with a per-sample
  dimension, add its size check there.

## GUIs

- The apps are designed in App Designer: `apps_mlapp/<name>.mlapp`. `.mlapp` is a binary
  zip; agents must not edit it as text.
- `toolbox/+dreemgui/<name>_gui.m` is the code exported from the app (classdef
  `<name>_gui`). After changing an `.mlapp`, re-export and rename into `+dreemgui`.
  Small fixes can be made in the `.m` file directly, but must be ported back to the
  `.mlapp` or they are lost on the next export. Say so explicitly in the PR.

## External binaries

`aqualog2nc` (used by `importaqualog`) is not shipped and not committed. It is
downloaded from Zenodo (record 21928517) for the user's OS on first use into `userpath`
(or `prefdir` if `userpath` is empty); `importaqualog(...,toolreset=true)` deletes it
to force a new download. Only Apple silicon Macs are supported on macOS.

## Versioning and releases

Version format is `2.YY.MM` (e.g. `2.26.10`). The version is stored in three places;
`ToolboxStructureTest` fails if they differ:

- `toolbox/@drEEMtoolbox/drEEMtoolbox.m`: `version`
- `matlab.toml`: `version` (written into the `.mltbx`)
- `toolbox/Contents.m`: line 2, version and month. Installed copies read their own
  version from here via `ver`, so a stale value causes endless update prompts.

Release steps:
1. Bump the version in the three places above; update `documentation/tutorials/Whats new.md`.
2. If tutorial output changed: Run All and save each tutorial in the Live Editor.
3. `buildtool` (check, test, docs, tutorials, package) → `release/dreem.mltbx`.
4. Install `release/dreem.mltbx` and check in the Add-On Manager that it shows the new
   version and *replaces* the installed drEEM (same identifier as `drEEMtoolbox.uuid`).
5. Publish a new version of the Zenodo record (concept DOI 10.5281/zenodo.17182160).
   **Installed copies check `zenodo.org/api/records/17182160/versions/latest`, so users
   are notified as soon as the Zenodo version is published.**
6. Create the GitHub release with the version as tag and `dreem.mltbx` attached under
   exactly that name (`releases/latest/download/dreem.mltbx` relies on it).
7. Update File Exchange.

## Update check and preferences

- The constructor calls `drEEMtoolbox.updatedreem`, which is split into
  `updatecheck` (decision, no dialog, tested in `UpdateCheckTest`) and
  `interactiveupdate` (dialog, download, install; not covered by tests).
  `updatecheck` must never error: anything unexpected skips the check.
- The last check date is a MATLAB preference (`getpref('drEEM','lastUpdateCheck')`),
  so users are checked at most once a day across sessions. The MATLAB version check
  uses `getpref('drEEM','MATLABversion')`. Preference names must be valid variable names.
- Copies up to 2.26.9 read `versions.txt` from the GitLab repo instead. Its first line
  must be `2.26.10;https://github.com/urbanwuensch/dreem/releases/latest/download/dreem.mltbx;`
  (added once 2.26.10 is released) so they update once to the Zenodo-based check.
  Keep that repo reachable.
- `drEEMtoolbox.options` (`plotByDefault`, `uifig`) only affects figures. Don't add
  options that change results: a script must produce the same data on every machine.

## Conventions

- Static methods only on `drEEMtoolbox`; all state lives in the `drEEMdataset`.
- Naming: lower-case verb+object (`subtractblanks`, `fitparafac`); viewers start with `view`,
  exporters with `export`, importers with `import`.
- Error IDs: `drEEM:<Reason>` via `MException` / `throwAsCaller`, so errors point at the
  user's line, not toolbox internals. Give warnings IDs too, so tests can check for them.
- Code must pass `buildtool check` without errors and support Windows, macOS and Linux
  (use `fullfile`, no shell calls except where already guarded).
- The Parallel Computing Toolbox is optional: every `parfor` path needs a serial fallback.
- Don't add dependencies on other MathWorks toolboxes without discussing it first.
- Keep `toolbox/external resources/` untouched; wrap third-party code instead.
- Commits: short imperative summaries (`fix ...`, `introduce ...`, `remove ...`).

## Things to avoid

- Changing default option values. Users' published scripts depend on them; a default
  change silently alters their results.
- Deleting or renaming public methods. Hide them (`Hidden = true`) and keep a compatible
  wrapper, as for `sampleQimport` / `aqualogimport` in `drEEMtoolbox.m`.
- Leaving method files in `@drEEMtoolbox/` that aren't declared in `drEEMtoolbox.m`.
- Editing generated HTML in `toolbox/doc/` instead of its Markdown or `.mlx` source.
- Updating regression references to make a failing test pass without understanding
  why the result changed.
- Committing build output (`*.mltbx`, `helpsearch*/`, `.buildtool/`), files the tutorials
  write when run, or large new data files.