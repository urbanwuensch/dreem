function doc(functionname)
arguments
    functionname (1,:) {mustBeText(functionname),mustBeMember(functionname,...
["addcomment" "alignsamples" "associatemetadata" "benchmark" "changestatus"...
        "displayhistory" "dreem" "drEEM" "drEEMdataset" "dreemdataset" ...
        "drEEMstatus" "dreemstatus" ...
        "drEEMhistory" "dreemhistory" "export2openfluor" "export2zip" "exportresults" ...
        "fitparafac" "fitslopes" "handlescatter" "ifecorrection" "importabsorbance"...
        "importeems" "importwizard" "mergedatasets" "pickpeaks" "processabsorbance" ...
        "ramancalibration" "reportresidualanalysis" "rmspikes" "scalesamples" ...
        "scores2fmax" "spectralcorrection" "splitdataset" "subdataset" "subtractblanks"...
        "upgradedataset" "validatedataset" "viewabsorbance" "viewcompcorr" ...
        "viewdmr" "vieweems" "viewhistory" "viewmodels" "viewopenfluormatches"...
        "viewscatter" "viewspectralvariance" "viewsplitvalidation" "zapnoise"])} =''
end
% drEEM-specific function for displaying custom formatted documentation
% (c) Urban Wuensch, 2019
%% Function init
% This bit is for cleanup
currentdirectory = pwd;
c = onCleanup(@() cd(currentdirectory));

rtpath=matlabroot;
doclocs = which('doc','-all');
restoredoc_i=contains(doclocs,rtpath);

% Database of published function docs
try functionname=lower(functionname);end %#ok<TRYNC>

% Catch users that just want to see the start page of doc 
if nargin==0
    cd(fileparts(doclocs{restoredoc_i}));
    help
    return
end

% Digest some of the automated attempts for documentation calls and
% redirect them
if matches(functionname,'dreemtoolbox')
    functionname='dreem';
end


% Search for existing documentation based on entries in "functiondirectory"
mthds=methods('drEEMtoolbox');
mthds=[{'dreem';'dreemdataset';'dreemhistory';'dreemstatus'};mthds];
if matches(functionname,mthds) % User is looking for drEEM function
    try
        web([char(functionname),'.html']);
        return
    catch
        % If nothing was found, just display the default MATLAB output
        cd(fileparts(doclocs{restoredoc_i}));
        doc(functionname);
        %warning('didn''t find the fancy doc html page')
    end
else % User wants other documentation, let's do that!
    cd(fileparts(doclocs{restoredoc_i}));
    doc(functionname);
end