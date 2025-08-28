function data = importeems(filePattern,options)
% <a href = "matlab:drEEMtoolbox.doc('importeems')">data = importeems(filePattern,options) (click to access documentation)</a>
%
% <strong>Import fluorescence EEMs</strong> and create drEEMdataset
%
% <strong>INPUTS - Required</strong>
% filePattern (1,:)                 {mustBeText}
% 
% <strong>INPUTS - Optional</strong>
% columnWave (1,:)          {mustBeNumericOrLogical} = true
% rowWave (1,:)             {mustBeNumericOrLogical} = true
% columnIsExcitation (1,:)  {mustBeNumericOrLogical}= true
% NumHeaderLines (1,1)      {mustBeNumeric}= 0
% waveDiffTollerance (1,1)  {mustBeNumeric} = 1
%
% <strong>EXAMPLE(S)</strong>
%   1. <strong>Horiba AquaLog</strong>
%       blanks = tbx.importeems(" - Waterfall Plot Blank.dat");
%   2. <strong>Horiba FluoroMax</strong>
%       blanks=tbx.importeems('*.dat','columnIsExcitation',true,'columnWave',240:10:450);
%   2. <strong>Cary Eclipse</strong>
%       samples=tbx.importeems("*.csv","columnIsExcitation",true);
%   3. <strong>Jasco csv-files with large header</strong>
%       Not supported due to complex file format. Contact dreem@openfluor.net 
%
% <a href = "matlab:drEEMtoolbox.doc('importeems')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
        % Inputs - Required
        filePattern (1,:)                   {mustBeText}
        
        % Inputs - Optional
        options.columnWave (1,:)            {mustBeNumericOrLogical} = true
        options.rowWave (1,:)               {mustBeNumericOrLogical} = true
        options.columnIsExcitation (1,:)    {mustBeNumericOrLogical}= true
        options.NumHeaderLines (1,1)        {mustBeNumeric}= 0
        options.waveDiffTollerance (1,1)    {mustBeNumeric} = 1
        options.changeStatusMessage (1,:) {mustBeText} = 'New fluorescence dataset.';
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
    error('Found no files that it the pattern. Check input and current directory.')
end

% Extract axis values if not given in files
if isnumeric(options.columnWave)
    colAxis=options.columnWave;
end
if isnumeric(options.rowWave)
    rowAxis=options.rowWave;
end

% Extract & diagnose wavelengths
if not(silent),disp('Checking wavelength integrity of data set'),end
sz=nan(numel(files),2);
for j=1:numel(files)
    x=readmatrix(files(j).name,NumHeaderLines=options.NumHeaderLines);
    xorg=x;

    % extract axes
    if options.rowWave==true
        rowAxis=xorg(:,1);
        x=x(:,2:end);
    end
    if options.columnWave==true
        colAxis=xorg(1,:);
        x=x(2:end,:);
    end
    
    % remove empty cell
    colAxis(isnan(colAxis))=[];
    rowAxis(isnan(rowAxis))=[];

    % Check if sizes match (rows and columns)
    if not(size(x,1)==numel(rowAxis))
        error(['file: ',files(j).name,' size of EEM inconsistent with row axis information'])
    end
    if not(size(x,2)==numel(colAxis))
        error(['file: ',files(j).name,' size of EEM inconsistent with column axis information'])
    end
    
    % Store the size for later use.
    sz(j,:)=size(x);

