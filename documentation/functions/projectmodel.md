<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# projectmodel
Force-fit an externally published PARAFAC model (OpenFluor format) onto a `drEEMdataset`



## Syntax

[`dataout = projectmodel(data,file)`](#syntax1)


## Description

<details open>
    <summary><b>`dataout = projectmodel(data,file)` - project a published model onto `data`</b></summary>
<a name="syntax1"></a>

Loads a PARAFAC model that was exported in OpenFluor format (see [www.openfluor.org](https://openfluor.lablicate.com/)) from the text file `file`, and force-fits it onto `data`. The model's excitation and emission loadings are interpolated onto the wavelengths of `data` and held fixed. Only the sample-mode loadings (scores) are re-estimated for the samples in `data`. You can either force one of your old, pre-existing models onto your new data or check if someone else's model fits your data well.

Since the loadings are not re-estimated, `data` is first trimmed to the wavelength range shared by `data` and the model (`projectmodel` does not extrapolate).

The constraints stated in the OpenFluor file (e.g. non-negativity) are honored during the forced fit. The resulting model is stored in `dataout.models` at the index matching its number of components, `model.status` is set to `"forced projection"` to distinguish it from a normally-fitted model, and `model.initialization` records the name of the file the model was projected from.

An entry will be added to the `history` field of `dataout`, detailing the file the model was projected from.

</details>


## Examples

1. project a published 4-component OpenFluor model onto a dataset
`samples = tbx.projectmodel(samples,'openfluormodel.txt');`


## Input arguments
<details>
    <summary><b>`data` - dataset to project the model onto</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 

</details>

<details open>
    <summary><b>`file` - PARAFAC model in OpenFluor format</b></summary>
    <i>character</i>

Path to a text file containing a PARAFAC model in the OpenFluor format, e.g. one downloaded from [www.openfluor.org](https://openfluor.lablicate.com/) or created with [`export2openfluor`](export2openfluor.html). The file must exist.

</details>


## Output arguments
<details>
    <summary><b>`dataout` - dataset with the projected model added</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

The projected model is added to `dataout.models`, at the index matching its number of components. If a model with that many components already existed in `dataout.models`, it is overwritten.

</details>