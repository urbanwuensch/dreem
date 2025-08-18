cd(fileparts(matlab.desktop.editor.getActiveFilename))
%%
cd AutomaticSampleQ\
samples=importeems('*SEM.dat');
blanks=importeems('*BEM.dat');
% This line will trigger warnings (wrong options)
absorbance=importabsorbance('*ABS.dat','absColumn',1,'waveColumn',2,'NumHeaderLines',0);
% This is the correct import
absorbance=importabsorbance('*ABS.dat','absColumn',2,'waveColumn',1,'NumHeaderLines',0);

alignDatasets(samples,blanks,absorbance);
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))
%%
cd csv_flipped\
samples=importeems('*.csv','columnIsEx',false);
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))

%%
cd csv\
samples=importeems('*.csv');
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))


%%
cd csv2\
blanks=importeems('*-MilliQ.csv');
samples=importeems('*-Sample.csv');

alignDatasets(samples,blanks);
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))
%%
cd AquaLog_csv\
samples=importeems('*-Blank.csv');
blanks=importeems('*-Sample.csv');
absorbance=importabsorbance('*-Absorbance.csv','absColumn',2,'waveColumn',1,'NumHeaderLines',0);
alignDatasets(samples,blanks,absorbance);
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))
%%
cd AquaLog_sampleQ\
samples=importeems('*PEM.dat','NumHeaderLines',3,'colWave',800:-3:230);
% This line will trigger warnings (wrong options)
absorbance=importabsorbance('*ABS.dat','absColumn',2,'waveColumn',1,'NumHeaderLines',0);

clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))

%% 
cd(fileparts(matlab.desktop.editor.getActiveFilename))
cd csv_noaxis
samples=importeems('*.csv','colWave',220:5:550,rowWave=230:5:600);
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))

%% 
cd(fileparts(matlab.desktop.editor.getActiveFilename))
cd csv_flipped_noaxis\
samples=importeems('*.csv','columnIsEx',false,...
    'rowWave',220:5:550,colWave=230:5:600);
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))
