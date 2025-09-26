<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# exportresults
Export a PARAFAC model to a spreadheet file. This includes a comprehensive description of the dataset.

## Syntax

`exportresults (data, f, filename)`

## Description

The `exportresults` function takes a drEEMdataset object, `data`, a `filename`, and a PARAFAC model index, `f`, and exports relevant data and results, including history, status, scatter treatment, Coble peaks and indicies, chosen parafac model overview, fluorescence maxima of samples, and excitation and emission loadings, to an Excel file. The function ensures the specified PARAFAC model exists within the `data` and organizes the data into several sheets within the spreadsheet.

> ***Note:*** The function deletes any existing file with the same name before writing the new data.

## Examples

`exportresults(data, 5, 'mymodel.xlsx')`

Export the 5-component model from `data` to Excel spreadsheet `mymodel.xlsx`.

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
    <summary><b>`filename` - name of export spreadsheet</b></summary>
    <i>char | string</i>
        
The name of the output file. It should be a text and will be saved with a `.xlsx` extension.
Note: Any extension at the end of the `filename` will be changed to `.xlsx`. If none is provided, it will be added.

</details>

<!---
## Name-Value arguments
-->
