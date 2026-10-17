%[text] %[text:anchor:H_65cd] # Data export
%[text] To open this page as a Matlab live script, run the command
%[text] ```matlabCodeExample
%[text] open(which("tutorial_export_01.m"))
%[text] ```
%[text] If you would like to use this page to build your own m-file , get started by running this command
%[text] ```matlabCodeExample
%[text] matlab.internal.liveeditor.openAndConvert('tutorial_export_01.m', 'export_example.m');
%[text] ```
%[text] 
%[text] At one point or another, you will want to get your data out of the Matlab environment. drEEM supports exporting of:
%[text] 1. The data (as csv files)
%[text] 2. A model (as spreadsheet file)
%[text] 3. The model for upload in OpenFluor (as text file) \
%[text] The relevant functions all start with the term "export", so they should be easy to find if you use the toolbox handle, then type exp and hit the tab key (⇥), for example
%[text] ```matlabCodeExample
%[text] drEEMtoolbox.exp (then hit the ⇥ key)
%[text] ```
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] %[text:anchor:H_5d06] ## Toolbox setup and data loading
clearvars
close all force
cd(fileparts(matlab.desktop.editor.getActiveFilename))
tbx=drEEMtoolbox;
load('tutorial_parafac_modelled.mat')
%[text] ## Extra step
%[text] Just to keep the overall size of the toolbox small, I will delete existing exported files here. 
if isfile("tutorial_data.zip")
    delete("tutorial_data.zip")
end
if isfile("tutorialModelExport.xlsx")
    delete("tutorialModelExport.xlsx")
end
if isfile('tutorial2openFluor.txt')
    delete('tutorial2openFluor.txt')
