<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# ramancalibration
Calibrate fluorescence signal by the division of Raman scatter peak area.



## Syntax
[`dataout = ramancalibration(samples, blanks)`](#syntax1)

[`dataout = ramancalibration( ___ , Name,Value)`](#syntax2)

[`ramancalibration( ___ , Name,Value)`](#syntax3)

## Description

The `ramancalibration` function calibrates the fluorescence signal in `samples` by the division of Raman scatter peak area at excitation=`ExWave` obtained from the dataset `blanks`. The area will be calculated after a baseline subtraction to take scatter or baseline noise into account.

An entry will be added to the `history` field of the `data`, detailing the processing options used, including the excitation wavelength, integration range, Raman area, and baseline area. If no output argument is specified, the function will overwrite the original `data` in the workspace.

> ***Depending on the measurement settings, the blank dataset might not contain a Raman scan of sufficient quality. It is your responsibility to verify that the Raman calibration worked well. The function produces a figure that should be inspected for every dataset.***

The function validates the input datasets to ensure that the calibration is only carried out if it is appropriate: 

>***The status-property "signalCalibration" must be "not applied". Otherwise, the function returns a validation error.***

<details open>
<summary>
<b>`dataout = ramancalibration(samples, blanks)` default options</b>
</summary>

Run the function with the default options. This will pick the emission scan at excitation 350nm and integrate from 378 to 424nm. The baseline between start and end of the Raman peak will be subtracted.
 <a name="syntax1"></a>
</details>


<details open>
<summary>
<b>`dataout = ramancalibration( ___ , Name,Value)` custom options</b>
</summary>
 <a name="syntax3"></a>
 specifies additional options using one or more name-value pair arguments. For example, you can specify the excitation wavelength for extracting Raman scan using `ExWave` or specify the emission range for the integration of the area under the peak using `iStart`, `iEnd`. <br>


</details>


## Examples
1. Trust us, but verify(!)
`samples = tbx.ramancalibration(samples,blanks);`
2. Trust us, and fly blind (only recommended if you have verified defaults!)
`samples = tbx.ramancalibration(samples,blanks,plot=false);`
3. Longer integration times, wider peak
`samples = tbx.ramancalibration(samples,blanks,iStart=375,iEnd=430);`
4. Different Raman peak (you need to decide start and end wavelength of peaks visually)
`samples = tbx.ramancalibration(samples,blanks,ExWave=275,iStart=...,iEnd=...);`


## Input arguments
<details>
    <summary><b>`samples` - contains EEMs of samples</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbs.validatedataset(samples)`.

> The property `samples.status.signalCalibration` must be `"not applied"`. Otherwise, the function returns a validation error.

</details>

<details>
    <summary><b>`blanks` - contains EEMs of blanks</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(blanks)`. 

> The property `blanks.status.signalCalibration` must be `"not applied"`. Otherwise, the function returns a validation error.

</details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>


<details open>
    <summary><b>`ExWave `- excitation wavelength for extracting Raman scan</b></summary>
    <i>numeric </i>
    
Indicates the excitation wavelength that the function uses to extract Raman scans. The function checks if the specified `ExWave` is present in the `blanksdataset`. If present, the function extracts the corresponding scans directly. Otherwise, it interpolates the data in `blanksdataset` to approximate the scans at the specified excitation wavelength.

Default excitation wavelength is `350`.


</details>


<details open>
    <summary><b>`iStart `- emission wavelength to start Raman peak area integration</b></summary>
    <i>numeric </i>
    
The function calculates the Raman area and baseline area over the specified integration range starting from `iStart`. Default starting wavelength is `378`.



</details>

<details open>
    <summary><b>`iEnd `- emission wavelength to end Raman peak area integration</b></summary>
    <i>numeric </i>
    
The function calculates the Raman area and baseline area over the specified integration range ending at `iEnd`. Default starting wavelength is `424`.


</details>

<details open>
    <summary><b>`plot`- switch to plot the results</b></summary>
    <i>logical</i>

If `true`, the function generates various plots to visualize the Raman emission scans, Raman area, baseline area relative to Raman area, and `SNB` (signal to background) across the dataset. For SNB, the signal is the maximum intensity of the Raman scan, and the background is the median fluorescence from the end of the peak +50nm.

Default is `true`.

</details>


## Output arguments
<details>
    <summary><b>`dataout` - contains EEMs of samples with intensities in Raman Units</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.


The status of the dataset is changed to reflect the fact that a Raman calibration has been applied by the drEEM toolbox

</details>