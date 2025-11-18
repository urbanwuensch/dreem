function dataout = upgradedataset(data,atypicalFieldnames)
% <a href = "matlab:drEEMtoolbox.doc('upgradedataset')">dataout=subdataset(data,options) (click to access documentation)</a>
%
% Upgrade drEEM datasets to the drEEMdataset class
%
% <strong>INPUTS - Required</strong>
% data (1,1) {mustBeA(data,'struct')}
%
% <strong>INPUTS - Optional</strong>
% atypicalFieldnames (:,2) cell = {}
%
% <strong>EXAMPLE(S)</strong>
%   1. Simple upgrade if dataset was constructed as advised in drEEM tutorials (>0.5.x)
%       data = tbx.upgradedataset(Xin);
%   2. Upgrade if dataset was constructed with alternative variable name for filelist
%       data = tbx.upgradedataset(Xin,{'samplename';'filelist'});
%   3. Upgrade if dataset was constructed with alternative variable name for the old notation Abs_wave
%       data = tbx.upgradedataset(Xin,{'wave';'absWave'});
%   4. Upgrade drEEM tutorial dataset from previous version (produces warning due to non-existent absorbance data)
%       load(which('drEEM_tutorial_DS_old.mat')),
%       samples = tbx.upgradedataset(dreemdata,{'longID','filelist'})
%
% <a href = "matlab:drEEMtoolbox.doc('upgradedataset')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'struct'),checkdataset(data)}
    atypicalFieldnames (:,2) cell = {}
end
if not(isempty(atypicalFieldnames))
    % Check input for existence in data
    nms=fieldnames(data);
    for j=1:height(atypicalFieldnames)
        try
            mustBeMember(atypicalFieldnames{j,1},nms);
        catch
            error(['Illigal name <strong>"',char(atypicalFieldnames{j,1}), ...
                '"</strong>. Input in first row of atypicalFieldnames must point to one of the variables in data'])
        end
    end
    
    % Check input for existence in drEEMdataset
    nms=properties(drEEMdataset);
    for j=1:height(atypicalFieldnames)
        try
            mustBeMember(atypicalFieldnames{j,2},nms);
        catch
            error(['Illigal name <strong>"',char(atypicalFieldnames{j,2}), ...
                '"</strong>. Input in second row of atypicalFieldnames must point to one of the properties of drEEMdataset'])
        end
    end
end
dataout=drEEMdataset.create;


