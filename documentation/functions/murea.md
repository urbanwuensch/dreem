<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# murea
Diagnose PARAFAC model performance sample-by-sample, by running a chemometric (PCA) analysis of the model's residuals



## Syntax
	murea(data)



## Description

Global model metrics - percent variance explained, core consistency, split-half validation - can look excellent while individual samples are still poorly represented by the model. This is especially easy to miss when a component barely fluoresces: trends in its `Fmax` values can then be driven more by modelling error than by real chemical differences between samples. With hundreds of samples, flipping through every individual residual EEM to catch this is not practical.

`murea` opens the **MuReA** ("Multivariate Analysis of Model Residuals") app, which addresses this by treating the residuals of a chosen PARAFAC model the same way PARAFAC itself treats raw EEMs: with a chemometric decomposition, in this case Principal Component Analysis (PCA). For the selected PARAFAC model, the app:

1. calculates the model residuals (`E = X - X̂`) for every sample,
2. unfolds the residual EEMs into a `nSample`-by-`nEm*nEx` matrix,
3. removes wavelength pairs that are always missing and interpolates any other gaps (e.g. scatter that was cut), and
4. fits a PCA model to the unfolded residuals.

If the PCA model explains a large share of the residual variance, and does so systematically rather than randomly, that points to structure PARAFAC left behind: a bias between sample groups, a component that needed refining, or scatter/instrument issues that weren't fully treated. If the PCA mostly picks up noise, that's reassuring evidence that the PARAFAC residuals are close to random, as they should be.

>***The dataset must already contain at least one PARAFAC model (fitted with `fitparafac`). Otherwise the function returns an error.***

Note: The app does not accept any output arguments!

<details open>
    <summary><b>Settings panel</b></summary>

- `# PARAFAC components`: choose which of the dataset's PARAFAC models (by number of components) to analyze the residuals of. Every other panel in the app updates to reflect this choice.
- `Plot focus`: on the `Scores & loadings` tab, choose whether to display `Scores & loadings` together, or `Scores only`.
- `Exclude low FDOM`: exclude samples with very low fluorescence signal from the PCA, analogous to the `deleteLow` option in `fitpca`.
- `Colormap EEM`: colormap used for the loading and residual EEM plots (e.g. `turbo`).

</details>

<details open>
    <summary><b>Overview graph</b></summary>

Shown when the app opens. Two linked plots, side by side:

- `Explained data (PARAFAC)`: cumulative variance explained by each of the dataset's PARAFAC models, plotted against their number of components.
- `Explained by PCA (residuals)`: for the PARAFAC model currently selected in the Settings panel, the variance explained by each individual PCA component (left axis) and the cumulative variance explained (right axis), plotted against the number of PCA components.

Lower is generally better here, but it's not unusual for PCA to explain a non-trivial share of the residuals; based on experience applying this tool to several datasets, less than 50% cumulative explained variance for the first two PCA components is a reasonable, if informal, benchmark.

</details>

<details open>
    <summary><b>Scores & loadings</b></summary>

- `Scores`: one line plot per retained PCA component, showing that component's score for every sample. Ideally these look like noise scattered around zero, indicating no systematic sample trend. Deviations from zero mark samples worth a closer look.
- `Loadings`: the loadings of each PCA component, reshaped back into an EEM-like contour plot and labeled with the percentage of residual variance that component explains. Unlike PARAFAC loadings, these can be negative as well as positive, since PCA is decomposing variance from an average rather than a non-negative signal; a systematic spectral shape here (rather than a random-looking pattern) indicates a real bias that PARAFAC left behind.

</details>

<details open>
    <summary><b>Score plots</b></summary>

- `Score overview`: a scatter plot of PCA scores, with `x-axis` and `y-axis` drop-downs to choose which two PCA components to plot against each other, and `color-by` to color points by a column from `data.metadata`. `randomize order` randomizes the plotting order, which helps when many overlapping categories are stacked on top of each other, and `alpha` controls marker transparency. `class boundary` draws a boundary between the colored categories.
- `Selected EEM`: clicking a point in the score overview plot shows that sample's EEM here. A `Data`/`Residuals` switch toggles between the sample's original EEM and its residual for the currently selected PARAFAC model, making it possible to directly connect a suspicious score to what it looks like in the data.

</details>


## Input arguments
<details>
    <summary><b>`data` - dataset containing one or more PARAFAC models</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`, and that contains at least one PARAFAC model fitted with `fitparafac`.

</details>