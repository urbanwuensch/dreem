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
    if ismac && ~strcmp(computer('arch'),'maca64')
        error('drEEM:unsupportedPlatform', ['aqualog2nc is only available for Apple silicon Macs. ' ...
            'Export your data from Origin as text files and use importeems/importabsorbance instead.'])
    end

elseif ispc
    platform='windows';
elseif isunix&&not(ismac)
    platform='linux';
end

switch platform
    case 'mac'
        toolname='aqualog2nc-macos-arm64';
    case 'windows'
        toolname='aqualog2nc-windows-x64.exe';
    case 'linux'
        toolname='aqualog2nc-linux-x64';
end

base = userpath;
if isempty(base) || ~isfolder(base)
    base = prefdir;
end
toolpath = char(fullfile(base,toolname));

ncfile=char(fullfile(folder,'NetCDF_rawdata.nc'));
if isfile(ncfile)
    delete(ncfile)
end

if not(isfile(toolpath))
    disp('Downloading OS-specific version of aqualog2nc...')
    try
        zenodo=webread('https://zenodo.org/api/records/21928517/versions/latest',ContentType='json');

        files = zenodo.files;
        if iscell(files), files = [files{:}]; end
        hit = files(strcmp(string({files.key}), toolname));
        assert(isscalar(hit), 'file %s not found in the aqualog2nc record', toolname)
        websave(toolpath, hit.links.self);

    catch ME
        if isfile(toolpath), delete(toolpath), end   % no half-downloaded binary
        error('drEEM:aqualog2ncDownload', ['Could not download aqualog2nc (%s).\n' ...
            'Check the internet connection, or download "%s" from ' ...
            'https://doi.org/10.5281/zenodo.21928517 and save it as\n  %s'], ...
            ME.message, toolname, toolpath)
    end
    disp('Success')
else
    disp('Found aqualog2nc on your path. Continuing...')
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
            error(response)
        end
    case 'windows'
        response=system(['"',toolpath,'" "',folder,'" "',ncfile,'"']);
        if response==0
            %disp([toolname,' has exported measurements in your OPJ files..'])
        else
            error(response)
        end
end

if isfile(ncfile)
    rawdata=horibaRawdata.importFromNetCDF(ncfile,bucket);
    if matches(version,'drEEMdataset')
        [samples,blanks]=horibaRawdata.importFromNetCDF(rawdata);
        varargout{1}=samples;
        varargout{2}=blanks;
    else
        varargout{1}=rawdata;
    end

end