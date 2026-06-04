function viewspectralvariance(data,options)
% <a href = "matlab:drEEMtoolbox.doc('viewspectralvariance')">spectralvariance(data) (click to access documentation)</a>
%
% <strong>Inspect the spectral variability</strong> of a drEEMdataset
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>INPUTS - Optional</strong>
% figurefile (1,:)      {mustBeText} = "";
%

% <strong>EXAMPLE(S)</strong>
%   spectralvariance(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewspectralvariance')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1)              {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    options.figurefile (1,:) {mustBeText} = ""
end


app=dreemgui.viewspectralvariance_gui(data);

figurefile=char(options.figurefile);
if not(isempty(figurefile))
    % Pause for figure rendering
    pause(3)
    try
        fig=dreemgui.extractUIfigure(app);
        dreemgui.saveAfterFunctionCall(fig,figurefile)
    catch ME
        throwAsCaller(ME)
    end
end

end