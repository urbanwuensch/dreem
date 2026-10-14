<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# Installation of the toolbox

The installation of the drEEM toolbox is straightforward and there are software routines to help ensure proper functionality and updating on demand.

## Download and installation


- Open MATLAB® on the HOME tab, use Add-ons browser to search and install and add drEEM to MATLAB®.
- Alternatively, download on MATLAB® File Exchange and follow instructions mentioned there.



## Recommended Add-Ons
Besides the MATLAB core, no other MathWorks toolboxes are required. The following might add to the user experience if installed.

1. [Parallel Processing Toolbox](https://www.mathworks.com/products/parallel-computing.html) (<ins>optional</ins>) to benefit from multi-core CPUs when fitting PARAFAC models. Even without it, drEEM-2 is 5x faster than previous versions.
2. [PLS\_toolbox](https://eigenvector.com/software/pls-toolbox/) (<ins>optional</ins>) to use the latest PARAFAC algorithms. However, this requires PLS\_toolbox to be purchased and installed. This toolbox is by no means required since drEEM ships with the free [N-Way toolbox](https://doi.org/10.1016/S0169-7439(00)00071-X).