<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# viewhistory
View and export a summary of the functions carried out on data and their details.


## Syntax

	viewhistory(data)

## Description


The function `viewhistory` opens up the drEEM viewhistory app that contains a summary of the drEEM functions that have been run on the data, along with their details and the comments added by the user during the process.

Functions that appear more than once are color-coded for easier navigation through the list.

Hovering over any cell will show the detailed content of the cell if their length exceed the cell's space.

Use the `Save list as spreadsheet` button to export the history in `.ods` (OpenDocument Spreadsheet) file format. The exported spreadsheet will contain all the history fields, timestamps, function names, user comments, and function messages.

By clicking on any of the functions (in drEEM function column) that accept some options as input, the two `View selected options` and `Transfer options to workspace` buttons will be enabled. Use the former to see the options associated with the selected function in a new window, and the latter to export the options to the workspace in a variable called `restoredOptions`.

## Input arguments ##
<details>
    <summary><b>`data`</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`.

</details>