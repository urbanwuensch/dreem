<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# vieweems #
Visualize and analyze Excitation Emission Matrices (EEMs) and modeled data.



## Syntax

	vieweems(data)




## Description ##

Opens up the `vieweems`'s user interface app. The app allows users to visualize contour or 3D plots of EEMs and 2D spectra of excitation, emission and absorbance data, using adjustable settings, e.g. number of contours, colormap, colorlimits, showing Coble peaks, etc.<br>

<img src="vieweems_example.png" width="auto" height="auto" align="center"/>


Interface components include:<br>
<strong>Sample Control panel:<br></strong> Use the arrow buttons, <img src="next.png" width="auto" height="14" display="inline"/> and<img src="back.png" width="auto" height="14" display="inline"/>, to navigate through different samples in `data`. Use the Ex/Em pair selection button,<img src="spectrum.png" width="auto" height="14" display="inline"/>, to visualize the 2D spectra. By selecting this button, a crosshair appears that by hovering it to the point of interest and left-clicking both 2D Ex and Em spectra will be plotted.

- `Sample `: Dropdown menu to select the sample to be visualized.
- `Data type`: Specify the type of data to be used for visualization. If models have been fit to the `data`, the modeled data or model residuals can be selected and plotted.
- `Number of component`: If models have been fit to the `data`, any of the fitted models can be selected and plotted. <comment> [I have to come back here and check] </comment>

<strong>EEM Format panel:<br></strong>

- `Colormap`: Dropdown menu to select the colormap for visualizing EEM data. Available colormaps include: `turbo`, `parula`, `jet`, `hsv`, `blue-red`.
- `Number of Contours.`: Specify the number of contour levels displayed on the EEM plot.
- `remember rotation`: Specify to remember the rotation settings of the EEM plot, if the plot has been rotated, when moving across samples.
- `remember colorlimits`: Retain the colormap limits across different samples.
- `show Coble Peaks`: Specify to display standard Coble peaks, e.g. Peak A, Peak C, Peak T, etc., on the EEM.
- `show indices`: Specify to display fluorescence indices, e.g. FI, HIX, BIX, etc., on the EEM.


<strong>Spectra Format panel:<br></strong>

- `hold on`: Allows to overlay multiple spectra at the same time for comparison.
- `remember selection`: Retain the current (last) selection settings for Ex/Em spectra pair for any subsequent sample. Checking this option will automatically plot the 2D spectra when moving through samples.
- `show scatter position`: Check to display the positions of scatter peaks (Rayleigh and Raman) on the 2D spectra.
- `show absorbance`: Check to plot the absorbance data of the samples on the right y-axis of the excitation plot. If the `abs` field in the `data` is empty the option is automatically disabled. 


<strong>Excitation Emission Matrix:<br></strong>

- EEM Plot:: Displays the EEM for the selected sample. The axes represent excitation (nm) and emission (nm) wavelengths, while the color scale represents fluorescence intensity.
- `Color Limit (percentiles):`: Slider to adjust the percentile limits for the colormap, allowing users to focus on different intensity ranges, e.g. to ignore scatter, highlight weak signals or compensate for negative values. The slider is disabled for residual plots as is expected behavior.

<strong>2D spectra panel:<br></strong>

- Excitation Spectrum at Emission = X: Shows the excitation spectrum at a fixed emission wavelength, X, selected by using the Ex/Em pair selection button. This plot also depicts the absorbance data on the right y-axis, if absorbance data is available and the `show absorbance` checkbox is checked.
- Emission Spectrum at Excitation = Y nm: Shows the emission spectrum at a fixed excitation wavelength, Y, selected by using the Ex/Em pair selection button.<br><br>
Note: Vertical lines represent the positions of Raman and Rayleigh scatter peaks for both excitation and emission spectra.



## Input arguments ##
<details>
    <summary><b>`data` - dataset containing fluorescence and absorbance data</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.

</details>
