<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# upgradedataset
Upgrade a given dataset to a newer format compatible with the new version of drEEM toolbox (2.0.0).



## Syntax

[`dataout = upgradedataset (data)`](#syntax1)

[`dataout = upgradedataset (data, atypicalFieldnames)`](#syntax2)




## Description

This function converts datasets from the older, non-standard format that `drEEM` used prior to version 2.0.0 and creates a standardized `drEEMdataset`.


<details open>
<summary><b>
`dataout = upgradedataset (data)` - conversion of data as desribed in tutorials</b></summary>

 <a name="syntax1"></a>

The functions assumes that `data` is a typical drEEM data structure built by previous versions of the toolbox. Hence, it expects the fields  `'X', 'Ex', 'Em','nEm',` `'nEx', 'filelist', 'i', 'nSample', 'Abs_wave', 'Abs'` to be present in the `data`. 

Other fields in the `data` that have compatible size will be transferred to the `metadata` table of the drEEMdataset `dataout`. 

If models are present in `data` they will be transferred to the `models` field.
</details>

<details>
<summary>
**Details on the model ransfer**
</summary>

* Models loadings should be stored in the `Model1`, `Model2`, `Model3` and `ModelN` fields in the `data`.
* All other properties are calculated and not transferred.
* The property `Initialization` is set to `'random'` since previous versions of the toolbox did not officially support other methods
* `Starts` is set to `NaN`, there is no way to retreive the information
* `Convergence` is retrieved from `data`, if it exists, otherwise is set to `NaN`.
* `Constraints` is retrieved from `data`, if it exists, otherwise is set to `'unknown'`.
* `Toolbox` is set to `'nway'`. Though PLS_toolbox could have been used, this information was never stored by the older versions of the toolbox.

</details>


</details>


<details>
<summary><b>
`dataout = upgradedataset (data, atypicalFieldnames)` - conversion with atypical fieldnames
</b></summary>
<a name="syntax2"></a>

If some of the mandatory information in `data` is stored in fields that differ from the "standard" convention, use `atypicalFieldnames` to help the function identify those fields. 

For example, use `{'EEM','X'}` if the information that the function expects to find as `X` is stored in field `EEM` inside `data`.

</details>

## Input arguments
<details>
    <summary><b>`data` - structure made with a previous version of drEEM</b></summary>
    <i>structure</i>

Ideally, the supplied structure should pass the validation function `checkdataset` of the previous version of drEEM. Expected, mandatory fields for the conversion are:

* `X`
* `Ex`
* `Em`
* `nEm`
* `nEx`
* `filelist`
* `i`
* `nSample`
* `Abs_wave`
* `Abs`

If one of these fields does not exist, a warning will be displayed. If the resulting `drEEMdataset` does not pass the validation, this warning will result in an error.

</details>

## Optional input arguments

<details open>
    <summary><b>`atypicalFieldnames`- names of non-typical fields and their corresponding new field names</b></summary>
    <i>logical</i>

A cell array of size N x 2. Each row should contain a pair of field names where the first column is the old field name (should exist in `data`), and the second column is the new field name (should exist in drEEMdataset class object, see `drEEMdataset` for more information).

Example `{'EEM','X'}` if fluorescence data in `data` was stored in the field `EEM` and should therefore now be stored as `X`.

Default is `[]`, meaning the option remains unused.




</details>

## Output arguments
<details>
    <summary><b>`dataout` - upgraded dataset</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.

</details>





