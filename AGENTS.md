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
| `toolbox/doc/` | Shipped HTML help, `helptoc.xml`, `GettingStarted.mlx`, images |
| `toolbox/examples/` | Tutorial live scripts (`.mlx`) and their data (`.mat`) |
| `toolbox/external resources/` | Third-party code (N-way toolbox, inpaint_nans, crameri). **Do not modify.** |
| `toolbox/AGENTS.md` | Guide for agents *using* the toolbox (ships to users) |
| `apps_mlapp/` | App Designer sources (`.mlapp`) for the GUIs in `+dreemgui` |
| `documentation/` | Markdown sources of the function and tutorial pages, diagrams, compiled PDF |
| `matlab.toml` | MATLAB project + packaging config (version, folders, output file name) |
| `buildfile.m` | Build tool plan: `check` (code issues), `test`, `package` |

## Building, checking, testing

From the repo root in MATLAB:

```matlab
buildtool check      % static code analysis (CodeIssuesTask) — must be clean of errors
buildtool test       % runs tests in tests/
buildtool            % default: package (depends on check + test)
```

Note: `buildfile.m` and `matlab.toml` reference a `tests/` folder that is not in the
repository right now, so `buildtool test` / `buildtool package` will fail until it exists.
Until there is a test suite, verify changes by running the affected tutorial
(`toolbox/examples/*.mlx`, using the shipped `tutorial_*.mat` data) end to end.
New tests go in `tests/` as `matlab.unittest` classes and should use the tutorial
data rather than new large files.

Agents usually can't drive MATLAB GUIs. When verifying, call methods with `plot=false`
and avoid anything that opens a blocking window (see `toolbox/AGENTS.md`).

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
3. **Output handling.** Methods never modify the input; they return `dataout`.
   - Processing methods: no output argument means **diagnostic mode** — print
     `'<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).'`,
     force `plot=true`, and `clearvars dataout` at the end.
   - Some methods also support the experimental `drEEMtoolbox.outputscenario(nargout)`
     ("implicitOut" overwrites the caller's variable via `assignin`). It is off by default
     (`options.OvrWrteUnless = false`); don't extend it to new methods unless asked.
4. **Status.** If the method performs a processing step, update the status only through
   `dataout.status = drEEMstatus.change(dataout.status, "<field>", "applied by toolbox");`.
   Allowed values are enumerated in `toolbox/classes/drEEMstatus.m`.
5. **History.** Every method that changes data appends exactly one entry, then validates:
   ```matlab
   idx = height(dataout.history)+1;
   dataout.history(idx,1) = drEEMhistory.addEntry(mfilename,'what happened',options,dataout);
   dataout.validate(dataout);
   ```
   Pass `options` as details so `viewhistory` can show the settings that were used.
6. **Models.** Methods that change `X`, `Ex`, `Em` or the samples must delete existing
   models (as `subdataset`/`zapnoise` do) and say so in the console.
7. **Figures.** Use `drEEMtoolbox.dreemfig` / `dreemuifig` and save via
   `dreemgui.saveAfterFunctionCall(fig, figurefile)`.

## Registering a new public method

A new file in `@drEEMtoolbox/` is not enough. Also:

- [ ] declare it in the `methods (Static = true, Access = public)` block of
      `drEEMtoolbox.m`, **with the same signature as the file** (several current
      declarations have drifted, e.g. `importeems`, `exportresults`, `mergedatasets`,
      `ifecorrection`; fix them when you touch them)
- [ ] add its name to the `mustBeMember` list in `@drEEMtoolbox/doc.m`
      (note: that list currently contains the typo `"importscsans"`)
- [ ] write `documentation/functions/<name>.md`, the shipped `toolbox/doc/<name>.html`,
      and a `<tocitem>` in `toolbox/doc/helptoc.xml`
- [ ] list it under its category in `toolbox/doc/function_overview.html`
- [ ] mention it in `toolbox/doc/Whats new.html`
- [ ] if users will call it routinely, update the workflow in `toolbox/AGENTS.md`

## Data classes and backward compatibility

- `drEEMdataset` is saved in users' `.mat` files and in `export2zip` archives. Adding,
  renaming or retyping a property breaks old files unless `upgradedataset` (and/or a
  `loadobj`) handles it. Don't change properties without a migration path.
- `drEEMstatus` property values are `mustBeMember` lists; adding a value is safe,
  renaming or removing one breaks saved datasets.
- `drEEMdataset.validate` defines what a consistent dataset is. If you add a field with
  a per-sample dimension, add its size check there.

## GUIs

- The apps are designed in App Designer: `apps_mlapp/<name>.mlapp`. `.mlapp` is a binary
  zip; agents must not edit it as text.
- `toolbox/+dreemgui/<name>_gui.m` is the code exported from the app (classdef
  `<name>_gui`). After changing an `.mlapp`, re-export and rename into `+dreemgui`.
  Small fixes can be made in the `.m` file directly, but must be ported back to the
  `.mlapp` or they are lost on the next export. Say so explicitly in the PR.
- `.mlx` live scripts are also binary. Edit tutorials in MATLAB, then re-export the
  matching HTML in `toolbox/doc/`.

## Versioning and releases

Version format is `2.YY.MM` (e.g. `2.26.10`). On release, update **all** of:

- `drEEMtoolbox.m`: `version` and `url` (Zenodo record of the new `.mltbx`)
- `matlab.toml`: `version` and `output-file-name`
- `toolbox/Contents.m`: version line
- `toolbox/@drEEMtoolbox/versions.txt`: prepend `version;download-url;`. The update
  check in installed copies reads this file from GitLab `main`, so only push it once
  the download URL works.
- `CITATION.cff` and `toolbox/citation.cff`
- `toolbox/doc/Whats new.html`

Then run `release/createRelease.m` (or `buildtool package`), upload to Zenodo/File Exchange,
and tag. Tagging triggers the GitLab mirror to MATLAB Online.

## Conventions

- Static methods only on `drEEMtoolbox`; all state lives in the `drEEMdataset`.
- Naming: lower-case verb+object (`subtractblanks`, `fitparafac`); viewers start with `view`,
  exporters with `export`, importers with `import`.
- Error IDs: `drEEM:<Reason>` via `MException` / `throwAsCaller`, so errors point at the
  user's line, not toolbox internals.
- Code must pass `buildtool check` without new warnings and support Windows, macOS and Linux
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
- Adding user-visible behaviour without documentation. Every public method has a help
  header, an HTML page and a TOC entry.
- Committing build output (`*.mltbx`, `helpsearch*/`) or large new data files.