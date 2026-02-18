function dataout = mergedatasets(a,b)
% <a href = "matlab:drEEMtoolbox.doc('mergedatasets')">dataout = mergedatasets(a,b) (click to access documentation)</a>
%
% <strong>Merge datasets with identical wavelength axes and metadata columns</strong>
%
% <strong>INPUTS - Required</strong>
% a (1,1) {drEEMdataset.validate,...
%     drEEMdataset.mustContainSamples}
% b (1,1)  {drEEMdataset.validate,...
%     drEEMdataset.mustContainSamples}
%
% <strong>EXAMPLE(S)</strong>
%   1. Merge two datasets
%       all = tbx.mergedatasets(janToJun,julToDec)
%
% <a href = "matlab:drEEMtoolbox.doc('mergedatasets')"><strong>-> full documentation</strong></a>

% Copyright (C) 2026 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)

arguments (Input)
    a (1,1) {mustBeNonempty,drEEMdataset.validate(a),drEEMdataset.mustContainSamples(a)}
    b (1,1) {mustBeNonempty,drEEMdataset.validate(b),drEEMdataset.mustContainSamples(b)}

end

[result,message]=drEEMstatus.isequal(a.status,b.status);
if not(result)
    throw(MException("drEEM:statusNotEqual",message))
end

messages='<strong>Merging not possible:\n</strong>';
pass=true;
if not(isequal(a.Ex,b.Ex))
    messages=[messages,' Exication wavelengths not identical. \n'];
    pass=false;
end
if not(isequal(a.Em,b.Em))
    messages=[messages,' Emission wavelengths not identical. \n'];
    pass=false;
end
if not(isequal(a.absWave,b.absWave))
    messages=[messages,' Absorbance wavelengths not identical. \n'];
    pass=false;
end

C=intersect(a.metadata.Properties.VariableNames,b.metadata.Properties.VariableNames);

if not(numel(C)==width(a.metadata)&&numel(C)==width(b.metadata))
    messages=[messages,' Metadata table columns identical. \n'];
    pass=false;
end

if not(pass)
    throw(MException("drEEM:NotIdentical",messages))
else
    dataout=drEEMdataset.create;
    dataout.status=a.status;
    dataout.abs=[a.abs;b.abs];
    dataout.absWave=a.absWave;
    dataout.metadata=[a.metadata;b.metadata];
    dataout.filelist=[a.filelist;b.filelist];
    dataout.X=[a.X;b.X];
    dataout.XBlank=[a.XBlank;b.XBlank];
    dataout.nEx=a.nEx;
    dataout.nEm=a.nEm;
    dataout.nSample=size(dataout.filelist,1);
    dataout.i=(1:dataout.nSample);
    dataout.Em=a.Em;
    dataout.Ex=a.Ex;
end

% drEEMhistory entry
idx=1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'created dataset by merging two existing datasets. Tracability limited since the dataset history of the origin datasets was not preserved.');
dataout.validate(dataout);

end