flds=[{'X','Ex','Em','nEm','nEx','filelist','i','nSample','Abs_wave','Abs'},atypicalFieldnames(:,1)'];
newflds=[{'X','Ex','Em','nEm','nEx','filelist','i','nSample','absWave','abs'},atypicalFieldnames(:,2)'];
if isfield(data,'metadata')
    if istable(data.metadata)
        dataout.metadata=data.metadata;
    else
        dataout.metadata.i=data.i;
    end
else
    dataout.metadata.i=data.i;
end
for j=1:numel(flds)
    if not(isfield(data,flds{j}))
        if not(contains(atypicalFieldnames(:,2),flds{j}))
            warning(['field "',flds{j},'" does not exist in old dataset' ...
                ' Consider using input "atypicalFieldnames" if the data exists but has a different name. If it doesn''t exist, ignore this warning (with caution)'])
        end
    else
            if isprop(drEEMdataset,newflds{j})
                dataout.(newflds{j})=data.(flds{j});
            elseif not(isprop(drEEMdataset,newflds{j}))
                warning([newflds{j},' is not a property of drEEMdataset and ' ...
                    'cannot be added like specified. atypicalFieldnames should ' ...
                    'only point at variables that were named unexpectedly in "data".' ...
                    ' If your variable size has as many columns as the dataset ' ...
                    'has samples, the variable will be transferred to metadata automatically in the next step.'])
            else
                error(['field "',flds{j},'" could not be transferred since ' ...
                    'it is not a property of drEEMdataset or could be added' ...
                    ' to the metadata table.'])
            end
    end
end


dataout.validate(dataout);

ssz=dataout.nSample;
flds=fieldnames(data);

for j=1:numel(flds)
    if ssz==size(data.(flds{j}),1)&&size(data.(flds{j}),2)==1
        dataout.metadata.(flds{j})=data.(flds{j});
    end
end

dataout.metadata = metadataconverter(dataout.metadata);

for j=1:100
    if isfield(data,['Model',num2str(j)])
        loads=data.(['Model',num2str(j)]);
        pass=true;
        for k=1:3
            if not(size(dataout.X,k)==size(loads{k},1))
                pass=false;
                warning([num2str(j),'-component model had an inconsistent size. Not transferred.'])
            end
        end
        if not(pass)
            continue
        end
        dataout.models(j,1)=drEEMmodel;
        dataout.models(j,1).loads=loads;
        for n=1:numel(loads)
            lev=diag(loads{n}*(loads{n}'*loads{n})^-1*loads{n}');
            dataout.models(j,1).leverages(1,n)={lev};
        end

        E=dataout.X-nway.modeleval.nmodel(loads);
        E_ex = squeeze(sum(sum(E.^2,1,'omitnan'),2,'omitnan'));
        E_em = squeeze(sum(sum(E.^2,1,'omitnan'),3,'omitnan'))';
        E_sample = squeeze(sum(sum(E.^2,2,'omitnan'),3,'omitnan'));
        dataout.models(j,1).sse={E_sample E_em E_ex};
        dataout.models(j,1).status='transferred from old dataset. status unknown';

        e=sum(E(:).^2,"omitmissing");

        dataout.models(j,1).percentExplained=...
            100 * (1 - e / sum(dataout.X(:).^2,'omitnan') );
        dataout.models(j,1).core=nway.modeleval.corcond(dataout.X,loads,[],0);
        dataout.models(j,1).percentUnconverged=NaN;

        sizeF=nan(1,size(loads{1},2));
        for l=1:size(loads{1},2)
            modelledH=nway.modeleval.nmodel([{loads{1}(:,l)} {loads{2}(:,l)} {loads{3}(:,l)}]);
            sizeF(l)=100 * (1 - (sum((dataout.X(:) - modelledH(:)).^2,'omitnan')) / sum(dataout.X(:).^2,'omitnan'));
        end
        dataout.models(j,1).componentContribution=sizeF;
        dataout.models(j,1).initialization='random'; %assumed
        dataout.models(j,1).starts=NaN;
        if isfield(data,['Model',num2str(j),'convgcrit'])
            dataout.models(j,1).convergence=data.(['Model',num2str(j),'convgcrit']);
        else
            dataout.models(j,1).convergence=NaN;
        end
        if isfield(data,['Model',num2str(j),'constraints'])
            dataout.models(j,1).constraints=data.(['Model',num2str(j),'constraints']);
        else
            dataout.models(j,1).constraints='unknown';
        end
        dataout.models(j,1).toolbox='nway'; %assumed.

    end
end
dataout.validate(dataout);


%%%%% IMPLEMENT SPLITS!!!!
% User needs to tell the toolbox what the status of the dataset is.
handle=dreemgui.setstatus_dreem(dataout,'data');
waitfor(handle,"finishedHere",true);
try
    dataout=handle.data;
    delete(handle)
catch
    error('setstatus closed before save & exit button was pushed.')
end

idx=1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'dataset conversion from older drEEM version',[],dataout);

dataout.validate(dataout);

end



function mdnew = metadataconverter(metadata)
    mdnew=table;
    for j=1:numel(metadata.Properties.VariableNames)
        here=metadata.Properties.VariableNames{j};
        md=metadata.(here);
        try
            if isscalar(unique(md))
                %continue
            end
        catch
            % different data types (nogo)
            continue
        end
        type=class(md);
        switch type
            case 'cell'
                alltype=cellfun(@(x) class(x),md,'UniformOutput',false);
                celltypes=unique(alltype);
                if numel(celltypes)>1
                    warning(['Variable "',here,'" consists of different datatypes and will not be included for plotting'])
                    continue
                else
                    celltypes=celltypes{1};
                end
                switch celltypes
                    case 'char'
                        mdconv=categorical(md);
                    case 'datetime'
                        mdconv=categorical(md);
                    case 'duration'
                        mdconv=double(md);
                    case 'categorical'
                        mdconv=md;
                    case 'numeric'
                        mdconv=md;
                    otherwise
                        error('Metadata type: cell, subtype not accounted for.')

                end
            case 'numeric'
                mdconv=md;
            case 'datetime'
                mdconv=categorical(md);
            case 'duration'
                mdconv=double(md);
            case 'double'
                    mdconv=md;
            case 'categorical'
                mdconv=md;
            case 'logical'
                mdconv=categorical(md);
            otherwise
                error(['<strong>',type,'</strong>: Metadata type not accounted for.'])
        end
        mdnew.(here)=mdconv;
    end
end


function checkdataset(data,varargin)
%
% <strong>Syntax</strong>
%   <strong>checkdataset</strong>(data)
%
% <a href="matlab: doc checkdataset">help for checkdataset</a> <- click on the link

% Check for the validity of a drEEM dataset structure.
% This function carries out the following tests in sequence
% 1) Are all required variables present?
% 2) Is the size of the EEMs consistent with the respecive variables?
% 3) Are all EEM-describing variables stored as column vectors?
% 4) Are excitation and emission steadily increasing?
% 5) Is the EEM oriented correctly (do excitation and emission information agree)?
%    This is checked via Stoke's shift and fluorescence properties.
%    Should your dataset not pass the test, only a warning will be issued
%    since the procedure is not 100% effective.
% 6) Does the dataset contain slabs of EEMs that only contain zeros and /
%    or NaN values? This is a common cause for strange PARAFAC solutions.
% 7) If models are present: Are they in the correct format? Does the model
%    describe the data present in the dataset?
%
%   EXAMPLE
% checkdataset(data)
%
%	INPUT VARIABLES: 
%       data:        One data structures to be diagnosed.
%
%	NOTES:
%  1) The checks are carried out in sequence. If one fails, the subsequent
%     checks are not carried if an error is thrown. The error must be
%     corrected and the function executed again to check for validity once
%     more.
%
% Notice:
% This mfile is part of the drEEM toolbox. Please cite the toolbox
% as follows:
%
% Murphy K.R., Stedmon C.A., Graeber D. and R. Bro, Fluorescence
%     spectroscopy and multi-way techniques. PARAFAC, Anal. Methods, 2013, 
%     DOI:10.1039/c3ay41160e. 
%
% checkdataset: Copyright (C) 2019 Urban J. Wuensch
% Chalmers University of Technology
% Sven Hultins Gata 6
% 41296 Gothenburg
% Sweden
% $ Version 0.1.0 $ August 2019 $ First Release

