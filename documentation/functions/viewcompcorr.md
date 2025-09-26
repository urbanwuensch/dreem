<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewcompcorr #
Investigate the correlations between scores of different components in parafac models.


## Syntax

	viewcompcorr(data)

## Description

The function `viewcompcorr` opens a new app, in which score correlation plots are generated as scatter plots and datapoints are color-labeled base on the information stored in metadata columns.
This app can also be opened from the `view correlations vs. metadata` button in the `Score Correlation` tab of the `viewmodels` app.

>

## Input arguments ##
<details>
    <summary><b>`data`- dataset with PARAFAC model</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 
</details>