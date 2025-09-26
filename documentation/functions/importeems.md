<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# importeems
Import measurement files and create drEEMdataset object



## Syntax
[`dataout = importeems(filePattern)`](#syntax1)

[`dataout = importeems( ___ , Name,Value)`](#syntax2)



## Description

This function scans the current working directory (`pwd`) for files using a given filename pattern, reads each file, and returns a `drEEMdataset` containing the fluorescence data.

The function does two passes of imports. The first is used to read the dimensions of each file and to subsequently check that all data contains the same wavelength information.

> ***All files must have the same dimensions. If this is not the case, the function will attempt to resolve the issue but most likely return an error!***

Upon successful import, the `changestatus` GUI will appear on screen and pause the execution until the user has acknowledged the status of the dataset. You are asked to specify to what level the dataset has been processed. Since the drEEMdataset can contain fluorescence and / or absorbance, the GUI will ask about absorbance properties. Please ignore these and focus on the property the remainder of the fields.

 <img src="newfldata.png" width="auto" height="auto" align="center"/>

> ***It is important to specify the correct properties at this moment. If you are unsure as to what has been done already, please reach out to the instrument manufacturer, collaborator, laboratory manager or similar to ensure that the right information is supplied here.***


<details open>
<summary><b>
`dataout = importeems(filePattern)` - standard options (fits e.g. HYJ Export for AquaLog data)</b>
</summary>
<a name="syntax1"></a><br>
returns a drEEMdataset class object that contains fluorescence EEMs and their associated information.

</details>

<details open>
<summary><b>
`dataout = importeems([ ___ ], Name,Value)` - custom options</b>
</summary>
<a name="syntax2"></a>

Custom options are specifed with optional pairs of arguments using one or more name-value arguments. For example, you can specify the orentation of the EEM, or the wavelength vector if it is not given in each file.

</details>

## Examples
<strong>Horiba AquaLog:</strong>
`blanks = tbx.importeems(" - Waterfall Plot Blank.dat");`

<strong>Horiba FluoroMax:</strong>     `blanks=tbx.importeems('*.dat','columnIsExcitation',true,'columnWave',240:10:450);`

<strong>Cary Eclipse</strong>  `samples=tbx.importeems("*.csv","columnIsExcitation",true);`

## Input arguments ##

<details open>
    <summary><b>`filePattern ` Text pattern to identify files for import</b></summary>
    <i>char | string</i>
        
A text specifying the pattern of the files to be imported. This can include wildcard characters (*) to match multiple files. The pattern will be completely removed from the sample name after import to leave only the non-repeating filename information. For example `S001PEM.dat` will be known as `S001` in the produced dataset.


Example: `'*.csv'`

Example: `'* - Waterfall Plot Samples.dat'`

</details>


## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`columnWave`- specify if first column contains wavelength data (or specify them)</b></summary>
    <i>numeric | logical</i>

If `true`, the data in the measurement files are expected to have wavelength information in columns. Default is `true`.

If numeric, the function assumes that you provide the wavelength vector to associate it with the data. In this case, the length of the vector must be equal to the number of columns in each file. 

*Take care that the vector is supplied in the same orientation as the data was recorded (increasing vs. decreasing wavelength).*
</details>

<details open>
    <summary><b>`rowWave`- specify if first row contains wavelength data (or specify them)</b></summary>
    <i>numeric | logical</i>

If `true`, the data in the measurement files are expected to have wavelength information in rows. Default is `true`.

If numeric, the function assumes that you provide the wavelength vector to associate it with the data. In this case, the length of the vector must be equal to the number of rows in each file. 

*Take care that the vector is supplied in the same orientation as the data was recorded (increasing vs. decreasing wavelength).*
</details>


<details open>
    <summary><b>`columnIsExcitation `- specify the orientation of the EEM</b></summary>
    <i>numeric | logical</i>

If `true`, the columns represent excitation wavelengths. If `false`, the data matrix will be rotated so that it matches the standard settings in the toolbox. Default is `true`.

</details>



<details open>
    <summary><b>`NumHeaderLines `- number of header lines to ignore</b></summary>
    <i>numeric</i>

Specify the number of  lines (rows) to skip from the top in each file. Default is `0`.<br>

Example: `'NumHeaderLines', 2` to remove the first 2 rows of each file<br>

Default is `0`.

</details>

## Output arguments
<details open>
    <summary><b>`dataout` - contains EEMs </b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`. 

The fluorescence data is stored using the properties `.X`, `.Ex`, `.Em`, `.nEx`, `.nEm`, and sample names are stored in `.filelist`. Read the documentation on the `drEEMdataset` for more information.

</details>