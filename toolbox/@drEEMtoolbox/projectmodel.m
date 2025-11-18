function dataout = projectmodel(data,file)
% <a href = "matlab:drEEMtoolbox.doc('projectmodel')">dataout = projectmodel(data,file) (click to access documentation)</a>
%
% <strong>Project a PARAFAC model (OpenFluor data format) onto an existing dataset (drEEMdataset)</strong>
%
% <strong>INPUTS - Required</strong>
% data (1,:) {drEEMdataset.sanityCheckPARAFAC(data)}
% file (1,:) {mustBeFile}
% 
%
% <strong>EXAMPLE(S)</strong>
%   1. Project OpenFluor model to existing dataset 
%       samples = tbx.projectmodel(samples,'openfluormodel.txt');
% <a href = "matlab:drEEMtoolbox.doc('projectmodel')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMtoolbox.validatedataset(data),drEEMdataset.sanityCheckPARAFAC(data)}
    file (1,:) {mustBeFile}
end

% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    nargoutchk(1,1)
end

% Load the OpenFluor model
model=loadOF(file);

% Convert the contraint to N-Way notation
constraints=model.constraints;
if contains(constraints,'nonnegativity')
        % Set default: All dims nonnegative
        cdim=1:3;
        % Check for custom input (deletes default)
        if ~isempty(erase(constraints,'nonnegativity'))
            t=(erase(constraints,'nonnegativity'));
            cdim=[];
            for n=1:numel(t)
                cdim=[cdim str2double(t(n))];
            end
            if numel(cdim)>3||any(cdim>3)
                error('numeric input to nonnegativity not understood')
            end
        end
        for i=cdim
            opt(i)=2;
        end
        for i=setdiff(1:3,cdim)
            opt(i)=0;
        end
        
    elseif contains(constraints,'unimodnonneg')
        for i=[1 3]
            opt(i)=2;
        end
        opt(2)=3;
    elseif contains(constraints,'unconstrained')
        for i=1:3
            opt(i)=0;
        end
end
% Define the inner boundary for "cutting"
minEx=max([data.Ex(1) model.Ex(1)]);
maxEx=min([data.Ex(end) model.Ex(end)]);
minEm=max([data.Em(1) model.Em(1)]);
maxEm=min([data.Em(end) model.Em(end)]);

