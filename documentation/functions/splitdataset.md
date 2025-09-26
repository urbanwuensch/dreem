<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# splitdataset
Split a dataset into multiple subsets for tasks such as cross-validation.



## Syntax
[`dataout = splitdataset(data,splitType)`](#syntax1)

[`dataout = splitdataset( ___ , Name,Value)`](#syntax2)


## Description

The `splitdataset` function creates subsets of `data` and store them in the `split` field of the output argument. If `data.split` contains subsets from previously subsetted data, those splits will be overwritten with the new splits.

Splits are either assigned "blind" or "by metadata", i.e. without or with considering any metadata such as sample campaign or location.

The function uses default values of input arguments (see Input arguments section) when options are not specified. 

An entry will be added to the `history` field of the `data`, detailing the  options used for `splitdataset`. If no output argument is specified, the function will overwrite the original `data` in the workspace.


<details open>
    <summary><b>`dataout = splitdataset(data,splitType)` - assign samples into 2 splits alternatingly</b></summary>
<a name="syntax1"></a>

The default syntax represents the most simple form of dataset splitting, i.e. the split-half. Samples are blindly assigned into one of two splits alternatingly without taking into account any information on sample origin.
    
</details>

<details open>
    <summary><b>`dataout = splitdataset( ___ , Name,Value)` - perform custom splits (recommended)</b></summary>
<a name="syntax2"></a>

specifies additional options using one or more [name-value](#NameValue) pair arguments. For example, you can specify number and type of splits.

    
</details>


## Examples

Please refer to the [Name,Value](#NameValue) section to see the defaults for optional arguments. In the examples, some defaults are used. To make this clear, the full function call with redundant arguments is shown below (redundant since default).

1. Randomly split into `4` subsets:
`data=splitdataset(data,"blind","numsplit",4,"blindType"="random")`

 
2. Split the dataset into 3 subsets using alternating splitting:
`data=splitdataset(data,"blind", "numsplit", 3,);`
Is the same as:
`data=splitdataset(data,"blind","numsplit",3,"blindType"="alternating")`

3. Split the dataset exactly according to `SampleType` in metadata:
`data=splitdataset(data,"byMetadata",metadataColumn="SampleType")` 



## Input arguments
<details>
    <summary><b>`data` - dataset to be split into smaller datasets</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(data)`. 

</details>


<details open>
    <summary><b>`splitType`- switch between "blind" and "byMetadata"</b></summary>
    <i>text</i>
 
 With this argument, yo specifically state whether a blind split (no information) should be performed, or whether the splitting operation is informed by metadata.
 
 If `"byMetadata"` is specified, the option "metadataColumn" *must* also be specified. Otherwise, an error will be displayed.

 </details>

## Name-Value arguments
Specify pairs of arguments as `Name1=Value1,...,NameN=ValueN`, where `Name` is the argument name and `Value` is the corresponding value. The notation `"Name",Value` is also supported. Name-value arguments must appear after other arguments, `data` in this case, but the order of the pairs does not matter. 
<a name="NameValue"></a>
 
<details open>
    <summary><b>`blindType`- options for blind splitting</b></summary>
    <i>text</i>
 
When `splitType="blind"`, use this option to specify how the splits should be assined. Options are `alternating`,`random`, or `contiguous`.

 Default is `"alternating"`.

</details>
 
<details open>
    <summary><b>`metadataColumn`- metadata to use for split assignment</b></summary>
    <i>text</i>
 
Specifies a column in `data.metadata` to sort `data` before splitting. Must be a valid metadata column name that exists in `data.metadata`. <br>Note: When `bysort` is provided, the `stype` must be set to `"exact"`. <br>

If `metadataColumn` is provided as optional input, it takes precedent over `splitType`, i.e. you can but don't have to set `splitType="byMetadata"` (a message will be displayed to inform you that the toolbox has interpreted your intention).

Default is `[]`, since `splitType="blind"` by default.


</details>

<details open>
    <summary><b>`numSplit`- specify number of splits</b></summary>
    <i>numeric</i>
 
The number of subsets to split the data into. Must be a positive integer.

Any input to this argument is ignored if `splitType="byMetadata"` and / or an Value is supplied to the argument `metadataColumn`.

Default is `2`.


 </details>
 




## Output arguments
<details>
    <summary><b>`dataout` - dataset with contents in `.split`</b></summary>
    <i>drEEMdataset</i>
        
A dataset of the class `drEEMdataset` that passes the validation function `tbx.validatedataset(dataout)`.

</details>