if nargin==0
    help checkdataset
    return
end
%% Input parsing
params = inputParser;
params.addParameter('output', true, @islogical);
params.addParameter('ignore', false, @islogical);
params.parse(varargin{:});
outputs = params.Results.output;
ignore = params.Results.ignore;
if ignore
    outputs=true; % If the function does not produce errors, it should still provide console output.
end

%% Testing
if outputs
    disp(' ')
    disp('<strong>Checking the validity of your old input dataset...</strong>')
    disp(' ')
end
% Scatter is cut in case a raw dataset is supplied (this would disturb some tests)
datanc=data;
try
    data=cutscatterout(data,[20 20],[20 20],[20 20],[20 20],[0 0 0 0],1,3382,0);
catch
    warning('Could not cut scatter.')
end
% Checks
[pass(1),msuccess,mfail,mdetail]=checkfields(data);
messages(pass(1),msuccess,mfail,mdetail,outputs,ignore);

[pass(2),msuccess,mfail,mdetail]=checkdims(data);
messages(pass(2),msuccess,mfail,mdetail,outputs,ignore);

[pass(3),msuccess,mfail,mdetail]=checkvecs(data);
messages(pass(3),msuccess,mfail,mdetail,outputs,ignore);

[pass(4),msuccess,mfail,mdetail]=checkexemorientation(data);
messages(pass(4),msuccess,mfail,mdetail,outputs,ignore);

[pass(5),msuccess,mfail,mdetail]=checkstokesshift(data);
messages(pass(5),msuccess,mfail,mdetail,outputs,true);

[pass(6),msuccess,mfail,mdetail]=checknanpercentage(datanc);
messages(pass(6),msuccess,mfail,mdetail,outputs,true);

% The following test targets PARAFAC-ready datasets only (smoothed)
if isfield(datanc,'Smooth')
    [pass(7),msuccess,mfail,mdetail]=checknanzerostrips(datanc);
    messages(pass(7),msuccess,mfail,mdetail,outputs,ignore);
