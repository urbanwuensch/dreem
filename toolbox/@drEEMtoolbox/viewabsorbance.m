function viewabsorbance(data)
% <a href = "matlab:drEEMtoolbox.doc('viewabsorbance')">viewabsorbance(data) (click to access documentation)</a>
%
% <strong>View absorbance spectra</strong> contained in drEEMdataset object
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>EXAMPLE(S)</strong>
%   tbx.viewabsorbance(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewabsorbance')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.mustContainSamples(data),drEEMdataset.sanityCheckAbsorbance(data)}
end
dreemgui.viewabsorbance_gui(data)
end