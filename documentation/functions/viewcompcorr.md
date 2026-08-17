<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewcompcorr #
Investigate the correlations between scores of different components in PARAFAC models.


## Syntax

	viewcompcorr(data,Name,Value)

## Description

The function `viewcompcorr` opens a new app, in which score correlation plots are generated as scatter plots and datapoints are color-labeled based on the information stored in metadata columns.
This app can also be opened from the `view correlations vs. metadata` button in the `Score Correlation` tab of the `viewmodels` app.



## Input arguments ##
<details>
    <summary><b>`data`- dataset with PARAFAC model</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 
</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`figurefile `- option to save the grapical user interface </b></summary>
    <i>character</i>

If a character vector is supplied (e.g. "output.png"), the function will save the current view of  the GUI.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewcompcorr`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewcompcorr.png". Likewise, providing "projectX.jpg" will result in "projectX-viewcompcorr.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving.

</details>