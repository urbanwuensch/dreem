<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# zapnoise
Set part of emission or excitation spectra from one or more samples to NaN.



## Syntax

[`dataout = zapnoise(data, sampleIdent, emRange, exRange)`](#syntax1)


## Description

Removes bad fluorescence data (set to `NaN`) in the emission range of `EmRange` and excitation range of `ExRange` from specified `sampleIdent `, in `data`.


> If the function `scalesamples` has been used prior to using the `zapnoise` function, the `zapnoise` will automatically perform the zapping on the unscaled dataset. This will ensure the toolbox works smoothly if the scaling is reverted. For more information see `scalesamples` function.

## Examples

* Zap noise at Ex 255 Em 450 in data.i==5

`samples = tbx.zapnoise(samples,data.i==5,450,255);`

* Zap entire emission scan at Ex 255 in sample data.i==5

`samples = tbx.zapnoise(samples,data.i==5,[],255);`

* Zap entire emission scans at Ex 255 and 300 in sample data.i==7

`samples = tbx.zapnoise(samples,data.i==5,[],255);`

`samples = tbx.zapnoise(samples,data.i==5,[],300);`


## Input arguments ##
<details>
    <summary><b>`data` - dataset containing fluorescence EEMs</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.

</details>


<details open>
    <summary><b>`sampleIdent ` - sample(s) to affect</b></summary>
    <i>logical [`1x data.nSample`]</i>
        
Specifies which samples are to be affected . Must be logical. Is comparative statements and functions as input to the option.

Matlab-internal functions include: `matches`, `contains`, `==`, `~` 

</details>

<details open>
    <summary><b>`emRange ` - emission wavelengths in nanometers to NaN</b></summary>
    <i>numeric</i>
        
Specify the range of emission wavelengths to be zapped from `sampleIdent`. The provided range must be within the emission range of `data`. If only one wavelength is provided (not a range) the function will automatically set the range to two closest neighboring wavelengths around the specified wavelength.<br>

Example: `(__, __, [300 350], __)` to remove emission data between `300` and `350` nm.<br>
Example: `(__, __, 300, __)` to remove emission data between the first emission wavelengths below and above `300` nm.<br>
Example: `(__, __, [min(data.Em):350], __)` to remove emission data between  the first emission wavelength and `350` nm.

</details>


<details open>
    <summary><b>`exRange ` - excitation wavelengths in nanometers to NaN</b></summary>
    <i>numeric</i>
        
Specify the range of excitation wavelengths to be zapped from `sampleIdent`. The provided range must be within the excitation range of `data`. If only one wavelength is provided (not a range) the function will automatically set the range to two closest neighboring wavelengths around the specified wavelength.

Example: `(__, __, __, [400 410])` to remove data between excitation `400` and `410` nm.

Example: `(__, __, __, 400)` to remove data between the first excitation wavelengths below and above `400` nm.

Example: `(__, __, __, [min(data.Ex):max(data.Ex)])` to remove data between  the first and last excitation wavelengths.

</details>


Example: `(__, __, __, [400 410])` to remove data between excitation `400` and `410` nm.

Example: `(__, __, __, 400)` to remove data between the first excitation wavelengths below and above `400` nm.

Example: `(__, __, __, [min(data.Ex):max(data.Ex)])` to remove data between  the first and last excitation wavelengths.

## Output arguments
<details>
    <summary><b>`dataout` - treated dataset</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

</details>