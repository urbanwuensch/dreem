function viewdmr(data,f)
% <a href = "matlab:drEEMtoolbox.doc('viewdmr')">viewdmr(data) (click to access documentation)</a>
%
% <strong>View data, modelled data, and residuals of FDOM PARAFAC models</strong>
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>EXAMPLE(S)</strong>
%   tbx.viewdmr(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewdmr')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    f (1,1) {mustBeNumeric} = nan
end
dreemgui.viewdmr_gui(data,f)
end