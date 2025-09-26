<img src="top right corner logo.png" width="100" height="auto" align="right"/>

# importwizard
Import absorbance spectra along with sample and blank EEMs and associated metadata tables.



## Syntax
[`importwizard`](#syntax1)




## Description ##

Opens up the `importwizard`'s user interface app. This GUI is designed to offer an interactive option for file imports and troubleshooting. 

The import-Wizard offers the same functionality as `importeems`, `importabsorbance`, and `associatemetadata`.

**Interface Components include:**<br>

<details open><summary><b>Toolbar</b></summary>

- `Help`: Opens this documentation
- `Import folder`: Specify the folder in which files will be searched for.
- `Metadata file`: Specify the file from which sample metadata will be gathered and matched to the samples.
- `A,B,S`: Toggle buttons that specify whether absorbance, blank EEMs, and sample EEMs should be imported. Options are always visible even if the import is disabled by the user.
- `Validate`: Runs a diagnostic import in the specified folder with the specified options. 
- `Import`: Runs the import, associates metadata, and organizes the data in the most appropriate manner.
- `Save`: Transfers the datasets to the workspace using the variable names `samples`, `blanks`, and `absorbance`.
</details>

<details open><summary><b>Settings Tab Group</b></summary>


- `EEMs`: In this tab, the settings from `importeems` can be specified interactively. Please refer to the documentation to learn more.
- `Absorbance spectra`: In this tab, the settings from `importabsorbance` can be specified interactively. Please refer to the documentation to learn more.
- `Metadata spreadsheet`: Once a metadata spreadsheet has been selected, the column names will be listed here. If corresponding datasets have also been imported, the Wizard will automatically find the column that best matches filenames to the metadata column and shows the %-success rate with which metadata was associated to the sample datasets.

</details>

<details open><summary><b>App log</b></summary>

In this section of the GUI, any information on app operations is shown. This includes error messages.

</details>