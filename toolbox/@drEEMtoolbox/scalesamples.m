function dataout = scalesamples(data,option)
% <a href = "matlab:drEEMtoolbox.doc('scalesamples')">dataout = scalesamples(data,option) (click to access documentation)</a>
%
% <strong>Scale samples</strong> of a dataset by the nth root of the standard deviation or maximum intensity in each sample
%
% <strong>INPUTS - Required</strong>
% data (1,1) {mustBeA("drEEMdataset"),drEEMdataset.validate}
% option (1,:) {mustBeNumeric OR mustBeMember(["max","reverse","help"])} = 2
%
% <strong>EXAMPLE(S)</strong>
%   1. <strong>normeem equivalent</strong> (unit variance scaling)
%       samples = tbx.scalesamples(samples,1);
%   2. <strong>gentle scaling </strong> (Pareto scaling, sqrt of std)
%       samples = tbx.scalesamples(samples);
%   3. <strong>very gentle scaling </strong> (5th root of std)
%       samples = tbx.scalesamples(samples,5);
%   4. <strong>maximum-normalization </strong> (division of intensities by maximum in each sample)
%       samples = tbx.scalesamples(samples,'max');
%   5. <strong>reverse scaling </strong> after it had been applied
%       samples = tbx.scalesamples(samples,'reverse');
%   6. <strong>Don't know what to do? </strong> Get decision help
%       samples = tbx.scalesamples(samples,'help');
%
% <a href = "matlab:drEEMtoolbox.doc('scalesamples')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    option (1,:) {optionValidator(option)} = 2
end



% Run optionValidator again to return the result opmode
opmode=optionValidator(option);
% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if matches(opmode,{'apply','reverse'})
        nargoutchk(1,1)
    else
        if nargout>0
            error('If you supply "help" as second input, no output should be assigned since the function runs in Diagnostics mode.')
        end
    end

end
%% Define some functions and stuff.
tens2mat=@(x,sz1,sz2,sz3) reshape(x,sz1,sz2*sz3);


% If scaling operation is repeated (i.e. dataset was already scaled),
% restore the backup and scale that version (it is up to date!).
pidx=drEEMhistory.searchhistory(data.history,"scalesamples","first");
lastidx=drEEMhistory.searchhistory(data.history,"scalesamples","last");
if not(isempty(pidx))&&not(isempty(lastidx))
    lastmessage=data.history(lastidx).fmessage;
    if not(isempty(pidx))&&matches(opmode,'apply')&&not(contains(lastmessage,'reversed'))
        unscaled=data.history(pidx).previous;
        data.X=unscaled.X;
        
        % But let's document what happened!
        idx=height(data.history)+1;
        data.history(idx,1)=...
            drEEMhistory.addEntry(mfilename,...
            'Repeated scaling; restored unscaled .X',[],data,unscaled);
        warning('FYI, repeated scaling detected. Original was restored and used for this call.')
    end
end

