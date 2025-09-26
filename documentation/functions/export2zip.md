<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# export2zip
Export a PARAFAC model to a spreadheet file. This includes a comprehensive description of the dataset.

## Syntax

	exportresults(data,filename)

## Description

The function exports a dataset in its entirety in accordance to FAIR principles to a compressed archive that is ready to be uploaded to data repositories without modification.

The export includes:

* Sample fluorescence EEMs
* Blank fluorescence EEMs (if `subtractblanks` was used)
* Absorbance spectra (if they exist in `data`)
* Scatter treatment settings
* The dataset history
* The dataset status entries
* A detailed README.txt to explain the contents of the archive

The dataset is exported in interoperable csv files, but a .mat file is added for convenience of Matlab users. Note that, while a drEEMdataset can only be used while the drEEM toolbox is installed (i.e. the class definition is known), the exported .mat file is converted to a conventional structure and can this be read independed of the Matlab configuration.


## Input arguments
<details>
    <summary><b>`data` - dataset to export</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 
</details>

<details open>
    <summary><b>`filename` - name of compressed archive</b></summary>
    <i>char | string</i>
        
The name of the output file. It should be a text and will be saved with a `.zip` extension.
Note: Any extension at the end of the `filename` will be changed to `.zip`. If none is provided, it will be added.

</details>
