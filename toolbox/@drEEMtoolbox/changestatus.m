function dataout = changestatus(data)
% <a href = "matlab:drEEMtoolbox.doc('changestatus')">dataout = changestatus(data) (click to access documentation)</a>
%
% <strong>Manually change the processing status</strong> of a drEEMdataset
%
% <strong>INPUTS - Required</strong>
% data (1,1)  {mustBeA("drEEMdataset"),drEEMdataset.validate}
%
% <strong>EXAMPLE(S)</strong>
%   samples = tbx.changestatus(samples); (follow the GUI advice)
%
% <a href = "matlab:drEEMtoolbox.doc('changestatus')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1)  {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
end
    % Get input name
    x_name = inputname(1);
    
    % Start app with names
    handle=setstatus_dreem(data, x_name);
    waitfor(handle,"finishedHere",true);
    try
        dataout=handle.data;
        delete(handle)
    catch
        error('setstatus closed before save & exit button was pushed.')
    end
    % assignin("base",x_name,dataout)
    % disp(['Data status of ',char(x_name),' changed (Workspace variable replaced with updated version).'])
end