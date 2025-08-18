function vieweems(data)
% <a href = "matlab:drEEMtoolbox.doc('vieweems')">vieweems(data)</a>
%
% <strong>GUI-assisted visualization of fluorescence datasets</strong>
%
% <a href = "matlab:drEEMtoolbox.doc('vieweems')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
end
dreemgui.vieweems_gui(data)
end