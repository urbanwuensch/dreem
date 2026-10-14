<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# What's new

drEEM version 2 introduces a set of new functionality, workflows, object-oriented programming, visualizations, and graphical user interfaces that aim to make the processing of fluorescence EEMs straightforward for users with limited programming experience. We should not need to be Matlab experts to process fluorescence data.

Please head over to the section [Toolbox setup](dreem_workflow.html) to learn how to work with version 2. If you're used to [DOMFluor](https://doi.org/10.4319/lom.2008.6.572b) or [drEEM 0.1-0.6.x](https://doi.org/10.1039/C3AY41160E), things have changed considerably and there are lots of "breaking changes". But luckly we have tutorials that should help.


<!--<details>
<summary><b>Take a tour of the new toolbox (video on page)</b>
</summary>



 <p align="center">
<div class="responsive-iframe-container">
 <iframe width="80%" height="400" allowfullscreen="true"
src="https://www.youtube.com/embed/N_M8hMbKJFA?autoplay=0&mute=1&hl=en&cc_lang_pref=en&cc_load_policy=1" frameborder="0" allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</iframe>
</p> 

</details>
-->

## Version 2.26.9 (25 Sep 2026)

### Added

* Added support for the `status` input argument in `upgradedataset`.

### Fixed

* Fixed an error that sometimes showed up in `fitslopes` related to slow figure updates in the diagnosis plots.
* Semantic version correction (removed leading zero from the month).
* Fixed the toolbox MATLAB requirements: newer MATLAB releases are now always supported instead of being capped at the release used for packaging.
* Fixed the UUID used for building the toolbox.

## Version 2.26.08 (31 Aug 2026)

### Added

* Support for the direct importing of Aqualog-derived opj and ogw files. Import is better & easier than before! Read more here: https://doi.org/10.5281/zenodo.21928517

### Changed

* Completely removed the dependence on the Statistics & Machine Learning Toolbox for drEEM. Now, core MATLAB is all that's needed.

### Fixed

* Fixed a crash in `pickpeaks` that occurred when scans had only missing numbers.
* Bug in `pickpeaks` legend order (thanks to Ali Esmaeeli, Chalmers).
* Bugfix in `ifecorrection`: Absorbance <2 now results in NaN'ed fluorescence (as documented).
* Fixed error message content in `subtractblanks` when filelists mismatched.
* Improved input validation in `scalesamples`, `fitparafac`, `processabsorbance`, and `splitdataset`.
* Fixed several minor bugs in `fitparafac`.
* Fixed GUI errors related to models with more than 9 components.
* Fixed several bugs in `viewabsorbance` related to absorbance units.
* Many small fixes of bugs that cover rare use cases.
* Fixed >250 inconsistencies in the html-based documentation and function header help sections.

## Version 2.26.07 (16 Jul 2026)

### Added

* `fitpca`: Compute PCA models of fluorescence EEMs.
* New folder `useful scripts` in `examples` to demonstrate drEEM-specific MATLAB usage to achieve tasks.
* Various plots in many functions now feature more information in the datacursor, e.g. to identify samples by name or `.i`. Thank you Jann Müller for the suggestion!
* Lots of undocumented functionality in the `horibaRawdata` class has been added while working up decades of time series data. If you're interested in exporting data from opj files directly, reach out and we'll help you get started. This functionality is not intended for broad use.

### Changed

* `importabsorbance` and `importeems` now accept optional inputs to specify dataset status (preventing the GUI from popping up). Thank you Jann Müller for the suggestion!
* `viewmodels`: Now calls `dreemgui.viewparafac_gui` or `dreemgui.viewpca_gui` depending on model type.
* `viewspectralvariance` is now implemented as an appdesigner app with more consistent figure resizing options.

### Fixed

* `ramancalibration`: Bugfixes on history entry, SNB calculation and a spelling mistake in the toolboxOptions entry. Credit goes to Shengbin NI (University of Yamanashi). Thank you!
* `viewmodels`: Fixed bug where `figurefile` did not get passed along.

