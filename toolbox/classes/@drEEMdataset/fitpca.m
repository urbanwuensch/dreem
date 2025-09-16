function results = fitpca(data)
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)

arguments
    % Required
    data (1,1) {drEEMdataset.sanityCheckPARAFAC(data)}
end

% Some central variables
comp=2;

% Handle missing data by inpainting and then reintroducing the scatter
% diagonals
allnan=squeeze(all(isnan(data.X),1));
for j=1:data.nSample
    if any(isnan(data.X(j,not(allnan))))
        data.X(j,:,:) = inpaint_nans(squeeze(data.X(j,:,:)),1);
    end
end
idx=drEEMhistory.searchhistory(data.history,'handlescatter','all');
if isempty(idx)
    %nothing yet
else
    for j=1:numel(idx)
        opt=data.history(idx).details; clearvars idx
        data=drEEMtoolbox.handlescatter(data,opt);
    end
end

% PCA models
tens2mat=@(x,sz1,sz2,sz3) reshape(x,sz1,sz2*sz3);
lev=@(x) diag(x*(x'*x)^-1*x');

X=data.X;
Xbackup=X;

Xunf          = tens2mat(X,data.nSample,data.nEm,data.nEx);
Xbackup       = tens2mat(Xbackup,data.nSample,data.nEm,data.nEx);

[Xunf,~,s]    = nway.tools.nprocess(Xunf,[1 0],[1 0],[],[],1,-1);
[Xbackup]     = nway.tools.nprocess(Xbackup,[1 0],[1 0],[],[],1,-1);

s=s{1};
lowdelete=false(size(Xunf,1),1);

excl=all(isnan(Xbackup),1); % Exclude variables that are all NaN (scatter)
incl=not(excl);
Xunf(:,excl) = [];
Xbackup(:,excl) = [];
lowdelete = lowdelete|any(isnan(Xbackup),2); % Mark samples (also samples containing ANY NaN)

Xunf(lowdelete,:) = [];
warning off
% [loads, score, ~ , ~ , explained] = pca(Xunf,...
%     'NumComponents',comp,...
%     'Centered',false,...
%     'Rows','complete');
[U,S,V] = svd(Xunf,"econ"); %V = coeff/loads
score=Xunf*V(:,1:comp);
loads=V;
data_ssq=sum(Xunf(:).^2);

for j=1:comp
    Xhat=score(:,j)*loads(:,j)';
    error_ssq=data_ssq-sum(Xhat(:).^2,"omitmissing");
    explained(j,1)=100 * (1 - error_ssq / data_ssq );
end
warning on
results.loads = loads;
results.score = score;
results.explained = explained;
results.lev=lev(score);

for j=1:comp
    dat=nan(data.nEm*data.nEx,1);
    dat(incl)=results.loads(:,j);
    results.loadsEEM(j,:,:)=reshape(dat,data.nEm,data.nEx);
end

end