function dataout = addcomment(data,comment,newopt)
% <a href = "matlab:drEEMtoolbox.doc('addcomment')">dataout = addcomment(data,comment) (click to access documentation)</a>
%
% <strong>Add a comment to a drEEMdataset object</strong> to document your analysis process
%
% <strong>INPUTS - Required</strong>
%   data (1,1)    {mustBeA("drEEMdataset"),drEEMdataset.validate}
%   comment (1,:) {mustBeText}
%   newopt (1,:) {mustBeMember(["","newline"])} = string.empty
%
% <strong>EXAMPLE(S)</strong>
%   samples = tbx.addcomment(data,'This last modification really made a difference');
%
% <a href = "matlab:drEEMtoolbox.doc('addcomment')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1)    {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
    comment (1,:) {mustBeText}
    newopt (1,:) {mustBeText,mustBeMember(newopt,["","newline"])} = string.empty
end

nargoutchk(1,1)

idx=height(data.history);
dataout=data;

if isempty(newopt)
    % Add to existing entry

    if not(dataout.history(idx).usercomment=="")
        % Solution 2: add a string
        dataout.history(idx).usercomment=...
            [dataout.history(idx).usercomment,string(comment)];

    else % New entry
        dataout.history(idx).usercomment=string(comment);
    end


else
    % new drEEMhistory entry
    idx=height(dataout.history)+1;
    dataout.history(idx,1)=...
        drEEMhistory.addEntry([char(mfilename),': user comment'],comment,[],dataout);
    dataout.validate(dataout);
end

end