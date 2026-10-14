<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewopenfluormatches
Plot match results from OpenFluor.

## Syntax


```
[summary,M]=viewopenfluormatches(filename,Name,Value)
```


## Description

This function lets the user plot OpenFluor database matching results in MATLAB for further inspection, export of graphical output and more.

After importing a model for visual comparison with the entries in OpenFluor ([https://openfluor.lablicate.com/](https://openfluor.lablicate.com/)), the user can choose to export the Matching results:

<img src="openfluor_matching.png" width="auto" height="auto" />

When calling the downloaded file ("OpenFluorSearch_ModelName_YYYYMMDD.csv") with [viewopenfluormatches](viewopenfluormatches.html), the results will be replotted in MATLAB. Note that the datacursor is active and hovering over the loadings plots will reveal additional information about the model that the selected component belongs to:


<img src="openfluor_match_plotting.png" width="auto" height="auto" />


**Note**: When hovering over any of the components, the datacursor will display additional information & the respective model's DOI is automatically copied to the clipboard. Simply paste into a browser (Windows: `Ctrl+v` and you will arrive at the landing page for most of the models in the database).

## Input arguments

<details>
<summary><b>`filename ` - filename of the OpenFluor results</b></summary>
<i>text</i>
        
Input must point at a file, e.g. `'OpenFluorSearch_ModelName_YYYMMDD.csv'`

</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `filename` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
<summary><b>`figurefile `- option to save grapical `plot` output </b></summary>
<i>character</i>

If a character vector is supplied (e.g. "output.png"), the function will save the output produced when plot is set to "true". If plot=false, no output will be saved even if a character vector is supplied.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewopenfluormatches`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewopenfluormatches.png". Likewise, providing "projectX.jpg" will result in "projectX-viewopenfluormatches.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving.

</details>



## Output arguments
<details>
<summary><b>`summary ` - overview table</b></summary>
<i>table</i>
        
A table containing a list of all match statistics. Model database name and ID, component number, and TCC statistics.

</details>



<details>
<summary><b>`M ` - results as structure</b></summary>
<i>struct</i>

A dataset structure containing all loadings of the matched models that were plotted.

</details>