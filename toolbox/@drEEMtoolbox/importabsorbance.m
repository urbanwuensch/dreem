function data = importabsorbance(filePattern,options)
% <a href = "matlab:drEEMtoolbox.doc('importabsorbance')">data = importabsorbance(filePattern,options) (click to access documentation)</a>
%
% <strong>Import absorbance measurements</strong> and create drEEMdataset
%
% <strong>INPUTS - Required</strong>
% filePattern (1,:)     {mustBeText}
% 
% <strong>INPUTS - Optional</strong>
% waveColumn (1,:)      {mustBeNumeric} = 1
% absColumn (1,:)       {mustBeNumeric} = 10
% NumHeaderLines (1,1)  {mustBeNumeric}= 0
%
% <strong>EXAMPLE(S)</strong>
%   1. <strong>Horiba AquaLog</strong>
%       absorbance = tbx.importabsorbance("* - Abs Spectra Graphs.dat");
%   2. <strong>csv-export of data from software</strong>
%       absorbance = tbx.importabsorbance("*.csv",waveColumn=1,absColumn=2);
%
% <a href = "matlab:drEEMtoolbox.doc('importabsorbance')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
        % Required
        filePattern (1,:) {mustBeText}
        
        % Optional
        options.waveColumn (1,:) {mustBeNumeric} = 1
        options.absColumn (1,:) {mustBeNumeric} = 10
        options.NumHeaderLines (1,1) {mustBeNumeric}= 0
        options.changeStatusMessage (1,:) {mustBeText} = 'New absorbance dataset.';
end

ST = dbstack;
if numel(ST)>1
    silent = true;
else
    silent = false;
end

% Diagnostic mode feature
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(1,1)
        diagnostic=false;
    else
        if not(silent)
            disp('<strong>Diagnostic mode</strong> to test whether options work as intended.')
        end
        diagnostic=true;
    end
end



% Find files & throw error when none are found
files=dir(filePattern);
if isempty(files)
    error('File pattern not found. Check input and current directory.')
end


% Extract & diagnose wavelengths
if not(silent),disp('Checking wavelength integrity of data set'),end
sz=nan(numel(files),2);
for j=1:numel(files)
    x=readmatrix(files(j).name,...
        NumHeaderLines=options.NumHeaderLines);
    % Find size for diagnosis step
    sz(j,:)=size(x);
end

% Next line will fail if there is an issue with the dimensions of the files
diagnoseDimensionIssue({files.name}',sz)

% Create the drEEMdataset (fills in session-specific information)
data=drEEMdataset.create;
% Actual import run
cnt=1; % successful import counter.
for j=1:numel(files)
    tc=tic;
    % read in file
    x=readmatrix(files(j).name,...
        NumHeaderLines=options.NumHeaderLines);
    wave=x(:,options.waveColumn);
    abso=x(:,options.absColumn);

    

    % Sort ascending
    [ ~ ,iRow] = sort(wave,"ascend");
    abso=abso(iRow);
    wave=wave(iRow);
    del=isnan(abso)|isnan(wave);
    abso(del)=[];
    wave(del)=[];

    wave4Check{j}=wave;
    % Check wavelengths against first version. Same assumptions as in
    % importeems.m, check that function to learn more.
    if not(isequal(wave4Check{1},wave))
        warning(['File ',files(j).name,': Missmatch in the absorbance wavlengths (compared to 1st file). Skipped...'])
        continue
    else
        data.abs(cnt,:)=abso;
        filelist{cnt,1}=strtrim(erase(files(j).name,erase(filePattern,'*')));
        data.i(cnt,1)=j; % this will leave a hint if an import did not work
        cnt=cnt+1;

        % message (optional, could be deleted)
        tc=toc(tc);
        ttl=num2str(numel(files));
        remain=num2str(round(tc.*(numel(files)-j),2));
        if not(diagnostic)||not(silent)
            disp([num2str(j),'/',ttl,': ',filelist{j,1},...
                ' (',remain,' sec. remaining)'])
        end
    end
end

% move filelist into the dataset
data.filelist=filelist;

% Assign the final fields and finish up
data.absWave=rcvec(wave,'column');
data.nSample=size(data.abs,1);
data.metadata.i=data.i;
% data.metadata.filelist=data.filelist; % Disabled since it's redundant.

% Validate the dataset
data.validate(data);

if not(diagnostic)
    % User needs to tell the toolbox what the status of the dataset is.
    handle=dreemgui.setstatus_dreem(data,'data',options.changeStatusMessage);
    options=rmfield(options,'changeStatusMessage');
    waitfor(handle,"finishedHere",true);
    try
        data=handle.data;
        delete(handle)
    catch
        error('setstatus closed before save & exit button was pushed.')
        end
    % Make the drEEMhistory entry
    idx=1;
    data.history(idx,1)=...
        drEEMhistory.addEntry(mfilename,'created dataset',options,data);
else
    if nargout==0
        clearvars data
    end
    if not(silent)
        disp('<strong>Success.</strong> These options work. To go ahead with an import, you can assign an output argument now.')
    end
end

end

function [vout] = rcvec(v,rc)
% Make row or column vector
% v: vector
% rc: either 'row' ([1:5])or 'column' ([1:5]')
sz=size(v);
if ~any(sz==1)
    error('Input is not a vector')
end

switch rc
    case 'row'
        if ~[sz(1)<sz(2)]
            vout=v';
        else
            vout=v;
        end
    case 'column'
        if ~[sz(1)>sz(2)]
            vout=v';
        else
            vout=v;
        end
    otherwise
            error('Input ''rc'' not recognized. Options are: ''row'' and ''column''.')
end


end

function diagnoseDimensionIssue(filenames,sz)



if isscalar(unique(sz(:,1)))%&&isscalar(unique(sz(:,2)))
    %disp('Dimension check for files <strong>passed</strong>.')
else
    message='Dimension check for files <strong>not passed</strong>. Information follows ... \n\n';
    szident=["Rows","Columns"];
    for j=1:2
        sinf=(sz(:,j));
        if not(isscalar(unique(sinf))) % issue
            sinf=categorical(sinf);
            message=[message,'Issue with <strong>',char(szident(j)),'</strong> ...\n'];
            cats=categories(sinf);
            counts=countcats(sinf);

            if numel(counts)==2&ismember(1,counts)
                % One sample sticks out
                culpritsz=str2num(cats{counts==1})
                culprit=sz(:,j)==culpritsz;
                culpritname=filenames{culprit}

                message=[message,'<strong>One sample is the culprit </strong>(open & inspect): ',culpritname,'\n'];
            end
        else
            diagt=table;
            diagt.name=categorical(filenames);
            diagt.nrow=sz(:,1);
            message=[message,'<strong>Seems like a complex issue. Inspect the figure </strong>\n'];
            f=uifigure("Name",'Dimension issue: Inspect the table...');
            uit=uitable(f,Data=diagt,Units="normalized",OuterPosition=[0 0 1 1]);
        end
    end
    throwAsCaller(MException("drEEM:inCorrectFileDimensions",message))
end

end