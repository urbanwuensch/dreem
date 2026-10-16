<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# exportresults
Export the results from a PARAFAC or PCA model to a spreadsheet file. This includes a comprehensive description of the dataset.

## Syntax

`exportresults(data, f, filename)`

## Description

The `exportresults` function takes a drEEMdataset object `data`, a model index `f` and a `filename`, and exports relevant data and results, including history, status, scatter treatment, Coble peaks and indices, chosen parafac model overview, fluorescence maxima of samples, and excitation and emission loadings, to an Excel file. The function ensures the specified PARAFAC / PCA model exists within the `data` and organizes the data into several sheets within the spreadsheet.

> ***Note:*** The function deletes any existing file with the same name before writing the new data.

> ***Note:*** If the dataset was scaled with `scalesamples`, the scaling is reversed before export, so all exported intensities and Fmax values are in the original units.

The spreadsheet contains these sheets:

| Sheet | Content |
|---|---|
| `dataset history` | all processing steps |
| `dataset status` | processing status |
| `scatter treatment` | scatter removal settings |
| `Peaks & indicies` | fluorescence peaks, indices and CDOM slopes (`.opticalMetadata`) |
| `PARAFAC model overview` / `PCA model overview` | fit statistics of the models |
| `Split-validation approach` | how the splits were made (only if splits exist) |
| `<f>C Fl. max.` | sample names and Fmax of each component |
| `<f>C ex loadings`, `<f>C em loadings` | PARAFAC: `Excitation` / `Emission` wavelengths, then one column per component |
| `PC<n> re-folded loadings` | PCA: loadings of component n as an excitation-emission matrix |

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

<summary><b>`f` - PARAFAC or PCA model with f components</b></summary>
<i>numeric</i>

Specify the number of components in the model that you want to export. A scalar (single number) is expected, exporting multiple models at once is not supported.

</details>

<details open>
<summary><b>`filename` - name of export spreadsheet</b></summary>
<i>char | string</i>
        
The name of the output file. It will be saved with a `.xlsx` extension.
Note: Any extension at the end of the `filename` will be changed to `.xlsx`. If none is provided, it will be added.

> ***Note:*** Provide a file name only, not a path. The file is always written to the current folder (`pwd`); change to the target folder with `cd` before exporting. The name ends at the first dot: `'model.v2'` is saved as `model.xlsx`, and a full path such as `'C:\results\model.xlsx'` does not work.

</details>

<!---

## Name-Value arguments
-->
