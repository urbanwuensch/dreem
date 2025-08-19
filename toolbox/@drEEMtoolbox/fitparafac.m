function dataout = fitparafac(data,mode,options)
% <a href = "matlab:drEEMtoolbox.doc('fitparafac')">dataout = fitparafac(data,options) (click to access documentation)</a>
%
% <strong>Fit PARAFAC models to fluorescence data</strong>
%
% <strong>INPUTS - Required</strong>
% data (1,:) {drEEMdataset.sanityCheckPARAFAC(data)}
% 
% <strong>INPUTS - Optional</strong> 
% f (1,:)                 {mustBeNumeric,mustBeNonempty} = 2:7
% mode (1,:)              {mustBeMember(["overall","split"])} = 'overall'
% constraints (1,:)       {mustBeMember(["unconstrained", "nonnegativity", "unimodnonneg"])} = 'nonnegativity'
% starts  (1,:)           {mustBeNumeric} = 40
% convergence (1,:)       {mustBeLessThanOrEqual(1e-2)} = 1e-6
% maxIteration (1,1)      {mustBeNumeric} = 3000
% initialization (1,:)    {mustBeMember(["svd", "random","multiplesmall"])} = 'random'
% parallelization (1,1)   {mustBeNumericOrLogical}= true
% consoleoutput (1,:)     {mustBeMember(["all", "minimum","none"])} = 'minimum'
% toolbox (1,:)           {mustBeMember(["parafac3w","nway", "pls"])} = 'parafac3w'
%
% <strong>EXAMPLE(S)</strong> (see documentation for assumed defaults!)
%   1. Fit models similar to the previous <strong>outliertest</strong> 
%       samples = tbx.fitparafac(samples,f=2:7,convergence=1e-4,starts=2);
%   2. Find the <strong>global minimum</strong> for a dataset
%       samples = tbx.fitparafac(samples,f=4:6,convergence=1e-8,starts=50,maxIteration=5000);
%   3. Explore what happens with <strong>no constraints</strong>
%       samples = tbx.fitparafac(samples,f=2:7,constraints="unconstrained",convergence=1e-6,starts=10,maxIteration=5000);
%   4. Equivalent to the former <strong>splitanalysis</strong>
%       samples = tbx.fitparafac(samples,f=2:7,mode="split",convergence=1e-8,starts=50,maxIteration=5000);
%
% <a href = "matlab:drEEMtoolbox.doc('fitparafac')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    % Required
    data (1,:)                      {drEEMdataset.sanityCheckPARAFAC(data),drEEMdataset.mustContainSamples(data)}
    mode (1,:)              {mustBeMember(mode,["fitoverall","fitsplits"])} = 'fitoverall'
    % Optional (but important)
    options.f (1,:)                 {mustBeNumeric,mustBeNonempty} = 2:7
    

    % Optional
    options.constraints (1,:)       {mustBeMember(options.constraints,["unconstrained", "nonnegativity", "unimodnonneg"])} = 'nonnegativity'
    options.starts  (1,:)           {mustBeNumeric} = 40
    options.convergence (1,:)       {mustBeLessThanOrEqual(options.convergence,1e-2)}= 1e-8
    options.maxIteration (1,1)      {mustBeNumeric}= 3000

    % Very optional
    options.initialization (1,:)    {mustBeMember(options.initialization,["svd", "random","multiplesmall"])} = 'random'
    options.parallelization (1,1)   {mustBeNumericOrLogical}= true
    options.consoleoutput (1,:)     {mustBeMember(options.consoleoutput,["all", "minimum","none"])}='minimum'
    options.toolbox (1,:)           {mustBeMember(options.toolbox,["parafac3w","nway", "pls"])} = 'parafac3w'
end

%% Input argument handling
if matches(mode,"fitsplits")
    if numel(data.split)==0
        error('mode="fitsplits" requires data.split to be populated with datasets. Have you run "splitdataset.m"?')
    end
end

% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    nargoutchk(1,1)
end

if not(matches(options.constraints,'nonnegativity'))&&matches(options.toolbox,'parafac3w')
    disp('<strong>Notice:</strong> Automatically changed from the default toolbox to nway')
    options.toolbox="nway";
end

%% Version check
if isMATLABReleaseOlderThan("R2022a")
    error("You need Matlab R2022a or newer to use this function.")
end

%% Setup
[oldp,newp]=tboxinit(options.toolbox);
if options.parallelization==true
    funmode=parallelcomp(options.consoleoutput);
else
    funmode='sequential';
end
opt = setoptions(options.toolbox,...
    options.constraints, ...
    options.convergence, ...
    options.maxIteration, ...
    options.initialization);
fac=options.f;

if matches(mode,'fitoverall')
    nsplit=1;
    mdata=data;
    mdata.split=mdata; % mdata.split is a dummy to make the modes work
elseif matches(mode,'fitsplits')
    nsplit=numel(data.split);
    mdata=data;
end
nfac=numel(fac);
numstarts=nsplit*options.starts*nfac;
facCalls=reshape(repmat(fac,options.starts*nsplit,1),numstarts,1);
splitsource=reshape(repmat((1:nsplit),options.starts,nfac),numstarts,1);

ivalsCalls=cell(1,numstarts);
%% Welcome messages
if ~matches(options.consoleoutput,'none')
    disp('  ')
    disp('-----')
    disp(['PARAFAC engine:                  ',char(options.toolbox)])
    disp(['Parallelization:                 ',char(categorical(options.parallelization))])
    disp(['Models with components:          [',num2str(options.f),']'])
    disp(['Number of random starts:         ',num2str(options.starts)])
    disp(['Convergence criterion:           ',num2str(options.convergence)])
    disp(['Maximum number of iterations:    ',num2str(options.maxIteration)])
    disp(['Constraint:                      ',char(options.constraints)])
    disp(['% missing numbers:               ',num2str(round( (sum(isnan(data.X(:)))./numel(data.X))*100 ,3))])
    disp('-----')
    disp('  ')
end
%% Submit the models
ttot=tic;
switch funmode
    case 'sequential'
         modout = repelem(struct('model',{},'err',{},'iterations',{}),1,numstarts); % Preallocate output
         h=waitbar(0,'PARAFAC models are being calculated');
        for i=1:numstarts
            modout(i)=dreemparafac(mdata.split(splitsource(i)).X,facCalls(i),opt,options.toolbox,ivalsCalls{i}); 
            try
                h=waitbar(i/numstarts,h,['PARAFAC models are being calculated [',num2str(i),'/',num2str(numstarts),']']);
            catch
                disp('Waitbar was closed, but function will keep running.')
            end
        end
        close(h)
        Model={modout.model}';
        Iter=arrayfun(@(x) x.iterations,modout,'UniformOutput',false)';
        Err=arrayfun(@(x) x.err,modout,'UniformOutput',false)';
        for ii=1:numel(Model)
            corecon{ii,1}=nway.modeleval.corcond(mdata.split(splitsource(i)).X,Model{ii},[],0);
        end

    case 'parallel'
        modout(1:numstarts) = parallel.FevalFuture; % Preallocate output
        
        for i=1:numstarts
            modout(i)=parfeval(@dreemparafac,1,mdata.split(splitsource(i)).X,facCalls(i),opt,options.toolbox,ivalsCalls{i});
        end
        [Model,Iter,Err,ttc]=...
            trackprogress(modout,numstarts,facCalls,options.consoleoutput,splitsource);
end
disp('<strong>All models finsished.</strong> Calculating model metrics ...')
restoreoldpath(oldp,newp); % In case matlabpath was changed, restore it.
%% Retreive results
Err=cellfun(@(x) x(:),Err);
Iter(cellfun(@(x) isempty(x),Iter))={NaN};
Iter=cellfun(@(x) x(:),Iter);
dataout=data;

