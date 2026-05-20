<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewmodels
Visualize, evaluate the performance, and compare different aspects of the PARAFAC or PCA models.





## Syntax
	viewmodels(data,Name,Value)




## Description ##

The function `vieweems` opens up a graphical user interface (GUI) that is designed for diagnosing and analyzing PARAFAC or PCA models built in using `fitparafac` or `fitpca` function. This app provides multiple tabs to evaluate the performance, see validation status, and visualize different aspects of models.<br>
Note: The app does not accept any output arguments!

<details>
	<summary><b>Elements in case of PARAFAC model</b></summary>

<details open>
    <summary><b>Overview</b></summary>
    
This tab provides a summary of the PARAFAC models including:

 - Number of components
 - Model status
 - Percentage of explained variance
 - Sum of Squared Errors (SSE)
 - Core consistency
 - Percentage of unconverged components
 - Initialization method
 - Number of starts
 - Convergence criteria
 - Constraints
 - Toolbox used

The bottom section of this tab includes:

 - A plot for Core Consistency vs. Number of components
 - A plot for Explained Variance vs. Number of components

</details>

<details open>
    <summary><b>Scores & Loadings</b></summary>

 This tab provides scores and loadings visualizations for each model:

 - Scores plots for each model
 - Loadings plots for each model (Emission and Excitation spectra)

</details>

<details open>
    <summary><b>Spectral Loadings</b></summary>

This tab provides spectral loadings plots for each component in each model separately:
Note: each row of plots correspond to one model.

</details>


<details open>
    <summary><b>Loadings & Leverages</b></summary>

This tab provides plots of scores for samples, excitation and emission loadings for each wavelength and leverages in each mode (samples, excitation, emission) to visualize the influence of each data point on the model. You can go through different models by using the drop-down menu button on top of the plots.
 
 </details>

<details open>
    <summary><b>Errors & Leverages</b></summary>

To visualize the sum of squared error against leverages in each mode (samples, excitation, emission). You can go through different models by using the drop-down menu button on top of the plots.
 
</details>

<details open>
    <summary><b>Fingerprint Plots</b></summary>

Use this tab to plot Excitation Emission Matrix (EEM) of each component in each model. Go through different models by using the drop-down menu button on top of the plots.

</details>

<details open>
    <summary><b>SSE</b></summary>

To visualize the sum of squared error for each mode (samples, excitation, emission). This can be helpful to identify which samples or wavelength impose the biggest errors on the model.
You can go through different models by using the drop-down menu button on top of the plots.

</details>


<details open>
    <summary><b>Score Correlation</b></summary>

This tab plots a heatmap of correlations between different components in each model. This provides insights into the relationships between different components.
Left-clicking on the `view correlations vs. metadata` button opens a new app, in which score correlation plots are generated as scatter plots and datapoints are color-labeled based on the information in metadata columns.

</details>

</details>

<details>
	<summary><b>Elements in case of PCA model</b></summary>

The app visualizing PCA models consists mainly of three tabs:

1. Scores
2. Loadings
3. Score-Score plots

The score tab shows the scores for every PC across the dataset in a seperate plot
The Loadings tab show the re-folded loadings of every PC in the EEM projection.
The Score-Score tab allows users to plot scores of PC's against one another and color the scatter markers by metadata. When a scatter marker is clicked on, the EEM will be shown on the right.

</details>

## Input arguments ##
<details>
    <summary><b>`data` - dataset containing PARAFAC models</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.

</details>


## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>


<details open>
    <summary><b>`figurefile `- option to save grapical `plot` output </b></summary>
    <i>character</i>

If a character vector is supplied (e.g. "output.png", the function will save the output produced when plot is set to "true". If plot=false, no output will be saved even if a character vector is supplied.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewmodels`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewmodels.png". Likewise, providing "projectX.jpg" will result in "projectX-viewmodels.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving.

</details>


<details open>
    <summary><b>`startTab `- specify opening tab (only PARAFAC). </b></summary>
    <i>character</i>


If desired, the default "Overview" can be replaced by one of the following:


- "Scores & loadings"
- "Spectral loadings"
- "Loadings & leverages"
- "Errors & leverages"
- "Fingerprint plots"
- "SSE"
- "Score correlation"

This results in a switch of tab focus after the GUI starts up. Can be particularly useful in conjunction with saving figure outputs automatically.

</details>


<details open>
    <summary><b>`f `- which model to show at startup (only PARAFAC) </b></summary>
    <i>numeric</i>

To start showing a particular model with f-components, the option can be supplied. Can be particularly useful in conjunction with saving figure outputs automatically.


</details>

