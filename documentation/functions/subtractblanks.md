<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# subtractblanks
subtract blanks from the samples



## Syntax
[`samplesout = subtractblanks(samples, blanks)`](#syntax1)

[`samplesout = subtractblanks( ___ , Name,Value)`](#syntax2)

[`subtractblanks( ___ , Name,Value)`](#syntax3)



## Description



Subtracts EEMs of blank stored in `blanks` from EEMs stored in `samples`.
The function `subtractblanks` makes sure the `blanks` and `samples`  have the same wavelength axes. Mismatches can occur especially
after the `ifecorrection` function has been applied on `samples`; parts of the EEM may have ben deleted due to lacking absorbance coverage. `subtractblanks` makes sure that the `blanks` will also be cut to be compatible.

Next, if the subtraction was successful, the function will plot the EEMs stored in `samples`, `blanks`, and `samplesout ` at an excitation of 275, where protein-like and humic-like fluorescence signal is likely to be observed, for the user to check the performance of the subtraction.

<img src="blankdiag.png" width="auto" height="auto" align="left"/>

All plots above show the predicted position of the different types of scatter. Take care that predictions and observations match, otherwise an issue with the wavelength accuracy might exist.

Observe that the area between 1st and 2nd order scatter in the top right corner is flat, otherwise your blanks contain significant levels of fluorescence.

If the last plot (bottom left) contains negative signals, more scatter was observed in the blank relative to the sample. This could be due to small air bubbles in one of the two samples, but is not necessarily a concerning observation.

> ***Always inspect the results of the blank subtraction and pay close attention to potential issues.***

An entry will be added to the `history` field of the `samplesout`.

<details open>
    <summary><b>`samplesout = subtractblanks(samples,blanks)` - default options</b></summary>
<a name="syntax1"></a>

Simply subtracts blanks and shows plots

</details>

<details open>
    <summary><b>`samplesout = subtractblanks( ___ , Name,Value)` - custom options</b></summary>
<a name="syntax2"></a>

specifies additional options using one or more [name-value](#NameValue) pair arguments.

</details>

<details open>
    <summary><b>`subtractblanks( ___ , Name,Value)` - Diagnosis mode</b></summary>
<a name="syntax3"></a>

When no output argument is supplied, the function automatically switches to diagnostics mode. Outputs are shown to allow you to see how the operation would affect your dataset.

</details>

## Input arguments
<details>
    <summary><b>`samples` - dataset with sample fluorescence</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(samples)`. 

> The property `samples.status.blankSubtraction` must be `"not applied"`. Otherwise, the function returns a validation error.

</details>

<details>
    <summary><b>`blanks` - dataset blank fluorescence</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(blanks)`. 

> The property `blanks.status.blankSubtraction` must be `"not applied"`. Otherwise, the function returns a validation error.

</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`plot`- switch to plot the results</b></summary>
    <i>logical</i>

Logical or numeric value to specify if a plot showing the results should be generated.
Default is `true`.

</details>

<details open>
    <summary><b>`figurefile `- option to save graphical `plot` output </b></summary>
    <i>character</i>

If a character vector is supplied (e.g. "output.png"), the function will save the output produced when plot is set to "true". If plot=false, no output will be saved even if a character vector is supplied.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`subtractblanks`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-subtractblanks.png". Likewise, providing "projectX.jpg" will result in "projectX-subtractblanks.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving)

</details>



## Output arguments
<details>
    <summary><b>`samplesout` - processed dataset </b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(samplesout)`. 

> The property `samples.status.blankSubtraction` will have changed from `"not applied"` to `"applied by toolbox"`.

</details>