function data = importscans(filePattern,status,options)
% <a href = "matlab:drEEMtoolbox.doc('importscans')">data = importscans(filePattern,options) (click to access documentation)</a>
%
% <strong>Import supplementary 1D scans (m/z spectra, distinct 2D emission scans, bacterial abundances and more)</strong> and create drEEMdataset
%
% <strong>INPUTS - Required</strong>
% filePattern (1,:)     {mustBeText}
% 
% <strong>INPUTS - Optional</strong>
% status (1,1) {mustBeA(drEEMstatus)} = drEEMstatus
% 
% axisColumn (1,:)      {mustBeNumeric} = 1
% spectrumColumn (1,:)       {mustBeNumeric} = 2
% NumHeaderLines (1,1)  {mustBeNumeric}= 0
%
% <strong>EXAMPLE(S)</strong>
%   1. <strong>Horiba AquaLog - Import 2D Raman scans</strong>
%       scans = tbx.importscans("* - Emission Graph.dat");
%
% <a href = "matlab:drEEMtoolbox.doc('importscans')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
        % Required
        filePattern (1,:) {mustBeText}

        % Status
        status (1,1) {mustBeA(status,'drEEMstatus')} = drEEMstatus;

        % Optional
        options.axisColumn (1,:) {mustBeNumeric} = 1
        options.spectrumColumn (1,:) {mustBeNumeric} = 2
        options.NumHeaderLines (1,1) {mustBeNumeric}= 0
        options.changeStatusMessage (1,:) {mustBeText} = 'New supplementary axis dataset.';

        
end

ST = dbstack;
if numel(ST)>1
    silent = true;
else
    silent = false;
end

% Diagnostic mode feature
if nargout>0
    nargoutchk(1,1)
    diagnostic=false;
else
    if not(silent)
        disp('<strong>Diagnostic mode</strong> to test whether options work as intended.')
    end
    diagnostic=true;
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
    axis=x(:,options.axisColumn);
    spectrum=x(:,options.spectrumColumn);

    

    % Sort ascending
    [ ~ ,iRow] = sort(axis,"ascend");
    spectrum=spectrum(iRow);
    axis=axis(iRow);
    del=isnan(spectrum)|isnan(axis);
    spectrum(del)=[];
    axis(del)=[];

    axis4Check{j}=axis;
    % Check axis against first version. Same assumptions as in
    % importeems.m, check that function to learn more.
    if not(isequal(axis4Check{1},axis))
        warning(['File ',files(j).name,': Missmatch in the axis column dimensions (compared to 1st file). Skipped...'])
        continue
    else
        data.suppSpectra(cnt,:)=spectrum;
        filelist{cnt,1}=strtrim(erase(files(j).name,erase(filePattern,'*')));
        data.i(cnt,1)=j; % this will leave a hint if an import did not work
        
        % message (optional, could be deleted)
        tc=toc(tc);
        ttl=num2str(numel(files));
        remain=num2str(round(tc.*(numel(files)-j),2));
        if not(diagnostic)&&not(silent)
            disp([num2str(j),'/',ttl,': ',filelist{cnt,1},...
                ' (',remain,' sec. remaining)'])
        end
        cnt=cnt+1;
    end
end

% move filelist into the dataset
data.filelist=filelist;

% Assign the final fields and finish up
data.suppSpectraAxis=rcvec(axis,'column');
data.nSample=size(data.suppSpectra,1);
data.metadata.i=data.i;

data.status=status;

% Validate the dataset
data.validate(data);

if not(diagnostic)
    % User needs to tell the toolbox what the status of the dataset is.
    % But only if the status contains unknowns

    warning off
    statusentries=drEEMstatus.getCurrent(data.status);
    statusentries=statusentries(8); % Only the suppSpectra one!
    warning on
    call_gui=any(contains(statusentries,"unknown"));

    if call_gui
        handle=dreemgui.setstatus_dreem(data,'data',options.changeStatusMessage);
        options=rmfield(options,'changeStatusMessage');
        waitfor(handle,"finishedHere",true);
        try
            data=handle.data;
            delete(handle)
        catch
            error('setstatus closed before save & exit button was pushed.')
        end
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
                culpritsz=str2num(cats{counts==1});
                culprit=sz(:,j)==culpritsz;
                culpritname=filenames{culprit};

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