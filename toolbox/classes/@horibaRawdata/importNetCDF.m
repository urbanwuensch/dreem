function varargout = importNetCDF(file,version)
%IMPORTNETCDF Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    file (1,:) {mustBeText(file),mustBeFile(file)}
    version (1,:) {mustBeMember(version,["drEEMdataset","horibaRawdata"])} = "drEEMdataset"
    
end
if matches(version,'drEEMdataset')
    nargoutchk(1,2)
elseif matches(version,'horibaRawdata')
    nargoutchk(1,1)
end

info = ncinfo(file);
groups = {info.Groups(:).Name}';


varmap={'AbsI1darkSample','AbsI1dark_Sample','att';...
    'AbsI1Sample','AbsI1_Sample','var';...
    'AbsI1darkBlank','AbsI1dark_Blank','att';...
    'AbsI1Blank','AbsI1_Blank','var';...
    'S1Blank','S1Blank','var';...
    'S1DarkBlank','S1Dark_Blank','var';...
    'MCorrect','MCorrect','var';...
    'R1Blank','R1_Blank','var';...
    'AbsR1Blank','R1_Blank','var';...
    'R1DarkBlank','R1dark_Blank','att';...
    'AbsR1darkBlank','R1dark_Blank','att';...
    'XCorrect','XCorrect','var';...
    'AbsXCorrect','XCorrect','var';...
    'S1Sample','S1Sample','var';...
    'S1DarkSample','S1Dark_Sample','var';...
    'R1Sample','R1_Sample','var';...
    'AbsR1Sample','R1_Sample','var';...
    'R1DarkSample','R1dark_Sample','att';...
    'AbsR1darkSample','R1dark_Sample','att';...
    'filelist','workbook_name','att';...
    'opjfile','source_opj_file','att';...
    'Em_parkpos','park_wavelength_nm','att';...
    'Em_PixelBin','ccd_xbin','att';...
    'CCD_gain','ccd_gain_factor','att';...
    'date_measured','creation_time','att'};

disp('NetCDF Aqualog file conversion to horibaRawdata (drEEM-specific rawdata format)')
disp(' ')
disp(['   Found ',num2str(numel(groups)),' samples in the NetCDF file...'])
disp(' ')
disp('    Converting to a drEEM-specific format...')
dataout=horibaRawdata;

dataout.nSample=numel(groups);
dataout.Ex=ncread(file,[groups{1},'/excitation']);
dataout.Abs_wave=ncread(file,[groups{1},'/excitation']);

nEx=numel(dataout.Ex);
dataout.Em=ncread(file,[groups{1},'/emission']);
nEm=numel(dataout.Em);

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

for j=1:dataout.nSample
    sample=groups{j};
    grpid = netcdf.inqNcid(ncid,sample);
    varid = netcdf.inqVarID(grpid,'excitation');
    value = netcdf.getVar(grpid,varid);
    if not(isequal(value,dataout.Ex))
        error('There was a mismatch in Excitation. Cannot import...')
    end

    varid = netcdf.inqVarID(grpid,'emission');
    value = netcdf.getVar(grpid,varid);
    if not(isequal(value,dataout.Em))
        error('There was a mismatch in Emission. Cannot import...')
    end
end

disp('    Success... All samples have identical emission and excitation axes')

for j=1:dataout.nSample
    sample=groups{j};
    grpid = netcdf.inqNcid(ncid,sample);
    %disp(['       ',sample])
    
    for k=1:height(varmap)
        drEEM_field=varmap{k,1};
        nc_field=varmap{k,2};
        field_type=varmap{k,3};
        switch field_type
            case 'att'
                
                grpid = netcdf.inqNcid(ncid,sample);
                value = netcdf.getAtt(grpid,netcdf.getConstant('NC_GLOBAL'),nc_field);

                if isnumeric(value)
                    dataout.(drEEM_field)(j,1)=value;
                else
                    dataout.(drEEM_field){j,1}=value;
                end
            case 'var'
                varid = netcdf.inqVarID(grpid,nc_field);
                value = netcdf.getVar(grpid,varid);
                if size(value,2)==1
                    try
                        dataout.(drEEM_field)(j,:)=value';
                    catch
                        asd
                    end
                else
                    dataout.(drEEM_field)(j,:,:)=value;
                end
        end
    end





end

netcdf.close(ncid);

disp(['   Success. Imported ',num2str(numel(groups)),' samples'])


switch version
    case 'horibaRawdata'
        idx=1;
        dataout.history(idx,1)=...
            drEEMhistory.addEntry(mfilename,'created horibaRawdata dataset from opj/ogw files with NetCDF intermediate',[],drEEMdataset);
        varargout{1} = dataout;
    case 'drEEMdataset'
        [varargout{1},varargout{2}]=drEEMtoolbox.processHJYdata(dataout);
end