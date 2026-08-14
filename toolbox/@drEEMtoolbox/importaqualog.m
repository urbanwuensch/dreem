function varargout = importaqualog(folder,options)
% <a href = "matlab:drEEMtoolbox.doc('importaqualog')">varargout = importaqualog(folder,options) (click to access documentation)</a>
%
% <strong>Import fluorescence EEMs from Aqualog-generated OPJ or OGW files</strong> and create drEEMdataset
%
% <strong>INPUTS - Required</strong>
% folder (1,:)                 {mustBeFolder}
% 
% <strong>INPUTS - Optional</strong>
% bucket (1,:)          {mustBeNumericOrLogical} = true
%
% <strong>EXAMPLE(S)</strong>
%   1. <strong>Grab any stored measurements in current folder, identical settings</strong>
%       [samples,blanks] = tbx.importaqualog(pwd);
%   2. <strong>Same as 1. but different settings, you want the largest group</strong>
%       [samples,blanks] = tbx.importaqualog(pwd,bucket=1);
%   3. <strong>Same as 2. but now you want to process the samples that got measured with different settings</strong>
%       [samples,blanks] = tbx.importaqualog(pwd,bucket=N); % Choose your N, depends on case.
%
% <a href = "matlab:drEEMtoolbox.doc('importaqualog')"><strong>-> full documentation</strong></a>

% Copyright (C) 2026 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)

arguments
    folder (1,:) {mustBeFolder(folder)} = pwd;
    options.bucket (1,:) {mustBeNumeric} = 1;
    options.type (1,:) {mustBeMember(options.type,["rawdata","processed"])} = "processed";

end
ds=horibaRawdata.importFromOrigin(folder,'horibaRawdata',options.bucket);
if matches(options.type,"rawdata")
    varargout{1}=ds;
    disp("use drEEMtoolbox.processHYJdata() to process the dataset. Your output is unprocessed rawdata")
else
    opt=horibaRawdata.convertTodrEEMdataset('options');
    [varargout{1},varargout{2}]=horibaRawdata.convertTodrEEMdataset(ds,opt);
end
end