function [varargout] = importFromOrigin(folder,version,bucket)
%IMPORTAQUALOGOPJ Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    folder (1,:) {mustBeText,mustBeFolder} = pwd
    version (1,:) {mustBeMember(version,["drEEMdataset","horibaRawdata"])} = "drEEMdataset"
    bucket (1,:) {mustBeNumeric} = 1;
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
% Get the URL of the latest version of the tool from Github.
urlbase=webread("https://raw.githubusercontent.com/urbanwuensch/aqualog2nc/refs/heads/master/versionlink.txt");
urlbase=strsplit(urlbase,{';'});
urlbase=urlbase{1};
switch platform
    case 'mac'
        toolname='aqualog2nc-macos-arm64';
    case 'windows'
        toolname='aqualog2nc-windows-x64.exe';
    case 'linux'
        toolname='aqualog2nc-linux-x64';
end
url=[urlbase,toolname,'?download=1'];

toolpath=char(fullfile(drEEMtoolbox.rootfolder,'external resources',toolname));
ncfile=char(fullfile(folder,'NetCDF_rawdata.nc'));

if isfile(ncfile)
    delete(ncfile)
end

if not(isfile(toolpath))
    disp('Downloading OS-specific version of aqualog2nc...')
    websave(toolpath,url);
    disp('Success')
else
    disp('Found aqualog2nc in your drEEM toolbox. Continuing...')
end


switch platform
    case {'mac','linux'}
        if system(['chmod +x',' "',toolpath,'"'])==0
            %disp([toolname,' is working fine and seems executable..'])
        else
            error([toolname,' not executable. Email author for help: urban.wunsch@chalmers.se'])
        end
        response=system(['"',toolpath,'" "',folder,'" "',ncfile,'"']);
        if response==0
            %disp([toolname,' has exported measurements in your OPJ files..'])
        else
            error(['Something went wrong during the use of ',toolname,'. Email author for help: urban.wunsch@chalmers.se'])
        end
    case 'windows'
        response=system(['"',toolpath,'" "',folder,'" "',ncfile,'"']);
        if response==0
            %disp([toolname,' has exported measurements in your OPJ files..'])
        else
            error(['Something went wrong during the use of ',toolname,'. Email author for help: urban.wunsch@chalmers.se'])
        end
end

if isfile(ncfile)
    rawdata=horibaRawdata.importFromNetCDF(ncfile,bucket);
    if matches(version,'drEEMdataset')
        [samples,blanks]=drEEMtoolbox.importFromNetCDF(rawdata);
        varargout{1}=samples;
        varargout{2}=blanks;
    else
        varargout{1}=rawdata;
    end

end