end
% Next line will fail if there is an issue with the dimensions of the files
diagnoseDimensionIssue({files.name}',sz)

% All checks passed, now move on to import
data=drEEMdataset.create; % Create a drEEMdataset (fills in machine-specific info)
data.status=drEEMstatus; % Initiate the status field with the proper class
cnt=1; % Counter for successful imports.
for j=1:numel(files)
    tc=tic;
    
    % read in file
    x=readmatrix(files(j).name,NumHeaderLines=options.NumHeaderLines);
    xorg=x;

    % extract axes
    if options.rowWave==true
        rowAxis=xorg(:,1);
        x=x(:,2:end);
    end
    if options.columnWave==true
        colAxis=xorg(1,:);
        x=x(2:end,:);
    end
    
    % remove empty cell
    colAxis(isnan(colAxis))=[];
    rowAxis(isnan(rowAxis))=[];

    % Sort ascending
    [ ~ ,iCol] = sort(colAxis,"ascend");
    [ ~ ,iRow] = sort(rowAxis,"ascend");
    x=x(iRow,iCol);
    colAxis_sorted=colAxis(iCol);
    rowAxis_sorted=rowAxis(iRow);

    % Make sure the matrix is rotated as expected (requires user expertise)
    if options.columnIsExcitation==true
        ex=round(colAxis_sorted,1); % Round in case for some reason many digits are supplied;
        em=round(rowAxis_sorted,1); % Round in case for some reason many digits are supplied;
    else
        em=round(colAxis_sorted,1); % Round in case for some reason many digits are supplied;
        ex=round(rowAxis_sorted,1); % Round in case for some reason many digits are supplied;
        x=x';
    end
    
    % Store the wavelength information for double-check of axis info
    ex4Check{j}=ex;
    em4Check{j}=em;

    % Check the current axis against the first to troubleshoot
    % Assumption: 1st file is not corrupt. Import will essentially fail if
    % the first file is the/a bad one. Could be made better, but should be
    % ok for 99.9% of users. Could add another layer of checking to select
    % those files that will result in the largest number of imported
    % samples.

    if not(isequal(ex4Check{1},ex))&&any(abs(ex4Check{1}-ex)>options.waveDiffTollerance)
        warning(['File ',files(j).name,': Missmatch in the excitation wavlengths that exceeded the wavelength difference tollerance (compared to 1st file). Skipped...'])
        continue
    end
    if not(isequal(em4Check{1},em))&&any(abs(em4Check{1}-em)>options.waveDiffTollerance)
        warning(['File ',files(j).name,': Missmatch in the emission wavlengths that exceeded the wavelength difference tollerance (compared to 1st file). Skipped...'])
        continue
    end
    
    % Fill the dataset with the info now that all checks passed.
    data.X(cnt,:,:)=x;
    filelist{cnt,1}=strtrim(erase(files(j).name,erase(filePattern,'*')));
    data.i(cnt,1)=j;
    

    % message (nice to have, could be deleted).
    tc=toc(tc);
    ttl=num2str(numel(files));
    remain=num2str(round(tc.*(numel(files)-j),2));
    if not(diagnostic)||not(silent)
        disp([num2str(j),'/',ttl,': ',filelist{cnt,1},...
            ' (',remain,' sec. remaining)'])
    end
    cnt=cnt+1; % +1 on the counter for a successful import.
end

% move filelist into the dataset
data.filelist=filelist;

% Final dataset variables can now be assigned.
data.Ex=rcvec(ex,'column');
data.Em=rcvec(em,'column');
data.nEx=numel(data.Ex);
data.nEm=numel(data.Em);
data.nSample=size(data.X,1);
data.metadata.i=data.i;
% data.metadata.filelist=data.filelist; % Disabled since it's redundant.

% Validate the dataset to make sure it's good to go (class-specific method)
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
    
    % Final step: Make the drEEMhistory entry.
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


if isscalar(unique(sz(:,1)))&&isscalar(unique(sz(:,2)))
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

            else
                diagt=table;
                diagt.name=categorical(filenames);
                diagt.nrow=sz(:,1);
                message=[message,'<strong>Seems like a complex issue. Inspect the figure </strong>\n'];
                f=uifigure("Name",'Dimension issue: Inspect the table...');
                uit=uitable(f,Data=diagt,Units="normalized",OuterPosition=[0 0 1 1]);
            end
        end
    end
    error(sprintf(message))
end

end