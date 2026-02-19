function viewdmr(data,f,options)
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
    options.figurefile (1,:) {mustBeText} = ""
end
app=dreemgui.viewdmr_gui(data,f);

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
