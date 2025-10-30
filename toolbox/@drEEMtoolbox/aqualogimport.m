function Xout = aqualogimport(workingpath,file,selector,deselector)
% This function is part of undocumented drEEM and not intended for general use

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
%% Establish a connection to Origin Pro
try
    disp('   Establishing connection with Origin Pro (1st attempt)...')
    originObj = actxserver('Origin.ApplicationSI');
    invoke(originObj, 'Execute', 'Save');
    invoke(originObj, 'IsModified', 'false');
    disp('   1st attempt worked. That''s great.')
catch
    disp('   1st attempt failed. Establishing connection with Origin Pro by jumpstarting the software from within Matlab (2nd attempt)...')
    try
        oldpath=pwd;
        oldspath=path;
        addpath(genpath('C:\Program Files\OriginLab'));
        p=erase(which('Origin64.exe'),'Origin64.exe');
        if isempty(p)
            error('   Cannot start Origin64.exe through the actxserver method OR manaully by searching the path "C:\Program Files\OriginLab". Is it installed???')
        end
        cd(p)
        system("Origin64.exe -minimized &");
        disp('   Waiting for 10s to see if Origin Pro started (this takes time on some computers).')
        pause(10)
        cd(oldpath)
        path(oldspath)
        originObj = actxserver('Origin.ApplicationSI');
        invoke(originObj, 'Execute', 'Save');
        invoke(originObj, 'IsModified', 'false');
        disp('   2nd attempt worked. You''lucky today.')
    catch ME
        disp(ME)
        error('   Could not establish connection with the Origin ACTX server after trying with two different methodologies.')
    end
end
disp(' ')

% This makes the session visible. Useful for troubleshooting
%     originObj.Execute('doc -mc 1;');

% Cleanup function makes sure to close the origin Session (otherwise this
% creates chaos if the function opens another session).
try 
    c1 = onCleanup(@() originObj.Exit);
catch
    warning('   Please manually exit Origin Pro with the Task Manager if error occurs.')
end
%% Finding files
disp('   Importing samples...')
if not(exist('file','var'))
    disp('   Idefify projects/samples to import (*.ogw first)')
    oldpath=pwd;
    patt='*.ogw';
    if not(contains(workingpath,patt(2:end)))
        cd(workingpath)
        pattern=patt;
    else
        cd(fileparts(workingpath))
        pattern=erase(workingpath,{fileparts(workingpath),filesep});
    end    
    
    
    clearvars DS
    files=dir(pattern);
    
    if numel(files)==0
        disp(['   No ',pattern,' files found.'])
        if matches(pattern,'*.ogw')
            pattern='*.opj';
        else
            pattern='*.ogw';
        end
        disp(['   Trying to find',pattern,' files instead.'])
        files=dir(pattern);
    
    end
else
    [filepath,name,ext]=fileparts(file);
    files.folder=filepath;
    files.name=[char(name),char(ext)];
    pattern=char(ext);
    oldpath=pwd;
end


if numel(files)==0
    disp('   Still no files found. Exiting (with an empty dataset structure)...')
    Xout=struct;
    return
end

disp(' ')
disp(['   Reading out the ',pattern,' files'])



