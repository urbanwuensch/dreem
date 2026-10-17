%[text] %[text:anchor:T_0a8c] # Tips and Tricks
%[text] Depending on the scientific discipline, Matlab is not the most popular choise of scientific programing language for the users of fluorescence spectroscopy. If you spend most of your time in R or Phython, you might find yourself frustrated at not knowing how to do ceratain jobs. If you're mostly using Excel, this might be even more pronounced. <u>***Don't worry, this page is for you!***</u>
%[text] We will go through several topics that often hinder users of our toolbox in getting to the fun part. Most of this is related to data importing and associated initial tasks. So let's start there.
%[text:tableOfContents]{"heading":"**Table of Contents**"}
%[text] 
%[text] %[text:anchor:H_3c01] ## Working with filenames
%[text] Often, fluorescence and absorbance are measured on separate instruments. Upon exporting, the filenames will often differ. Sometimes just by the extension (e.g. ".csv" vs. ".dat" or ".txt"), but often they are entirely different.
%[text] If you use [`importabsorbance`](file:importabsorbance.html) or [`importeems`](file:importeems.html), the common extension part of the filenames (e.g. ".csv") and trailing or leading empty characters are already removed for you. So you don't need to worry about those anymore. Problem solved!
%[text] %[text:anchor:H_89df] ## Useful Matlab functionality
%[text] This section is dedicated to sharing code that the developer team has discovered over the years. This is of course mostly documented already, but you might still find it useful!
%[text] %[text:anchor:H_537e] ### Universal script header
%[text] Once the projects pile up, you find yourself importing a lot of fluorescence data. Wouldn't it be nice to have a script that you can use to import the data? Of course, but a lot of things change between each project, so modifications always seem necessary. But it's all too easy to forget about modifications you made to a script 2 months ago down in line 58 where you loaded and overwrote some variable for some reason. You could start your script as follows:
%[text] ```matlabCodeExample
%[text] clearvars
%[text] close all force
%[text] cd(fileparts(matlab.desktop.editor.getActiveFilename))
%[text] tbx=drEEMtoolbox;
%[text] ```
%[text] Regardless of what follows, this ensures that all variables are cleared, figures are closed, that you are in fact in the project directory (which is  automatically chosen as the one where the file is saved!) and that drEEM is properly installed.
%[text] Next, standard folder names are a good idea. E.g. store raw data in a folder called "raw data". Separate absorbance data in e.g. "absorbance data". If you don't change these names, you can reuse the same import script. Example to *copy* (don't try to run it, it will produce errors):
%[text] ```matlabCodeExample
%[text] clearvars
%[text] close all force
%[text] cd(fileparts(matlab.desktop.editor.getActiveFilename))
%[text] tbx=drEEMtoolbox;
%[text] 
%[text] projectName='someNiceDataset';
%[text] 
%[text] if not(exist([projectName,'.mat']
%[text]     cd 'raw data'
%[text]     samples=tbx.importeems('* - Waterfall Plot Sample.dat');
%[text]     blanks=tbx.importeems('* - Waterfall Plot Blank.dat');
%[text]     absorbance=tbx.importabsorbance('* - Abs Spectra Graphs.dat');
%[text]     cd ..
%[text]     save([projectName,'.mat'],"samples","blanks","absorbance")
%[text] else
%[text]     load([projectName,'.mat'])
%[text] end
%[text] ```
%[text] This code will only import the files if the rawdata mat-file doesn't exist yet (don't do this if you keep adding samples into an ongoing project).
%[text] %[text:anchor:H_547f] ### Working with filenames
%[text] Working with strings, cell array of strings (or characters) is really important. This is where some knowledge of Matlab will pay off. Often, we need to find samples, erase, or replace parts of strings or certain sample names or identify issues when sample datasets need to be aligned. ***Though, generally, the more attention you pay to sample names and make sure things align at the stage of measuring, the less you need to do in Matlab!***
%[text] Some functions that come in extremely handy:
%[text] - `contains`: Find samples that contain a certain string. No complete match is necessary (though that can be dangerous). But useful particularly if you want to find groups of samples. Example: \
%[text] ```matlabCodeExample
%[text] idx=contains(data.filelist,'my first bad sample')
%[text] data=tbx.subdataset(data,outSample=idx);
%[text] ```
%[text] - `matches:` Much like contains, you'll find samples where the search string is matched *entirely*. Like `contains`, `matches` does case-sensitive lookups.
%[text] - `lower / upper`: If you have a dataset where upper and lower case is mixed up, these two functions can be a life saver because these mixups are eliminated. \
%[text] ```matlabCodeExample
%[text] idx=contains(lower(data.filelist),'my first bad sample')
%[text] data=tbx.subdataset(data,outSample=idx);
%[text] ```
%[text] - `erase`: Super helpful to fix mismatches between sample logs and filenames. Imagine all filenames in a metadata Excel sheet were typed in with the file extension, but this extension is deleted during the import of the samples. Example: \
%[text] ```matlabCodeExample
%[text] data.metadata.absorbanceFileName=erase(data.metadata.absorbanceFileName,'.csv')
%[text] ```
%[text] - `intersect`: A very useful function to find common strings between two lists. drEEMs `alignsamples` uses this function and generally will take care of many relevant operations to align different datasets, but it is sometimes necessary to take manual action to figure out what's going wrong when there seems to be little overlap between datasets. Example: \
%[text] ```matlabCodeExample
%[text] [C,ia,ib] = intersect(samples.filelist,absorbance.filelist)
%[text] 
%[text] notMatchedAbs=absorbance.filelist(setdiff(1:absorbance.nSample,ib);
%[text] notMatchedEEM=samples.filelist(setdiff(1:samples.nSample,ia);
%[text] disp(notMatchedAbs)
%[text] disp(notMatchedEEM)
%[text] ```
%[text] %[text:anchor:H_675b] ## drEEM-specific Tips and Tricks
%[text] %[text:anchor:H_6268] ### Correcting filename errors
%[text] Say you made a mistake in naming one of your samples. It was supposed to be called "PCEP26" but accidentally got called "LCEP26". You could fix the filename(s), but you can also handle this sort of issue in Matlab:
%[text] ```matlabCodeExample
%[text] load("benchmarkDataset.mat")
%[text] idx=matches(data.filelist,'LCEP26');
%[text] data.filelist{idx}='PCEP26';
%[text] ```
%[text] If you're not used to Matlab, the use of "{}" vs. "()" seems strange (especially the third vs. the second line). We chose to store the filenames of your samples in a cell array. This allows us to store character arrays of different lengths together in one variable, but cell arrays can also be a little confusing *because* they are so flexible as information storage. Luckily, Matlab's internal text-focused functions can and do handle it for us. Long story short, read more [here](https://www.mathworks.com/help/matlab/cell-arrays.html) if you are completely unfamiliar with this.

%[appendix]{"version":"1.0"}
%---
%[metadata:styles]
%   data: {"title":{"bold":true}}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":40}
%---
