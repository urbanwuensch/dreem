<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewspectralvariance
Visualize and analyze the spectral variability in fluorescence and absorbance data.



## Syntax
	viewspectralvariance(data,Name,Value)




## Description

The `viewspectralvariance` function plots the spectral variability of absorbance and fluorescence data. The function scales all data to unit variance in the sample mode, giving each sample equal weighting.



The function identifies samples with very low signals and will generate a warning regarding the impact of those samples.




## Input arguments

<details>
    <summary><b>`data` - dataset with fluorescence and absorbance data.</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 


</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`figurefile `- option to save grapical `plot` output </b></summary>
    <i>character</i>

If a character vector is supplied (e.g. "output.png", the function will save the output produced when plot is set to "true". If plot=false, no output will be saved even if a character vector is supplied.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewspectralvariance`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewspectralvariance.png". Likewise, providing "projectX.jpg" will result in "projectX-viewspectralvariance.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving.

</details>

