 <img src="top right corner logo.png" width="100" height="auto" align="right"/>

# importscans
Import supplementary one-dimensional scans (e.g. Raman emission scans, distinct emission scans, m/z spectra) and create drEEMdataset object.



## Syntax

[`data = importscans(filePattern)`](#syntax1)

[`data = importscans(filePattern,status)`](#syntax3)

[`data = importscans( ___ , Name,Value)`](#syntax2)

[`importscans( ___ )`](#syntax4)



## Description

This function scans the current working directory (`pwd`) for files using a given filename pattern, reads one axis column and one spectrum column from each file, and returns a `drEEMdataset` containing the scans as supplementary spectra.

Supplementary spectra are any one-dimensional measurement that accompanies your EEMs or absorbance spectra. The most common use is a separately measured **Raman scan of the blanks**, which `ramancalibration` can use instead of extracting the Raman peak from the blank EEMs (`source="scan"`).

The function does two passes of imports. The first reads the dimensions of each file and checks that all files have the same number of rows. The second pass imports the data. During import, each scan is sorted by ascending axis values and rows with missing numbers are removed.

> ***All files must contain the same axis information. Files whose axis differs from the first file are skipped with a warning and will be missing from the dataset!***




<details open>
<summary><b>
`data = importscans(filePattern)` - standard options, interactively provide status</b>
</summary>
<a name="syntax1"></a><br>

returns a drEEMdataset class object that contains the scans and their associated information.

Upon successful import, the `changestatus` GUI will appear on screen and pause the execution until the user has acknowledged the status of the dataset. Since the drEEMdataset can contain fluorescence, absorbance and supplementary spectra, the GUI will ask about all of these properties. Please ignore the others and focus on the property `suppSpectraInfo`, a free-text description of what the scans contain (e.g. `"Raman scans of blanks, Ex=350 nm"`).

> ***The GUI must be exited by clicking on "save & exit". Otherwise, the import will be cancelled and no dataset will be created.***

</details>

<details open>
<summary><b>
`data = importscans(filePattern,status)` - explicitly supply processing status</b>
</summary>
<a name="syntax3"></a>

For large projects with many imports and automated processing, it is much easier to prevent a GUI from popping up during import. This syntax gives you the option to supply the correct drEEMstatus to the function. The GUI only appears if the property `suppSpectraInfo` is `"unknown"`, so describing the scans is enough to suppress it.

Example: 

```
scan_status=drEEMstatus(suppSpectraInfo="Raman emission scans of blanks, Ex=350 nm");

ramanscans=tbx.importscans("* - Emission Graph.dat",scan_status);
```

</details>

<details open>
<summary><b>
`data = importscans([ ___ ], Name,Value)` - custom options</b>
</summary>
<a name="syntax2"></a>

Custom options are specified with optional pairs of arguments using one or more name-value arguments. For example, you can specify the column number that holds the axis data (e.g. wavelength) or the column that holds the spectrum.

</details>

<details open>
<summary><b>
`importscans( ___ )` - diagnostic mode</b>
</summary>
<a name="syntax4"></a>

Calling the function without an output argument tests whether the file pattern and options work, without creating a dataset and without the status GUI. If the test succeeds, you can call the function again and assign the output.

</details>

## Examples

<strong>Horiba AquaLog: Raman scans of blanks, used for signal calibration</strong>

```
tbx = drEEMtoolbox;
blanks = tbx.importeems("* - Waterfall Plot Blank.dat");
ramanscans = tbx.importscans("* - Emission Graph.dat", ...
    drEEMstatus(suppSpectraInfo="Raman scans of blanks, Ex=350 nm"));

% Move the scans into the blank dataset (sample names must match)
blanks = tbx.mergemeasurements(blanks,ramanscans,"supplementarySpectra");

% Calibrate using the discrete scans rather than the blank EEMs
samples = tbx.ramancalibration(samples,blanks,source="scan");
```
      
<strong>csv files with the axis in column 1 and the signal in column 3, one header line:</strong>

`scans = tbx.importscans("*.csv",axisColumn=1,spectrumColumn=3,NumHeaderLines=1);`

<strong>Test the options before importing (diagnostic mode):</strong>

`tbx.importscans("*.csv",spectrumColumn=3);`

## Input arguments
<details open>
<summary><b>`filePattern ` Text pattern to identify files for import</b></summary>
<i>char | string</i>
        
A text specifying the pattern of the files to be imported. This can include wildcard characters (*) to match multiple files. The pattern will be completely removed from the sample name after import to leave only the non-repeating filename information. For example `S001 - Emission Graph.dat` will be known as `S001` in the produced dataset.

> ***To merge scans into another dataset with `mergemeasurements`, the resulting sample names must match those of the target dataset.***

Examples:

* `'*.csv'`
* `'* - Emission Graph.dat'`

</details>


<details open>
<summary><b>`status ` drEEMstatus object with correct parameters preset</b></summary>
<i>drEEMstatus</i>
        
Provide an already customized drEEMstatus object to prevent the GUI from appearing at the end of an import. Only `suppSpectraInfo` is checked; describe what the scans are.

```
scan_status=drEEMstatus(suppSpectraInfo="Raman emission scans of blanks, Ex=350 nm");
```

</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `filePattern` and `status` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>


<details open>
<summary><b>`axisColumn`- which column of data contains the axis</b></summary>
<i>numeric</i>
    
The axis data (e.g. emission wavelength, m/z) in the measurement files are expected to be found in the specified column.<br>

Example: `'axisColumn', 1` if the first column contains the axis information.

Default is `1`.

</details>

<details open>
<summary><b>`spectrumColumn `- which column of data contains the spectrum</b></summary>
<i>numeric</i>

Specify which column of data in the measurement files contains the signal. 

Example: `'spectrumColumn', 2` if the second column contains the signal.

Default is `2`.
    
</details>

<details open>
<summary><b>`NumHeaderLines `- number of header lines to ignore</b></summary>
<i>numeric</i>

Specify the number of lines (rows) to skip from the top in each file.<br>

Example: `'NumHeaderLines', 2` to remove the first 2 rows of each file<br>

Default is `0`.

</details>

## Output arguments
<details open>
<summary><b>`data` - contains supplementary spectra </b></summary>
<i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.
The scans are stored in `.suppSpectra` (samples × axis), the axis in `.suppSpectraAxis`, and sample names in `.filelist`. `.i` holds the position of each file in the import list, so gaps in `.i` indicate skipped files. Read the documentation on the `drEEMdataset` for more information.

</details>