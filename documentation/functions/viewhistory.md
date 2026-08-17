<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewhistory
View and export a summary of the functions carried out on data and their details.


## Syntax

	viewhistory(data,Name,Value)

## Description


The function `viewhistory` opens up the drEEM viewhistory app that contains a summary of the drEEM functions that have been run on the data, along with their details and the comments added by the user during the process.

Functions that appear more than once are color-coded for easier navigation through the list.

Hovering over any cell will show the detailed content of the cell if their length exceeds the cell's space.

Use the `Save list as spreadsheet` button to export the history in `.ods` (OpenDocument Spreadsheet) file format. The exported spreadsheet will contain all the history fields, timestamps, function names, user comments, and function messages.

By clicking on any of the functions (in drEEM function column) that accept some options as input, the two `View selected options` and `Transfer options to workspace` buttons will be enabled. Use the former to see the options associated with the selected function in a new window, and the latter to export the options to the workspace in a variable called `restoredOptions`.

## Input arguments ##
<details>
    <summary><b>`data`</b></summary>
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

A file extension can be supplied if desired (any extension supported by MATLAB's `exportgraphics` is fine). Note however that the function will insert a "-" followed by the calling function's name (`viewhistory`) before the extension to facilitate file organization. I.e. providing "projectX" as input will result in a file called "projectX-viewhistory.png". Likewise, providing "projectX.jpg" will result in "projectX-viewhistory.jpg".

A pause of 3 seconds is implemented to allow graphical rendering to finish before saving a figure.

Default: `""` (i.e. an empty string disabling the figure saving.

</details>

