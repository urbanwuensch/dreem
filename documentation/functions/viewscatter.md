<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewscatter
Excise and treat Excitation-Emission Matrix (EEM) scatter and optionally interpolate between missing values.



## Syntax
[`viewscatter(data)`](#syntax1)




## Description ##

Opens up the `viewscatter`'s user interface app. The interface allows users to investigate settings for treating 1st and 2nd order Rayleigh and Raman scatter and visualize the results in real-time.

> The app can also be opened using `handlescatter` function with `gui` option. For more information see `handlescatter`. In contrast to  `viewscatter` does not allow user to save the settings to the original `data`, but instead is used to explore different options and hence does not accept any output argument. To apply and save the setting use the `handlescatter` function.

**Interface Components include:**<br>

<details open><summary><b>Control Panel</b></summary>

- `Test On`: Select the sample to view the plots for. Use the arrow buttons to navigate through different samples in `data`.
- `Apply`: Apply the current scatter treatment settings to the whole `data`.<br> Note: this will not change the original data stored in `data`.
- `Save Settings`: Save the settings used for `handlescatter` in a variable called `scatteroptions` in the workspace.
- `Apply & Close`: This button will not work when the app has been opened up using `viewscatter`, as data is not intended to be saved. To enable the functionality of this function open the app from the `handlescatter` function.
- `Plot`: Toggle between `raw` and `treated` data visualization.
</details>

<details open><summary><b>Scatter Treatment Settings</b></summary>


- `Cut`: Enable or disable the cut option for the chosen scatter.
- `Int.`: Enable or disable the interpolation option for the chosen scatter.
- `Below`: Set the nm distance below the center of the chosen scatter for  scatter cut. Adjusting this value will automatically be reflected on the plots with red bars around the center of the scatter.
- `Above`: Set the nm distance above the center of the chosen scatter for scatter cut. Adjusting this value will automatically be reflected on the plots with red bars around the center of the scatter.

</details>

<details open><summary><b>Miscellaneous Settings</b></summary>

- `Set Negative Fluorescence Values to Zero`: Enable this option to set all negative fluorescence values to zero.
- `nm Distance to Zero`: Specify the nm distance from the center of the 1st order Rayleigh scatter below which all values will be set to zero.
- `Interpolation method`: Toggle between `vector` and `inpaint` interpolation for the scatter treatment.

</details>


<details open><summary><b>Visualization</b></summary>



- `Scatter-Centered Spectra`: this tab displays the scatter-centered spectra for 1st and 2nd order Rayleigh and Raman scatter. Red bars indicate the chosen settings using `below` and `above` in the `scatter treatment settings` panel.
- `Excitation-Emission Matrix`: This tab visualizes the `raw` or `treated` excitation-emission matrix after applying the scatter removal settings.

</details>

<details open><summary><b>Interpolation methods</b></summary>

Specifies the interpolation method to use for filling cut scatters.`'inpaint'` uses an inpainting algorithm, `'fillmissing'` uses MATLAB's fillmissing function. '`inpaint'` applies del^2 over the entire array, then drops those parts of the array which do not have any contact with NaNs. '`inpaint'` uses a least squares approach, but it does not modify known values. In the case of small arrays, this method is quite fast as it does very little extra work. Extrapolation behavior is linear. See inpaint: Copyright (c) 2017, Damien Garcia. `fillmissing` options fills missing values using Shape-preserving piecewise cubic spline interpolation. For any missing values at the ends of the array, it uses the nearest non-missing value. This ensures that data is completed with a smooth and shape-preserving interpolation method, while boundary gaps are filled with adjacent values. Default method used in `handlescatter` is `inpaint`.

</details>

## Input arguments ##
<details>
    <summary><b>`data` - dataset containing fluorescence data</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.

</details>