else
    pass(7)=true; % Assume passed in that case.
end


% Test if models are present
f=zeros(1,100);
for n=1:100
    if isfield(datanc,['Model',num2str(n)])
        f(n)=n;
    else
        f(n)=0;
    end

end
f(f==0)=[];

if ~isempty(f)
    [pass(8),msuccess,mfail,mdetail]=modeldimensions(data,f);
    messages(pass(8),msuccess,mfail,mdetail,outputs,ignore);
else
    if outputs
        disp('     No PARAFAC models in the data structure.')
    end
end
% if isfield(data,'Split')
%     disp('Found data splits. Checking them now...')
%     pause(0.1)
%     for n=1:numel(datanc.Split)
%         disp(['Split ',num2str(n)])
%         checkdataset(datanc.Split(n))
%     end
% end

if outputs&&all(pass)
    disp(' ')
    disp('<strong>Success.</strong> Moving on to the conversion to drEEMdataset')
elseif ~all(pass)
    disp('Issues were detected but the function settings prevented an error message.')
end

end
%%
function [pass,msuccess,mfail,mdetail]=checkfields(data)
% Default options
msuccess='     Success: All required dataset variables are present';
mfail='     Failed: Some required variables are missing';
pass=true;
missing='';

% Perform the checks
reqfields = {'X','Ex','Em','nEx','nEm','i','nSample'};
isfields = fieldnames(data);

successfield=false(numel(reqfields),1);
for n=1:numel(reqfields)
    for i=1:numel(isfields)
        res=strcmp(reqfields{n},isfields{i});
        if res
            successfield(n)=true;
        end
    end
    if ~successfield(n)
        pass=false;
        missing=[missing ['\n    <strong>' reqfields{n},'</strong>']];
    end
end
mdetail=['    Dataset does not contain all mandatory variables. \n    Missing fields: \n ',missing];
end
%%
function [pass,msuccess,mfail,mdetail]=checkdims(data)
% Default options
msuccess='     Success: The size of your EEM cube is consistent with Ex, Em, and i (incl. nEx, nEm, nSample)';
mfail='     Failed: The size of your EEM cube is inconsistent with Ex, Em, or i (perhaps also nEx, nEm, nSample)';
pass=true;
message1='';message2='';

% Perform the checks
Xsz=size(data.X);
% Check numel of fields vs. X
pass1=isequal(Xsz,[numel(data.i) numel(data.Em) numel(data.Ex)]);
if ~pass1
    message1=[message1 'Size of ''X'' is not equal to ''i'', ''Em'', or ''Ex''.'];
end

% Check nX of fields vs. X
pass2=isequal(Xsz,[data.nSample data.nEm data.nEx]);
if ~pass2
    message2=[message2 'Size of ''X'' is not equal to ''nSample'', ''nEm'', or ''nEx''.'];
end

if ~all([pass1 pass2])
    pass=false;
end
mdetail=[message1 '\n' message2];
end
%%
function [pass,msuccess,mfail,mdetail]=checkvecs(data)
% Default options
msuccess='     Success: The fields i, Ex, and Em are correctly stored as column vectors.';
mfail='     Failed: The fields i, Ex, and Em are not all stored as column vectors.';
wrong='';
pass=true;

% Perform the checks
fields = {'i','Em','Ex'};
passfields=false(numel(fields),1);
for n=1:numel(fields)
    passfields(n)=iscolumn(data.(fields{n}));
    if ~passfields(n)
        pass=false;
        wrong=[wrong ['- <strong>' fields{n} '</strong> \n ' ]];
    end
end
mdetail=['    Some fields should be column vectors (see ''help iscolumn''), but are not: \n    ',wrong];
end
%%
function [pass,msuccess,mfail,mdetail]=checkstokesshift(data)
% Default options for messages
msuccess='     Success: EEMs content suggests that Ex and Em information is correct.';
mfail='     Failed: EEMs content suggests that Ex and Em information is not correct.';
pass=true;pass1=true;pass2=true;
message='';
% Perform the checks
if size(data.X,1)>1
    X=squeeze(nanmedian(data.X));
else
    X=data.X;
end

[~,mEm]=max(max(X,[],2,'omitnan'),[],'omitnan');
[~,mEx]=max(max(X,[],1,'omitnan'),[],'omitnan');
stokes=(...
    (1/data.Ex(mEx)*1E7) - (1/data.Em(mEm)*1E7)...
    ).*1.23981E-4;