if (nsplit*numel(fac))>7
    disp(['This might take a moment with ',num2str(nsplit*numel(fac)),' models in total ...'])
end

for j=1:nsplit
    %mdl=drEEMmodel;
    for k=1:numel(fac)
        conum=fac(k);

        idx=splitsource==j&facCalls==conum;
        spltsrc = splitsource(idx);
        
        
        ihere=Iter(idx);
        ehere=Err(idx);
        ehere(ihere==options.maxIteration)=NaN;
        if all(isnan(ehere))
            continue
        end
        mhere=Model(idx);
        pu=sum(isnan(ehere))/numel(ehere)*100;
        [~,midx] = min(ehere,[],"omitmissing");
        
        measuredF = mdata.split(spltsrc(midx)).X;
        measuredSS = sum(measuredF(:).^2,'omitnan'); % sum of sq. data
        modelledF = nway.modeleval.nmodel(mhere{midx});
        
        mdl=drEEMmodel;
        mdl.loads=mhere{midx};

        for n=1:numel(mdl.loads)
            lev=diag(mdl.loads{n}*(mdl.loads{n}'*mdl.loads{n})^-1*mdl.loads{n}');
            mdl.leverages(1,n)={lev};
        end

        E=measuredF-modelledF;
        E_ex = squeeze(sum(sum(E.^2,1,'omitnan'),2,'omitnan'));
        E_em = squeeze(sum(sum(E.^2,1,'omitnan'),3,'omitnan'))';
        E_sample = squeeze(sum(sum(E.^2,2,'omitnan'),3,'omitnan'));
        mdl.sse={E_sample E_em E_ex};
        
        mdl.status='not yet validated';
        mdl.percentExplained=...
            100 * (1 - ehere(midx) / measuredSS );

        mdl.error=ehere(midx);
        mdl.core=nway.modeleval.corcond(mdata.split(spltsrc(midx)).X,mdl.loads);
        mdl.percentUnconverged=pu;

        sizeF=nan(1,size(mdl.loads{1},2));
        for l=1:size(mdl.loads{1},2)
            modelledH=nway.modeleval.nmodel([{mdl.loads{1}(:,l)} {mdl.loads{2}(:,l)} {mdl.loads{3}(:,l)}]);
            sizeF(l)=100 * (1 - (sum((measuredF(:) - modelledH(:)).^2,'omitnan')) / measuredSS);
        end
        mdl.componentContribution=sizeF;
        mdl.initialization=options.initialization;
        mdl.starts=options.starts;
        mdl.convergence=options.convergence;
        mdl.constraints=options.constraints;
        mdl.toolbox=options.toolbox;
    
        if nsplit==1
            dataout.models(conum,1)=mdl;
        elseif nsplit>1
            dataout.split(j).models(conum,1)=mdl;
        end
    end
end



switch funmode
    case 'parallel'
    ttot=toc(ttot);
    ttc=sum(seconds(ttc));
    ips=sum(Iter)/ttot;
    if ~strcmp(options.consoleoutput,'none')
        disp(' ')
        disp(['Done. This took: ',num2str(round(ttot./60,2)),'min. Iterations per second (parallelized): ',num2str(round(ips))])
        disp(' ');
    end
 case 'sequential'
    ttot=toc(ttot);
    if ~strcmp(options.consoleoutput,'none')
        disp(' ')
        disp('Finished.')
        disp(['Time elaped: ',num2str(round(ttot./60,2)),'min.'])
    end
end

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,['fit parafac models (',char(mode),')'],options,dataout);

if matches(mode,"fitsplits")
    C=drEEMdataset.validatableModels(dataout);
    if isempty(C)
        warning('"f = drEEMdataset.validatableModels(data)" is empty. Could not auto-validate the models in the dataset.')
    end
    for j=1:numel(C)
        res=drEEMtoolbox.silentvalidation(dataout,C(j));
        if res
            disp(['<strong> Successful validation </strong> (',num2str(C(j)),'-compnent model)'])
            dataout.models(C(j)).status='validated';
        else
            disp(['<strong> Failed validation </strong> (',num2str(C(j)),'-compnent model)'])
            dataout.models(C(j)).status='not validated';
        end
        
    end
