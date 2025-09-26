<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# processabsorbance
Perform basic corrections on absorbance data



## Syntax
[`dataout = processabsorbance(data)`](#syntax1)


[`dataout = processabsorbance( ___ , Name,Value)`](#syntax2)

[`processabsorbance( ___ , Name,Value)`](#syntax3) 

## Description

The `processabsorbance` function reads `absorbance` values from `data` and performs multiple corrections of the data. These are:

* baseline correction. The average absorbance above the value [`baseWave`](#NameValue) are subtracted.
* extrapolating the longer wavelength (needed for inner filter effects correction). This is done via the exponential slope that is fitted to the existing data and then extracted to the longest wavelength in the EEM (excitation or emission).
* Replacing negative values with zeroes. This option is not intended to improve the quality of CDOM spectra but to avoid IFE correction artefacts.

These processes are performed in the order specified above. If extrapolation is requested, baseline correction will be carried out both prior and after the extrapolation to ensure data quality. 

<details open>
<summary><b>`dataout = processabsorbance(data)` - perform default correction</b>
</summary>
<a name="syntax1"></a>
If no option is specified, the function will perform a baseline correction and an extrapolation of CDOM data to wavelengths covered in the EEM if these exceed the absorbance. 

When the processing is finished, the function will plot the original absorbance data, the extrapolated data, and the final processed data in one figure.

</details>



<details open>
<summary><b>`dataout = processabsorbance(___ , Name,Value)` - perform corrections as specified with custom options</b>
</summary>
<a name="syntax2"></a>
specifies additional options using one or more [name-value](#NameValue) pair arguments. For example, you can specify if a baseline correction must be performed, and whether the absorbance data must be extrapolate or not. <br>
Example: `data = processabsorbance(data,'correctBase',false)` to skip the baseline correction step. 

</details>

<details open>
<summary><b>`processabsorbance(___ , Name,Value)` - run the function in diagnostic mode</b>
</summary>
<a name="syntax3"></a>
If no output is specified, the function will simply give a visual overview over the results that would be assigned an output. Use this to decide which corrections you want or need to apply.

</details>


## Examples

1. correct CDOM baseline, extrapolate if EEM wavelength coverage is different from CDOM, and plot outcomes
`samples = tbx.processabsorbance(samples);`

2. Just carry out a baseline correction
`samples = tbx.processabsorbance(samples,correctBase=true,extrapolate=false,zero=false);`

3. Do something, but please don't show that final plot
`samples = tbx.processabsorbance(samples,...,plot=false);`

## Input arguments ##
<details>
    <summary><b>`data` - contains CDOM spectra to correct</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. If no absorbance is present, the function will return an error.
</details>



## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>


<details open>
    <summary><b>`correctBase `- switch for baseline correction</b></summary>
    <i>logical</i>

Indicates if the baseline correction should be performed. Default value is `true`.
The baseline correction is applied using the mean absorbance beyond the specified or default `baseWave`

Default is `true`.

If no absorbance is measured past 580nm, the option is automatically disabled. However, if extrapolation is turned on, the baseline correction will be carried out regardless.

</details>

<details open>
    <summary><b>`baseWave `- wavelength range for baseline correction</b></summary>
    <i>numeric scalar</i>

Specify the wavelength from which the absorbance data is used for baseline correction. The wavelength must be greater than 580 nm.

Wavelengths above the specified value will be used to extract the average baseline absorbance to subtract.

Default value is `595`.

</details>

<details open>
    <summary><b>`zero `- switch for zeroing of negative absorbance</b></summary>
    <i>logical</i>

If `true` the negative values will be set to zeroes.
Default is `false`.

</details>


<details open>
    <summary><b>`extrapolate `- switch for spectral extrapolation</b></summary>
    <i>logical</i>

If `true`, the function performs a non-linear fit of the absorbance data (`b1*exp(b2/1000*(350-lambda))+b3`) to model the exponential absorbance spectra, based on [Stedmon et al. (2000)](https://doi.org/10.1006/ecss.2000.0645), and extrapolate it to cover the wavelength range needed for EEM IFE corrections.

Default is `true`.

</details>


<details open>
    <summary><b>`plot`- switch to plot the results</b></summary>
    <i>logical</i>

Logical or numeric value to specify if a plot showing the results should be generated. The plot shows an overview of slopes for all sample in `data`. If no output argument is supplied, plotting is enabled automatically.

Default is `true`.

</details>

## Output arguments

<details open>
    <summary><b>`dataout` - dataset with processed absorbance</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.
</details>