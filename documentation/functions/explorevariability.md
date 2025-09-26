<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# explorevariability #
Run a Principal Component Analysis (PCA) on Excitation Emission Matrices (EEMs) to visualize and explore the variability of data.



## Syntax
### [explorevariability(data)](#syntax1) ###




## Description ##
### explorevariability([data](#varargin)) <a name="syntax1"></a>

Opens up the `explorevariability`'s user interface app. The app provides a quick and unsupervised way to explore the variance in fluorescence data via PCA. The app automatically detects if scatter treatment has been done. If it detects no scatter removal has been done, the scatters removal with conservative setting will be applied prior to modeling. <br> Note: The app does not accept any output arguments!<br>

Interface components include:<br>

<strong>`Settings` panel:<br></strong> 

- `Exclude samples with low fluorescence `: Check this box to exclude samples with low fluorescence, as noisy data can deter PCA performance. This will reinitialize the `explorevariability` app. <br> If no exceptionally low-intensity sample is found, the option will automatically be disabled and a message will be displayed in the prompt box.
- `Interpolate missing`: Check this box to interpolate missing data. This will not include the previously deleted scatter areas.<br> If checked, will reinitialize the `explorevariability` app.<br> If no missing data is found, the option will automatically be disabled and a message will be displayed in the prompt box.
- `PCA model of`: Choose the data for PCA modeling (e.g., raw data, residual EEMs). If PARAFAC models are calculated, the app can calculate PCA models on the residual EEMs. <br> If no PARAFAC model is found, the option will automatically be disabled and a message will be displayed in the prompt box.
- `PARAFAC model residuals`: If several PARAFAC models have been calculated, specify which models residual to use for PCA analysis.
- `Show leverages`: Display leverages in the overview tab. <br> Nore: if enabled, the plots can be cluttered.
- `Export PCA model`: Export the PCA model results to Matlab workspace in a variable called `pca_data`. The exported variable is a structure with `loads`, `scores`, `explained`, `lev`, and `Xloads` fields.`loads` contains the row-vector representation of the EEMs and components, `score` contain the scores of components for each sample, `explained` contains the explained variability by each component, `lev` contains the leverage values of each sample, and `Xload` contains the 3-way representation of loading for components.

<strong>Broad PCA Model Overview panel:<br></strong>

- This section shows the variance explained by each of the PCA components  on right y-axis and the cumulative explained variance on left y-axis.


<strong>Model Overview tab:</strong> The Scores and Loadings section contains:<br>

- Score Plots: Displays the scores for each component and sample.
- EEM Plots: Displays the loadings for each component. Component-explained variance and the cumulative variance explained by the component is shown is the title of each plot.


<strong>Score details tab:<br></strong>

- `Score Overview section`: Allows you to explore PCA component scores as a function of provided metadata:
	- `x-axis` Select which principal components to display on x-axis.
	- `y-axis`: Select which principal components to display on y-axis.
	- `Color-by`: Choose a `metadata` variable to color the scores.
	- `Select a Sampl`e: Allows you to plot and view EEM of a sample. By left-clicking on the button a crosshair will appear, hover over the `score overview` plot and left-click on the data point (sample) you want to see the EEM for. In the `Selected EEM` section, toggle between `Data` or `Residuals` of the selected sample.
	- `Class Boundary`: Draws class boundaries.
	- `randomize order`: Click to randomly reorder the Score plot which can be useful if different categories are superimposed.
	- `Alpha`: Adjusts transparency of the data points in the score plot.


<strong>help/methodology tab:<br></strong>

This section provides a detailed explanation of the PCA methodology and how to interpret the results, see methodology section.


## Input arguments ##
#### data - drEEMdataset containing samples or models  <a name="varargin"></a> <br> Type: drEEMdataset class object
Dataset of the class `drEEMdataset`, with standardized contents and automated validation methods.


## Methodology ##
Randomness of model residuals is generally thought to be very important for good PARAFAC models. This can be a challenge in large datasets. This tool allows you to see trends in model residuals and inspect whether residuals group with certain sample sets. If all PCs (principal components) are noisy and spectral features are hard to identify, the corresponding PARAFAC model most likely did not feature systematic residuals. If on the other hand, most PCs show spectral features and much of the variance in the residuals is explained by few PCs, the model most certainly left behind lots of information and oversimplified / misrepresented the complexity of the dataset at hand.


A general overview of principal component analysis can be found here (Rasmus Bro & Age Smilde, "Principal Component Analysis", Anal. Methods, 2014,6, 2812-2831):  https://doi.org/10.1039/C3AY41907J. <br>

The methodology used in the `explorevariability` app consists of:

**Preprocessing:**

- Scatters are cut with relatively broad settings, if not previously treated.
- Areas of EEMs that are always missing are excluded from the analysis, as these don't benefit the modeling.
- EEMs with missing data (other than scatter) are excluded from the analysis, unless the `interpolate missing` option is enabled.
- EEMs are mean-centered and scaled.
- EEMs with low intensities compared to the average are excluded, unless otherwise chosen in the `Exclude samples with low fluorescence` checkbox.
- EEM Unfolding: Each EEM is reduced to a row-vector.

**Modeling PCA:**

- PCA Model Calculation: A PCA model with `7` components is calculated. If the number of included samples is lower than `7`, the number of components will be reduced.
- Loadings Transformation: Loadings are transformed back into EEMs for visual inspection.
- Model Leverages: Calculated but not plotted by default.


**Interpretation of PCA Models (Raw Data):**

- PCA models allow you to explore the variability of your fluorescence dataset from a spectral point-of-view. This can serve to show trends in relation to other parameters, such as carbon concentration or water column depth. It is important to remember that scores and loadings can be positive and negative, so the interpretation of PCA models requires a slightly different approach compared to non-negative PARAFAC models.

- If this tool is used prior to PARAFAC, it can be useful to observe how much of the EEMs is explained with the first `7` PCs to indicate how well a dataset might be modeled with PARAFAC or how many components might be appropriate. However, there are no general rules regarding this interpretation.
- You can use this tool as a quick way to tell apparent different groups of samples. If the relevant metadata is provided, the score plot will allow you to visually inspect whether groups distinguish themselves via their scores.

- Besides general trends, the PCA models can serve as an indicator of quality issues. Problems can manifest in e.g. 1) Strongly positive or negative loadings along the scatter diagonals: Scatter leftovers in all or some samples (inspect scores and EEMs of samples with high scores in the tab `score details`)
2) Samples with unusually high or low scores in one or several PCs: Unusual features such as noise or unusual fluorescence composition. Inspect the loadings, as well as EEMs with suspicious scores in the tab "score details".





## See Also ##

<a href="link.com">vieweems</a> | 
<a href="link.com"> Link2 </a> |
<a href="link.com"> Link3 </a> |


## Topics ##