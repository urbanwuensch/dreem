# drEEM toolbox for MATLAB version 2
MATLAB toolbox aids the import, processing, and analysis of ultraviolet-visible absorbance and fluorescence spectra. Particular focus is on FAIR data policies.
The toolbox is particularly useful for the chemometric analysis of excitation-emission matrices (EEMs) of dissolved organic matter (DOM). Spectral properties of chromophoric DOM can also be determined easily.

## Installation

Option 1 (preferrable): [![Download on File Exchange](https://dreem.openfluor.org/assets/matlab-fileexchange.svg)](https://se.mathworks.com/matlabcentral/fileexchange/162526-dreem-toolbox)

Option 2 (convenient): [![Open in MATLAB Online](https://dreem.openfluor.org/assets/matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=urbanwuensch/drEEM-online&file=GettingStartedOnline.mlx)


Each method ends in displaying a guide to get started with more information.

## Usage
- drEEM version 2 is based on object-oriented programming. To initialize the toolbox, type `tbx = drEEMtoolbox;`.
- Access the toolbox methods by calling e.g. `tbx.importeems(...)`
- To see which methods are available, type `tbx.` followed by hitting the TAB key to get a list of method suggestions.
- For orientation, method names generally refer to an action and an object, e.g. `importeems`, `fitparafac`, `subtractblanks`, `splitdataset`, etc.
- Type `doc drEEM` for for an overview of functions.

## Additional toolboxes contained within
drEEM ships with several functions provided by external sources:

1. [N-Way toolbox by Rasmus Bro](https://doi.org/10.1039/c3ay41160e)
2. [inpaint_nans by John D'Errico](https://www.mathworks.com/matlabcentral/fileexchange/4551-inpaint_nans)
3. [crameri colormaps by Fabio Crameri & Chad Greene](https://www.mathworks.com/matlabcentral/fileexchange/68546-crameri-perceptually-uniform-scientific-colormaps)

These toolboxes are contained in a seperate namespace and will not interfere with your MATLAB path environment.

## Further reading (peer-reviewed publications)
- [drEEM toolbox](https://doi.org/10.1039/c3ay41160e)
- [N-way toolbox](https://doi.org/10.1016/S0169-7439(00)00071-X)
- [OpenFluor](https://doi.org/10.1039/C3AY41935E)

## Further watching on multiway analysis
- [Lecture series on multiway analysis](https://www.youtube.com/watch?v=_gIb6PzBEc4&list=PL4L59zaizb3E-Pgp-f90iKHdQQi15JJoL)

## Questions, comments , suggestions?
- Contact Urban [urban.wunsch@chalmers.se](mailto:urban.wunsch@chalmers.se)