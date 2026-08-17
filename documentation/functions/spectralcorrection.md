<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# spectralcorrection
Correct systematic, wavelength-dependent sensitivity biases of the excitation and emission monochromators using user-supplied instrument correction factors.



## Syntax

[`dataout = spectralcorrection(data,Name,Value)`](#syntax1)

[`spectralcorrection(data,Name,Value)`](#syntax2)

## Description

<details open>
    <summary><b>`dataout = spectralcorrection(data,Name,Value)` - apply spectral correction</b></summary>
<a name="syntax1"></a>

Applies a spectral (instrument-response) correction to the fluorescence EEMs in `data`, using excitation and emission correction factors supplied via the [name-value](#NameValue) pair notation. This compensates for wavelength-dependent sensitivity biases of the excitation and emission monochromators that were not already corrected by the instrument's own software.

The correction factors in `XCor` and `MCor` are interpolated onto the excitation (`Ex`) and emission (`Em`) wavelengths of `data`, combined into a single correction matrix, and applied to every sample in `data` by element-wise multiplication.

If the wavelength range covered by `XCor` or `MCor` is narrower than the `Ex`/`Em` range of `data`, `data` is trimmed to the overlapping range and a warning is displayed informing the user of this.

An entry will be added to the `history` field of `data`, detailing the processing options used.

>***The status-property "spectralCorrection" must be "not applied". Otherwise, the function returns a validation error. This property changes upon completion of the function to "applied by toolbox".***

</details>

<details open>
    <summary><b>`spectralcorrection(data,Name,Value)` - diagnostic mode</b></summary>
<a name="syntax2"></a>

By not supplying an output argument, the function will run in diagnostic mode. The excitation and emission correction curves and the resulting correction matrix will be calculated and shown, but the correction will not be applied to the dataset.

</details>


## Examples

1. correct a dataset with excitation and emission correction factors loaded from instrument-supplied calibration files
`xcorr = readmatrix('excitation_correction.csv');`
`mcorr = readmatrix('emission_correction.csv');`
`samples = tbx.spectralcorrection(samples,XCor=xcorr,MCor=mcorr);`

2. inspect the correction curves and matrix without applying them (diagnostic mode)
`tbx.spectralcorrection(samples,XCor=xcorr,MCor=mcorr);`

## Input arguments
<details>
    <summary><b>`data` - dataset with fluorescence data</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 

> The property `data.status.spectralCorrection` must be `"not applied"`. Otherwise, the function returns a validation error.

</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter.
<a name="NameValue"></a>

<details open>
    <summary><b>`XCor` - excitation correction factors</b></summary>
    <i>numeric, n-by-2</i>

A two-column numeric matrix with excitation wavelengths in the first column and the corresponding correction factor in the second column. Wavelengths do not need to match `data.Ex`; the factors are interpolated onto `data.Ex`. Typically supplied by the instrument manufacturer.

This argument is required; the function returns an error if it is not supplied.

</details>

<details open>
    <summary><b>`MCor` - emission correction factors</b></summary>
    <i>numeric, n-by-2</i>

A two-column numeric matrix with emission wavelengths in the first column and the corresponding correction factor in the second column. Wavelengths do not need to match `data.Em`; the factors are interpolated onto `data.Em`. Typically supplied by the instrument manufacturer.

This argument is required; the function returns an error if it is not supplied.

</details>

<details open>
    <summary><b>`plot`- switch to plot the results</b></summary>
    <i>logical</i>

Logical or numeric value to specify if a plot showing the results should be generated. The plot shows the excitation and emission correction curves, as well as the combined correction matrix. If no output argument is supplied, plotting is enabled automatically.

Default is `true`.

</details>


<details open>
    <summary><b>`figurefile` - option to save graphical `plot` output</b></summary>
    <i>character</i>

If a character vector is supplied (e.g. `"output.png"`), the function will save the output produced when `plot` is set to `true`. If `plot=false`, no output will be saved even if a character vector is supplied.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`spectralcorrection`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-spectralcorrection.png". Likewise, providing "projectX.jpg" will result in "projectX-spectralcorrection.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving)

</details>

## Output arguments
<details>
    <summary><b>`dataout` - spectrally corrected dataset</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

The status of the dataset is changed to reflect the fact that a spectral correction has been applied by the drEEM toolbox.

</details>