end


% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
end

end

%% Internal functions used above (shared with splitanalysis)
function funmode=parallelcomp(consoleoutput)
test=ver;
funmode='sequential';
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

%%
function [oldp,newp]=tboxinit(tbox)
warning off
oldp = path;
mlpath = path;mlpath=textscan(mlpath,'%s','delimiter',pathsep);mlpath=mlpath{:};
nway=contains(mlpath,'drEEM');
plsp=contains(mlpath,'PLS');

switch tbox
    case {'nway','parafac3w'}
        if find(nway,1,'first') > find(plsp,1,'first')
            rmpath(mlpath{nway|plsp});
            addpath(mlpath{plsp});
            addpath(mlpath{nway});
        end
    case 'pls'
        if find(nway,1,'first') < find(plsp,1,'first')
            rmpath(mlpath{nway|plsp});
            addpath(mlpath{nway});
            addpath(mlpath{plsp});
        end
        clearvars plsp
        try
            pls test
            disp('Testing PLS_toolbox'),evridebug
        catch
            error('PLS_toolbox either not installed or not functional.')
        end
    otherwise
        error('That''s a toolbox I don''t know about.')
end
newp = path;
warning on
end

%%
function opt = setoptions(tbox,constraints,convgcrit,maxIt,initstyle)
if contains(tbox,'pls')
    opt=parafac('options');
    opt.plots='none';
    opt.waitbar='off';
    opt.coreconsist='off';
    opt.display='on';

    if contains(constraints,'nonnegativity')
        % Set default: All dims nonnegative
        cdim=[1:3];
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
        for i=cdim;opt.constraints{i}.type='nonnegativity';end
    elseif contains(constraints,'unimodality')
        for i=[1 3];opt.constraints{i}.type='nonnegativity';end
        opt.constraints{2}.type='unimodnonneg';
    end
    if contains(initstyle,'svd')
        opt.init=2;
    elseif contains(initstyle,'random')
        opt.init=3;
    elseif contains(initstyle,'given')
        opt.init=0;
    end
    opt.stopcriteria.iterations=maxIt;
    opt.stopcriteria.relativechange=convgcrit;
elseif contains(tbox,'nway')||contains(tbox,'parafac3w')
    if contains(constraints,'nonnegativity')
        % Set default: All dims nonnegative
        cdim=[1:3];
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
        for i=cdim;opt.constraints{i}.type=2;end
        for i=setdiff(1:3,cdim);opt.constraints{i}.type=0;end
        
    elseif contains(constraints,'unimodnonneg')
        for i=[1 3];opt.constraints{i}.type=2;end
        opt.constraints{2}.type=3;
    elseif contains(constraints,'unconstrained')
        for i=1:3;opt.constraints{i}.type=0;end
    end
    if contains(initstyle,'svd')
        opt.init=1;
    elseif contains(initstyle,'random')
        opt.init=2;
    elseif contains(initstyle,'multiplesmall')
        opt.init=10;
    elseif contains(initstyle,'given')
        opt.init=0;
    end
    opt.stopcriteria.iterations=maxIt;
    opt.stopcriteria.relativechange=convgcrit;
end

end

%%
function [out] = dreemparafac(tensor,f,opt,tbox,initvalues)
vec=@(x) x(:);
% Start the PARAFAC model. PLS_toolbox reads a pref-file, which is tricky if
% that's done in parallel. This here is to catch errors related to that.
if opt.init==0
    for n=1:3
        randvals=rand(size(initvalues{n},1),size(initvalues{n},2));
        randvals=randvals./vecnorm(randvals,2);
        idx=isnan(initvalues{n});
        initvalues{n}(idx)=randvals(idx);
    end
