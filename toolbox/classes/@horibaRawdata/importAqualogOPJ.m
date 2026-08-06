function [varargout] = importAqualogOPJ(folder,version)
%IMPORTAQUALOGOPJ Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    folder (1,:) {mustBeText,mustBeFolder} = pwd
    version (1,:) {mustBeMember(version,["drEEMdataset","horibaRawdata"])} = "drEEMdataset"
end

% Just making sure that it's char (not string)
folder=char(folder);

if ismac&&isunix
    platform='mac';
elseif ispc
    platform='windows';
elseif isunix&&not(ismac)
    platform='linux';
end

switch platform
    case 'mac'
        url='https://github.com/urbanwuensch/aqualog2nc/releases/download/v0.3.0/aqualog2nc-macos-arm64';
        toolname='aqualog2nc-macos-arm64';
    case 'windows'
        url='https://github.com/urbanwuensch/aqualog2nc/releases/download/v0.3.0/aqualog2nc-windows-x64.exe';
        toolname='aqualog2nc-windows-x64.exe';
    case 'linux'
        url='https://github.com/urbanwuensch/aqualog2nc/releases/download/v0.3.0/aqualog2nc-linux-x64';
        toolname='aqualog2nc-linux-x64';
end

toolpath=char(fullfile(drEEMtoolbox.rootfolder,'external resources',toolname));
ncfile=char(fullfile(folder,'NetCDF_rawdata.nc'));

if not(isfile(toolpath))
    disp('Downloading OS-specific version of aqualog2nc...')
    websave(toolpath,url);
    disp('Success')
else
    disp('Found aqualog2nc in your drEEM toolbox. Continuing...')
end


switch platform
    case 'mac'
        if system(['chmod +x',' "',toolpath,'"'])==0
            disp(['Good news: ',toolname,' is working fine and seems executable..'])
        else
            error([toolname,' not executable. Email author for help: urban.wunsch@chalmers.se'])
        end
        response=system(['"',toolpath,'" "',folder,'" "',ncfile,'"']);
        if response==0
            disp(['Good news: ',toolname,' should have exported measurements in your OPJ files..'])
        else
            error(['Something went wrong during the use of ',toolname,'. Email author for help: urban.wunsch@chalmers.se'])
        end
    case 'windows'
        response=system(['"',toolpath,'" "',folder,'" "',ncfile,'"']);
        if response==0
            disp(['Good news: ',toolname,' should have exported measurements in your OPJ files..'])
        else
            error(['Something went wrong during the use of ',toolname,'. Email author for help: urban.wunsch@chalmers.se'])
        end
    case 'linux'
        error('Linux not yet suported. Get in touch... urban.wunsch@chalmers.se')

end

if isfile(ncfile)
    if matches(version,'drEEMdataset')
        [samples,blanks]=horibaRawdata.importNetCDF(ncfile,'drEEMdataset');
        varargout{1}=samples;
        varargout{2}=blanks;
    else
        rawdata=horibaRawdata.importNetCDF(ncfile,'horibaRawdata');
        varargout{1}=rawdata;
    end

end