if stokes<0 %#ok<BDSCI>
    pass1=false;
    message=[message ['    The average EEMs Stoke''s shift is negative.' ...
        ' This is may indicate \n    - fields ''X'' ' ...
        'and ''Ex'' are misoriented and may need to be flipped upside down.']];
end

pfl=X(:,mindist(data.Ex,280))./max(X(:,mindist(data.Ex,280)));
hfl=X(:,mindist(data.Ex,400))./max(X(:,mindist(data.Ex,400)));

[~,mpfl] = max(pfl,[],'omitnan');
[~,mhfl] = max(hfl,[],'omitnan');
if data.Em(mpfl)>data.Em(mhfl)
    pass2=false;
     message=[message ['\n    The average EEMs protein-like fluorescence emission' ...
         ' maximum is shorther than the humic-like maximum. This is may ' ... 
         'indicate \n    - fields ''X'' and ''Em'' are' ... 
         ' misoriented and may need to be flipped upside down.']];
end

if ~all([pass1 pass2])
    pass=false;
end
mdetail=message;
end

%%
function [pass,msuccess,mfail,mdetail]=checkexemorientation(data)
% Default options for messages
msuccess='     Success: Emission and excitation wavelengths steadily increase.';
mfail='     Failed: Emission and excitation wavelengths do not steadily increase.';
pass=true;pass1=true;pass2=true;
message='';


% Perform the checks
if any(diff(data.Ex)<0)
    pass1=false;
    message=[message ['    The excitation wavelengths are not monotonically increasing.' ... 
        '\n    Organize the excitation information in such a way that wavelengths steadily increase.' ... 
        '\n    See ''help flip'' for further help. '...
        '\n    The two calls ''flip(DS.X,3); and flipud(DS.Ex)'' may accomplish this']];
end
if any(diff(data.Em)<0)
    pass2=false;
    message=[message ['The emission wavelengths are not monotonically increasing.'...
        '\n    Organize the emission information in such a way that wavelengths steadily increase.'...
        '\n    See ''help flipud'' for further help'...
        '\n    The two calls ''flip(DS.X,2); and flipud(DS.Em)'' may accomplish this']];
end
if ~all([pass1 pass2])
    pass=false;
end
mdetail=message;
end


%%
function [pass,msuccess,mfail,mdetail]=checknanzerostrips(data)
%% Default options for messages
msuccess='     Success: There are no slabs of only NaN- or zero-signals in your dataset.';
mfail='     Failed: There are some slabs of only NaN- or zero-signals.';
pass=true;pass1=true;pass2=true;
message_ex='';message_em='';


%% Perform the checks
X=squeeze(sum(data.X,1,'omitnan'));
Ex_nz=nan(data.nEx,1);
Em_nz=nan(data.nEm,1);

for n=1:data.nEx
    Ex_nz(n)=(sum(X(:,n)==0)+sum(isnan(X(:,n))));
end
for n=1:data.nEm
    Em_nz(n)=(sum(X(n,:)==0)+sum(isnan(X(n,:))));
end
if any(Ex_nz==data.nEm)
    pass1=false;
    exi=find(Ex_nz==data.nEm);
    message_ex='    Ex: ';
    for i=1:numel(exi)
        message_ex=[message_ex [' ' num2str(data.Ex(exi(i))) ' ' ]];
    end
end
if any(Em_nz==data.nEx)
    pass2=false;
    emi=find(Em_nz==data.nEx);
    message_em='    Em: ';
    for i=1:numel(emi)
        message_em=[message_em [' ' num2str(data.Em(emi(i))) ' ' ]];
    end
end
if ~all([pass1 pass2])
    pass=false;
end
mdetail=['\n    Some slabs of data do not contain any useful information: \n' message_ex ' \n' message_em ...
         '\n    Please use ''subdataset'' to exclude these wavelengths. Type ''help subdataset'' for more information.'];
end

