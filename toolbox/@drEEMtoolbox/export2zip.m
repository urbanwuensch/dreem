function export2zip(data,filename)
% <a href = "matlab:drEEMtoolbox.doc('export2zip')"">export2zip(data,filename) (click to access documentation)</a>
%
% <strong>Export entire dataset</strong> in accordance to FAIR principles
%
% <strong>INPUTS - Required</strong>
% data (1,1)      {mustBeA("drEEMdataset"),drEEMdataset.validate}
% filename (1,:)  {mustBeText}
%
% <strong>EXAMPLE(S)</strong>
%   1. Export sample and blank EEMs, dataset status, history, and
%   processing steps to a zip file including README.txt for upload to data  repository
%       tbx.export2zip(samples,'project_XY_asPublished',char(datetime('today'))]);
%
% <a href = "matlab:drEEMtoolbox.doc('export2zip')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.validate(data)}
    filename (1,:) {mustBeText}
end
rootdir=pwd;
% Take care of pre-export data stuff
% Reverse scaling (if needed)
if contains(lower(data.status.signalScaling),'scaled to')
    data=drEEMtoolbox.scalesamples(data,'reverse');
end
% Add an entry to include the export as an action
idx=height(data.history)+1;
data.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'exported data to zip file',[],data);


% Digest filename
filename=[char(erase(filename,'.zip')),'.zip'];

% delete file if already exists
if exist(filename,"file")
    delete(filename)
end

% Prepare temp folder for the export
disp('<strong> Writing to temporary directory</strong>')
tempfolder='drEEMexportTemporary';
mkdir(tempfolder)

cd(tempfolder)

% Export dataset history
% disp(['<strong> Writing to file: ',filename,'</strong>'])
t=historyConverter(data);
writetable(t,'dataset_history.xlsx',"FileType",'spreadsheet')
disp('    Finished file: dataset_history.xlsx')

% Export dataset status
flds=fieldnames(data.status);
stat=table;
warning off
for j=1:numel(flds)
    stat.Aspect{j}=flds{j};
    stat.Status{j}=data.status.(flds{j});
end
stat.Step={'Spectral correction';...
    'Inner filter effect correction';...
    'Blank subtraction';...
    'Fluorescence signal calibration';...
    'Scatter treatment';...
    'Fluorescence signal scaling';...
    'Absorbance unit'};
stat.Aspect=[];
stat=stat(:,[2 1]);
warning on
writetable(stat,'dataset_status.csv',...
    "WriteMode","overwrite")
disp('    Finished file: dataset_status.csv')
% Export dataset scatter treatment
scatter_i=drEEMhistory.searchhistory(data.history,'handlescatter','all');

if isempty(scatter_i)
    % Do nothing
else
    start=1:3:3*numel(scatter_i);
    for j=1:numel(scatter_i)
        details=data.history(scatter_i(j)).details;
        warning off
        details=struct(details);
        warning on
        details=struct2table(details);

        details.plot=[];details.plottype=[];
        details.description=['handlescatter executed on ',char(data.history(scatter_i(j)).timestamp)];
        details.Properties.VariableNames=...
            {'Scatter deleted (Ray/Ram 1st/2nd)',...
            'Scatter interpolated (Ray/Ram 1st/2nd)',...
            'Negative fluorescence zero''ed',...
            'Rayleigh 1st (below,above)',...
            'Raman 1st (below,above)',...
            'Rayleigh 2nd (below,above)',...
            'Raman 2nd (below,above)',...
            'nm below Rayleigh 1st zero''ed',...
            'interpolation method',...
            'interpolation approach',...
            'samples',...
            'date / time'};
        varNames=details.Properties.VariableNames;
        for k=1:numel(varNames)
            details.(varNames{k})=num2str(details.(varNames{k}));
        end
        writetable(details,'dataset_scatterRemovalParameters.xlsx',"FileType","spreadsheet",...
            "WriteMode","inplace",...
            "Range",['A',num2str(start(j))],"PreserveFormat",true)

        % writetable(details,'dataset_scatterRemovalParameters.csv',...
        %     "WriteMode","overwrite")

    end
