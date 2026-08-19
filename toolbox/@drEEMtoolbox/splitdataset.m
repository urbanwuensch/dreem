function dataout = splitdataset(data,splitType,options)
% <a href = "matlab:drEEMtoolbox.doc('splitdataset')">dataout = splitdataset(data,splitType,options) (click to access documentation)</a>
%
% <strong>Split dataset into subsets</strong> for split-validation of PARAFAC models
%
% <strong>INPUTS - Required</strong>
% data {drEEMdataset.validate}
% % splitType (1,:) {mustBeMember(["blind","byMetadata"])} = "blind"
%
% <strong>INPUTS - Optional</strong>
% options.blindType (1,:)     {mustBeMember(["alternating","random","contiguous"])} = "alternating"
% options.metadataColumn (1,:)    {drEEMdataset.mustBeMetadataColumn} = []
% options.numsplit (1,1)  {mustBePositive} = 2
%
% <strong>EXAMPLE(S)</strong>
%   1. The <strong>DOMfluor-type</strong> split (two splits, alternating split assignment)
%       samples = tbx.splitdataset(samples);
%   2. Four splits with random sample assignment
%       samples = tbx.splitdataset(samples,splitType='blind',blindType='random',numSplit=4);
%   3. Split dataset according to metadata variable "origin" (must exist, needs to be adopted to your dataset)
%       samples = tbx.splitdataset(samples,splitType='byMetadata',metadataColumn='origin');
%
% <a href = "matlab:drEEMtoolbox.doc('splitdataset')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data {drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    splitType (1,:) {mustBeText,mustBeMember(splitType,["blind","byMetadata"])} = "blind"
    options.blindType (1,:)     {mustBeMember(options.blindType,["alternating","random","contiguous"])} = "alternating"  
    options.metadataColumn (1,:)    {drEEMdataset.mustBeMetadataColumn(data,options.metadataColumn),optValMC(splitType,options.metadataColumn)} = string.empty
    options.numSplit (1,1)  {mustBePositive} = 2
    
end


% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    nargoutchk(1,1)
end

% This bit is doing the splitting
switch splitType
    case "blind"
        % #1 Create an alternating-type split allocation by repeating 1:nSplit
        % until number of samples is exceeded.
        % This can be used by several methods
        splitIdent=repmat((1:options.numSplit)',ceil(data.nSample./options.numSplit),1);
        % #2 since nSample can be exceeded, truncate the identity vector to nSample
        splitIdent=splitIdent(1:data.nSample);
    case "byMetadata"
        groups = categorical(data.metadata.(options.metadataColumn));
        grps=categories(groups);
        splitIdent=nan(data.nSample,1);
        for j=1:numel(grps)
            idx=groups==grps{j};
            splitIdent(idx,1)=j;
        end
        options.numSplit=numel(grps);
end

% If blind case, and an option other than alternating (default) was specified, do that!
if matches(splitType,'blind')
    switch options.blindType
        case "random"
            mixer=randperm(data.nSample);
            splitIdent=splitIdent(mixer);
        case "contiguous"
            splitIdent=sort(splitIdent);
    end
end
dataout=data;

dataout.split=drEEMdataset.create; % Overwrite any preexisting split
for j=1:options.numSplit
    out=not(splitIdent==j);
    dataout.split(j,1)=cutsamples(data,out);
    dataout.split(j,1).history=...
        drEEMhistory.addEntry(mfilename,'created as a split of a larger dataset',options,drEEMdataset);
    dataout.split(j,1).models=drEEMmodel;
end
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,['dataset split with split-type: "',char(splitType),'"'],options,dataout);

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
end


end

function optValMC(splitType,option)
%option is metadataColumn
if matches(splitType,'blind')&&not(isempty(option))
    warning('<strong>Conflicting inputs: </strong>"splitType", takes precedent over specifying input to "metadataColumn".')
end
if matches(splitType,'byMetadata')&&isempty(char(option))
    error(['<strong>Invalid input: </strong> When specifying splitType="byMetadata",' ...
        ' option "metadataColumn" cannot be empty.'])
end
end

function [dataout] = cutsamples(data,index)
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data  (1,1) {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
    index {mustBeNumericOrLogical}
end

if isempty(index)|sum(index)==0
    %warning('rmsamples: input "index" was empty. No action taken.')
    dataout=data;
    return
end

drEEMdataset.validate(data)

dataout=data;

if islogical(index)|isnumeric(index)
    dataout.X(index,:,:)=[];
    dataout.i(index)=[];
    dataout.filelist(index)=[];
    dataout.metadata(index,:)=[];
    if not(isempty(dataout.opticalMetadata))
        dataout.opticalMetadata(index,:)=[];
    end
    if not(isempty(dataout.XBlank))
        dataout.XBlank(index,:,:)=[];
    end
    if not(isempty(dataout.abs))
        dataout.abs(index,:)=[];
    end
    dataout.nSample=size(dataout.X,1);
else
    error("input to index must be numeric or logical")
end

f=drEEMdataset.modelsWithContent(dataout);
if not(isempty(f))
    dataout.models=drEEMmodel;
end



if islogical(index)
    index=find(index);
end

ident=data.filelist(index);
if iscolumn(ident)
    ident=ident';
end
if isscalar(ident)
    ident=ident{1};
else
    newident=[];
    for j=1:numel(ident)
        newident=[newident,' ; ',ident{j}];
    end
    ident=newident;clearvars newident;
end
drEEMdataset.validate(dataout)
end