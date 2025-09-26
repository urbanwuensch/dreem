<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# subdataset
Remove samples, emission spectra or excitation spectra from the dataset.



## Syntax

[`dataout = subdataset(data, Name,Value)`](#syntax1)


## Description

The function removes, i.e. truncates parts of a dataset. Use this to remove problematic samples, noisy excitation scans, or unneeded emission scans.

A particularly useful case is the removal of EEM regions that contain only NaN or zeros. These can disturb various processing functions and prove problematic for PARAFAC.


The `history` field of the `dataout` contains a summary of the results of the carried-out subsetting, including which sample, emission and excitation wavelengths were successfully removed. 

> **Note:** When `subdataset` is called:
> 
> * If the function `scalesamples` has been used prior to using the `subdataset`, the orginal unscaled data will also be cut.
> * any existing PARAFAC models are deleted since they no longer reflect the data.
> * the removal will automatically be carried out in any splits as well!

<details open>
<summary><b>`dataout = subdataset(data, Name,Value)` - remove parts of a dataset entirely</b>
</summary>

Contrary to previous version of `subdataset`, only two inputs are required and the ['name-value'](#NameValue)-pair notation is used to specify which parts of the dataset should be deleted.

You can specify any combination of `outSample`,`outEm`, or `outEx`. If one of these is not explicitly specified as input, it is automatically set to `false`, resulting in no action along that dimension of the dataset.

> ***Note:*** `subdataset` works _only_ with logical inputs. Do not provide indicies of wavelength or wavelengths directly. This will be caught during the input validation and results in an error message.

</details>




## Examples

1. Delete sample based on name
`samples = tbx.subdataset(samples,outSample=matches(samples.filelist,'LCEP23 (01)'));`

2. Delete sample based identifier
`samples = tbx.subdataset(samples,outSample=samples.i==2);`

3. Delete emission ranges
`samples = tbx.subdataset(samples,outEm=samples.Em<300|samples.Em>700);
`
4. Delete excitation ranges
`samples = tbx.subdataset(samples,outEx=samples.Ex<240|samples.Ex>450);`

5. Delete specific excitation
`samples = tbx.subdataset(samples,outEx=samples.Ex==275);`

6. drEEM ships with a <strong>nearest neighbor function</strong>: `isNearest`, use it if wavelengths have many decimals
`samples = tbx.subdataset(samples,outEm=tbx.isNearest(samples.Em,349));`


## Input arguments

<details>
    <summary><b>`data` - dataset to truncate</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 

</details>

## Optional arguments
<details open>
    <summary><b>`outSample ` - samples to delete</b></summary>
    <i>logical [`1x data.nSample`]</i>
        
Specifies which samples are to be deleted from the dataset. Must be logical. Is comparative statements and functions as input to the option.

Matlab-internal functions include: `matches`, `contains`, `==`, `~` 

</details>

<details open>
    <summary><b>`outEm ` - emission wavelengths to delete</b></summary>
    <i>logical [`1x data.nEm`]</i>
        
Specifies which emission wavelengths are to be deleted from the dataset. Must be logical. Is comparative statements and functions as input to the option.

Functions to use include: `==`, `~`, `<`, `>`, `drEEMtoolbox.isNearest(data.Em,___)`

</details>

<details open>
    <summary><b>`outEx ` - excitation to delete</b></summary>
    <i>logical [`1x data.nEx`]</i>
        
Specifies which excitation wavelengths are to be deleted from the dataset. Must be logical. Is comparative statements and functions as input to the option.

Functions to use include: `==`, `~`, `<`, `>`, `drEEMtoolbox.isNearest(data.Em,___)`

</details>



## Output arguments
<details>
    <summary><b>`dataout` - truncated dataset</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

</details>