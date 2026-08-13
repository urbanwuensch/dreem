<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# importaqualog
Import absorbance-fluorescence measurements from Aqualog-generated OPJ or OGW files and create drEEMdataset



## Syntax
[`[samples,blanks] = importaqualog(folder)`](#syntax1)

[`[samples,blanks] = importaqualog( ___ , Name,Value)`](#syntax2)



## Description

This function scans the current working directory (`pwd`) for .opj and / or .ogw files and uses aqualog2nc (C++ software) to grab all rawdata to reprocess into absorbance spectra and fluorescence EEMs.

If the C++ tool detects incompatible settings, it will flag this and by default import the group with the most samples. If you wish to change this, use the "bucket" option.

During the import, a ACDD/CF-compliant NetCDF file gets generated. This is an excellent archive for your data as it is about 10x smaller than your OPJ/OGW files.


<details open>
<summary><b>
`dataout = importaqualog(folder)` - standard options</b>
</summary>
<a name="syntax1"></a><br>
returns two drEEMdataset opjects (samples, blanks) that contains fluorescence EEMs and their associated information. Samples.metadata contains date/time of measurement, integration time, and other useful extracted information.

The drEEMstatus is auto-populated since the import is aware of the processing status and instrument properties.


</details>


</details>

<details open>
<summary><b>
`dataout = importaqualog([ ___ ], Name,Value)` - custom options</b>
</summary>
<a name="syntax2"></a>

In case things went wrong and you'd like to have control over which settings-batch to import, you can do so in this syntax.

</details>

## Examples

   1. <strong>Grab any stored measurements in current folder, identical settings</strong>
       `[samples,blanks] = tbx.importaqualog(pwd);`
   2. <strong>Same as 1. but different settings, you want the largest group</strong>
       `[samples,blanks] = tbx.importaqualog(pwd,bucket=1);`
   3. <strong>Same as 2. but now you want to process the samples that got measured with different settings</strong>
       `[samples,blanks] = tbx.importaqualog(pwd,bucket=N); % Choose your N, depends on case.`

## Input arguments ##

<details open>
    <summary><b>`folder ` Folder containing the measurements in OPJ or OGW files</b></summary>
    <i>char | string</i>
        
A text specifying the folder from which to import your measurements.


Example: `pwd`

</details>


## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>

<details open>
    <summary><b>`bucket`- specify which group ("bucket") to import from</b></summary>
    <i>numeric | logical</i>

In case the opj/ogw files contain absorbance+fluorescence measurements with incompatible settings (e.g. different excitation wavelengths), the C++ converter will create groups within the NetCDF file. Here, you specify the numeric group. The larger the number, the fewer samples there will be (decending ordering).

</details>


## Output arguments
<details open>
    <summary><b>`samples` - contains EEMs </b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`. 

The fluorescence data is stored using the properties `.X`, `.Ex`, `.Em`, `.nEx`, `.nEm`, and sample names are stored in `.filelist`. Read the documentation on the `drEEMdataset` for more information.

</details>

<details open>
    <summary><b>`blanks` - contains EEMs of pure water </b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`. 

The fluorescence data is stored using the properties `.X`, `.Ex`, `.Em`, `.nEx`, `.nEm`, and sample names are stored in `.filelist`. Read the documentation on the `drEEMdataset` for more information.

</details>