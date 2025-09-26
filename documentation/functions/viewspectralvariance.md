<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewspectralvariance
Visualize and analyze the spectral variability in fluorescence and absorbance data.



## Syntax
	viewspectralvariance(data)




## Description

The `viewspectralvariance` function plots the spectral variability of absorbance and fluorescence data. The function scales all data to unit variance in the sample mode, giving each sample equal weighting.



The function identifies samples with very low signals and will generate a warning regarding the impact of those samples.




## Input arguments

<details>
    <summary><b>`data` - dataset with fluorescence and absorbance data.</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 


</details>
