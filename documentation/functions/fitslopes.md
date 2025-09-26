<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# fitslopes
Fit slopes to the CDOM absorbance data in a drEEMdataset object.



## Syntax
[`dataout = fitslopes(data)`](#syntax1)

[`dataout = fitslopes( ___ , Name,Value)`](#syntax1)

[`fitslopes( ___ , Name,Value)`](#syntax2)

## Description ##

The function `fitslopes` fits slopes to the CDOM absorbance data in `data`. The function returns the processed `data` with CDOM slopes stored in the table `data.opticalMetadata`. 

> ***Results are reported in the unit per µm and expressed as positive values (though CDOM absorbance is decreasing with increasing wavelength)***

When reporting slopes in publications, please refer to the original studies that presented the methodolog (see "Fitting methods")

> ***`fitslopes` is automatically called in `viewabsorbance`, `export2zip`, and `exportresults` to present CDOM slopes for futher analysis.***

<details open>
<summary><b><i>Fitting methods</b></i>
</summary>

The function fits slopes to the data using three ranges:

* Long range exponential slope fitting (specified by `options.LongRange`) according to [Stedmon et al. (2000)](https://doi.org/10.1006/ecss.2000.0645)

* Linear slope fitting of log-transformed data in the wavelength range `275`-`295` nm according to [Helms et al. (2008)](https://doi.org/10.4319/lo.2008.53.3.0955)

* Linear slope fitting of log-transformed data in the wavelength range `350`-`400` nm according to [Helms et al. (2008)](https://doi.org/10.4319/lo.2008.53.3.0955)
</details>

The function uses default values of input arguments (see Input arguments section) when options are not specified.

An entry will be added to the `history` field of the `dataout`, detailing the  options used for `fitslopes`. 

<details open>
<summary><b>`dataout = fitslopes(data,Name,Value)`</b>
</summary>
<a name="syntax2"></a>

Specifies additional options using one or more name-value pair arguments. For example, you can specify the Wavelength range for long-range exponential slope fitting using `LongRange` or turn plotting options on or off. <br>
Example: 

</details>




<details>
<summary><b>`fitslopes(data,Name,Value)`- Diagnostic mode</b>
</summary>
 <a name="syntax2"></a>

Runs the function in diagnostic mode. In this mode, opeions are automatically set to `details=true` and `plot=true` to inspect fits and adjust the default value of `rsq` or the wavelength range for the exponential slope before obtaining the slopes.

</details>

## Examples
`data = fitslopes(data,  'plot',false, LongRange=[300 700], rsq=0.9)` 
Fit slopes using a custom wavelength range for the expoential slope and use an R2 threshold of 0.9 to omit bad fits while also not producing any final plot.

## Input arguments ##
<details>
    <summary><b>`data` - contains CDOM spectra to fit slopes to</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. If no absorbance is present, the function will return an error.
</details>



## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`LongRange `- Range of the exponential slope</b></summary>
    <i>numeric [1x2]</i>
    
Numeric array specifying Wavelength range for long-range exponential slope fitting. Default is `[300 600]`.

</details>

<details open>
    <summary><b>`rsq `- R-squared threshold for fits</b></summary>
    <i>numeric</i>
    
A scalar numeric specifying R-squared threshold for linear fits. `rsq` must be numeric and less than or equal to `1`.
Default is `0.95`.

</details>

<details open>
    <summary><b>`plot`- switch to plot the results</b></summary>
    <i>logical</i>

Logical or numeric value to specify if a plot showing the results should be generated. The plot shows an overview of slopes for all sample in `data`. If no output argument is supplied, plotting is enabled automatically.

Default is `true`.

</details>



<details open>
    <summary><b>`details `- switch to plot diagnostics</b></summary>
    <i>logical</i>

Logical or numeric value to specify if detailed diagnostic plots should be shown for each sample. Each plot will show the raw, modeled, and residual data if a fit was possible.If no output argument is supplied, the option is enabled automatically.

Default is `false`.

</details>

## Output arguments
<details>
    <summary><b>`dataout` - dataset with slope data in .opticalMetadata</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

All calculated slopes are saved in a table inside the dataset called `opticalMetadata`. The table can be extracted to the workspace, e.g. slopes=dataout.opticalMetadata.

</details>