end
disp('    Finished file: dataset_scatterRemovalParameters.xlsx')
% Export optical metadata
warning off
data=drEEMtoolbox.fitslopes(data,quiet=true);
data=drEEMtoolbox.pickpeaks(data,quiet=true);
pl=table;
pl.filelist=data.filelist;
pl=[pl data.opticalMetadata];
writetable(pl,'dataset_opticalIndiciesAndPeakIntensities.csv',...
    "WriteMode","overwrite")
warning on
disp('    Finished file: dataset_opticalIndiciesAndPeakIntensities.csv')


% Export metadata
warning off
pl=table;
if not(matches(data.metadata.Properties.VariableNames,'filelist'));
    pl.filelist=data.filelist;
    pl=[pl data.metadata];
else
    pl=data.metadata;
end
writetable(pl,'dataset_metadata.csv',...
    "WriteMode","overwrite")
warning on
disp('    Finished file: dataset_metadata.csv')

% Export toolbox data
pl=struct2table(data.toolboxdata);
try pl.matlabToolboxes=[];end %#ok<*TRYNC>
try pl.settings=[];end
try pl.uifig=[];end

writetable(pl,'drEEM_versionInformation.csv',...
    "WriteMode","overwrite")
disp('    Finished file: drEEM_versionInformation.csv')

% Make readme
T=["The contents of this file was created with the drEEM toolbox for Matlab",newline,...
    newline,...
    "FOLDER INFORMATION",newline,...
    "The folder 'EEMs' contains fluorescence EEMs with emission wavelengths as rows and excitation wavelengths as columns.",newline,...
    "If blank EEMs were subtracted by the toolbox (and only then), these will be provided as an additional file, same filename with an '_blank' added before the '.csv'.",newline,...
    "The folder 'absorbance' spectra contains wavelengths in column 1 and absorbance data in column 2. The unit is specified in column 2 header.",newline,...
    "",newline,...
    "PROCESSING / STATUS INFORMATION",newline,...
    "Any processing of the data done by the toolbox is documented in the file 'dataset_history.csv'",newline,...
    "If scatter was removed by the toolbox, the settings for the removal are stored in the file 'dataset_scatterRemovalParameters.csv'",newline,...
    "The general status of the dataset (signal calibration, spectral correction, and more) is provided in the file 'dataset_status.csv'",newline,...
    "",newline,...
    "ENVIRONMENTAL / OPTICAL METADATA",newline,...
    "The DOM-specific optical indicies, peaks, and CDOM slopes are provided in the file 'dataset_opticalIndiciesAndPeakIntensities.csv'",newline,...
    "If provided, other metadata is stored in the file 'dataset_metadata.csv'",newline,...
    "",newline,...
    "OTHER",newline,...
    "For convenience of Matlab users, the dataset is also provided as .mat file 'dataset_dreem.mat'",newline,...
    "Information regarding the version of Matlab used and the drEEM toolbox is stored in 'drEEM_versionInformation.csv'",newline,...
    "",newline...
    "THIS IS THE END OF THIS FILE."]; 
FN = 'README.txt';  % better to use fullfile(path,name) 
fid = fopen(FN,'w');    % open file for writing (overwrite if necessary)
fprintf(fid,'%s',T);          % Write the char array, interpret newline as new line
fclose(fid);                  % Close the file (important)
disp('    Finished file: README.txt')

% export dataset as mat file.
warning off
temp=struct(data);
temp2=rmfield(temp,{'history','models','split','status'});
for j=1:numel(temp.history)
    temp2.history(j,1)=struct(temp.history(j));
end
for j=1:numel(temp.models)
    temp2.models(j,1)=struct(temp.models(j));
end
for j=1:numel(temp.split)
    temp2.split(j,1)=struct(temp.split(j));
end
temp2.status=struct(temp.status);
warning on
dataExported=temp2;
clearvars temp temp2
save("dataset_dreem.mat","dataExported")
disp('    Finished file: dataset_dreem.mat')

