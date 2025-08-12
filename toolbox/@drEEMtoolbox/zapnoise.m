function dataout = zapnoise(data,sampleIdent,emRange,exRange)
% <a href = "matlab:drEEMtoolbox.doc('zapnoise')">dataout = zapnoise(data,sampleIdent,emRange,exRange) (click to access documentation)</a>
%
% NaN ("zap") parts of individual EEMs to treat outliers.
%
% <strong>INPUTS - Required</strong>
% data (1,1)    {mustBeA("drEEMdataset"),drEEMdataset.validate}
% sampleIdent   {mustBeNonempty(sampleIdent),mustBeA('logical'),outSampleVal(data,sampleIdent)}
% emRange (1,:) {mustBeNumeric,mustBeNonempty,drEEMdataset.mustBeInRangeEm}
% exRange (1,:) {mustBeNumeric,mustBeNonempty,drEEMdataset.mustBeInRangeEx}
%
% <strong>EXAMPLE(S)</strong>
%   1. Zap noise at Ex 255 Em 450 in data.i==5
%       samples = tbx.zapnoise(samples,data.i==5,450,255)
%   2. Zap entire emission scan at Ex 255 in sample data.i==5
%       samples = tbx.zapnoise(samples,data.i==5,[],255)
%   1. Zap entire emission scans at Ex 255 and 300 in sample data.i==7
%       like example 2., but in two calls since [255 300] would delete the
%       entire block between both.
%
% <a href = "matlab:drEEMtoolbox.doc('zapnoise')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    sampleIdent  (1,:) {mustBeNonempty(sampleIdent),mustBeA(sampleIdent,'logical'),outSampleVal(data,sampleIdent)}
    emRange (1,:) {mustBeNumeric,drEEMdataset.mustBeInRangeEm(data,emRange)}
    exRange (1,:) {mustBeNumeric,drEEMdataset.mustBeInRangeEx(data,exRange)}

end

% Secondary input validation (stuff that's not possible in the argument block)
try 
    mustBeLessThanOrEqual(sampleIdent,data.nSample)
catch ME
    error(['outSample: ',ME.message])
end

% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    nargoutchk(1,1)
end


% Anonymous function, finds the clostest match to the provided wavelengths
% Similar to knnsearch, but does not require any toolboxes.

%% Function execution

% Find first unscaled dataset and zap it as well. That's not strickly
% speaking needed (no dimension error), but it's a safe choice to avoid big
% differences in fits (excessive noise that zapnoise might remove).
idx=drEEMhistory.searchhistory(data.history,'scalesamples','first');
if not(isempty(idx))
    previouseem=data.history(idx).previous;
    previouseem=drEEMtoolbox.zapnoise(previouseem,sampleIdent,emRange,exRange);
    data.history(idx).previous=previouseem;
end

% Assign output variable
dataout=data;


% two equal blocks for em and ex. If one input, find the closest match, if
% two make a vector of indices from start to end.
if isempty(emRange)
    emRange=1:data.nEm;
else
    for j=1:numel(emRange)
        emRange(j)=drEEMtoolbox.mindist(data.Em,emRange(j));
    end
    if numel(emRange)==2
        emRange=emRange(1):emRange(end);
    end
end
if isempty(exRange)
    exRange=1:data.nEx;
else
    for j=1:numel(exRange)
        exRange(j)=drEEMtoolbox.mindist(data.Ex,exRange(j));
    end
    if numel(exRange)==2
        exRange=exRange(1):exRange(end);
    end
end

% The actual zapping
dataout.X(sampleIdent,emRange,exRange)=NaN;

% Final validation (just in case)
dataout.validate(dataout);

% Finishing up: Write the drEEMhistory entry
message=['SampleIdent = ',num2str(rcvec(find(sampleIdent),'row')),...
    ';  EmRange = ',num2str(rcvec(find(emRange),'row')),...
    ';  ExRange = ',num2str(rcvec(find(exRange),'row'))];
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,message,[],dataout);

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
end

f=drEEMdataset.modelsWithContent(dataout);
if not(isempty(f))
    dataout.models=drEEMmodel;
    idx=height(dataout.history)+1;
    dataout.history(idx,1)=...
        drEEMhistory.addEntry(mfilename,...
        'deleted models due to call to zapnoise (likely through subdataset)',[],dataout);
    disp('A call to zapnoise with pre-existing models results in their deletion.')
end

end

function [vout] = rcvec(v,rc)
% Make row or column vector
% v: vector
% rc: either 'row' ([1:5])or 'column' ([1:5]')
sz=size(v);
if ~any(sz==1)
    error('Input is not a vector')
end

switch rc
    case 'row'
        if ~[sz(1)<sz(2)]
            vout=v';
        else
            vout=v;
        end
    case 'column'
        if ~[sz(1)>sz(2)]
            vout=v';
        else
            vout=v;
        end
    otherwise
            error('Input ''rc'' not recognized. Options are: ''row'' and ''column''.')
end


end

function outSampleVal(data,outSample)
if not(size(outSample,2)==data.nSample)
message=['<strong>sampleIdent must be specified as logical array of the size [', ...
    num2str(data.nSample),' x 1].</strong> Why? ' ...
    'zapnoise works with results of comparisons. E.g. ' ...
    'sampleIdent=matches(data.filelist,''sample01''),' ...
    ' sampleIdent=contains(data.metadata.location,''siteA''),' ...
    ' or sampleIdent=data.i==1.'];
throwAsCaller(MException("drEEM:invalid",message))
end
end