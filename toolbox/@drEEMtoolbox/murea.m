function murea(data)
% <a href = "matlab:drEEMtoolbox.doc('murea')">murea(data)</a>
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
ncomp=numel(find(arrayfun(@(x) not(isempty(x.loads{1})),data.models)));
if ncomp==0
    error('Dataset must contain PARAFAC models to analyze their residuals.')
end
    
dreemgui.murea_gui(data)
end