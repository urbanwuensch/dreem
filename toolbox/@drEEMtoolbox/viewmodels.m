function viewmodels(data,startTab,f)
% <a href = "matlab:drEEMtoolbox.doc('viewmodels')">viewmodels(data) (click to access documentation)</a>
%
% <strong>Inspect PARAFAC models of fluorescence EEMs</strong>
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>EXAMPLE(S)</strong>
%   tbx.viewmodels(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewmodels')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    startTab (1,:) {mustBeText,...
        mustBeMember(startTab,["Overview","Scores & loadings",...
        "Spectral loadings","Loadings & leverages","Errors & leverages", ...
        "Fingerprint plots","SSE","Score correlation"])} = "Overview"
    f (1,1) {mustBeNumeric,drEEMdataset.mustBeModel(data,f)} = nan
end
ncomp=numel(find(arrayfun(@(x) not(isempty(x.loads{1})),data.models)));
if ncomp==0
    error('Can''t find any models to plot.')
end
viewmodels_gui(data,startTab,f)
end