end
% plotfac(initvalues)
switch tbox
    case 'pls'
        tries=0;
        while tries<100
            try
                disp(datetime)
                if opt.init~=0
                    outlocal=parafac(tensor,f,opt);
                elseif opt.init==0
                    outlocal=parafac(tensor,initvalues,opt);
                    disp('Initialization with given values')
                end
                tries=102;
            catch ME
                tries = tries+1;
                pause(rand(1)/16);
                if tries>100
                    disp('PLS PARAFAC could not be initiated due to error')
                    rethrow(ME)
                end
            end
        end
        out.model = outlocal.loads;
        out.iterations = outlocal.detail.critfinal(3);
        out.err = outlocal.detail.ssq.residual;
    case {'nway','parafac3w'}
        constraints=[opt.constraints{1}.type opt.constraints{2}.type opt.constraints{3}.type];
        optInNew=true;
        if matches(tbox,'nway')
            optInNew=false;
        end
        if opt.init~=0&&not(all(constraints==2))
            [Factors,it,err,~] = nway.models.parafac(tensor,f,...
                [opt.stopcriteria.relativechange opt.init 0 0 50 opt.stopcriteria.iterations],...
                constraints);
            out.model = Factors;
            out.iterations = it;
            out.err = err;
            clearvars Factors it err
        elseif opt.init==0
            [Factors,it,err,~] = nway.models.parafac(tensor,f,...
                [opt.stopcriteria.relativechange opt.init 0 0 50 opt.stopcriteria.iterations],...
                constraints,...
                initvalues,[0 0 0]);
            out.model = Factors;
            out.iterations = it;
            out.err = err;
            clearvars Factors it err
        elseif opt.init~=0&&all(constraints==2)
            if optInNew
                opthere=struct;
                opthere.ConvCrit=opt.stopcriteria.relativechange;
                opthere.MaxIt = opt.stopcriteria.iterations;
                res=parafac3w(tensor,f,opthere);

                out.model={res.A res.B res.C};
                out.iterations=numel(res.allfits);
                out.err=sum(vec(tensor-nway.modeleval.nmodel({res.A,res.B,res.C})).^2,'omitnan');
            elseif not(optInNew)
                [Factors,it,err,~] = nway.models.parafac(tensor,f,...
                    [opt.stopcriteria.relativechange opt.init 0 0 50 opt.stopcriteria.iterations],...
                    constraints);
                out.model = Factors;
                out.iterations = it;
                out.err = err;
                clearvars Factors it err
            end

        end
        
        
end
end

%%
function restoreoldpath(oldp,newp)
    if ~isequal(oldp,newp)
        path(oldp)
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
        if ~(sz(1)<sz(2))
            vout=v';
        else
            vout=v;
        end
    case 'column'
        if ~(sz(1)>sz(2))
            vout=v';
        else
            vout=v;
        end
    otherwise
            error('Input ''rc'' not recognized. Options are: ''row'' and ''column''.')
end


end

%%
function [cncl] = blockbar(names,state,col)
% Blockbar is similar to a multiwaitbar, but visualizes the state of
% individual jobs rather than a % completed bar.
% (c) Urban Wünsch, 2019 (first version).
% Modified for drEEM 2.0
%% Default options
icalpha = 0.2;
 calpha = 1;

multi=numel(names);
init=true; % init state is true by default. When old figure is found, init = false.
cncl=false(numel(names),1);
%% Find existing blockbar and axes within it (not the buttons)
figHandles =  findall(0,'Type','figure','tag','Progress uifigure for drEEM');
for n=1:numel(figHandles)
    if strcmp(figHandles(n).Name,'Progress...')
        init=false; % Success, do not make another figure, use the old
        old=figHandles(n);
        break
    end
end
% Close blockbar if 'close' is requested by user
if ischar(names)&&sum(strcmp(names,'close'))==1
    try
       close(old)
       return
    catch
        warning('Coudn''t close the blockbar. Probably, there was none.')
        return
    end
