function viewcompcorr(data,options)
% <a href = "matlab:drEEMtoolbox.doc('viewcompcorr')">viewcompcorr(data) (click to access documentation)</a>
%
% <strong>Inspect PARAFAC models of fluorescence EEMs</strong>
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>INPUTS - Optional</strong>
% figurefile (1,:)      {mustBeText} = "";
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
    options.figurefile (1,:) {mustBeText} = ""
end
app=dreemgui.viewcompcorr_gui(data);

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