## Version 2.26.03 (25 Mar 2026)

### Changed

* `murea`: Improved labels on plots and axes.
* Added more context to the `drEEMdataset` documentation about the intended usage of the class.
* Auto-scaling of blank scans in `subtractblanks` was improved.

### Fixed

* PARAFAC tutorial: Fixed metadata table class for "type" to ensure better compatibility with functions.
* `ifecorrection`: Fixed upper vs. lower case spelling of units in the absorbanceConverter subfunction (thanks to Jessica Kennedy, University of Auckland - Institute of Marine Science).

## Version 2.26.02 (20 Feb 2026)

### Added

* `mergedatasets`: Combine datasets with equal wavelength axes, status, and metadata columns.
* Support for figure exporting in `viewdmr` and `vieweems`.
* `murea`: Multivariate Residual Analysis.
* `figurefile` option in all functions that produce a figure or GUI. This allows scripted figure saving to document results in automated workflows.

### Changed

* Added more diagnosis plots for `subtractblanks` and `ifecorrection`.

### Fixed

* `handlescatter(...,'gui')` crash was fixed.
* `export2zip` crash when no fluorescence or absorbance data was present is now handled.
* Removed empty rows during table import in `associatemetadata`.
* `doc`: Added "drEEMstatus" to the doc library.

## Version 2.25.12 (18 Dec 2025)

### Added

* `projectmodel`: Project the loadings of an existing PARAFAC model onto new samples with the help of an OpenFluor txt file.
* `ramancalibration`: Added the ability to model the Raman peak with a `gauss1` fit instead of raw data. Improved robustness against random noise.

### Fixed

* `exportresults`: Fixed an error that occurred when no CDOM data was present (thanks to Rose Cory & Morimaru Kida).
* `upgradedataset`: Included handling of the `logical` datatype for metadata.
* `vieweems`: Fixed missing contours on app startup by replacing the numeric edit field with a spinner.

## Version 2.25.11 (4 Nov 2025)

### Added

* Support for more versioning levels: Major, year, month, day (x.xx.xx.xx).
* Support for automated updating via Zenodo download and autoinstall.
* Crameri colormap toolbox included in drEEM (implemented by Chad Greene).
* `vieweems` supports colour-vision-deficient friendlier colormaps. Also removed unfriendly colormaps (jet + hsv).
* drEEMtoolbox will display citation information after calls to export functions.

### Changed

* Version validation no longer tolerates multiple versions and throws an error when the toolbox is initiated.
* Documentation of `pickpeaks` now contains references to primary research articles.

### Fixed

* Fixed an error that occurred in `handlescatter` when the Parallel Computing Toolbox is not installed.
* `viewsplitvalidation`: Fixed an issue where dissimilar components were not shown and others were shown multiple times (uncritical cosmetic error).
* Fixed an error in the `benchmark` function.

## Version 2.25.10 (5 Oct 2025)

### Added

* drEEM figures and apps now widely support a context menu (right-click) for publication-quality figures.
* `scalesamples` supports normalization to maximum fluorescence via `samples=scalesamples(samples,'max')`.
* Added dataset validator step: uniqueness of the `filelist` strings.
* Default fields in the `about` property of the `drEEMdataset` object (preparation for future functionality).
* Custom properties in the `metadata` table object within the drEEM dataset object (preparation for future functionality).
* `drEEMtoolbox` validation check: if older versions of the toolbox exist, an error is thrown to avoid unpredictable behavior.

### Changed

* The `changestatus` GUI is now always on top to catch more attention.
* Several other GUIs were lowered in priority: Their window focus can be changed by the user by switching windows or apps.
* Richer function message for `processabsorbance` and `ramancalibration` in their history entries.
* `viewmodels`: Made scatter diagonals an optional feature with a checkbox.

