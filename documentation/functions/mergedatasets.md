<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# mergedatasets
Merge two datasets to create one bigger dataset



## Syntax

[`dataout = mergedatasets(a,b)`](#syntax1)


## Description

<details open>
<summary><b>`dataout = mergedatasets(a,b)` - Merge datasets</b></summary>
<a name="syntax1"></a> 

Merges two datasets of the class drEEMdataset. Each dataset is validated before merging and must have:

- identical status properties
- equal absorbance wavelength axes
- identical emission axes
- identical excitation axes
- the same columns in the metadata tables

The function does **not** currently interpolate to create comparable datasets with identical axes.

> Note: The traceability of the resulting dataset `dataout` is limited since the histories of `a` and `b` cannot be preserved in `dataout`


</details>




## Input arguments
<details>
<summary><b>`a` - dataset with fluorescence and / or absorbance data</b></summary>
<i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(a)`. 

</details>

<details>
<summary><b>`b` - dataset with fluorescence and / or absorbance data</b></summary>
<i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(b)`. 

</details>


## Output arguments
<details>
<summary><b>`dataout` - merged dataset</b></summary>
<i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.


</details>
