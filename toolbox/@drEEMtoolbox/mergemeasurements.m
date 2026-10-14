function dataout = mergemeasurements(a,b,measurement,mode)
% <a href = "matlab:drEEMtoolbox.doc('mergemeasurements')">dataout = mergemeasurements(a,b,measurement) (click to access documentation)</a>
%
% <strong>Transfer one measurement type from dataset b into dataset a</strong> (absorbance, fluorescence or supplementary spectra)
%
% Samples are matched by name (.filelist). Samples in "a" without a match in "b"
% receive missing numbers (NaN); samples in "b" without a match in "a" are ignored.
% The axis information (e.g. .absWave) and the related status entries are copied from "b".
%
% <strong>Note:</strong> The history of "b" is NOT transferred. Only the merge itself is
% recorded in the history of "a". Any processing applied to "b" beforehand (e.g.
% processabsorbance) will not appear in the history of the merged dataset. To keep
% a record, merge before processing, or document it with addcomment / export2zip(b,...).
%
% <strong>INPUTS - Required</strong>
% a (1,1)           {mustBeA("drEEMdataset"),drEEMdataset.validate}   receiving dataset
% b (1,1)           {mustBeA("drEEMdataset"),drEEMdataset.validate}   source dataset
% measurement (1,:) {mustBeMember(["absorbance","fluorescence","supplementarySpectra"])}
%
% <strong>INPUTS - Optional</strong>
% mode (1,:)        {mustBeMember(["replace","noreplace"])} = "replace"
%                   "replace" overwrites existing data of this type in "a" (with a warning)
%                   "noreplace" stops with an error if "a" already contains such data
%
% <strong>EXAMPLE(S)</strong>
%   1. <strong>Move absorbance into the sample dataset</strong> (after alignsamples)
%       [samples,absorbance] = tbx.alignsamples(samples,absorbance);
%       samples = tbx.mergemeasurements(samples,absorbance,"absorbance");
%   2. <strong>Add Raman scans to the blanks</strong> for ramancalibration(...,source="scan")
%       blanks = tbx.mergemeasurements(blanks,ramanscans,"supplementarySpectra");
%   3. <strong>Never overwrite existing data</strong>
%       samples = tbx.mergemeasurements(samples,absorbance,"absorbance","noreplace");
%
% <a href = "matlab:drEEMtoolbox.doc('mergemeasurements')"><strong>-> full documentation</strong></a>

% Copyright (C) 2026 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments (Input)
    a (1,1) {mustBeNonempty,drEEMdataset.validate(a),...
        drEEMdataset.mustContainSamples(a)}
    b (1,1) {mustBeNonempty,drEEMdataset.validate(b),...
        drEEMdataset.mustContainSamples(b)}
    measurement (1,:) {mustBeMember(measurement,["absorbance","fluorescence","supplementarySpectra"])}
    mode (1,:) {mustBeMember(mode,["replace","noreplace"])} = "replace"
end

arguments (Output)
    dataout
end

% Digest inputs and validate feasibility
switch measurement
    case "absorbance"
        if not(b.hasAbsorbance)
            error('input to "b" must have data in b.abs')
        end
        if a.hasAbsorbance
            if matches(mode,"replace")
                warning('In mode="replace" (default), data in a.abs will be overwritten')
            elseif matches(mode,"noreplace")
                error('a.abs already contains data, since mode="noreplace", the function must stop now.')
            end
        end
        measurement=replace(measurement,"absorbance","abs");
    case "fluorescence"
        if not(b.hasFluorescence)
            error('input to "b" must have data in b.X')
        end
        if a.hasFluorescence
            if matches(mode,"replace")
                warning('In mode="replace" (default), data in a.X will be overwritten')
            else
                matches(mode,"noreplace")
                error('a.X already contains data, since mode="noreplace", the function must stop now.')
            end
        end
        measurement=replace(measurement,"fluorescence","X");
    case "supplementarySpectra"
        if not(b.hasSupplementarySpectra)
            error('input to "b" must have data in b.suppSpectra')
        end
        if a.hasSupplementarySpectra
            if matches(mode,"replace")
                warning('In mode="replace" (default), data in a.suppSpectra will be overwritten')
            else
                matches(mode,"noreplace")
                error('a.suppSpectra already contains data, since mode="noreplace", the function must stop now.')
            end
        end
        measurement=replace(measurement,"supplementarySpectra","suppSpectra");
end

[C,ia,ib] = intersect(a.filelist,b.filelist,"stable");

if isempty(C)
    error('No common samples between "a" and "b". inspect .filelist in both datasets and compare.')
end

if not(numel(C)==a.nSample)
    message='';
    ah=drEEMhistory.searchhistory(a.history,'alignsamples','last');
    bh=drEEMhistory.searchhistory(b.history,'alignsamples','last');
    if isempty(ah)|isempty(bh)
        message=[message,'You have not used "alignsamples" to align the sequence of measurements in your datasets.',newline];
    end
    message=[message,'The number of overlapping samples is less than the number of samples in "a". Some entries in ',char(measurement),' will contain missing numbers'];

    warning(message)
end

if matches(measurement,'X')
    a.(measurement)=nan(a.nSample,b.nEm,b.nEx);
    a.(measurement)(ia,:,:)=b.(measurement)(ib,:,:);
    a.Em=b.Em;
    a.Ex=b.Ex;
    a.nEm=b.nEm;
    a.nEx=b.nEx;
    a.models=[];
    a.split=[];
    if not(isempty(b.([measurement,'Blank'])))
        a.([measurement,'Blank'])(ia,:,:)=b.([measurement,'Blank'])(ib,:,:);
    elseif not(isempty(a.([measurement,'Blank'])))
        a.([measurement,'Blank'])=[];
        disp('No blanks exist in "b", so existing blanks in "a" were cleared.')
    end
    stats={'spectralCorrection',...
        'IFEcorrection',...
        'blankSubtraction',...
        'signalCalibration',...
        'scatterTreatment',...
        'signalScaling'};


elseif matches(measurement,'abs')
    a.(measurement)=nan(a.nSample,numel(b.absWave));
    a.(measurement)(ia,:)=b.(measurement)(ib,:);

    a.absWave=b.absWave;

    stats={'absorbanceUnit'};

    if contains(a.status.IFEcorrection,{'applied by'})
        message=['<strong>Inner filter effects have already been corrected.\n</strong>' ...
            ' Replacing the absorbance record now makes the process non-tracable. You should merge measurements prior to the correction!\n'];
         throwAsCaller(MException("drEEM:Insane",message))
    end


elseif matches(measurement,'suppSpectra')
    a.(measurement)=nan(a.nSample,numel(b.suppSpectraAxis));
    a.(measurement)(ia,:)=b.(measurement)(ib,:);

    a.suppSpectraAxis=b.suppSpectraAxis;
    stats={'suppSpectraInfo'};
end

for j=1:numel(stats)
    a.status=drEEMstatus.change(a.status,stats{j},b.status.(stats{j}));
end

dataout=a;
% Make drEEMhistory entry with message information

message=['Transfered measurements, axis information, and status of "',char(measurement),'" from "',char(inputname(2)),'" to "',char(inputname(1)),'"'];

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,message,[],dataout);

end