%% Reading out files
wb1 = waitbar(0,'Projects progress...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
try
    c2 = onCleanup(@() wb1.delete);
catch
end
% Preallocate some variables
usefile       = false(numel(files),1);
n_attempt     = zeros(numel(files),1);
nbooks        = zeros(numel(files),1);
grabsample    = cell(numel(files),1);
workbookNames = cell(numel(files),1);
opjname       = cell(numel(files),1);
wsdata        = cell(numel(files),1);
sampletype    = cell(numel(files),1);

tstart=tic;
for j=1:numel(files)
    if getappdata(wb1,'canceling')
        disp('   import stopped by user')
        invoke(originObj, 'Exit');
        wb1.delete;
        Xout=[];
        return
    end
    try waitbar(j/numel(files),wb1,['Project  ',num2str(j),' / ',num2str(numel(files))]),end %#ok<TRYNC>
    usefile(j,1)=true;
    n_attempt(j,1)=0;
    while n_attempt(j,1)<10
        try
           
            originObj.Load(strcat(files(j).folder,filesep,files(j).name));
            
            workbooksHandle = originObj.WorksheetPages; % Handle to the workbooks
            nbooks(j,1) = workbooksHandle.Count;
            if nbooks(j,1)>0
                n_attempt(j,1)=12;
            else
                error('No workbooks')
            end
            
        catch ME
            n_attempt(j,1) = n_attempt(j,1)+1;
            pause(rand(1)/16);
            if n_attempt(j,1)>=10
                disp(ME)
                disp(['Tried but failed to access',strcat(files(j).folder,filesep,files(j).name)])
                usefile(j,1)=false;
            end
        end
    end


    if usefile(j,1)
        grabsample{j,1} = false(nbooks(j,1),1);
        workbookNames{j,1}=cell(nbooks(j,1),1);
        for k=0:nbooks(j,1)-1
            wbh = get(workbooksHandle,'Item',uint8(k)); % Handle to workbook b
            % .ogw's will sometimes not have a valid long name, just use
            % the filename instead. We don't use it for accessing the
            % workbook anyways.
            if matches(pattern,"*.ogw")
                workbookName = get(wbh,'Name'); % Short name of workbook b
                workbookNameL=erase(files(j).name,pattern(2:end));
            else
                workbookName = get(wbh,'Name'); % Short name of workbook b
                workbookNameL = get(wbh,'LongName'); % Long name of workbook b
            end
            workbookNames{j}{k+1} = workbookNameL;
            opjname{j}{k+1} = files(j).name;
            
            try
                notes = invoke(originObj,'GetWorksheet',sprintf('[%s]%s',workbookName,'Note')); % Get worksheet data

                notes=strsplit(notes{1},'\n');
                notes=erase(notes(contains(notes,'Experiment Type: ')),'Experiment Type: ');

                if contains(notes,'3D Acquisition')||contains(notes,'[EEM 3D CCD + Absorbance]')
                    grabsample{j}(k+1,1)=true;
                    if contains(notes,'3D Acquisition')
                        sampletype{j}(k+1,1)=categorical(cellstr('EEM'));
                    else
                        sampletype{j}(k+1,1)=categorical(cellstr('ABS'));
                    end
                else
                    grabsample{j}(k+1,1)=false;
                    sampletype{j}(k+1,1)=categorical(cellstr('not'));
                end
            catch
                grabsample{j}(k+1,1)=false;
                sampletype{j}(k+1,1)=categorical(cellstr('not'));
            end
            
            if grabsample{j}(k+1,1)
                worksheetsHandle = get(wbh,'layers'); % Handle to worksheets of workbook b
                nsheets = get(worksheetsHandle,'Count'); % Number of sheets in workbook b
                for s = 0:nsheets-1 % Loop all worksheets
                    worksheetHandle = get(worksheetsHandle,'Item',uint8(s)); % Handle to sheet s
                    worksheetName = get(worksheetHandle,'Name'); % Short name of sheet s
                    wsdata{j}{k+1}.(erase(worksheetName,{' ','/','-',':','_'})) = invoke(originObj,'GetWorksheet',sprintf('[%s]%s',workbookName,worksheetName)); % Get worksheet data
                end
                release(worksheetHandle);
            end
            
        end
        % .ogw's will only have one sample per project and the table output
        % makes no sense. Display filename instead.
        if not(matches(pattern,"*.ogw"))
            t=table;
            t.workbookName=grabsample{j};
            t.sampleType=sampletype{j};
            t.Properties.VariableNames={[files(j).name,': Extract'],'Sample type'};
            t.Properties.RowNames=workbookNames{j};
            disp(t)
        else
            disp(files(j).name)
        end
    end
    release(workbooksHandle)
    % .ogw's will be accumulated, so we need a new project in that case
    if matches(pattern,'*.ogw')
        originObj.NewProject;
    end
end
wb1.delete;
invoke(originObj, 'Exit');

tstop=toc(tstart);
disp(['   Import took ',num2str(round(tstop./60,2)),' minutes.'])
disp(' ')
s_sum=0;
for j=1:numel(usefile)
    if not(any(grabsample{j}))
        usefile(j,1)=false;
    end
    s_sum=s_sum+sum(grabsample{j});
end

disp(['   Found ',num2str(s_sum),' samples in ',num2str(sum(usefile)),' of ',num2str(numel(usefile)),' projects'])


wsdata = wsdata(usefile);
workbookNames = workbookNames(usefile);
grabsample = grabsample(usefile);
opjname = opjname(usefile);
sampletype = sampletype(usefile);
for j=1:numel(grabsample)
    try
        wsdata{j} = wsdata{j}(grabsample{j});
        workbookNames{j} = workbookNames{j}(grabsample{j});
        opjname{j} = opjname{j}(grabsample{j});
        sampletype{j} = sampletype{j}(grabsample{j});

%         wsdata{j}(grabsample{j});
%         workbookNames{j}(grabsample{j});
%         opjname{j}(grabsample{j});
%         sampletype{j}(grabsample{j});
    catch
        error(['Something when wrong here:  ' char(categorical(unique(opjname{j})))])
    end
end


alldata = horzcat(wsdata{:})';
workbookNames = vertcat(workbookNames{:});
opjname = horzcat(opjname{:})';
sampletype = vertcat(sampletype{:});

%% Time for a little cleanup
cd(oldpath)
clearvars -except alldata workbookNames opjname sampletype workingpath selector

%% Now digest the data and transform
disp('   Digisting the read-out data and converting them into a single dataset')

% Delete blanks (no sample fluorescence or absorbance measured) 
blanksamples    = cellfun(@(x) not(any(contains(fieldnames(x),'Blank'))),alldata);

% Hidden option to select for certain samples
if exist('selector','var')
    takesamples     = contains(lower(workbookNames),lower(selector));
else
    takesamples     = true(numel(blanksamples),1);
end

if exist('noselector','var')
    notakesamples     = contains(lower(workbookNames),lower(deselector));
else
    notakesamples     = false(numel(blanksamples),1);
end


blanksamples    = blanksamples|not(takesamples)|notakesamples;

alldata         = alldata(not(blanksamples));
workbookNames   = workbookNames(not(blanksamples));
opjname         = opjname(not(blanksamples));
sampletype      = sampletype(not(blanksamples));

disp(['   Found ',num2str(sum(blanksamples)),' blanks and excluded them'])

eemdata=alldata(sampletype=='EEM');
absdata=alldata(sampletype=='ABS');

workbookNames_eem = workbookNames(sampletype=='EEM');
opjname_eem       = opjname(sampletype=='EEM');

workbookNames_abs = workbookNames(sampletype=='ABS');
opjname_abs       = opjname(sampletype=='ABS');

for j=1:numel(eemdata)
    data = eemdata{j};
    sheetnames={'AbsSpectrumSample','AbsSpectrumBlank','S1Blank','S1DarkandMcorrectBlank',...
            'R1andR1cBlank','S1Sample','S1DarkandMcorrectSample',...
            'R1andR1cSample','Note'};
    for k=1:numel(sheetnames)
        switch sheetnames{k}
            case 'AbsSpectrumSample'
                try
                    worksheetData = data.('AbsSpectrumSample');
                catch
                    continue
                end
                x=[worksheetData{:,1}]';
                y=[worksheetData{:,2}]';
                ybackup=[worksheetData{:,10}]';
                % Take care to have increasing wavelengths.
                [~,i]=sort(x);
                x=x(i);
                y=y(i);
                ybackup=ybackup(i);
                    Xout.AbsI1darkSample(j,1)=worksheetData{1,3};
                try
                    Xout.Abs_horiba(j,:) = ybackup';
                    Xout.AbsI1Sample(j,:) = y';
                    Xout.Abs_wave = x;
                catch
                    error(' Error, likely due to incompatible measurement settings')
                end
            case 'AbsSpectrumBlank'
                try
                    worksheetData = data.('AbsSpectrumBlank');
                catch
                    continue
                end
                x=[worksheetData{:,1}]';
                y=[worksheetData{:,2}]';
                % Take care to have increasing wavelengths.
                [~,i]=sort(x);
                x=x(i);
                y=y(i);
                Xout.AbsI1darkBlank(j,1)=worksheetData{1,3};
                try
                    Xout.AbsI1Blank(j,:) = y';
                    Xout.Abs_wave = x;
                catch
                    error(' Error, likely due to incompatible measurement settings')
                end
            case 'S1Blank'
                try
                    worksheetData = data.('S1Blank');
                catch
                    continue
                end
                em=[worksheetData{:,1}]';
                dat=cell2mat(worksheetData(:,2:end));
                
                Xout.Ex=Xout.Abs_wave;
                Xout.Em=em;
                Xout.S1Blank(j,:,:)=flip(dat,2);
            case 'S1DarkandMcorrectBlank'
                try
                    worksheetData = data.('S1DarkandMcorrectBlank');
                catch
                    continue
                end
                Xout.S1DarkBlank(j,:)=[worksheetData{:,2}]';
                Xout.MCorrect(j,:)=[worksheetData{:,3}]';
                
            case 'R1andR1cBlank'
                try
                    worksheetData = data.('R1andR1cBlank');
                catch
                    continue
                end
                Xout.R1Blank(j,:)=flip([worksheetData{:,2}]');
                Xout.AbsR1Blank(j,:)=Xout.R1Blank(j,:);
                Xout.R1DarkBlank(j,1)=[worksheetData{1,3}]';
                Xout.AbsR1darkBlank(j,1)=Xout.R1DarkBlank(j,1);
                Xout.XCorrect(j,:)=flip([worksheetData{:,4}]');
                Xout.AbsXCorrect(j,:)=Xout.XCorrect(j,:);
                
            case 'S1Sample'
                try
                    worksheetData = data.('S1Sample');
                catch
                    continue
                end
                dat=cell2mat(worksheetData(:,2:end));
                Xout.S1Sample(j,:,:)=flip(dat,2);
            case 'S1DarkandMcorrectSample'
                try
                    worksheetData = data.('S1DarkandMcorrectSample');
                catch
                    continue
                end
                Xout.S1DarkSample(j,:)=[worksheetData{:,2}]';
                
            case 'R1andR1cSample'
                try
                    worksheetData = data.('R1andR1cSample');
                catch
                    continue
                end
                Xout.R1Sample(j,:)=flip([worksheetData{:,2}]');
                Xout.AbsR1Sample(j,:)=Xout.R1Sample(j,:);
                Xout.R1DarkSample(j,1)=[worksheetData{1,3}]';
                Xout.AbsR1darkSample(j,1)=Xout.R1DarkSample(j,1);
            case 'Note'
                worksheetData = data.('Note');
                
                % Integration time
                try
                    temp=strsplit(worksheetData{1},'\n');
                    temp=erase(temp(contains(temp,'Integration Time: ')),'Integration Time: ');
                    if not(any(contains(temp,'s')))
                        Xout.integrationtime(j,:)=str2double(temp{1});
                    else
                        Xout.integrationtime(j,:)=str2double(temp{1}(1:end-2));
                    end
                catch
                end

                % Em park position
                try
                    temp=strsplit(worksheetData{1},'\n');
                    temp=erase(temp(contains(temp,'Park: ')),'Park: ');
                    if not(isempty(temp))
                        Xout.Em_parkpos(j,1)=str2double(temp{1}(1:end-3));
                    else
                        Xout.Em_parkpos(j,1)=nan;
                    end
                catch
                end

                % Em pixel binning
                try
                    temp=strsplit(worksheetData{1},'\n');
                    temp=temp(contains(temp,'XStart:'));
                    if not(isempty(temp))
                        Xout.Em_PixelBin(j,1)=str2double(temp{1}(strfind(temp{1},'XBin')+5));
                    else
                        Xout.Em_PixelBin(j,1)=nan;
                    end
                catch
                end
                
                % CCD gain
                try
                    temp=strsplit(worksheetData{1},'\n');
                    temp1=temp(contains(temp,'ADC: '));
                    temp=temp(contains(temp,'Gain: '));
                    if matches(temp1{1}(1:end-1),'ADC: 500 kHz R')&&matches(temp{1}(1:end-1),'Gain: ADC Gain / 1.00')
                        Xout.CCD_gain(j,1)=1;
                    elseif matches(temp1{1}(1:end-1),'ADC: 500 kHz G')&&matches(temp{1}(1:end-1),'Gain: ADC Gain / 1.00')
                        Xout.CCD_gain(j,1)=2;
                    elseif matches(temp1{1}(1:end-1),'ADC: 500 kHz G')&&matches(temp{1}(1:end-1),'Gain: ADC Gain / 2.00')
                        Xout.CCD_gain(j,1)=4;
                    else
                        Xout.CCD_gain(j,1)=nan;
                        
                    end
                catch
                end
        end
    end
    Xout.filelist{j,1}=workbookNames_eem{j};
    Xout.opjfile{j,1}=[workingpath,filesep,opjname_eem{j}];
end


for j=1:numel(absdata)
    data = absdata{j};
    sheetnames={'AbsSpectrumSample','AbsSpectrumBlank','Note'};
    for k=1:numel(sheetnames)
        switch sheetnames{k}
            case 'AbsSpectrumSample'
                try
                    worksheetData = data.('AbsSpectrumSample');
                catch
                    continue
                end
                x=[worksheetData{:,1}]';
                y=[worksheetData{:,2}]';
                y1=[worksheetData{:,4}]';
                ybackup=[worksheetData{:,10}]';
                % Take care to have increasing wavelengths.
                [~,i]=sort(x);
                x=x(i);
                y=y(i);
                y1=y1(i);
                ybackup=ybackup(i);
                Xout.abs.AbsI1darkSample(j,1)=worksheetData{1,3};
                Xout.abs.AbsR1darkSample(j,1)=worksheetData{1,5};
                try
                    Xout.Abs.Abs_horiba(j,:) = ybackup';
                    Xout.Abs.AbsI1Sample(j,:) = y';
                    Xout.Abs.AbsR1Sample(j,:) = y1';
                    Xout.Abs.Abs_wave = x;
                catch
                    error(' Error, likely due to incompatible measurement settings')
                end
            case 'AbsSpectrumBlank'
                try
                    worksheetData = data.('AbsSpectrumBlank');
                catch
                    continue
                end
                x=[worksheetData{:,1}]';
                y=[worksheetData{:,2}]';
                y1=[worksheetData{:,4}]';
                y2=[worksheetData{:,6}];
                % Take care to have increasing wavelengths.
                [~,i]=sort(x);
                x=x(i);
                y=y(i);
                y1=y1(i);
                y2=y2(i);
                Xout.Abs.AbsI1darkBlank(j,1)=worksheetData{1,3};
                Xout.Abs.AbsR1darkBlank(j,1)=worksheetData{1,5};
                try
                    Xout.Abs.AbsI1Blank(j,:) = y';
                    Xout.Abs.AbsR1Blank(j,:) = y1';
                    Xout.Abs.AbsXCorrect(j,:) = y2';
                    Xout.Abs.Abs_wave = x;
                catch
                    error(' Error, likely due to incompatible measurement settings')
                end
            case 'Note'
                worksheetData = data.('Note');
                
                % Integration time
                try
                    temp=strsplit(worksheetData{1},'\n');
                    temp=erase(temp(contains(temp,'Integration Time: ')),'Integration Time: ');
                    if not(any(contains(temp,'s')))
                        Xout.Abs.integrationtime(j,:)=str2double(temp{1});
                    else
                        Xout.Abs.integrationtime(j,:)=str2double(temp{1}(1:end-2));
                    end
                catch
                end
        end
    end
    Xout.Abs.filelist{j,1}=workbookNames_abs{j};
    Xout.Abs.opjfile{j,1}=[workingpath,filesep,opjname_abs{j}];
end
Xout.nSample=size(Xout.S1Sample,1);


%% Time for a little cleanup
clearvars -except Xout path

%% Addtitional absorbance business (if needed) 
if isfield(Xout,'Abs')
   Xout.Abs.nSample=numel(Xout.Abs.filelist);
   trytoalign=true;
else
    trytoalign=false;
end


if trytoalign
    disp(' ')
    disp('   Detected separate absorbance and fluorescence measurements.')
    disp('   Attempting to merge both by their filename')
end

try
if trytoalign
    eemfl=Xout.filelist;
    absfl=Xout.Abs.filelist;
    
    eemfl = cellfun(@(x) x{1},cellfun(@(x) strsplit(x,' ('),eemfl,'UniformOutput',false),'UniformOutput',false);
    absfl = cellfun(@(x) x{1},cellfun(@(x) strsplit(x,' ('),absfl,'UniformOutput',false),'UniformOutput',false);

    [~,ia,ib] = intersect(eemfl,absfl,'stable');

    flds={'AbsI1darkSample','AbsR1darkSample','Abs_horiba','AbsI1Sample','AbsR1Sample'...
            'AbsI1darkBlank','AbsR1darkBlank','AbsI1Blank','AbsR1Blank','AbsXCorrect'};
    for j=1:numel(flds)
        try %#ok<TRYNC> 
            Xout=rmfield(Xout,flds{j});
        end
        Xout.(flds{j})(ia,:)=Xout.Abs.(flds{j})(ib,:);
    end
    Xout.Abs_wave=Xout.Abs.Abs_wave;
    Xout=rmfield(Xout,'Abs');
end
catch
    disp('   Merging failed. Absorbance data stored in .Abs')
end
disp(' ')

disp('   Done.')
end