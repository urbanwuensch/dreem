<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# handlescatter
Excise and treat Excitation-Emission Matrix (EEM) scatter and optionally interpolate between missing values.



## Syntax
[`dataout = handlescatter(data)`](#syntax1)

[`dataout = handlescatter(data, 'gui')`](#syntax2)

[`dataout = handlescatter(data, options`)](#syntax3)

[`scatteroptions = handlescatter('options')`](#syntax4)

## Description ##
The function `handlescatter` handles primary and secondary Rayleigh and Raman scatter, by either replacing the values around the scatter with NaNs or interpolation. Additionally, it can set values to `zero` at a specified distance below the 1st order Rayleigh scatter line (where Emission wavelength equals Excitation wavelength). The function also offers optional plotting to compare the raw, cut and final EEMs for quality check. When no `options` is provided as input, the function will use the default `options` for its processing. That include cutting out all the four scatters from all samples and no interpolation. See Input arguments section for `options` default values.

>**Important:** The status-property "scatterTreatment" must be "not applied". Otherwise, the function returns a validation error. Upon completion, the status of the dataset is changed to "applied by toolbox".

The function uses a defined class `handlescatterOptions` for all settings. A copy of the default options can be made as follows:

	>> handlescatterOptions

	ans = handlescatterOptions with properties:

            cutout: [1 1 1 1]
       interpolate: [0 0 0 0]
    negativetozero: 1
              ray1: [10 10]
              ram1: [15 15]
              ray2: [5 5]
              ram2: [5 5]
            d2zero: 60
           imethod: "inpaint"
              iopt: "normal"
              plot: 1
          plottype: "mesh"
           samples: 'all'
       description: 'Options for handlescatter.m'

> ***NOTE: The default options contain settings and choices that would likely cause issues when PARAFACing. This is to ensure that users make concious choices for scatter removal as leftover scatter violates the trilinearity assumptions of PARAFAC.***

<details open>
<summary><b>`handlescatterOptions` explained in detail</b>
</summary>

- <strong>cutout:</strong> Specify which scatter to cut from the data in the following order: [Ray1 Ram1 Ray2 Ram2]. To cut choose `1` and to leave out choose `0`. Default values are `[1 1 1 1]` 
<br>
<br>
- <strong>interpolate:</strong> Specifies whether to interpolate over the cut scatter regions. `1` indicates interpolation, `0` indicates no interpolation over the specified scatter in the following order for scatters:[Ray1 Ram1 Ray2 Ram2]. Default values are `[0 1 1 1]`
<br>
<br>
- <strong>ray1:</strong> Specifies the range around the 1st Rayleigh scatter peak to cut (and interpolate, if chosen). Format: [below, above] in nanometers (nm) from the center of the scatter peak. Default is `[10 10]`.
<br>
<br>
- <strong>ram1:</strong> Specifies the range around the 1st Raman scatter peak to cut (and interpolate, if chosen). Format: [below, above] in nanometers (nm) from the center of the scatter peak. Default is `[15 15]`.
<br>
<br>
- <strong>ray2:</strong> Specifies the range around the 2nd Rayleigh scatter peak to cut (and interpolate, if chosen). Format: [below, above] in nanometers (nm) from the center of the scatter peak. Default is `[5 5]`.
<br>
<br>
- <strong>ram2:</strong> Specifies the range around the 2nd Raman scatter peak to cut (and interpolate, if chosen). Format: [below, above] in nanometers (nm) from the center of the scatter peak. Default is `[5 5]`.
<br>
<br>
- <strong>d2zero:</strong> Specifies the distance in nm below Ray1 below which the emission values are forced to `zero`. Default value is `60` nm.
<br>
<br>
- <strong>iopt:<br></strong> Specifies the method for handling overlapping `NaN` regions during interpolation. `'normal'` means standard interpolation, `'conservative'` means leaving `NaN`s uninterpolated. Default is `'normal'`.
<br>
<br>
- <strong>imethod:</strong> Specifies the interpolation method to use for filling cut scatters.`'inpaint'` uses an inpainting algorithm, `'fillmissing'` uses MATLAB's fillmissing function. '`inpaint'` applies del^2 over the entire array, then drops those parts of the array which do not have any contact with NaNs. '`inpaint'` uses a least squares approach, but it does not modify known values. In the case of small arrays, this method is quite fast as it does very little extra work. Extrapolation behavior is linear. See inpaint: Copyright (c) 2017, Damien Garcia. `fillmissing` options fills missing values using Shape-preserving piecewise cubic spline interpolation. For any missing values at the ends of the array, it uses the nearest non-missing value. This ensures that data is completed with a smooth and shape-preserving interpolation method, while boundary gaps are filled with adjacent values. Default method used in `handlescatter` is `inpaint`.
<br>
<br>
- <strong>negativetozero:</strong> Specifies whether to convert all negative values in the data to `zero`. It is useful for ensuring non-negative data values. Default is `'on'`.
<br>
<br>
- <strong>plot:</strong> Specifies whether to plot the raw, cut, and final Excitation-Emission Matrices (EEMs). `'on'` enables plotting, `'off'` disables it. NOTE: Plots will always be shown for all samples, but simply closing the window will terminate plotting and return the smoothed data.
<br>
<br>
- <strong>samples:</strong> Specifies which samples to process. `'all'` means process all samples. A numeric vector specifies which samples to process, for example `[2 3 4 5]`, will only apply the function on samples `2` to `5`. Default is `'all'`..
<br>
<br>
- <strong>plottype:</strong> Specifies the type of plot to display when plotting is enabled. Options are `'mesh'`, `'surface'`, or `'contourf'`. Default is `mesh`.

</details>

<details open>
    <summary><b>`dataout = handlescatter(data)` - default options (for quick visualization)</b></summary>
    <a name="syntax1"></a>
<a name="syntax1"></a>

This syntax will automatically apply some default settings for scatter removal. This can be useful to take a quick look at EEMs without scatter having a dominant visual effect in the graphs. However, the settings *will not work well for PARAFAC*.

</details>


<details open>
    <summary><b>`dataout = handlescatter(data, 'gui')` - GUI decision support</b></summary>
    <a name="syntax1"></a>
<a name="syntax2"></a>

Running `handlescatter` with `gui` options opens up the `viewscatter` user interface app. The interface allows users to apply settings for treating 1st and 2nd order Rayleigh and Raman scatter and visualize the results in real-time.
Interface Components include:





<strong>Control Panel:<br></strong>

- `Test On`: Select the sample to view the plots for. Use the arrow buttons to navigate through different samples in `data`.
- `Apply`: Apply the current scatter treatment settings to the whole `data`.
- `Save Settings`: Save the settings used for `handlescatter` in a variable called `scatteroptions` in the workspace.
- `Apply & Close`: Apply the current settings and close the interface.
- `Plot`: Toggle between `raw` and `treated` data visualization.

<strong>Scatter Treatment Settings:<br></strong>

- `Cut`: Enable or disable the cut option for the chosen scatter.
- `Int.`: Enable or disable the interpolation option for the chosen scatter.
- `Below`: Set the nm distance below the center of the chosen scatter for  scatter cut. Adjusting this value will automatically be reflected on the plots with red bars around the center of the scatter.
- `Above`: Set the nm distance above the center of the chosen scatter for scatter cut. Adjusting this value will automatically be reflected on the plots with red bars around the center of the scatter.


<strong>Miscellaneous Settings:<br></strong>

- `Set Negative Fluorescence Values to Zero`: Enable this option to set all negative fluorescence values to zero.
- `nm Distance to Zero`: Specify the nm distance from the center of the 1st order Rayleigh scatter below which all values will be set to zero.
- `Interpolation method`: Toggle between `vector` and `inpaint` interpolation for the scatter treatment.

<strong>Visualization:<br></strong>


- `Scatter-Centered Spectra`: this tab displays the scatter-centered spectra for 1st and 2nd order Rayleigh and Raman scatter. Red bars indicate the chosen settings using `below` and `above` in the `scatter treatment settings` panel.
- `Excitation-Emission Matrix`: This tab visualizes the `raw` or `treated` excitation-emission matrix after applying the scatter removal settings.

</details>

<details open>
    <summary><b>`dataout= handlescatter(data, options)` - apply scatter treatment with options structure from workspace</b></summary>
    <a name="syntax3"></a>

`handlescatter` can obtain and process the scatter handling using user customized `options` supplied as a single structure. Default values are obtained by calling `scatteroptions = handlescatter('options')`. the fields in `options` can be modified and passed out to the function. See Input arguments section for the fields of `options`.

</details>

<details open>
    <summary><b>`scatteroptions = handlescatter('options')` - Retreive option structure for modification</b></summary>
    <a name="syntax4"></a>

Obtains the default `options` of the function and save them in `scatteroptions `. These can be modified and later passed down to function by calling `data = handlescatter(data, scatteroptions)`.

</details>

## Examples

Retreive and modify options to apply them:


	scatteroptions = handlescatter('options');
	scatteroptions.ray1 = [25 15];
	scatteroptions.ram1 = [10 12];
	scatteroptions.interpolate = [0 0 0 1];
	dataout = handlescatter(data, scatteroptions);
	
 In this example, we obtain the default options to change the lower and upper distance from the center for 1st order Rayleigh scatter,  to change the lower and upper distance from the center for 1st order Raman scatter cut, and
 to turn off interpolation for all scatters except the 2nd order Raman scatter.  Finally, we apply the settings.

## Input arguments

<details>
    <summary><b>`data` - dataset with scatter for removal</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 

> The property `data.status.scatterTreatment` must be `"not applied"`. Otherwise, the function returns a validation error.

</details>

<details open>
<summary><b>`options` - function mode switch (apply or retreive options or start GUI)</b></summary>
    <i>char | handlescatterOptions</i>
    </summary>

This variable serves multiple purposes and is thus best described as a mode switch.

If **text ("gui")** is supplied, the app starts a GUI to allow you to define scatter treatment settings interactively.

If **text ("options")** is supplied, the app returns the default options to the workspace

If a **structure of the type handlescatterOptions** is supplied, the app applies these settings and returns a treated dataset.


</details>


## Output arguments
<details>
    <summary><b>`dataout` - contains EEMs of samples, hopefully without scatter</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.


The status of the dataset is changed to reflect the fact that the scatter excision has been performed by the drEEM toolbox

</details>