end
% Check input
if numel(names)~=size(state,1)
    warning('Size of ''names'' and ''state'' are inconsistent. Can''t draw the blockbar...')
    return
end
if size(state,2)~=size(col,1)
    warning('Size of ''state'' and ''col'' are inconsistent. Can''t draw the blockbar...')
    return
end
%% Draw the blockbar
stp=[0:1/size(state,2):1 1];
if init % This generates the figure and bars
    screenSize = get(0,'ScreenSize');
    pointsPerPixel = 72/get(0,'ScreenPixelsPerInch');
    width = 360 * pointsPerPixel;
    height = multi * 75 * pointsPerPixel;
    fpos = [screenSize(3)/2-width/2 screenSize(4)/2-height/2 width height];
    figureh=uifigure('Position',fpos,...
        'MenuBar','none',...
        'Numbertitle','off',...
        'Name','Progress...',...
        'Resize','off',...
        Tag='Progress uifigure for drEEM',Units='pixels', ...
        WindowStyle='alwaysontop');
    axeswidth = round(width*0.6);
    axesheight = round(axeswidth/14);
    axesbottom = fliplr(linspace(15,fpos(4)-axesheight*3,multi));
    addprop(figureh,'state');
    addprop(figureh,'sname');
    figureh.state=state;
    figureh.sname=names;
    for i=1:numel(names)
        axPos = [axesheight*2.5 axesbottom(i) axeswidth axesheight];
        bPos = [axPos(1)+axPos(3)+10 axPos(2) 50 axPos(4)*1.5];
        bPos(2) = bPos(2)-0.5*(bPos(4)-axPos(4));
        ax(i)=axes(figureh,'units','pixel','pos',axPos); %#ok<AGROW>
        addprop(ax(i),'sname');
        set(ax(i),'units','pixel','Tag',names{i});
        uic=uicontrol(figureh,'Style', 'togglebutton', ...
            'String', '', ...
            'FontWeight', 'Bold', ...
            'units','pixel',...
            'Position',bPos,...
            'Tag',num2str(i),...
            'String','Cancel','FontWeight','normal');
        addprop(uic,'snames');
        uic.snames=i;
        
        title(ax(i),names{i});
        set(ax(i),'YTickLabel','');
        set(ax(i),'XTickLabel','');
        for n=1:size(state,2)
            if state(i,n)
                av=calpha;
            else
                av=icalpha;
            end
            p=patch(ax(i),[stp(n) stp(n+1) stp(n+1) stp(n)],[0 0 1 1],col(n,:),...
                'EdgeColor','none','FaceAlpha',av);hold(ax(i),"on")
            addprop(p,'id');
            p.id=n;
        end
        set(ax(i),'YColor',[0 0 0 0.5],'XColor',[0 0 0 0.5],'Box','on','YTick','','XTick','')
    end
    drawnow
    %uistack(figureh, 'top')
else % This updates  the figure and bars
    oldstate=old.state;
    if ~isequal(oldstate,state)
        ax=get(old,'Children');
        ax=ax(strcmp(get(ax,'Type'),'axes'));
        ni=multi:-1:1;
        for n=1:numel(names)
            newstate=state(n,:);
            if ~isequal(oldstate,newstate)
                h=get(ax(ni(n)),'Children');
                ii=size(state,2):-1:1;
                for i=1:size(state,2)
                    if state(n,i)&&~oldstate(n,i)
                        h(ii(i)).FaceAlpha=calpha;
                    end
                end
            end
        end
        old.state=state;
    end
    childs=get(old,'Children');
    tbutt=childs(strcmp(get(childs,'Type'),'uicontrol'));
    ni=multi:-1:1;    
    for n=1:numel(names)
        if logical(tbutt(ni(n)).Value)&&any(~state(n,:))
            cncl(n)=true;
        else
            cncl(n)=false;
        end
    end
    drawnow
    %uistack(old, 'top')