% Assign the output variable (data will be modified after)
dataout=data;
% Cut the input data according to the inner boundary (we won't extrapolate)
dataout=drEEMtoolbox.subdataset(dataout,...
    outEx=dataout.Ex<minEx|dataout.Ex>maxEx,...
    outEm=dataout.Em<minEm|dataout.Em>maxEm);

% We will interpolate the model to fit the data (not the other way around)
for j=1:model.nComp
    mi{2}(:,j)=interp1(model.Em,model.model{2}(:,j),dataout.Em);
    mi{3}(:,j)=interp1(model.Ex,model.model{3}(:,j),dataout.Ex);
end

% Create the loads cell and validate the size (parafac is not checking
% that)
initLoads={rand(dataout.nSample,model.nComp);mi{2};mi{3}};
if not(height(initLoads{1})==size(dataout.X,1))
    error('Model vs. data emission size missmatch.')
end
if not(height(initLoads{2})==size(dataout.X,2))
    error('Model vs. data emission size missmatch.')
end
if not(height(initLoads{3})==size(dataout.X,3))
    error('Model vs. data excitation size missmatch.')
end


% Project the old model
[forced,it,err]=nway.models.parafac(dataout.X,model.nComp,[1e-8 2 0 0 -1 5000],opt,...
                initLoads,[0 1 1]);
% Double check. If it==1 or err is nan, something has gone totally wrong
if it==1||isnan(err)
    error('Something went wrong with the forced fitting.')
end

% Allocate the results to a new model structure
mdl=drEEMmodel;
measuredF = dataout.X;
measuredSS = sum(measuredF(:).^2,'omitnan'); % sum of sq. data
modelledF = nway.modeleval.nmodel(forced);

mdl.loads=forced;
mdl.core=nway.modeleval.corcond(dataout.X,forced);
for n=1:numel(mdl.loads)
    lev=diag(mdl.loads{n}*(mdl.loads{n}'*mdl.loads{n})^-1*mdl.loads{n}');
    mdl.leverages(1,n)={lev};
end
clearvars lev

E=measuredF-modelledF;
E_ex = squeeze(sum(sum(E.^2,1,'omitnan'),2,'omitnan'));
E_em = squeeze(sum(sum(E.^2,1,'omitnan'),3,'omitnan'))';
E_sample = squeeze(sum(sum(E.^2,2,'omitnan'),3,'omitnan'));
mdl.sse={E_sample E_em E_ex};

mdl.status='forced projection';
mdl.percentExplained=...
    100 * (1 - err / measuredSS );
mdl.error=err;
mdl.percentUnconverged=0;
sizeF=nan(1,size(mdl.loads{1},2));
for l=1:size(mdl.loads{1},2)
    modelledH=nway.modeleval.nmodel([{mdl.loads{1}(:,l)} {mdl.loads{2}(:,l)} {mdl.loads{3}(:,l)}]);
    sizeF(l)=100 * (1 - (sum((measuredF(:) - modelledH(:)).^2,'omitnan')) / measuredSS);
end
mdl.componentContribution=sizeF;
mdl.initialization=['old loadings: ',char(file)];
mdl.starts=1;
mdl.convergence=1e-8;
mdl.constraints=model.constraints;
mdl.toolbox="nway";
% Transfer structure to dataset
dataout.models(model.nComp)=mdl;


% Housekeeping
disp('Model projection complete. Use e.g. "drEEMtoolbox.viewmodels" to inspect')
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,['PARAFAC model projection forced (',char(file),')'],[],dataout);

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
end
end

function [modout] = loadOF(filename)
%Load a PARAFAC model from an OpenFluor text file
%
% USEAGE:
%     loadOF(filename)
%
% INPUTS:
%      filename: name of the text file to be read, 
%            e.g. 'MyModel6.txt'.
%
% OUTPUTS:
%         modout will be created having fields (modout.): M, Ex, Em, name, ref, nComp
%         and modout.modelN where N=no. components (e.g. Y.model2 for a 2-comp
%         model)
%
% EXAMPLES:
%   drEEM6=loadpmod('D:\PARAFAC\OpenFluor\models\Murphy_drEEM.txt');
%
% Copyright (C) 2018 Urban J. Wuensch

arguments
    filename (1,:) {mustBeText,mustBeFile}
end

%% Read text file
if iscell(filename)
    filename=deblank(char(filename));
end

fid = fopen(filename, 'r');
%Get model name
counter = 1;    
tline = fgetl(fid);
while ischar(tline)
    tline = fgetl(fid);
    data{counter,1}=tline;
    counter=counter+1;
end
fclose(fid);
data(end)=[];

%% Load metadata
modout = struct;
metadata={'name' 'creator' 'email' 'doi' 'reference' 'unit' 'toolbox'...
    'date' 'fluorometer' 'nSample' 'constraints' 'validation' 'methods'...
    'preprocess' 'sources' 'ecozones' 'description'};

space=false; % Text files are tab separated, but some are actually space separated.

for n=1:size(data,1)
    splitdata=strsplit(data{n},'\t');
    if isscalar(splitdata)
        splitdata=strsplit(splitdata{1},' ');
        space=true;
    end
    for i=1:numel(metadata)
        if strcmp(splitdata{1},metadata{i})
            if ~space
                modout.(metadata{i})=splitdata{2};
            else
                modout.(metadata{i})=strjoin(string(char(splitdata(2:end))));
            end
        end
        
    end
    space=false;
    if strcmp(splitdata{1},'Ex')
        istart_import=n;
        break
    end
end
% Conversion of nSample to numeric value
if isfield(modout,'nSample')
    modout.nSample=str2double(modout.nSample);
end
% Hack to get the year of publication
yrs=char(num2str((2000:2050)'));
if isfield(modout,'reference')
    for n=1:size(yrs,1)
        if strfind(modout.reference,yrs(n,1:end))>=1
            modout.year=str2num(yrs(n,:));
            break
        end
    end
end





% Some files might not have a name field. In that case, the filename becomes the model name
if isfield(modout,'name')
    if strcmp(modout.name,'?')
        name=strsplit(filename,'\');
        modout.name=name{end}(1:end-4);
    end
end

% Some models have weird model names, let's make sure they are character arrays
modout.name = char(modout.name);
%% Load component spectra
i_em=1; % Counter for row of emission
i_ex=1; % Counter for row of excitation
for n=istart_import:size(data,1)
    splitdata=strsplit(data{n},'\t');
    if strcmp(splitdata{1},'Ex')
        exload(i_ex,:)=cellfun(@str2double,splitdata(2:numel(splitdata)));
        i_ex=i_ex+1;
    end
    if strcmp(splitdata{1},'Em')
        emload(i_em,:)=cellfun(@str2double,splitdata(2:numel(splitdata)));
        i_em=i_em+1;
    end
end

%% Assign everything to model structure
exload=exload(:,any(~isnan(exload))); % This is a fix if some components don't exist (nan)
emload=emload(:,any(~isnan(emload))); % This is a fix if some components don't exist (nan)

modout.Ex=exload(:,1);
modout.Em=emload(:,1);
modout.nEx=size(modout.Ex,1);
modout.nEm=size(modout.Em,1);
modout.nComp=size(exload,2)-1;
modout.model={{} emload(:,2:end) exload(:,2:end)};
modout=setfield(modout,['Model',num2str(modout.nComp)],modout.model);


%% Some added stuff to make the model structure nicer to work with
modout.filename=filename;



end