<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# export2openfluor
Export a PARAFAC model to text file formatted for OpenFluor.

## Syntax

`export2openfluor(data, f, filename)`

## Description

The `export2openfluor` function exports the excitation and emission loadings of a parafac model, specified by the number of components, `f`, from `data.models` to a text file formatted for OpenFluor. If wavelengths are not whole numbers (integers) the function ensures the data is interpolated using a spline method to fit the new wavelength ranges. The function ensures the data properly formatted before writing it to the specified `filename`.

## Examples

`export2openfluor(data, 5, 'mymodel.txt')`

Export the 5-component model of `data` to text file `mymodel.txt`.



## Input arguments
<details>
    <summary><b>`data` - dataset to extract model from</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 
</details>

<details open>

<summary><b>`f` - PARAFAC model with f components</b></summary>
    <i>numeric</i>

Specify the number of parafac components in the model that you want to export. A scalar (single number) is expected, exporting multiple models at once is not supported.

</details>

<details open>
    <summary><b>`filename` - name of export txt-file</b></summary>
    <i>char | string</i>
        
The name of the output file. It should be a text and will be saved with a `.txt` extension.
Note: Any extension at the end of the `filename` will be changed to `.txt`. If none is provided, it will be added.

</details>

<!---
## Name-Value arguments
-->
