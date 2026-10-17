%[text] # **Getting Started with the drEEM toolbox**
%[text] Congrats on installing drEEM toolbox. If you are a new user, [we](file:./dreem.html) extend a very warm welcome. If you are coming from an older version of the toolbox (anything older than 2.25.07), please make sure to remove any folders from the searchable Matlab path that include an older version. This has not been done for you during the installation. If older versions are searchable, some functionality will not behave as expected.
%[text] 
%[text] This toolbox ships with demo datasets to make the introduction as easy as possible. Below, you find a very general introduction to the toolbox. More importantly, there are several tutorials based on the demo data to show you how you can use the toolbox with your own data whether you have it or not (yet).
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Initialize the toolbox
tbx=drEEMtoolbox;
%[text] %[text:anchor:TMP_3ba8] If this line above already produces an error, the built-in checks have detected an issue with your MATLAB version or your path evnvironment. Note down the error and the suggested fixes. If you need assistance, [email us](mailto:urban.wunsch@chalmers.se).
%[text] ## Getting help
%[text] Access the full drEEM documentation with lots of tutorials and information:
tbx.doc("drEEM")
%[text] Note, do not use "doc" for the toolbox. It will not work. To access the short help for a fuction, type:
%[text] ```matlabCodeExample
%[text] help functionname
%[text] ```
%[text] For example:
help importeems %[output:767a0220]
%[text] To access the full documentation, click the hyperlink (-\> full documentation) at the bottom of the help text in the console output. If you click the actual hyperlink above, you should see the documentation. If you want to directly access the full documentation, you can do so by typing:
%[text] ```matlabCodeExample
%[text] drEEMtoolbox.doc("functionname") % if toolbox has not been assigned an object
%[text] tbx.doc("drEEM") % if you use a handle to access the toolbox.
%[text] ```
%[text] So in our example, you'd run
tbx.doc('importeems')
%[text] %[text:anchor:TMP_7c0a] Notice how during typing, you get suggestion for function names? This is unfortunately not the case when using MATLAB's own help function. But you've got two ways to access help for any function.
%[text] ## Examples / Tutorials
%[text] To get you started, you can open any of these tutorials:
  %[control:button:696d]{"position":[1,2]}
  %[control:button:720c]{"position":[1,2]}
  %[control:button:7ca8]{"position":[1,2]}
  %[control:button:26d5]{"position":[1,2]}
  %[control:button:5000]{"position":[1,2]}
%[text] - Opening one of these files will create a local copy in Documents/MATLAB/drEEM\_tutorials
%[text] - If you want to make changes to these files (e.g. if you use them to create your own workflow), **you should rename the files**. Otherwise, they will be overwritten when you remake the example by clicking the button. \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
%[control:button:696d]
%   data: {"callbackCode":"drEEMtoolbox.openWritableDoc(['examples',filesep,'drEEM_workflow.m'])","label":"Working with the drEEM package","run":"Callback"}
%---
%[control:button:720c]
%   data: {"callbackCode":"drEEMtoolbox.openWritableDoc(['examples',filesep,'import_tutorial_01.m'])","label":"Data import","run":"Callback"}
%---
%[control:button:7ca8]
%   data: {"callbackCode":"drEEMtoolbox.openWritableDoc(['examples',filesep,'processing_tutorial_01.m'])","label":"Data processing","run":"Callback"}
%---
%[control:button:26d5]
%   data: {"callbackCode":"drEEMtoolbox.openWritableDoc(['examples',filesep,'parafac_tutorial_01.m'])","label":"Parallel Factor Analysis (PARAFAC)","run":"Callback"}
%---
%[control:button:5000]
%   data: {"callbackCode":"drEEMtoolbox.openWritableDoc(['examples',filesep,'tutorial_export_01.m'])","label":"FAIRness: Data export","run":"Callback"}
%---
%[output:767a0220]
%   data: {"dataType":"text","outputData":{"text":"--- help for <strong>drEEMtoolbox.importeems<\/strong> ---\n\n  <a href = \"matlab:drEEMtoolbox.doc('importeems')\">data = importeems(filePattern,options) (click to access documentation)<\/a>\n \n  <strong>Import fluorescence EEMs<\/strong> and create drEEMdataset\n \n  <strong>INPUTS - Required<\/strong>\n  filePattern (1,:)                 {mustBeText}\n  \n  <strong>INPUTS - Optional<\/strong>\n  columnWave (1,:)          {mustBeNumericOrLogical} = true\n  rowWave (1,:)             {mustBeNumericOrLogical} = true\n  columnIsExcitation (1,:)  {mustBeNumericOrLogical}= true\n  NumHeaderLines (1,1)      {mustBeNumeric}= 0\n  waveDiffTollerance (1,1)  {mustBeNumeric} = 1\n \n  <strong>EXAMPLE(S)<\/strong>\n    1. <strong>Horiba AquaLog<\/strong>\n        blanks = tbx.importeems(\" - Waterfall Plot Blank.dat\");\n    2. <strong>Horiba FluoroMax<\/strong>\n        blanks=tbx.importeems('*.dat','columnIsExcitation',true,'columnWave',240:10:450);\n    2. <strong>Cary Eclipse<\/strong>\n        samples=tbx.importeems(\"*.csv\",\"columnIsExcitation\",true);\n    3. <strong>Jasco csv-files with large header<\/strong>\n        Not supported due to complex file format. Contact dreem@openfluor.net \n \n  <a href = \"matlab:drEEMtoolbox.doc('importeems')\"><strong>-> full documentation<\/strong><\/a>\n\n","truncated":false}}
%---
