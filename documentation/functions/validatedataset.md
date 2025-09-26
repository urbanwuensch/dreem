<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# validatedataset
Check for the correct dimensions and consistency of various fields within a `drEEMdataset` object, ensuring that the data meets the expected structure required for subsequent analysis.



## Syntax
[`validatedataset(dataset)`](#syntax1) 


## Description ##
	
The validatedataset function performs several validation checks on the dataset object. These checks include:

- Class verification: The dataset must be of the class `drEEMdataset`. This means that its contents is prescribed and cannot be changed.
- Dimension Checks: Verifies that the `X` field has three dimensions and checks its consistency with other related fields (`nSample`, `filelist`, `metadata`, `i`, `Em`, `nEm`, `Ex`, `nEx`, `models`). 
- `abs` property is a 2-dimensional matrix and checks its consistency with relevant fields.
- NaN and Complex Number Checks: Identifies fields containing only `NaN` values or complex numbers.


**Error Reporting**

The function generally collects and then reports errors if any inconsistencies are found in the dataset. However, if issues are found that prevent the validation itself from executing correctly, the function will throw an error prematurely.

If no errors were found and the function was called from the `drEEMtoolbox`, a success message is displayed.



## Input arguments ##
<details>
    <summary><b>`dataout` - a drEEMdataset</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that will be evaluated with the validation function.


</details>