%%
function [pass,msuccess,mfail,mdetail]=checknanpercentage(data)
msuccess = '     Success: NaN-percentage < 20%';
mfail    = '     Failed: NaN-percentage > 20%';
pass=true;
mdetail='';
np=sum(isnan(data.X(:)))./numel(data.X);
if np>=0.2
    mdetail=['\n    The dataset contains a large proportion of missing numbers \n'  ...
              '    Please decrease the convergence criterion, and increase the number of random starts.\n' ...
        '    NaN-percentage: ' num2str(np*100)];
    pass=false;
end

end



function [pass,msuccess,mfail,mdetail]=modeldimensions(data,f)
msuccess = '     Success: PARAFAC models are correctly formatted.';
mfail    = '     Faild: Issues with formatting of PARAFAC models detected.';
pass=true;
mdetail='';

for n=f
    cells   = numel(data.(['Model',num2str(n)]));
    nSample = size(data.(['Model',num2str(n)]){1},1);
    nEm     = size(data.(['Model',num2str(n)]){2},1);
    nEx     = size(data.(['Model',num2str(n)]){3},1);
    
    nC(1)   = size(data.(['Model',num2str(n)]){1},2);
    nC(2)   = size(data.(['Model',num2str(n)]){2},2);
    nC(3)   = size(data.(['Model',num2str(n)]){3},2);
    
    if cells~=3
        mdetail=['\n    The dataset contains a incorrectly formatted PARAFAC model: \n'  ...
            '    PARAFAC models must consist of thre cells (A,B,C). The ',num2str(n),'-component model does not consist of three cells\n' ...
            ];
        pass=false;
    end
    
    if data.nSample~=nSample
        mdetail=['\n    The dataset contains a incorrectly formatted PARAFAC model: \n'  ...
            '    The ',num2str(n),'-component model does not contain the number of samples that the dataset itself contains\n' ...
            ];
        pass=false;
    end
    
    if data.nEm~=nEm
        mdetail=['\n    The dataset contains a incorrectly formatted PARAFAC model: \n'  ...
            '    The ',num2str(n),'-component model does not contain the number of emission data points that the dataset itself contains\n' ...
            ];
        pass=false;
    end
    
    if data.nEx~=nEx
        mdetail=['\n    The dataset contains a incorrectly formatted PARAFAC model: \n'  ...
            '    The ',num2str(n),'-component model does not contain the number of excitation data points that the dataset itself contains\n' ...
            ];
        pass=false;
    end
    
    if any(nC~=n)
        mdetail=['\n    The dataset contains a incorrectly formatted PARAFAC model: \n'  ...
            '    The ',num2str(n),'-component model does not contain the expected number of components in some modes.\n' ...
            ];
        pass=false;
    end
end

end

%%
function messages(pass,msuccess,mfail,mdetail,pout,ignore)
if ~pass
    if ~ignore
    error(sprintf(mdetail)) %#ok<SPERR>
    else
    warning(sprintf(mdetail)) %#ok<SPWRN>
    end
end
if pout&&pass
    disp(msuccess)
elseif pout&&~pass
    disp(' ')
    disp(' ')
    disp(mfail)
end

end

%%
function [idx,distance] = mindist( vec,value)
[distance,idx]=min(abs(vec-value));
end
%%
function Xs=cutscatterout(Xin,varargin)
% Silent copy of smootheem, specifically for this function
narginchk(2,9)
Ray1=[];Ray2=[];Ram1=[];Ram2=[];NaNfilter=[];d2zero=40;freq=3382;
warning('OFF', 'MATLAB:interp1:NaNstrip'); %ignore columns of missing data
if nargin>=2
    plotview=varargin{nargin-1};
    if isnumeric(plotview)
        if or(isempty(plotview),max(size(plotview))>1)
            error('The final input variable must specify a valid plot display option')
        elseif plotview>0
            fprintf(['plots will be displayed for ' num2str(plotview) ' seconds. \n'])
        end
    end
    if nargin>=3
        Ray1=varargin{1};
        if  nargin>=4
            Ram1=varargin{2};
            if  nargin>=5
                Ray2=varargin{3};
                if  nargin>=6
                    Ram2=varargin{4};
                    if  nargin>=7
                        NaNfilter=varargin{5};
                        if  nargin>=8
                            d2zero=varargin{6};
                            if  nargin>=9
                                freq=varargin{7};
                                if or(max(size(freq))>1,isempty(freq))
                                    error('invalid value for wave number')
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

