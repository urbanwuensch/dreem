<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewsplitvalidation
Visualize a split validation on a specific model present in data.



## Syntax

	dataout = viewsplitvalidation(data, fac,Name,Value)

## Description

The `viewsplitvalidation` function visualizes the split validation on a provided dataset by checking the similarities of excitation and emission spectral loading between different subsets. Two spectra are sufficiently similar if the Tucker congruence coefficient is greater than `0.95`.

> ***The actual split validation is already performed after a call to `fitparafac` with the option `mode='fitsplits'`. There, the results are shown as console output but no plots are shown. Use this function to find out how well the validation worked or where it did not succeed.***
 
The function checks if the model specified by the number of components `fac` is validated across different splits and the model obtained from all of the data, `"overall"` (see `fitparafac` function for options `"fitoverall"` and `"fitsplit"`).

If validation check is passes, the function plots the validated models, displaying their loadings and contours, and provides diagnostic plots if validation fails. 

The function includes detailed error messages to help diagnose why a validation might have failed.

`viewsplitvalidation` checks for the presence of desired model in the overall and all split datasets during the input parsing. If a model is not found in all cases, an error will be shown. 

> ***Note:*** A splitvalidation with the function is only possible if the overall model can be compared with models in all splits.


## Input arguments
<details>
    <summary><b>`data` - dataset with PARAFAC models</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 

PARAFAC models should be present in the overall dataset and all splits for full functionality.



</details>


<details open>
    <summary><b>`fac` - number of PARAFAC compoents in the validated model</b></summary>
    <i>numeric</i>
        
Specifies the number of components in the model you wish to validate.



</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`figurefile `- option to save grapical `plot` output </b></summary>
    <i>character</i>

If a character vector is supplied (e.g. "output.png", the function will save the output produced when plot is set to "true". If plot=false, no output will be saved even if a character vector is supplied.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewsplitvalidation`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewsplitvalidation.png". Likewise, providing "projectX.jpg" will result in "projectX-viewsplitvalidation.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving.

</details>

