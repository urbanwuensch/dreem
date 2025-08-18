function [ modelout,neworder] = reordercomponents( model,varargin )
% Internal function, hence no documentation.

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
%% Input parsing
if nargin==1
    method='emmax';
    f=find(arrayfun(@(x) not(isempty(x.loads)),model.models));
elseif nargin>1
    % 2 varargs 1st:
    for n=1:numel(varargin)
        if isnumeric(varargin{n})
            f=varargin{n};
        elseif ischar(varargin{n})
            method=varargin{n};
        end
    end
    
    if not(exist('method','var'))
        method='emmax';
    end
    
    if not(exist('f','var'))
        f=find(arrayfun(@(x) not(isempty(x.loads)),model.models));
    end
    
    if nargin>3
        error('reordercomponents only parses three input arguments.')
    end
end

        
clearvars cnt
modelout=model;
neworder=cell(max(f),1);
for j=1:numel(f)
    n=f(j);
    % if isempty(model.models(n).loads)
    %     disp(modelout.models)
    %     error('reodercomponents:fields',...
    %         'The dataset does not contain a model with the specified number of factors')
    % end
    
    M = modelout.models(n).loads;
    Csize = modelout.models(n).componentContribution;
    switch method
        case 'emmax'
            [~,idx]=max(M{2});
            [~,seq]=sort(idx);
        case 'emmaxinv'
            [~,idx]=max(M{2});
            [~,seq]=sort(idx,'descend');
        case 'waveem'
            waveem=mean(modelout.Em.*M{2});
            [~,seq]=sort(waveem);
        case 'apparentstokes'
            [~,idx]=max(M{2});
            Em_pos=1./model.Em(idx).*1E7;
            [~,idx]=max(M{3});
            Ex_pos=1./model.Ex(idx).*1E7;            
            astokes=Ex_pos-Em_pos;
            astokes=astokes.*1.23981E-4;
            [~,seq]=sort(astokes);
        case 'contribution'
            [~,seq]=sort(diag(M{1}'*M{1}),'descend');
        otherwise
            error('''method'' must be one of the following: [emmax|waveem|apparentstokes|contribution]')
    end
    neworder{n}=seq;
    
    Mnew=cell(1,3);

    CsizeNew=Csize(seq);
    for i=1:numel(M)
        Mnew{i}=M{i}(:,seq);
    end
    
    modelout.models(n).loads = Mnew;
    modelout.models(n).componentContribution = CsizeNew;
end


% In case f was just one specific component, neworder need not be a cell array
if n==1
    neworder=neworder{1};
end

message={'emmax','emission maximum';...
    'waveem','weigted average emission maximum';...
    'apparentstokes','apparent Stokes shift (max. Ex/Em)';...
    'contribution','component contribution (drEEM/N-way default)'};

midx=contains(message(:,1),method);

disp(sprintf(['\nModels with [',num2str(f'),'] components reordered according to the ',message{midx,2},'\n'])) %#ok<DSPS>

end