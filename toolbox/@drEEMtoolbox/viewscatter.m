function viewscatter(data,options)
% <a href = "matlab:drEEMtoolbox.doc('viewscatter')">viewscatter(data) (click to access documentation)</a>
%
% <strong>Visually identify and handle scatter in fluorescence datasets</strong>
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>EXAMPLE(S)</strong>
%   tbx.viewscatter(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewscatter')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.mustContainSamples(data)}
    options.figurefile (1,:) {mustBeText} = ""
end
app=dreemgui.viewscatter_gui(data);

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