% export EEMs as csv's
mkdir('EEMs')
cd('EEMs')
for j=1:data.nSample

    eem=squeeze(data.X(j,:,:));

    eem=[data.Em,eem];
    eem=[nan,data.Ex';eem];
    writematrix(eem,[data.filelist{j},'.csv'],"Delimiter",',','WriteMode','overwrite')

    if not(isempty(data.XBlank))
        eem=squeeze(data.XBlank(j,:,:));

        eem=[data.Em,eem];
        eem=[nan,data.Ex';eem];
        writematrix(eem,[data.filelist{j},'_blank.csv'],"Delimiter",',','WriteMode','overwrite')
    end

end
disp('    Finished files: Sample (and Blanks if available) EEMs')
cd ..

% export Absorbance as csv's
if not(isempty(data.abs))
    mkdir('absorbance spectra')
    cd('absorbance spectra')
    for j=1:data.nSample
    
        absData=data.abs(j,:)';
    
        absData=[data.absWave,absData];
        absData=array2table(absData,"VariableNames",{'wavelength',char(data.status.absorbanceUnit)});
        writetable(absData,[data.filelist{j},'.csv'],"Delimiter",',','WriteMode','overwrite')
    end
    disp('    Finished files: Absorbance spectra')
end
cd ..
zip(filename,{'absorbance spectra','EEMs','*.csv','*.mat','*.txt','*.xlsx'});
movefile([pwd,filesep,filename],[rootdir,filesep,filename])
disp(['    Finished files: ',filename])
cd(rootdir)
rmdir("drEEMexportTemporary",'s')
disp('    Removed temporary directory.')
disp('<strong> Success! Done with export.</strong>')

drEEMtoolbox.displaycitationinformation

end


function tbl=historyConverter(data)
arguments
    data {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
end

t=drEEMhistory.convert2table(data.history);

tno=table((1:height(t))',VariableNames={'#'});
t=[tno,t];
history=t;
%history=struct2table(history);
%{'timestamp','fname','fmessage','details','backup','previous','usercomment'}
history=history(:,[1:4 8]);

% Work in progress for multiple entries
tbl=history;
count=1;
while count<=height(tbl)
    % store the comments separately
    cmts=string(tbl.usercomment{count});
    nCmts=numel(cmts);
    cnt=1;
    if nCmts==1
        %tbl.usercomment(count)=cmts;
    elseif nCmts>1
        % If multiple comments split the table
        t1=tbl(1:count,:);
        t2=tbl(count+1:end,:);
        % First table get's first comment
        t1.usercomment{count}=cmts(1);
        % First comment get's deleted
        cmts(1)=[];
        % interjected table gets created
        ti=t1; % Make it based on the 1st half
        ti=ti(count,:); % delete all but one row
        ti.usercomment={""};
        ti.timestamp=missing;
        ti.fname=""; % Just keeping the fname here for the moment.
        ti.fmessage="";
        hno=ti.("#");
        warning off
        while numel(cmts)>0
            ti.usercomment(cnt)={cmts(1)};
            % These things need to be repeated if more than one
            % additional comment is there
            ti.timestamp(cnt)=missing;
            ti.fname(cnt)=""; % Just keeping the fname here for the moment.
            ti.fmessage(cnt)="";
            ti.("#")(cnt)=hno;
            % delete the comment and increase the count
            cmts(1)=[];
            cnt = cnt + 1;
        end
        warning on
        tbl=[t1;ti;t2];
    end
    count=count+cnt;
end
tbl.timestamp=[];
tbl.Properties.VariableNames={'#','Function','Function message','User comment'};
tbl=tbl(:,[1 2 4 3]);

% Old (no multiple entry support)
% t.details=[];
% t.backup=[];
% t.previous=[];
% t.Properties.VariableNames={'Date/time','Function','Function message','User comment'};
% t.Function=categorical(t.Function);
% t.('Function message')=categorical(t.('Function message'));
% t.('#')=(1:height(t))';
% t=t(:,[end 1 2 4 3]);
% disp(t)


end