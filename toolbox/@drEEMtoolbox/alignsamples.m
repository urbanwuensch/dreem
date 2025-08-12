function varargout = alignsamples(varargin)
% <a href = "matlab:drEEMtoolbox.doc('alignsamples')">varargout = alignsamples(varargin) (click to access documentation)</a>
%
% <strong>Compare filelists between datasets</strong>, align filelists, and delete non-ubiquitous samples
%
% <strong>INPUTS - Required</strong>
% varargin (1,1) {mustBeA("drEEMdataset"),drEEMdataset.validate}
%
% <strong>EXAMPLE(S)</strong>
%   1. samples, blanks, and absorbance scans should only contain samples with the same names in identical sequence
%       [samples,blanks,absorbance] = tbx.alignsamples(samples,blanks,absorbance);
%   2. FDOM only
%       [samples,blanks] = tbx.alignsamples(samples,blanks);
%
% <a href = "matlab:drEEMtoolbox.doc('alignsamples')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments (Repeating)
    varargin {mustBeA(varargin,"drEEMdataset"),drEEMdataset.validate(varargin),drEEMdataset.mustContainSamples(varargin)}
end
% Optional feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(numel(varargin),numel(varargin))
        diagnostic=false;
    else
        disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified)')
        diagnostic=true;
    end
end
% Get the dataset names for messages
name=strings(nargin,1);
for j=1:numel(varargin)
    name(j,1)=string(inputname(j));
end

% Find all comparisons between the input datasets for all comparisons
combs=nchoosek(1:numel(varargin),2);

% cmn = common. Preallocate this cell
cmn=cell(size(combs,1),1);

% Comparison of filenames across all the combinations of datasets
for j=1:size(combs,1)
    % This compares the filenames between two datasets
    C = intersect(varargin{combs(j,1)}.filelist,...
        varargin{combs(j,2)}.filelist);
    % Store the common names for later
    cmn{j}=C;
    % Store the names of the comparison (could be useful, not used atm).
    comparison(j,1)= ...
        categorical(cellstr([char(name(combs(j,1))),' vs. ',char(name(combs(j,2)))]));
end

% A bit of transformation to obtain the filenames that occur
% numel(varargin) times across all the comparisons.
cmn=vertcat(cmn{:});
cmn=cmn(:);
cmn=categorical(cmn);
cmn=cmn(countcats(cmn)==size(combs,1));

if isempty(cmn)
    error("No common sample names were found. Exiting...")
end

% This loop sorts the files and deletes missing samples
for j=1:numel(varargin)
    % This one finds the indices of the common files
    [~,~,idx] = intersect(cmn,varargin{j}.filelist);

    % Convert that into the ones that should be deleted
    deleted=setdiff(1:numel(varargin{j}.filelist),idx);
    delP=numel(deleted)/varargin{j}.nSample;
    if diagnostic
        deleted_diag{j}=deleted;
    end
    if delP==1
        error(['The call to this function would delete all samples for dataset "<strong>',char(name(j)),'"</strong> Exiting...'])
    elseif delP>0.1
        warning(['Deleted more than 10% of the samples for dataset "<strong>',char(name(j)),'"</strong> You might want to investigate what''s wrong...'])
    end

    % Now delete the sample information in all fields of interest.
    flds=fieldnames(varargin{j});
    flds(matches(flds,{'history','Ex','Em','absWave'}))=[]; % These won't be touched
    sel=[];cnt=1;
    for k=1:numel(flds)
        if size(varargin{j}.(flds{k}),1)==varargin{j}.nSample
            % If the field matches in the sample dimension, it gets marked
            % for deletion
            sel(cnt)=k;
            cnt=cnt+1;
        end
        
    end
    % Subset the fieldnames for those that are marked for sample deletion
    flds=flds(sel);

    % Assign the dataset to be modified as an output argument
    varargout{j}=varargin{j};

    % Execute the deletion
    for k=1:numel(flds)
        % This try-catch solution is not pretty, but for now it works.
        try % 3 way tensors
            varargout{j}.(flds{k})=varargout{j}.(flds{k})(idx,:,:);
        catch % tables & matrices
            varargout{j}.(flds{k})=varargout{j}.(flds{k})(idx,:);
        end
    end
    
    varargout{j}.nSample=varargout{j}.nSample-numel(deleted);

 
    
    % Gather information for user.
    if isempty(deleted)
        message='No action necessary. All files between supplied datasets had same names.';
    else
        message=['removed ',num2str(numel(deleted)),' samples with the previous .i: ',num2str(deleted)];
    end
    
    % Make drEEMhistory entry with message information
    idx=height(varargout{j}.history)+1;
    varargout{j}.history(idx,1)=...
        drEEMhistory.addEntry(mfilename,message,[],varargout{j});
    
    % Also display the message in the command window
    disp([char(name(j)),': ',message])
    
    %Final validation of the dataset
    drEEMdataset.validate(varargout{j});
end

if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    for j=1:numel(varargout)
        assignin("base",name(j),varargout{j})
        disp(['<strong> "',char(name(j)), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    end
    return
else
    if nargout==0
        clearvars varargout
    end
end

if diagnostic
    diagnosis(varargin,deleted_diag,name)
end

end


function diagnosis(varargin,deleted_diag,name)

fnms=cellfun(@(x) x.filelist,varargin,UniformOutput=false);
fnms_all=unique(vertcat(fnms{:}));

results=table;
results.('Unique filenames')=fnms_all;

for j=1:numel(varargin)
    results.(name(j))=matches(results.('Unique filenames'),varargin{j}.filelist);
end

fig=drEEMtoolbox.dreemuifig;

uit=uitable(fig,"Units","normalized",Position=[0.01 0.01 0.98 0.98]);
uit.Data=results;
s  = uistyle(BackgroundColor=[.8 0 0]);
idx=table2array(not(uit.Data(:,2:end)));
idx=any(idx,2);

addStyle(uit,s,'row',find(idx));

end