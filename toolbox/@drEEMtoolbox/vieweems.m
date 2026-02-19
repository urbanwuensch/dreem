function vieweems(data,options)
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
    options.figurefile (1,:) {mustBeText} = ""
end
app=dreemgui.vieweems_gui(data);
end

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