switch opmode
    case 'apply'
        if isnumeric(option)
            if not(option>=1&option<=50)
                error('''intensity'' should be a number between 1 (close to unit variance) and 50 (close to no scaling)')
            end
            
            dataout=data;
            if not(option==1)
                dataout.status=drEEMstatus.change(dataout.status,...
                    "signalScaling",...
                    ['Scaled to ',num2str(option),'th root of standard deviation in sample mode']);
            else
                dataout.status=drEEMstatus.change(dataout.status,...
                    "signalScaling",'Scaled to unit variance in sample mode');
            end
            scalefac=1./nthroot(std(...
                tens2mat(dataout.X,dataout.nSample,dataout.nEm,dataout.nEx)...
                ,0,2,'omitnan'),option);
            
            if any(isnan(scalefac))
                error('Some scaling factors are NaN!')
            end
            
            dataout.X=dataout.X.*scalefac;
            message=['scaling applied nth root of std, n = ',num2str(option)];
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(mfilename,message,[],dataout,data);
        elseif ischar(option)|isstring(option)
            if not(matches(option,'max'))
                error('Somehow, scalesamples believes it is in "opmode", but the input to option is not "max". This should not happen')
            end
            dataout=data;
            X=tens2mat(dataout.X,dataout.nSample,dataout.nEm,dataout.nEx);
            maxval=max(X,[],2,"omitmissing");

            dataout.X=dataout.X./maxval;
            message='EEMs scaled by maximum intensity in each sample';
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(mfilename,message,[],dataout,data);
        end

    case 'reverse'
        dataout=data;
        f=drEEMdataset.modelsWithContent(dataout);
        idx=drEEMhistory.searchhistory(data.history,'scalesamples','first');

        if isempty(idx)
            error('It appears that this dataset has not been scaled before. Exiting...')
        end
        Xnotscaled=data.history(idx).previous.X;
        dataout.X=Xnotscaled;
        for n=1:numel(f)
            loads=data.models(f(n)).loads;
            cc=data.models(f(n)).convergence;
            const=data.models(f(n)).constraints;
            if matches(const,'unconstrained') %no constraints
                constr=[0 0 0];
            elseif matches(const,'nonnegativity') %all non-negative
                constr=[2 2 2];
            elseif matches(const,'unimodnonneg') %unimodal emission
                constr=[2 3 2];
            else
                error(['unknown constraint: ',char(const)])
            end

            
            % cc, init, plotting, scaling, showfit, maxit
            forced=nway.models.parafac(Xnotscaled,f(n),[cc 2 0 0 -1 5000],constr,...
                {rand(data.history(idx).previous.nSample,f(n));loads{2};loads{3}},[0 1 1]);
            dataout.models(f(n)).loads = forced;
           
        end
        disp('Scaling reversed.')
        dataout.status=drEEMstatus.change(dataout.status,...
                "signalScaling","reversed to original units (see signal calibration)");
        idx=height(dataout.history)+1;
        dataout.history(idx,1)=...
            drEEMhistory.addEntry(mfilename,'scaling reversed',[],dataout);

        
    case 'help'
        if isfield(data,'Xnotscaled')
            disp('Data appear to be scaled already. Performing diagnosis on the unscaled data.')
            temp=data;
            temp.X=temp.Xnotscaled;
            scaleeemdiag(temp,[1 5])
        else
            scaleeemdiag(data,[1 5])
        end
        return
    otherwise
        error('Input to ''intensity'' (second input) not understood.')
end

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
end

end



function scaleeemdiag(data,nthrootlim)
% plot peak distributions for different normalization parameters

%% Functions % definitions
mindist  = @(vec,val) find(ismember(abs(vec-val),min(abs(vec-val))),1,'first');
tens2mat = @(x,sz1,sz2,sz3) reshape(x,sz1,sz2*sz3);

nthrootspec=linspace(nthrootlim(1),nthrootlim(2),50);
ploc=[442.5 340;...
    510 390;...
    390 300;...
    345 275];
peakletter={'C';'D';'M';'T'};

%% Calculations
peak=table;
dist=table;

% Distribtions (within peak)
xtemp=data.X./std(tens2mat(data.X,data.nSample,data.nEm,data.nEx),0,2,'omitnan');
for i=1:numel(peakletter)
    dist.(peakletter{i})(:,1)=xtemp(:,mindist(data.Em,ploc(i,1)),mindist(data.Ex,ploc(i,2)));
    peak.(peakletter{i})(:,1)=dist.(peakletter{i})(:,1)./max(dist.(peakletter{i})(:,1),[],1,'omitnan');
end


for n=1:numel(nthrootspec)
    xtemp=data.X./nthroot(std(tens2mat(data.X,data.nSample,data.nEm,data.nEx),0,2,'omitnan'),nthrootspec(n));
    for i=1:numel(peakletter)
        dist.(peakletter{i})(:,n+1)=xtemp(:,mindist(data.Em,ploc(i,1)),mindist(data.Ex,ploc(i,2)));
        peak.(peakletter{i})(:,n+1)=dist.(peakletter{i})(:,n+1)./max(dist.(peakletter{i})(:,n+1),[],1,'omitnan');
    end
end

% xtemp=data.X;
% for i=1:numel(peakletter)
%     dist.(peakletter{i})(:,n+1)=xtemp(:,mindist(data.Em,ploc(i,1)),mindist(data.Em,ploc(i,2)));
%     peak.(peakletter{i})(:,n+1)=dist.(peakletter{i})(:,n+1)./max(dist.(peakletter{i})(:,n+1),[],1,'omitnan');
% end

% Distribtions (across peak)
reldist=table('Size',[(numel(nthrootspec)+1) 4],'VariableTypes',{'double','double','double','double'});

for n=1:size(dist.(peakletter{1}),2)
    reldist.('MT')(n,1)=median(dist.('M')(:,n),'omitnan')./median(dist.('T')(:,n),'omitnan');
    reldist.('CM')(n,1)=median(dist.('C')(:,n),'omitnan')./median(dist.('M')(:,n),'omitnan');
    reldist.('CD')(n,1)=median(dist.('C')(:,n),'omitnan')./median(dist.('D')(:,n),'omitnan');
    reldist.('TD')(n,1)=median(dist.('T')(:,n),'omitnan')./median(dist.('D')(:,n),'omitnan');
end


% Correlations
r=table('Size',[(numel(nthrootspec)+1) 4],'VariableTypes',{'double','double','double','double'});
for n=1:(numel(nthrootspec)+1)
    r.('MT')(n,1)=rsquared(peak.('M')(:,n),peak.('T')(:,n));
    r.('CM')(n,1)=rsquared(peak.('C')(:,n),peak.('M')(:,n));
    r.('CD')(n,1)=rsquared(peak.('C')(:,n),peak.('D')(:,n));
    r.('TD')(n,1)=rsquared(peak.('T')(:,n),peak.('D')(:,n));
end

%% Plotting
% Distribtions (within peak)DS=(DS-nanmin(DS))/(nanmax(DS)-nanmin(DS))
% scaling = @(x) (x-min(x,[],'omitnan'))/(max(x,[],'omitnan')-min(x,[],'omitnan'));
% strength=logspace(1,0,numel(nthrootspec)+1);
% strength=scaling(strength)*100;
strength=[1 nthrootspec];

if data.toolboxOptions.uifig
    f=drEEMtoolbox.dreemuifig;
else
    f=drEEMtoolbox.dreemfig;
end
f.Name='drEEM: scalesamples.m';
t=tiledlayout(f,3,4,'padding','tight','TileSpacing','tight');
for i=1:numel(peakletter)
    ax=nexttile(t);
    hold(ax,'on')
    plot(ax,strength,1-median(peak.(peakletter{i}),'omitnan'),'LineWidth',2,'Color','k')
    title(ax,peakletter{i})
    ylabel(ax,'Median distance from max.')

end


% Distribtions (across peak)

target={'MT','CM','CD','TD'};

for n=1:numel(target)
    ax=nexttile(t);
    scatter(ax,strength,reldist.(target{n}),'filled','k')
    title(ax,[target{n}(1),' / ',target{n}(2)])
    ylabel(ax,'Median distance')

end


% Correlations
target={'MT','CM','CD','TD'};

for n=1:numel(target)
    ax=nexttile(t);
    scatter(ax,strength,r.(target{n}),'filled','k')
    yline(ax,0,'-','Color','r')
    title(ax,[target{n}(1),' vs. ',target{n}(2)])
    ylim(ax,[-1 1])
    ylabel(ax,'Correlation (r)')
end

xlabel(t,'n^{th} root')

end
% Quick R suared with built-in Matlab functions (pair-wise complete)
function rsq = rsquared(x,y)
compare=not(ismissing(x))&not(ismissing(y));
R=corrcoef(x(compare),y(compare));
rsq=(R(2,1));
end

function opmode=optionValidator(option)
mustBeA(option,{'char','string','double'})
if isnumeric(option)
    mustBeLessThanOrEqual(option,50)
    mustBeGreaterThanOrEqual(option,1)
    opmode='apply';
else
    mustBeMember(option,["reverse","help","max"])
    if matches(option,'reverse')
        opmode='reverse';
    elseif matches(option,'help')
        opmode='help';
    elseif matches(option,'max')
        opmode='apply';
    end
end

end