end
end


%%
function [Model,Iter,Err,ttc] = trackprogress(futures,numtry,facCalls,consoleoutput,splitsource)
% Monitor parfeval progress supervision (c) Urban Wünsch, 2016-2019

% Allocation of PARAFAC outputs
Model = cell(numtry,1);            % Allocate Model cell
Iter = cell(numtry,1);             % Allocate cell for #of interations
Err = cell(numtry,1);              % Allocate cell for SSE

% Allocation of monitoring variables
fetchthese=true(1,numel(facCalls));% fetchNext: only these (not cancelled)
completed    = false(numtry,1);    % Complete / incomplete?
numCompleted = 0;                  % Total number of completed models
ttc=repmat(duration,numtry,1);     % time-to-convergence for each run

% Allocation of variables for prelim. plotfacs
facs=unique(facCalls);

% 1st Blockbar
state=false(numel(facs),numtry/numel(facs));
mname=cellstr(strcat(num2str(unique(facs)),...
	repmat(' componenents',numel(unique(facs)),1),...
    repmat(' (color = data set)',numel(unique(facs)),1)))';
col=lines(numel(unique(splitsource)));
col=repelem(col,numtry/numel(unique(facs))./numel(unique(splitsource)),1);
% Close any old blockbar
figHandles = get(0,'Children');
for n=1:numel(figHandles)
    if strcmp(figHandles(n).Name,'Progress...')
        close(figHandles(n));
    end
end
clearvars n figHandles
blockbar(mname,state,col);


while numCompleted < numtry
    ffetch=futures(fetchthese&~completed');
    [completedIdx,Modelres] = fetchNext(ffetch,0.1);
    % If fetchNext returned an output, let's extract it.
    if ~isempty(completedIdx)
        % Get actual index of future if ffetch-futures were subset
        [~,completedIdx]=intersect([futures.ID],ffetch(completedIdx).ID);
        numCompleted = numCompleted + 1;
        % Update list of completed futures.
        completed(completedIdx) = true;
        % Update state to account for completed futures
        state=reshape(completed,numtry/numel(facs),numel(facs))';
        Model{completedIdx,1} = rcvec(Modelres.model,'row');
        Iter{completedIdx,1} = Modelres.iterations;
        Err{completedIdx,1} = Modelres.err;
        
        ttc(completedIdx)=datetime(futures(completedIdx).FinishDateTime,'TimeZone','Europe/London',Format='mm:ss')-...
            datetime(futures(completedIdx).StartDateTime,'TimeZone','Europe/London',Format='mm:ss');
        
        [~,m,s]=hms(ttc(completedIdx));
        ttc_string=[sprintf( '%02d', round(m) ),':',sprintf( '%02d', ceil(s) )];
        if ~strcmp(consoleoutput,'none')||strcmp(consoleoutput,'minimum')
            disp(['# ',sprintf('%03d',completedIdx),' done | #iter: ',...
                sprintf('%-*s',4,num2str(Iter{completedIdx,1})),...
                ' | time: ',ttc_string,...
                ' | it/sec: ',num2str(round(Iter{completedIdx,1}./seconds(ttc(completedIdx))))]);
        end
    end
    % Check status of blockbar
    c=blockbar(mname,state,col);
    
    % Check if any models were cancelled and cancel the unfinished jobs among these models
    fetchthese=~repelem(c,numtry/numel(unique(facCalls)),1)';
    if any(~fetchthese)
        if ~isempty(futures(~fetchthese&~completed'))
            cancel(futures(~fetchthese&~completed'));
            Err(~fetchthese&~completed',1)=num2cell(nan(sum(~fetchthese&~completed'),1));
            numCompleted=numCompleted+numel(futures(~fetchthese&~completed'));
            completed(~fetchthese) = true;
            warning('User canceled some models prematurely. No output fetched for those.')
        end
    end
end
% If complete, cancel the futures and delete the waitbar.
cancel(futures);
blockbar('close');
end