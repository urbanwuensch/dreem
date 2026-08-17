<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewabsorbance
Visualize and analyze CDOM absorbance data.



## Syntax

	viewabsorbance(data,Name,Value)




## Description

<img src="viewabsorbance_example.png" width="auto" height="auto" align="center"/>

Opens up the `viewabsorbance` user interface app. The app allows users to visualize absorbance spectra, switch between displayed absorbance units, and color spectra according to metadata in `data.metadata`.

Spectra can be plotted all at once or on a single sample basis. If a single sample is selected, the spectral area of the different CDOM slopes can be highlighted.


The app automatically calculates CDOM slopes during startup and these can be explored when selecting a different tab for visualization. The tab "slopes" shows Box-Whisker plots for each slope.



<img src="viewabsorbance_Sexample.png" width="auto" height="auto" align="center"/>

The "OTHER" tab (above) displays the CDOM source diagram according to [Stedmon et al (2000)](https://doi.org/10.1006/ecss.2000.0645). Two dilution lines for allochthonous and autochthonous material are provided with default values according to the publication and samples are inserted according to their exponential CDOM slope and Naperian absorption coefficient at 375nm. This visualization can be used to assign a dominant putative source for CDOM.

## Input arguments ##
<details>
    <summary><b>`data` - dataset containing  absorbance data</b></summary>
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

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewabsorbance`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewabsorbance.png". Likewise, providing "projectX.jpg" will result in "projectX-viewabsorbance.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving.

</details>