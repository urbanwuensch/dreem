<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# scores2fmax

Convert model scores to Fmax.

## Syntax

	
`Fmax=scores2fmax(data,f)`

## Description

Convert model scores to fluorescence maxima in the original intensity units. While scores have no unit, conversion of scores (A) by multiplication with the maxima in B and C for each component yields their intensities in the units of the original dataset.



## Input Arguments

<details>
    <summary><b>`data` - dataset with PARAFAC models</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 

</details>


<details open>
    <summary><b>`f` - model with f components</b></summary>
    <i>numeric</i>
        
The f-component model for which scores should be converted to fluorescence maxima (fmax).

The f-component model must exist!

</details>


## Output Arguments

<details open>
    <summary><b>`Fmax` - matrix with fluorescence maxima</b></summary>
    <i>numeric</i>
        
`[data.nSample x f]` matrix containing the fluorescence maxima of components.

</details>