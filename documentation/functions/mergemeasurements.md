 <img src="top right corner logo.png" width="100" height="auto" align="right"/>

# mergemeasurements
Transfer one measurement type (absorbance, fluorescence or supplementary spectra) from one drEEMdataset into another



## Syntax

[`dataout = mergemeasurements(a,b,measurement)`](#syntax1)

[`dataout = mergemeasurements(a,b,measurement,mode)`](#syntax2)



## Description

Measurements of the same samples are often imported separately, e.g. EEMs with `importeems`, absorbance spectra with `importabsorbance` and Raman scans with `importscans`. Each import creates its own `drEEMdataset`. `mergemeasurements` copies one type of measurement from dataset `b` into dataset `a`, so that all information on a sample is kept in one dataset.

Samples are matched by their names (`.filelist`), not by their position in the dataset:

* Samples in `a` without a match in `b` receive missing numbers (`NaN`) for the transferred measurement. A warning is displayed.
* Samples in `b` without a match in `a` are ignored.

Together with the measurement, the function copies its axis information (e.g. `.absWave`) and the related entries of the dataset status (e.g. `absorbanceUnit`) from `b` to `a`.

> ***Use `alignsamples` before merging. It reports and removes samples that are not present in all datasets, so that no missing numbers are introduced.***

> ***The history of `b` is not transferred. Only the merge itself is recorded in the history of `a`. Any processing applied to `b` beforehand (e.g. `processabsorbance`) will not appear in the history of the merged dataset. To keep a complete record, merge first and process afterwards, or document the processing of `b` with `addcomment` or `export2zip` before merging.***



<details open>
<summary><b>
`dataout = mergemeasurements(a,b,measurement)` - transfer a measurement, overwrite existing data</b>
</summary>
<a name="syntax1"></a><br>

returns `a` with the measurement of the type `measurement` taken from `b`. If `a` already contains this type of measurement, it is overwritten and a warning is displayed.

</details>

<details open>
<summary><b>
`dataout = mergemeasurements(a,b,measurement,mode)` - control whether existing data may be overwritten</b>
</summary>
<a name="syntax2"></a>

With `mode="noreplace"`, the function stops with an error if `a` already contains this type of measurement. Use this in scripts where accidentally overwriting data must be ruled out.

</details>

## Examples

<strong>Move absorbance into the sample dataset (standard workflow after import):</strong>

	samples = tbx.importeems("* - Waterfall Plot Sample.dat");
	absorbance = tbx.importabsorbance("* - Abs Spectra Graphs.dat");

	[samples,absorbance] = tbx.alignsamples(samples,absorbance);
	samples = tbx.mergemeasurements(samples,absorbance,"absorbance");
	clearvars absorbance

	samples = tbx.processabsorbance(samples);   % process after merging: recorded in the history
      
<strong>Add Raman scans to the blanks for signal calibration:</strong>

	ramanscans = tbx.importscans("* - Emission Graph.dat");
	blanks = tbx.mergemeasurements(blanks,ramanscans,"supplementarySpectra");
	samples = tbx.ramancalibration(samples,blanks,source="scan");

<strong>Never overwrite existing data:</strong>

`samples = tbx.mergemeasurements(samples,absorbance,"absorbance","noreplace");`

## Input arguments
<details open>
    <summary><b>`a ` Receiving dataset</b></summary>
    <i>drEEMdataset</i>
        
The dataset that receives the measurement. Its samples, sample names, metadata and other measurements are kept. Its history is continued with an entry for the merge.

</details>

<details open>
    <summary><b>`b ` Source dataset</b></summary>
    <i>drEEMdataset</i>
        
The dataset that provides the measurement. It must contain data of the type `measurement`. Sample names (`.filelist`) must match those in `a`; check this by comparing `a.filelist` and `b.filelist` if the merge reports unmatched samples. Differences usually come from file patterns during import that removed different parts of the file names.

</details>

<details open>
    <summary><b>`measurement ` Type of measurement to transfer</b></summary>
    <i>"absorbance" | "fluorescence" | "supplementarySpectra"</i>
        
| `measurement` | Transferred data | Transferred status |
|---|---|---|
| `"absorbance"` | `.abs`, `.absWave` | `absorbanceUnit` |
| `"fluorescence"` | `.X`, `.Ex`, `.Em`, `.nEx`, `.nEm` | `spectralCorrection`, `IFEcorrection`, `blankSubtraction`, `signalCalibration`, `scatterTreatment`, `signalScaling` |
| `"supplementarySpectra"` | `.suppSpectra`, `.suppSpectraAxis` | `suppSpectraInfo` |

</details>

<details open>
    <summary><b>`mode ` Behaviour if `a` already contains this measurement</b></summary>
    <i>"replace" | "noreplace"</i>

* `"replace"` (default): existing data in `a` are overwritten and a warning is displayed.
* `"noreplace"`: the function stops with an error and nothing is changed.

</details>

## Output arguments
<details open>
    <summary><b>`dataout` - dataset `a` with the transferred measurement </b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset`. The history contains an entry describing which measurement was transferred from which dataset. Read the documentation on the `drEEMdataset` for more information.

</details>

## See also
`alignsamples` | `mergedatasets` | `importeems` | `importabsorbance` | `importscans` | `addcomment`