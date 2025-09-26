<img src="top right corner logo.png" width="100" height="auto" align="right"/>
# Installation of the toolbox

The installation of the drEEM toolbox is straightforward and there are software routines to help ensure proper functionality and updating on demand.

## Download and installation


- Open MATLAB® on the HOME tab, use Add-ons browser to search and install and add drEEM to MATLAB®.
- Alternatively, download on MATLAB® File Exchange and follow instructions mentioned there.



## Requirements
The drEEM toolbox requires the [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html) to calculate exponential CDOM slopes. Such fits are used to to calculate the long wavelength range CDOM slope and to extrapolate CDOM absorbance data in cases where the measured fluorescence emission exceeds the coverage of absorbance data. If you don't require these features, drEEM will run fine without the toolbox.

Considerable speed advantages can be achieved if the [Parallel Processing Toolbox](https://www.mathworks.com/products/parallel-computing.html) is installed. This toolbox is needed to take advantage of modern multi-core CPUs. However, the toolbox is designed to run without the toolbox as well.

drEEM can take advantage of algorithm refinements that have taken place over recent years via the [PLS_toolbox](https://eigenvector.com/software/pls-toolbox/). However, this requires PLS_toolbox to be purchased and installed. This toolbox is by no means required since drEEM ships with the free [N-Way toolbox](https://doi.org/10.1016/S0169-7439(00)00071-X).