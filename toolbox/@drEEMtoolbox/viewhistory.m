function viewhistory(data)
% <a href = "matlab:drEEMtoolbox.doc('viewhistory')">viewhistory(data) (click to access documentation)</a>
%
% <strong>View the history of a drEEMdataset object</strong>
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>EXAMPLE(S)</strong>
%   tbx.viewhistory(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewhistory')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.mustContainSamples(data)}
end
if height(data.history)==0
    error('No entries to display.')
end
dreemgui.viewhistory_gui(data)
end