cd(fileparts(matlab.desktop.editor.getActiveFilename))
load("tutorial_01_processed.mat")
test=samples;
file='CMOP_2016.nc';
tbx=drEEMtoolbox;
export2openuv(test,file,...
    summary="FDOM / CDOM samples from the Columbia River. Dissolved Organic Carbon samples from salt marsh sites, river sites, aided by metadata from the CMOP SATURN obseravtional network.",...
    keywords="Columbia River, FDOM, CDOM, DOM, DOC, fluorescence, absorbance, estuary, CMOP, SATURN",...
    acknowledgement="USGS Portland: access to usage of instrumentation . OHSU: help with fieldwork and lab access",...
    citation='',...
    comment="This data has not been used in a per-reviewed publication at the date of data publication",...
    id='CMOP2016', ...
    naming_authority='Technical University of Denmark (Urban Wünsch)',...
    license="CC BY-NC 4.0",...
    publisher_email='wuensch@chalmers.se',...
    publisher_name='Urban J. Wünsch',...
    publisher_url="https://orcid.org/0000-0001-6972-6932",...
    title='Wunsch & Needoba (2016)',...
    references='https://doi.org/10.5194/bg-2016-263',...
    creator_email='wuensch@chalmers.se',...
    creator_name='Urban J. Wünsch',...
    creator_url="https://orcid.org/0000-0001-6972-6932",...
    contributor_name='Joseph Needoba',...
    contributor_role='Principal investigator, host for research exchange (OHSU)',...
    date_created=datetime(char(samples.metadata.date(10))),...
    date_modified=datetime("2025-02-05"),...
    institution='Technical University of Denmark',...
    project='Resolving the chemical structures responsible for the UV-visible spectroscopic properties of dissolved organic matter in aquatic environments',...
    instrument='Horiba AquaLog',...
    time_coverage_start=datetime('29-Mar-2016 13:00'),...
    time_coverage_end=datetime('06-Apr-2016 13:00'),...
    geospatial_lat_min=min(test.metadata.latitude),...
    geospatial_lat_max=max(test.metadata.latitude),...
    geospatial_lon_min=min(test.metadata.longitude),...
    geospatial_lon_max=max(test.metadata.longitude),...
    geospatial_vertical_min=0,...
    geospatial_vertical_max=9,...
    geospatial_vertical_units="meter",...
    geospatial_vertical_positive="down", ...
    sample_storage_duration="<5 days",...
    sample_filter_meshsize="0.2um filter",...
    sample_storage_temperature='2-8°C',...
    processing_level='Data fully processed, final',...
    product_version='v1')
% test2=readopenuv(file);

% info=ncinfo(file);
% disp(info)
% info.Variables(3).Attributes.Value
clc
ncdisp("CMOP_2016.nc")

%%
plot(ncread("CMOP_2016.nc",'absorbance_wavelength'),ncread("CMOP_2016.nc","absorbance_sample"),'k'),
xlabel('absorbance_wavelength',Interpreter='none')
ylabel('absorbance_sample(sample_name,absorbance_waelength)',interpreter='none')
scifig(width=18,height=10)
copygraphics(gcf)
%%
x=ncread("CMOP_2016.nc","fluorescence_sample");
x=squeeze(x(5,:,:));
contourf(ncread("CMOP_2016.nc",'excitation_wavelength'),...
    ncread("CMOP_2016.nc",'emission_wavelength'),...
    x,LevelList=linspace(0,0.9,50))

xlabel('excitation_wavelength',Interpreter='none')
ylabel('emission_wavelength',interpreter='none')
title({'fluorescence_sample(sample_name,...', ...
    'emission_wavelength,excitation_wavelength)'},Interpreter='none')
scifig(width=10,height=8)
copygraphics(gcf)



%%
cd(fileparts(matlab.desktop.editor.getActiveFilename))
clc
directory='https://gitlab.com/dreem/dreem-2/-/raw/main/toolbox/@drEEMtoolbox/versions.txt';
existing=[2 25 11];
online=[2 25 11 05];
drEEMtoolbox.countinstallations
drEEMtoolbox.updatedreem(directory,true,existing,online)

tbx=drEEMtoolbox;



%% projectmodel development
cd(fileparts(matlab.desktop.editor.getActiveFilename))
clc
clearvars
tbx=drEEMtoolbox;
load("tutorial_01_processed.mat")

samples=tbx.projectmodel(samples,"TRM_6C_PARAFAC.txt");

tbx.viewmodels(samples)
tbx.vieweems(samples)


%%
clearvars
cd(fileparts(matlab.desktop.editor.getActiveFilename))
load("tutorial_01_processed.mat")
export_cmop=cdf_toolbox.load("CMOP_2016.nc");

somevariable=cdf_toolbox.cdfvariable(samples.metadata.location);

somevariable.Attributes.comment='this is some variable for demo purposes';
somevariable.Attributes.long_name='Some variable with a long name';
somevariable.Attributes.missing_value=-9999;
somevariable.Attributes.units='1';
somevariable.Attributes.standard_name='standard_name';
somevariable.Attributes.coverage_content_type='physicalMeasurement';
somevariable.Attributes.coordinates='some_other_variable';
somevariable.Dimensions='some_other_variable';

export_cmop.variables.somevariable=somevariable;

save(export_cmop,'test')

ncdisp("test.nc")


%%
clearvars
close all force
initSession
tbx=drEEMtoolbox;
load("HE452drEEM2.mat")

samples=tbx.processabsorbance(samples,plot=false);
samples=tbx.ifecorrection(samples,plot=false);
samples=tbx.subtractblanks(samples,blanks,plot=false);
samples=tbx.ramancalibration(samples,blanks,"method","gauss1",plot=false);

samples=tbx.subdataset(samples,outEm=samples.Em<330|samples.Em>550,outEx=samples.Ex<260|samples.Ex>450);
load("HE452scatteroptions.mat")
samples=tbx.handlescatter(samples,scatteroptions);
samples=misc.XMcorrect(samples,3);
out=samples.absWave<240;
samples.abs(:,out)=[];
samples.absWave(out)=[];
out=samples.absWave>600;
samples.abs(:,out)=[];
samples.absWave(out)=[];
fitnpls(samples)