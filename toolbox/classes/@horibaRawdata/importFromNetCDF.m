function dataout = importFromNetCDF(file,bucket)
%IMPORTNETCDF Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    file (1,:) {mustBeText(file),mustBeFile(file)}
    bucket (1,1) {mustBeNumeric,mustBePositive} = 1
    
end


info = ncinfo(file);
if not(isempty(info.Groups))&&bucket==1
    warning('off','backtrace')
    warning('Multiple measurement types are stored in the NetCDF file, due to differences in measurement settings. By default, the first group with the most samples gets exported. If another group should be imported, the option "bucket" must be changed')
    warning('on','backtrace')
    groups = {info.Groups(:).Name}';
    selectedGroup=groups{bucket};
    importtype='group';
elseif isempty(info.Groups)
    disp('The sample record consist of only one, entirely compatible measurement set.')
    importtype='root';
elseif not(isempty(info.Groups))&&bucket~=1
    disp(['Multiple measurement types are stored in the NetCDF file, due to differences in measurement settings. measurement_type_',num2str(bucket),' was imported (not the default)'])
    groups = {info.Groups(:).Name}';
    selectedGroup=groups{bucket};
    importtype='group';
end

% Extract key variables (needed for pre-allocation)
ncid = netcdf.open(file,'NOWRITE');
switch importtype
    case 'group'
        ncid = netcdf.open(file,'NOWRITE');
        grpid = netcdf.inqNcid(ncid,selectedGroup);
    case 'root'
        grpid = ncid;
end

varid = netcdf.inqVarID(grpid,'data_identifier');
value = netcdf.getVar(grpid,varid);
nSample=height(value);
varid = netcdf.inqVarID(grpid,'excitation');
value = netcdf.getVar(grpid,varid);
excitation=value;
varid = netcdf.inqVarID(grpid,'emission');
value = netcdf.getVar(grpid,varid);
emission=value;
netcdf.close(ncid);



varmap={'AbsI1darkSample','AbsI1dark_Sample','var';...
    'AbsI1Sample','AbsI1_Sample','var';...
    'AbsI1darkBlank','AbsI1dark_Blank','var';...
    'AbsI1Blank','AbsI1_Blank','var';...
    'S1Blank','S1Blank','var';...
    'S1DarkBlank','S1Dark_Blank','var';...
    'MCorrect','MCorrect','var';...
    'R1Blank','R1_Blank','var';...
    'AbsR1Blank','R1_Blank','var';...
    'R1DarkBlank','R1dark_Blank','var';...
    'AbsR1darkBlank','R1dark_Blank','var';...
    'XCorrect','XCorrect','var';...
    'AbsXCorrect','XCorrect','var';...
    'S1Sample','S1Sample','var';...
    'S1DarkSample','S1Dark_Sample','var';...
    'R1Sample','R1_Sample','var';...
    'AbsR1Sample','R1_Sample','var';...
    'R1DarkSample','R1dark_Sample','var';...
    'AbsR1darkSample','R1dark_Sample','var';...
    'filelist','data_identifier','var';...
    'opjfile','source_opj_file','var';...
    'Em_parkpos','park_wavelength_nm','var';...
    'Em_PixelBin','ccd_xbin','var';...
    'CCD_gain','ccd_gain_factor','var';...
    'date_measured','creation_time','var';...
    'integrationtime','integration_time','var'};

dataout=horibaRawdata;

dataout.nSample=nSample;
dataout.Ex=excitation;
dataout.Abs_wave=excitation;

nEx=numel(dataout.Ex);
dataout.Em=emission;
nEm=numel(dataout.Em);

clearvars excitation emission nSample

% Initialize the variables
dataout.AbsI1darkSample=nan(dataout.nSample,1);
dataout.AbsI1Sample=nan(dataout.nSample,nEx);
dataout.AbsI1darkBlank=nan(dataout.nSample,nEx);
dataout.AbsI1Blank=nan(dataout.nSample,nEx);
dataout.S1Blank=nan(dataout.nSample,nEm,nEx);
dataout.S1DarkBlank=nan(dataout.nSample,nEm);
dataout.MCorrect=nan(dataout.nSample,nEm);
dataout.R1Blank=nan(dataout.nSample,nEx);
dataout.AbsR1Blank=dataout.R1Blank;
dataout.R1DarkBlank=nan(dataout.nSample,1);
dataout.AbsR1darkBlank=dataout.R1DarkBlank;
dataout.XCorrect=nan(dataout.nSample,nEx);
dataout.AbsXCorrect=dataout.XCorrect;
dataout.S1Sample=nan(dataout.nSample,nEm,nEx);
dataout.S1DarkSample=nan(dataout.nSample,nEm);
dataout.R1Sample=nan(dataout.nSample,nEx);
dataout.AbsR1Sample=dataout.R1Sample;
dataout.R1DarkSample=nan(dataout.nSample,1);
dataout.AbsR1darkSample=dataout.R1DarkSample;
dataout.filelist=cell(dataout.nSample,1);
dataout.opjfile=cell(dataout.nSample,1);
dataout.date_measured=cell(dataout.nSample,1);

ncid = netcdf.open(file,'NOWRITE');

    
for k=1:height(varmap)
    drEEM_field=varmap{k,1};
    nc_field=varmap{k,2};
    field_type=varmap{k,3};
    switch field_type
        case 'att'
            % Entirely unused now.
        case 'var'
            varid = netcdf.inqVarID(grpid,nc_field);
            try
                value = getVarFull(grpid, varid,[dataout.nSample,numel(dataout.Em),numel(dataout.Ex)]);
            catch
                error(['variable ',nc_field,' could not be retreived. This is a terminal failure.'])
            end
            if isnumeric(value)
                dataout.(drEEM_field)=value;
            elseif isstring(value)
                dataout.(drEEM_field)=cellstr(value);
            end
    end
end

disp(['Imported ',num2str(dataout.nSample),' samples from NetCDF file ',file])
value = netcdf.getAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'history');
importhistory=char(value);
versioncpp = char(netcdf.getAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'version_aqualog2nc'));


netcdf.close(ncid);

idx=1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,[importhistory,newline,'finished drEEM-import via aqualog2nc C++ software (',versioncpp,') & NetCDF intermediate (still on disk)'],[],drEEMdataset);
end

function value = getVarFull(grpid, varid, dims)
% value = getVarFull(grpid, varid, [nSample, em, ex])
%
% Reads a variable via netcdf.getVar and restores its full shape using
% the caller-supplied dimension counts (read once from the coordinate
% variables data_identifier/emission/excitation) instead of introspecting
% dimids order - sidesteps the getVar/inqVar reversal question entirely.

nSample = dims(1);
em      = dims(2);
ex      = dims(3);

value = netcdf.getVar(grpid, varid);
n = numel(value);

if n == nSample * em * ex
    value = reshape(value, [nSample, em, ex]);
elseif n == nSample * ex
    value = reshape(value, [nSample, ex]);
elseif n == nSample * em
    value = reshape(value, [nSample, em]);
elseif n == nSample
    % already a plain per-sample vector/string array - nothing to reshape
elseif n == ex
    % excitation-only, not per-sample (XCorrect, or the excitation
    % coordinate variable itself) - already 1D, nothing to reshape
elseif n == em
    % emission-only, not per-sample (MCorrect, or the emission
    % coordinate variable itself) - already 1D, nothing to reshape
else
    error('getVarFull:unexpectedSize', ...
        'Variable element count (%d) does not match any expected shape for nSample=%d, em=%d, ex=%d.', ...
        n, nSample, em, ex);
end

end