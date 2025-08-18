function viewcompcorr(data)
% <a href = "matlab:drEEMtoolbox.doc('viewcompcorr')">viewcompcorr(data) (click to access documentation)</a>
%
% <strong>Inspect PARAFAC models of fluorescence EEMs</strong>
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>EXAMPLE(S)</strong>
%   tbx.viewcompcorr(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewcompcorr')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.mustContainSamples(data)}
end
dreemgui.viewcompcorr_gui(data)