end
%[text] Moving on...
%[text] %[text:anchor:H_40e8] ## Export the data
%[text] Open research data is an important part of [Open Science](https://en.wikipedia.org/wiki/Open_science) and we support you to make this as easy as possible. If you wish to export all of your EEM and absorbance data, you can use `export2zip` to create an archive version of the dataset. Each sample's EEM and absorbance spectrum is exported as csv file with the wavelength information. The dataset's history is saved, along with it's status, CDOM absorbance slopes, Coble peaks, and scatter removal settings. The archive also contains information on the toolbox and Matlab version and a readme.txt file to explain the contents. For convenience of Matlab users, the .mat-file is also saved.
tbx.export2zip(samples,'tutorial_data.zip') %[output:115c9023]
%[text] %[text:anchor:H_8c68] It's as easy as that. Now you could send this to collaborators, submit it along with your publication, or simply store it for later use. Even if the scripts get lost, you would still know what happened to this data. Think of pairing this export with an export directly after the data import. Then, if worst comes to worst, you could even recreate the final dataset by combining the raw data archive with the information from the export file at the end of the analyisis above.
%[text] %[text:anchor:H_6e0c] ## Export the model
%[text] You might also want to export the PARAFAC modeling results to a spreadsheet to analyze in Excel or other statistical programming environments.
tbx.exportresults(samples,5,'tutorialModelExport'); %[output:94d2ac6e]
%[text] There's no nice way to open spreadsheets in your System's spreadsheet editor, but this below will open Matlab's Import wizard which you can use to browse the file content. Otherwise, just find the file in the File exlorer (usually at the left side of the Matlab environment) and select "Open Outside Matlab".
open("tutorialModelExport.xlsx")
%[text] %[text:anchor:H_66f8] ## Export the model in OpenFluor format
%[text] At the end of the PARAFAC tutorial we had obtained a validated model and we would propably want to analyze it. You'd probably want to know how this model compares against what's out there. So let's get a .txt file that can be uploaded to OpenFluor.
tbx.export2openfluor(samples,5,'tutorial2openFluor.txt') %[output:30bc6d33]

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"title":{"bold":true}}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":38.8}
%---
%[output:115c9023]
%   data: {"dataType":"text","outputData":{"text":"<strong> Writing to temporary directory<\/strong>\n    Finished file: dataset_history.xlsx\n    Finished file: dataset_status.csv\n    Finished file: dataset_scatterRemovalParameters.xlsx\n    Finished file: dataset_opticalIndiciesAndPeakIntensities.csv\n    Finished file: dataset_metadata.csv\n    Finished file: drEEM_versionInformation.csv\n    Finished file: README.txt\n    Finished file: dataset_dreem.mat\n    Finished files: Sample (and Blanks if available) EEMs\n    Finished files: Absorbance spectra\n    Finished files: tutorial_data.zip\n    Removed temporary directory.\n<strong> Success! Done with export.<\/strong>\n\n<strong>drEEM is free & open source.<\/strong> We ask that you cite these resources to indicate its use:\n    1. Toolbox: Zenodo entry (<a href = \"matlab:clipboard('copy','Wünsch, U., Murphy, K., Esmaeeli, A., & Bro, R. (2025). drEEM toolbox version 2. Zenodo. https:\/\/doi.org\/10.5281\/zenodo.17182160')\">click to copy reference<\/a> | <a href = \"matlab:web('https:\/\/doi.org\/10.5281\/zenodo.17182160')\">visit resource website<\/a>)\n    2. PARAFAC methodology: 2013 tutorial review (<a href = \"matlab:clipboard('copy','Murphy, Kathleen R., et al. (2013). Fluorescence Spectroscopy and Multi-Way Techniques. PARAFAC. Analytical Methods, vol. 5, no. 23, Royal Society of Chemistry (RSC), p. 6557, https:\/\/doi.org\/10.1039\/c3ay41160e.')\">click to copy reference<\/a> | <a href = \"matlab:web('https:\/\/doi.org\/10.1039\/c3ay41160e')\">visit resource website<\/a>)\n\n    We also ask that you cite the appropriate primary references for peaks, slopes, and indicies.\n","truncated":false}}
%---
%[output:94d2ac6e]
%   data: {"dataType":"text","outputData":{"text":" \n<strong> Writing to file: \/Users\/wuensch\/git repros\/dreem-2\/toolbox\/examples\/tutorialModelExport.xlsx<\/strong>\n    Finished spreadsheet: dataset history\n    Finished spreadsheet: dataset status\n    Finished spreadsheet: scatter treatment\n    Finished spreadsheet: Peaks & indicies\n    Finished spreadsheet: PARAFAC model overview\n    Finished spreadsheet: Split-validation approach\n    Finished spreadsheets for selected PARAFAC model (scores and loadings)\n<strong> Success! Done with result export.<\/strong>\n\n<strong>drEEM is free & open source.<\/strong> We ask that you cite these resources to indicate its use:\n    1. Toolbox: Zenodo entry (<a href = \"matlab:clipboard('copy','Wünsch, U., Murphy, K., Esmaeeli, A., & Bro, R. (2025). drEEM toolbox version 2. Zenodo. https:\/\/doi.org\/10.5281\/zenodo.17182160')\">click to copy reference<\/a> | <a href = \"matlab:web('https:\/\/doi.org\/10.5281\/zenodo.17182160')\">visit resource website<\/a>)\n    2. PARAFAC methodology: 2013 tutorial review (<a href = \"matlab:clipboard('copy','Murphy, Kathleen R., et al. (2013). Fluorescence Spectroscopy and Multi-Way Techniques. PARAFAC. Analytical Methods, vol. 5, no. 23, Royal Society of Chemistry (RSC), p. 6557, https:\/\/doi.org\/10.1039\/c3ay41160e.')\">click to copy reference<\/a> | <a href = \"matlab:web('https:\/\/doi.org\/10.1039\/c3ay41160e')\">visit resource website<\/a>)\n\n    We also ask that you cite the appropriate primary references for peaks, slopes, and indicies.\n","truncated":false}}
%---
%[output:30bc6d33]
%   data: {"dataType":"text","outputData":{"text":"\n<strong>drEEM is free & open source.<\/strong> We ask that you cite these resources to indicate its use:\n    1. Toolbox: Zenodo entry (<a href = \"matlab:clipboard('copy','Wünsch, U., Murphy, K., Esmaeeli, A., & Bro, R. (2025). drEEM toolbox version 2. Zenodo. https:\/\/doi.org\/10.5281\/zenodo.17182160')\">click to copy reference<\/a> | <a href = \"matlab:web('https:\/\/doi.org\/10.5281\/zenodo.17182160')\">visit resource website<\/a>)\n    2. PARAFAC methodology: 2013 tutorial review (<a href = \"matlab:clipboard('copy','Murphy, Kathleen R., et al. (2013). Fluorescence Spectroscopy and Multi-Way Techniques. PARAFAC. Analytical Methods, vol. 5, no. 23, Royal Society of Chemistry (RSC), p. 6557, https:\/\/doi.org\/10.1039\/c3ay41160e.')\">click to copy reference<\/a> | <a href = \"matlab:web('https:\/\/doi.org\/10.1039\/c3ay41160e')\">visit resource website<\/a>)\n\n    We also ask that you cite the appropriate primary references for peaks, slopes, and indicies.\n","truncated":false}}
%---