%% Obtain X, Ex and Em from input data structure / dataset
if isstruct(Xin)
    Em=Xin.Em';
    Ex=Xin.Ex';
    X=Xin.X;
    Xm=X;
    Xs=Xin;
else
    try
        Em=Xin.axisscale{2};
        Ex=Xin.axisscale{3};
        X=Xin.data;
        Xm=X;
        Xs.Em=Em'; Xs.Ex=Ex';Xs.nSample=size(Xm,1);
        Xs.nEx=length(Ex); Xs.nEm=length(Em);
    catch ME1
        fprintf('\n');
        error('X must be either a MATLAB data structure or a PLStoolbox dataset structure.')
    end
end
Xs.X=NaN*ones(size(Xm));
[N, EmLen, ExLen]=size(Xm);

RamScat=zeros([1 ExLen]);
for i=1:ExLen
    RamScat(i)=1/(1/Ex(i) - freq/10^7); 
    if ~isempty(Ray1)
        j1=and(Em>Ex(i)-Ray1(2),Em<Ex(i)+Ray1(1));
        Xm(:,j1,i)=NaN;
    end
    if ~isempty(Ram1)
        j2=and(Em>RamScat(i)-Ram1(2),Em<RamScat(i)+Ram1(1));
        Xm(:,j2,i)=NaN;
    end
    if ~isempty(Ray2)
        j3=and(Em>(2*Ex(i)-Ray2(2)),Em<2*Ex(i)+Ray2(1));
        Xm(:,j3,i)=NaN;
    end
    if ~isempty(Ram2)
        j4=and(Em>2*RamScat(i)-Ram2(2),Em<2*RamScat(i)+Ram2(1));
        Xm(:,j4,i)=NaN;
    end
end

%% Interpolation
i_data3=~isnan(Xm);
for j=1:N
    i_ex=squeeze(i_data3(j,EmLen,:));
    EmVecNonNAN=squeeze(Xm(j,end,i_ex));
    ExNonNAN=Ex(i_ex);
    try
    endvec=interp1(ExNonNAN,EmVecNonNAN,Ex,'pchip','extrap');
    catch
        disp(['Problem interpolating sample number: ' num2str(j) '. Check raw data!'])
        error('Can not interpolate')
    end        
    endvec(endvec<0)=0;
    Xm(j,EmLen,:)=endvec;
    
    i_data2=~isnan(squeeze(Xm(j,:,:)));
    for i=1:ExLen
        i_em=squeeze(i_data2(:,i));
        ExVecNonNAN=squeeze(Xm(j,i_em,i));
        EmNonNAN=Em(i_em);
        if i_em(1)==1
            ExVec=interp1(EmNonNAN,ExVecNonNAN,Em,'pchip');
        elseif i_em(1)==0
            ExVec=interp1([Ex(1),EmNonNAN],[0,ExVecNonNAN],Em,'pchip');
        end
        Xm(j,:,i)=ExVec;
        if ~isnan(d2zero)
            k1 = Em<Ex(i);
            Xm(:,k1,i)=NaN;
            k2 = Em<Ex(i)-Ray1(2)-d2zero;
            Xm(:,k2,i)=0;
        end
    end
end
Xm(Xm<0)=0;

%Apply optional NaN filter
if ~isempty(NaNfilter)
    for i=1:ExLen
        RamScat(i)=1/(1/Ex(i) - freq/10^7);
        if and(NaNfilter(1)==0,~isempty(Ray1))
            j1=and(Em>Ex(i)-Ray1(2),Em<Ex(i)+Ray1(1));
            Xm(:,j1,i)=NaN;
        end
        if and(NaNfilter(2)==0,~isempty(Ram1))
            j2=and(Em>RamScat(i)-Ram1(2),Em<RamScat(i)+Ram1(1));
            Xm(:,j2,i)=NaN;
        end
        if and(NaNfilter(3)==0,~isempty(Ray2))
            j3=and(Em>(2*Ex(i)-Ray2(2)),Em<2*Ex(i)+Ray2(1));
            Xm(:,j3,i)=NaN;
        end
        if and(NaNfilter(4)==0,~isempty(Ram2))
            j4=and(Em>2*RamScat(i)-Ram2(2),Em<2*RamScat(i)+Ram2(1));
            Xm(:,j4,i)=NaN;
        end
    end
end
Xs.X=Xm;
end