### Fixed

* `viewabsorbance`: Fixed missing callback when changing sample.
* `importabsorbance` & `importeems`: Fixed quick help error (string pattern).
* Fixed minor errors in help sections, tutorials, and apps.
* Replaced the legacy random number generator in N-way with the recommended option (avoids unpredictable error messages).

### Comments

* drEEM uses uifigure windows instead of figure windows by default. In many cases, a `close all` command needs to be specified with the 'force' option, i.e. `close all force`, to close these uifigure windows.

## Version 2.25.09 (2 Sep 2025)

### Changed

* Moved the `doc` helper function to the toolbox due to toolbox packaging and path position (`doc` -> `drEEMtoolbox.doc`).
* Moved mlapp files to the `dreemgui` namespace and replaced mlapp files with .m-export files.
* Moved the N-way toolbox to a namespace to avoid future function conflicts with e.g. `PLS_toolbox`. If you want to use it yourself, type `nway.` followed by a tab on the keyboard to explore the functionality.
* Implemented a UUID for the toolbox to aid the installation and update process. The UUID now (and in future) matches 2.25.08.
* Fixed update procedure bugs (wrong URL and unnecessary repeated update reminders).

### Added

* GUI app `timezoneselector` (preparation for upcoming functionality).

### Comments

* The getting-started guide reflects the changes made to the doc-helper function. This is an unfortunate move we had to make for complicated reasons that are out of our control.

## Version 2.25.08 (11 Aug 2025)

### Improvements

* `importwizard` supports settings templates for several instrument types.
* Automated update check now links to MATLAB File Exchange (the old installer was removed).
* Added CDOM-only support for `subdataset` (i.e. it works for datasets without fluorescence).
* Minor improvements to readme.txt on the GitLab repository.

### Bugfixes

* Fixed a background color issue in `vieweems`.
* Fixed a variable name issue in `importwizard` that caused an error when only importing some types of data.

## Version 2.25.07 (31 Jul 2025)


### New features

* Object-oriented programming. `tbx=drEEMtoolbox;` assigns the toolbox to an object, and then you call `tbx.___` to use any function (use the TAB key to get suggestions!)
* A standardized CDOM dataset object called [`drEEMdataset`](dreemdataset.html): A class object that stores fluorescence and absorbance data. Read more in the [documentation](dreemdataset.html)
* Detailed information regarding the status of processing for `drEEMdataset` objects with the  [status property](dreemdataset.html). Loading a dataset from 5 years ago and wondering if IFE corrections had been done? The dataset would tell you from now on.
* [`drEEMhistory`](drEEMhistory.html): A class object that keeps a record of modifications by toolbox functions including their settings, date-time information, and comments if provided. Users can also add comments to the history independent from the toolbox to document the workflow.
* A new PARAFAC engine, courtesy of [Prof. Rasmus Bro](https://scholar.google.com/citations?user=gW_FGdQAAAAJ), that speeds up nonnegative PARAFAC by a factor of 4-5!
* Interactive tool to define scatter treatment options. Read more about [`handlescatter`](handlescatter.html).
* New data export functionalities. Open Science is amazing and we are fully committed to supporting you in this regard!

### General improvements

* Rewrites of all drEEM functions with `arguments` input validation. For the user, this means smart input argument suggestions and quick and helpful input validation. Hitting the tab-key during scripting is extremely helpful from now.
* Entirely new documentation with collapsing sections and nice formatting. The documentation is enriched with videos that walk you through the process.
* Data processing steps are implemented as **standalone** functions. No more custom code for vital standard operations (e.g. raman normalization or IFE correction). This also generally reduces the skills required for Matlab.
* Reduction in Addon Product dependencies. We've done our best to cut down the costly additional Matlab products requirements.
* Renamed functions to help occasional users remember / find functionality. For example, any function that primarily visualizes data starts with `view...` (e.g. `vieweems`)