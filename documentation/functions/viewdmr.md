<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewdmr
Visualize the raw data, modeled data, and residual EEM plots for every sample in each PARAFAC model.



## Syntax
`viewdmr(data,Name,Value)`




## Description

The app visualizes the EEMs of raw data (unmodeled data), modeled data, and the residuals of a specified sample and a PARAFAC model. You can go through different models and samples using the `Model` and `Sample` drop-down menus, respectively. 

You can also navigate through sample using the `prev.` and `next` buttons. Moving through samples will automatically reset the axis view, unless specified otherwise using the `Keep axis view` checkbox.


To adjust the upper limit of the Residual plot's colorbar, use the `% of max. intensity` input box. Maximum intensity refers to the upper limit of the data or model plots' colorbar.


<img src="dmr_example.png" width="auto" height="auto" align="left"/>

An example of the `viewdmr` GUI

## Input arguments

<details>
    <summary><b>`data` - dataset containing PARAFAC models</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.

</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`figurefile `- option to save graphical `plot` output </b></summary>
    <i>character</i>

If a character vector is supplied (e.g. "output.png"), the function will save the output produced when plot is set to "true". If plot=false, no output will be saved even if a character vector is supplied.

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewdmr`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewdmr.png". Likewise, providing "projectX.jpg" will result in "projectX-viewdmr.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving)

</details>
