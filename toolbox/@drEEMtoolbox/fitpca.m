function dataout = fitpca(data,options)
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)

arguments
    % Required
    data (1,1) {drEEMdataset.sanityCheckPARAFAC(data)}
    options.maxcomp (1,1) {mustBeNumeric(options.maxcomp),mustBeLessThan(options.maxcomp,10)} = 5;
    options.interpolateMissing (1,1) {mustBeA(options.interpolateMissing,'logical')} = true;
    options.deleteLow (1,1) {mustBeA(options.deleteLow,'logical')} = false;
end


% Handle missing data by inpainting
if options.interpolateMissing
    for j=1:data.nSample
        data.X(j,:,:) = inpaint_nans(squeeze(data.X(j,:,:)),1);
    end

    % then reintroducing the scatter diagonals
    idx=drEEMhistory.searchhistory(data.history,'handlescatter','all');
    if isempty(idx)
        %nothing yet
    else
        for j=1:numel(idx)
            opt=data.history(idx(j)).details;
            data=drEEMtoolbox.handlescatter(data,opt);
        end
    end
end


tens2mat=@(x,sz1,sz2,sz3) reshape(x,sz1,sz2*sz3);
lev=@(x) diag(x*(x'*x)^-1*x');

% Unfold the data (prep for PCA)
X=data.X;
Xbackup=X;
Xunf          = tens2mat(X,data.nSample,data.nEm,data.nEx);
Xbackup       = tens2mat(Xbackup,data.nSample,data.nEm,data.nEx);

% Preprocess: Delete observations that are always missing
excl=all(isnan(Xbackup),1); % Exclude variables that are all NaN (scatter)
incl=not(excl); % Just the opposite (needed elsewhere)
Xunf(:,excl) = [];
Xbackup(:,excl) = [];


% Preprocess: Mean center samples
[Xunf,~,s]    = nway.tools.nprocess(Xunf,[1 0],[1 0],[],[],1,-1);
[Xbackup]     = nway.tools.nprocess(Xbackup,[1 0],[1 0],[],[],1,-1);

% Preprocess: Delete low intensity samples (<5x median intensity)
s=s{1};
if options.deleteLow
    lowdelete=s>5*median(s); % Exclude exceptionally low signal samples
else
    lowdelete=false(size(Xunf,1),1);
end


if options.deleteLow
    % Mark low samples (also samples containing _ANY_ NaN)
    lowdelete = lowdelete|any(isnan(Xbackup),2);
    Xunf(lowdelete,:) = [];
else
    % This only marks samples that contain _ANY_ NaN (svd can't handle that)
    lowdelete=any(isnan(Xbackup),2);
    Xunf(lowdelete,:) = [];
end

% PCA models
warning off
[~,~,V] = svd(Xunf,"econ"); %V = coeff/loads
warning on

% Extract scores and loadings and other metrics
score=Xunf*V(:,1:options.maxcomp);
scores=nan(data.nSample,options.maxcomp);
scores(not(lowdelete),:)=score;

loads=V(:,1:options.maxcomp);
data_ssq=sum(Xunf(:).^2);
Xhat=scores*loads';
Xhat_sse=sum(Xhat(:).^2,"omitmissing");
sse=data_ssq-Xhat_sse;
for j=1:options.maxcomp
    Xhat=scores(:,j)*loads(:,j)';
    error_ssq=data_ssq-sum(Xhat(:).^2,"omitmissing");
    explained(j,1)=100 * (1 - error_ssq / data_ssq );
end

model=drEEMmodel;
model.modelName='PCA';
model.leverages={lev(scores) lev(loads) {} };
model.loads={scores,loads, {} };
model.percentExplained=sum(explained);
model.error=sse;
model.status='Model fitted';
model.core=nan;
model.percentUnconverged=0;
model.componentContribution=explained;
model.starts=1;
model.convergence=nan;
model.constraints='orthogonality on mean centered data';
model.toolbox='MATLAB internal SVD (econ)';
model.initialization='algorithmically';
model.loadingsMatrix=nan(options.maxcomp,data.nEm,data.nEx);
for j=1:options.maxcomp
    dat=nan(data.nEm*data.nEx,1);
    dat(incl)=model.loads{2}(:,j);
    model.loadingsMatrix(j,:,:)=reshape(dat,data.nEm,data.nEx);
end

dataout=data;
f=drEEMdataset.modelsWithContent(data);
if not(isempty(f))
    idx=height(dataout.history)+1;
    dataout.history(idx,1)=...
        drEEMhistory.addEntry(mfilename,['deleted existing models due to call of "fitpca"'],options,dataout);
    dataout.models=drEEMmodel;
end

dataout.models(options.maxcomp)=model;
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,['fit PCA model to raw data'],options,dataout);


end