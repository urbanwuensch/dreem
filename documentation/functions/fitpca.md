<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# fitpca
Fit PCA models to fluorescence data.

## Syntax

[`dataout = fitpca(data)`](#syntax1)

[`dataout = fitpca(___ , Name,Value)`](#syntax2)


## Description

The `fitpca ` function uses a principal component analysis to the fluorescence EEMs provided in `data`. The models are saved in `data.models`. 

Principal Component Analysis (PCA) is a two-way model and thus requires unfolding of the EEMs (from 3 to 2 dimensions). The EEM is thus transformed to a matrix with the dimensions `[data.nSample,data.nEm*data.nEx]`. 

PCA is an efficient and fast tool to highlight differences from an average composition. To suit this purpose, EEMs are mean-centered prior to the analysis. This is done internally, so the origial data is not affected. Note however that calculating model residuals would require pre-processing the data by mean-centering.

Results can be inspected with the `viewmodels` GUI.

>Read more here: Persson, T.; Wedborg, M. Multivariate [Evaluation of the Fluorescence of Aquatic Organic Matter](https://doi.org/10.1016/S0003-2670(01)00812-1). Analytica Chimica Acta 2001, 434 (2), 179–192. [https://doi.org/10.1016/S0003-2670(01)00812-1](https://doi.org/10.1016/S0003-2670(01)00812-1).



PCA in the way fitted here cannot handle missing data. We therefore:

1. delete all data that is missing in all samples (scatter diagonals)
2. delete any samples that have missing data remaining (i.e. those that have been zapped with e.g. `zapnoise` or handled with `rmspikes`. However, the function offers an interpolation option (enabled by default) which would prevent sample deletion in this case. This might however introduce interpolation artefacts.

Note that since PCA models are nested, there is only one model present with `maxcomp` components (default = 5).

An entry will be added to the `history` field of the `data`, detailing the  options used for `fitpca`. 
<details open>
    <summary><b>`dataout = fitpca(data)` - Default options</b></summary>
    <a name="syntax1"></a>


Here, the default options are chosen. These are to only consider the first 5 components, interpolate missing values (unless they are always missing), and to not delete samples with low intensities (e.g. process blanks).

</details>


<details open>
    <summary><b>`dataout = fitpca( ___ , Name,Value)` - [Name,Value](#NameValue) arguments</b></summary>
    <a name="syntax2"></a>

The default options might not be the right options in your case. You can therefore specifiy Name,Value arguments to modify how data are preprocessed or how many components you'd like to get returned.

</details>


## Examples

`samples=tbx.fitpca(samples,maxcomp=8,deleteLow=true);`

Fit an 8-component PCA model after deleting samples that have less than 1/5 of the median sum of fluorescence in their EEM.
   

## Input arguments
<details>
    <summary><b>`data`- contains EEMs to fit models to</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 
</details>


## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`maxcomp`- the number of components</b></summary>
    <i>numeric</i>

Numeric scalar specifying the maximum number of components to export. Default is 5.

Note that since PCA models are nested, there is only one model present with `maxcomp` components (default = 5).

</details>


<details open>
    <summary><b>`interpolateMissing` - should missing data be interpolated?</b></summary>
    <i>logical</i>

Note that this setting only applies to observations missing in individual samples. Data that is missing in all samples will always be deleted.
The interpolation happens with a 2D inpainting algorithm.

</details>

<details open>
    <summary><b>`deleteLow` - should low-intensity samples be deleted?</b></summary>
    <i> logical </i>

If present, low-intensity samples can distract PCA from fitting meaningful components. This option will delete samples that have less than 1/5th the median overall fluorescence (sum).

</details>





## Output arguments
<details>
    <summary><b>`dataout` - dataset with PCA model</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

Note that since PCA models are nested, there is only one model present with `maxcomp` components (default = 5).

Models are stored in dataout.models. Each model is a `drEEMmodel` object contains the following information (no contents in this case):

	  drEEMmodel with properties:

                    loads: {1×0 cell}
                leverages: {1×0 cell}
                      sse: {1×0 cell}
                   status: ""
         percentExplained: NaN
                    error: NaN
                     core: NaN
       percentUnconverged: NaN
    componentContribution: NaN
           initialization: ""
                   starts: NaN
              convergence: NaN
              constraints: ""
                  toolbox: ""
                modelName: "PCA"
           loadingsMatrix: []





</details>