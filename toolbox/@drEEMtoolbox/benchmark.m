function  varargout=benchmark
% <a href = "matlab:doc benchmark">[singlescore,multiscore,tsinglecore] = benchmark (click to access documentation)</a>
%
% <strong>Perform CPU benchmark</strong> using a PARAFAC problem.
%

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
funmode=parallelcomp;

fpath=[drEEMtoolbox.tbxpath,'doc',filesep,'benchmarkDataset.mat'];
load(fpath,'data')
X=data.X;
clearvars data
nfac=5;

opthere=struct;
opthere.ConvCrit=1e-6;
opthere.MaxIt = 5000;

%% Single core stuff
disp('single-core non-negative PARAFAC (50 passes) ... ')
s_tpm=tic;
for j=1:50
    rs(j)=parafac3w(X,nfac,opthere); %#ok<AGROW>
end
s_its=arrayfun(@(x) x.it/x.tela,rs); % Iterations per second
s_tpm=toc(s_tpm)./50; % time per model

%% Multicore stuff
if matches(funmode,'parallel')
    disp('multi-core non-negative PARAFAC (100 passes) ... ')
    nc=gcp().NumWorkers;
    tela=tic;
    parfor j=1:100
        rp(j)=parafac3w(X,nfac,opthere);
    end
    tela=toc(tela);
    
    p_its=arrayfun(@(x) x.it/x.tela,rp); % iterations per second per model
    p_tpm=sum(arrayfun(@(x) x.tela,rp))./100; % time per model
    p_its_overall=sum(arrayfun(@(x) x.it,rp))./tela;  % apparent iterations per second (parallel)
    
    sp=p_its_overall./median(s_its);
end
%% Messages at the end
disp(' ')
disp('................................................................')
disp('<strong>drEEM toolbox PARAFAC CPU Benchmark results</strong>')
disp('................................................................')
disp('<strong>Scores ...</strong>')
disp(['Single-core score (higher is better):            <strong>',num2str(round(median(s_its))),'</strong>'])
if matches(funmode,'parallel')
    disp(['Multi-core  score (higher is better):            <strong>',num2str(round(p_its_overall)),'</strong>'])
end
disp(' ')
disp('<strong>Other performance indicators ...</strong>')
if matches(funmode,'sequential')
    disp(['Average time per model (lower is better):        <strong>',num2str(round(s_tpm,1)),'s</strong>'])
else
    disp(['Average time per model (lower is better):        <strong>',num2str(round(s_tpm,1)),...
        's (sequential) vs. ',num2str(round(p_tpm,1)),'s (parallel)</strong>'])
end
if matches(funmode,'parallel')
    disp(['Multi-core accel. factor (higher is better):     <strong>',num2str(round(sp,1)),' with ',num2str(nc),' cores ("workers")','</strong>'])
end
disp('................................................................')

singlescore=round(median(s_its));
if matches(funmode,'parallel')
    multiscore=round(p_its_overall);
else
    multiscore=missing;
end
tsinglecore=s_tpm;
out=[singlescore,multiscore,tsinglecore];
for j=1:nargout
    varargout{j}=out(j);
end
end

function funmode=parallelcomp
test=ver;
funmode='sequential';
consoleoutput='none';
if any(contains({test.Name},'Parallel'))
    funmode='parallel';
    try
        initppool(consoleoutput)
    catch
        funmode='sequential';
    end
end
end

function initppool(consoleoutput)
warning off
try
    poolsize=feature('NumCores');
    p = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(p)
        parpool;
    elseif p.NumWorkers~=poolsize
        warning(['Found existing parpool, but features("NumCores") is not the ' ...
            'same as the number of workers. You might want to take a look at your configuration'])
        % if ~strcmp(consoleoutput,'none')
        %     disp('Found existing parpool with wrong number of workers.')
        %     disp(['Will now create pool with ',num2str(poolsize),' Workers.'])
        % end
        % delete(p);
        % parpool('local',poolsize);
    else
        if ~strcmp(consoleoutput,'none')
            disp(['Existing parallel pool of ',num2str(p.NumWorkers),' workers found and used...'])
        end
    end
catch ME
    rethrow(ME)
end
warning on
end