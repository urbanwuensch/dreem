function viewmodels(data,options)
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
    options.startTab (1,:) {mustBeText,...
        mustBeMember(options.startTab,["Overview","Scores & loadings",...
        "Spectral loadings","Loadings & leverages","Errors & leverages", ...
        "Fingerprint plots","SSE","Score correlation"])} = "Overview"
    options.f (1,1) {mustBeNumeric,drEEMdataset.mustBeModel(data,options.f)} = nan
    options.figurefile (1,:) {mustBeText} = ""
end
ncomp=numel(find(arrayfun(@(x) not(isempty(x.loads{1})),data.models)));
if ncomp==0
    error('Can''t find any models to plot.')
end
app=dreemgui.viewmodels_gui(data,options.startTab,options.f);

figurefile=char(options.figurefile);
if not(isempty(figurefile))
    % Pause for figure rendering
    pause(3)
    try
        fig=dreemgui.extractUIfigure(app);
        dreemgui.saveAfterFunctionCall(fig,'test.png')
    catch ME
        throwAsCaller(ME)
    end
end

end
