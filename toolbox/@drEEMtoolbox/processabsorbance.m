function dataout = processabsorbance(data,options)
% <a href = "matlab:drEEMtoolbox.doc('processabsorbance')">dataout = processabsorbance(data,options) (click to access documentation)</a>
%
% <strong>Process CDOM absorbance measurements</strong>
%
% <strong>INPUTS - Required</strong>
% data (1,:) {mustBeA("drEEMdataset"),drEEMdataset.validate,drEEMdataset.sanityCheckAbsorbance}
%
% <strong>INPUTS - Optional</strong>
% correctBase           {MustBeLogical} = true
% baseWave              {mustBeNumeric,mustBeGreaterThan(580),mustBeBetween(numel(baseWave),1,2)} = 595
% zero                  {mustBeNumericOrLogical} = false
% extrapolate           {mustBeNumericOrLogical} = true
% plot                  {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
%
% <strong>EXAMPLE(S)</strong>
%   1. correct CDOM baseline, extrapolate if EEM wavelength coverage is 
%   different from CDOM, and plot outcomes
%       samples = tbx.processabsorbance(samples);
%   3. Just carry out a baseline correction
%       samples = tbx.processabsorbance(samples,correctBase=true,extrapolate=false,zero=false);
%   4. Baseline correction with narrow range averages
%       samples = tbx.processabsorbance(samples,correctBase=true,baseWave=[650 700],extrapolate=false,zero=false);
%   5. Do something, but please don't show that final plot
%       samples = tbx.processabsorbance(samples,...,plot=false);
%
% <a href = "matlab:drEEMtoolbox.doc('processabsorbance')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    % Required
    data (1,:) {mustBeNonempty,...
        mustBeA(data,"drEEMdataset"),...
        drEEMdataset.validate(data),...
        drEEMdataset.sanityCheckAbsorbance(data),...
        drEEMdataset.mustContainSamples(data)}

    % Optional
    options.correctBase (1,:)   {mustBeA(options.correctBase,'logical')} = true
    options.baseWave (1,:)      {mustBeNumeric,mustBeGreaterThan(options.baseWave,580),baseValidator(options.baseWave)} = 595
    options.zero (1,:)          {mustBeNumericOrLogical} = false
    options.extrapolate (1,:)   {mustBeNumericOrLogical} = true
    options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
    options.figurefile (1,:) {mustBeText} = "";
end


% Check if the function has already been run
idx=drEEMhistory.searchhistory(data.history,'processabsorbance','first');
if not(isempty(idx))
    error(['"processabsorbance" has already been run before.' ...
        ' Please chose appropriate settings and only' ...
        ' run this function once to avoid ambiguity."'])
end

% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(1,1)
    else
        disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).')
        options.plot=true;
    end
end

% If there are any strange imaginary numbers, fix it here by converting.
data.abs=real(data.abs);

% Assign the output variable
dataout=data;

% The function creates a result figure. The dataset setting determines if
% it's a uifigure (somewhat cleaner & simple) or figure (much faster)
if options.plot
    if data.toolboxOptions.uifig
        f=drEEMtoolbox.dreemuifig;
    else
        f=drEEMtoolbox.dreemfig;
    end
    f.Name='drEEM: processabsorbance.m';
    
    % Show the original data
    t=tiledlayout(f,"flow");
    ax=nexttile(t);
    p=plot(ax,data.absWave,data.abs,Color=[0 0 0 0.5]);
    
    for k=1:numel(p)
        row1 = dataTipTextRow('Sample',repelem(data.filelist(k),numel(data.absWave),1));
        p(k).DataTipTemplate.DataTipRows(end+1) = row1;
        p(k).DataTipTemplate.DataTipRows(1).Label = 'Wave';
        p(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
    end
    yline(ax,0,LineStyle="-",Color='b')
    xlabel(ax,'Wavelength (nm)')
    ylabel(ax,'Absorbance')
    title(ax,'Absorbance prior to any correction')
end
%% Scenario 1, no extrapolation needed
if max([dataout.Ex;dataout.Em])<max(dataout.absWave)
    %% Baseline correction (if possible and wanted)
    % It's only allowed if there's plenty of long-wl information though
    if max(dataout.absWave)>=580
        blcor_allowed=true;
    else
        warning('CDOM coverage does not allow baseline correction (needs to be > 580 nm). Option disabled.')
        blcor_allowed=false;
    end
    
    % Baseline possible, wanted, and no extrapolation necessary
    % Otherwise, the baseline subtraction is done later.
    if blcor_allowed&&options.correctBase
        baseValidator_2(options.baseWave,data)
        if isscalar(options.baseWave)
            idx=dataout.absWave>=options.baseWave;
        else
            idx=dataout.absWave>=options.baseWave(1)&dataout.absWave<=options.baseWave(2);
        end
        if not(any(idx))
            warning('Please double-check the baseline correction wavelength. Could not perform the baseline correction.')
        else
            bl=mean(dataout.abs(:,idx),2,'omitmissing');
            dataout.abs=dataout.abs-bl;
        end
    end

%% Scenario 2: Stitch-on (extrapolation)
elseif max([dataout.Ex;dataout.Em])>max(dataout.absWave)
    
    % The extrapolation bit
    if options.extrapolate
        if options.correctBase
            baseValidator_extra(options.baseWave,data)
        end
        disp('EEMs were measured at wavelengths longer than CDOM spectra.')
        disp('Extrapolation of CDOM spectra will avoid the automatic deletion of EEM data during IFE correction.')
        abswave=dataout.absWave(drEEMtoolbox.mindist(dataout.absWave,300):end);
        absspec=dataout.abs(:,drEEMtoolbox.mindist(dataout.absWave,300):end)';

      
        % Anonymous function to fit data to the model afteer parameters
        % were found
        afit=@(b1,b2,b3,lambda) b1*exp(b2/1000*(350-lambda))+b3;
        ewstep=round(mean(diff(dataout.absWave)));
        ex_start=dataout.absWave(end)+ewstep;
        options.extrapolation_start=ex_start;
        extrawave=(dataout.absWave(end)+ewstep:ewstep:ceil(max([dataout.Ex;dataout.Em])))';
        new=zeros(data.nSample,numel([abswave;extrawave]));
        beta=nan(data.nSample,3);
        % Carry out the non-linear fit to find the CDOM exponential slope
        % parameters
        warning off
        for n=1:size(absspec,2)
            try
                beta(n,:) = CDOMexp_fit(abswave,absspec(:,n),[mean(absspec(:,n)); 18; 0]);
                new(n,:)=afit(beta(n,1),beta(n,2),beta(n,3),[abswave;extrawave]);
            catch
                new(n,:)=0;
            end
        end
        warning on
        % if a350 is too small, set it to zero
        new(beta(:,2)<1,:)=0;
        new=new(:,size(abswave,1)+1:end);

        % find and eliminate offset between measured and modelled data
        off=data.abs(:,end)-new(:,1);
        new=new+off;
        
        % show intermediate results
        if options.plot
            ax=nexttile(t);
            p=plot(ax,data.absWave,data.abs,Color=[0 0 0 0.5]);
            
            for k=1:numel(p)
                row1 = dataTipTextRow('Sample',repelem(data.filelist(k),numel(data.absWave),1));
                p(k).DataTipTemplate.DataTipRows(end+1) = row1;
                p(k).DataTipTemplate.DataTipRows(1).Label = 'Wave';
                p(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
            end
            hold(ax,'on')

            p=plot(ax,extrawave,new,Color=[1 0 0 0.5]);
            xlabel(ax,'Wavelength (nm)')
            ylabel(ax,'Absorbance')
            title(ax,'Given (black) and extrapl. data (red)')
            yline(ax,0,LineStyle="-",Color='b')
            
            
            for k=1:numel(p)
                row1 = dataTipTextRow('Sample',repelem(data.filelist(k),numel(extrawave),1));
                p(k).DataTipTemplate.DataTipRows(end+1) = row1;
                p(k).DataTipTemplate.DataTipRows(1).Label = 'Wave';
                p(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
            end

        end
        
        % Assign the extrapolated data to the output
        dataout.abs=horzcat(dataout.abs,new);
        dataout.absWave=vertcat(dataout.absWave,extrawave);
        
        % Now let's try the baseline correction again. Same code as above
        if max(extrawave)>580
            blcor_allowed=true;
        else
            blcor_allowed=false;
        end
        
        if blcor_allowed&&options.correctBase
            if isscalar(options.baseWave)
                idx=dataout.absWave>options.baseWave;
            else
                idx=dataout.absWave>=options.baseWave(1)&dataout.absWave<=options.baseWave(2);
            end
            bl=mean(dataout.abs(:,idx),2,'omitnan');
            dataout.abs=dataout.abs-bl;
        end
        
    else
        %% Baseline correction (if possible and wanted)
        % It's only allowed if there's plenty of long-wl information though
        if max(dataout.absWave)>=580
            blcor_allowed=true;
        else
            warning('CDOM coverage does not allow baseline correction (needs to be > 580 nm). Option disabled.')
            blcor_allowed=false;
        end

        % Baseline possible, wanted, and no extrapolation necessary
        % Otherwise, the baseline subtraction is done later.
        if blcor_allowed&&options.correctBase
            if isscalar(options.baseWave)
                i = dataout.absWave>=options.baseWave;
            elseif numel(options.baseWave)==2
                i(1) =drEEMtoolbox.mindist(dataout.absWave,options.baseWave(1));
                i(2) = drEEMtoolbox.mindist(dataout.absWave,options.baseWave(2));
                i=i(1):i(2);
            end
            if not(any(i))
                warning('Please double-check the baseline correction wavelength. Could not perform the baseline correction.')
            else
                bl=mean(dataout.abs(:,i),2,'omitmissing');
                dataout.abs=dataout.abs-bl;
            end
        end
    end
end



%% <0 = 0 correction (if needed and wanted)
if any(dataout.abs(:)<0)&&options.zero
    dataout.abs(dataout.abs<0)=0;
end
% Show the final output
if options.plot
    ax=nexttile(t);
    p=plot(ax,dataout.absWave,dataout.abs,Color=[0 0 0 0.5]);
    
    for k=1:numel(p)
        row1 = dataTipTextRow('Sample',repelem(data.filelist(k),numel(dataout.absWave),1));
        p(k).DataTipTemplate.DataTipRows(end+1) = row1;
        p(k).DataTipTemplate.DataTipRows(1).Label = 'Wave';
        p(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
    end
    xlabel(ax,'Wavelength (nm)')
    ylabel(ax,'Absorbance')
    title(ax,'Final output')
    yline(ax,0,LineStyle="-",Color='b')

    figurefile=char(options.figurefile);
    if not(isempty(figurefile))
        % Pause for figure rendering
        pause(3)
        try
            dreemgui.saveAfterFunctionCall(f,figurefile)
        catch ME
            throwAsCaller(ME)
        end
    end
end

%% drEEMhistory entry
message=[...
    'baseWave = ',num2str(options.baseWave),...
    ', baseline offset corrected = ', char(string(options.correctBase)),...
    ', long-range absorbance extrapolated = ',char(string(options.extrapolate)),...
    ', zero negative values = ',char(string(options.zero))];
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,message,options,dataout);

if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',char(inputname(1)), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
else
    if nargout==0
        clearvars dataout
    end
end

end

function yhat = CDOMexp_K(beta,x)
%CDOM exponential abs model.
%   YHAT = CDOMexp(BETA,X) gives the predicted values of the
%   reaction rate, YHAT, as a function of the vector of 
%   parameters, BETA, and the matrix of data, X.
%   BETA must have ? elements and X must have three
%   columns.
%
%   y = a350*exp(S/1000*(350-lamda))+k
% (c) Colin Stedmon

b1 = beta(1); %a350
b2 = beta(2); %S
b3 = beta(3); %K

x = x(:,1); %lamda


yhat = b1*exp(b2/1000*(350-x))+b3;

end

function beta = CDOMexp_fit(x,y,beta0)
% CDOMexp_fit: fits the CDOMexp_K model (b1*exp(b2/1000*(350-x))+b3) to
% data with a small Levenberg-Marquardt solver. Written to replace the
% Statistics and Machine Learning Toolbox's nlinfit so that CDOM
% extrapolation works without that toolbox installed. Uses only core
% MATLAB (matrix algebra, no toolbox functions).
warnstate=warning('off','MATLAB:singularMatrix');
warnstate(2)=warning('off','MATLAB:nearlySingularMatrix');
warnstate(3)=warning('off','MATLAB:illConditionedMatrix');
cleanupWarn=onCleanup(@() warning(warnstate));

x=x(:); y=y(:);
beta=beta0(:);
lambda=1e-3;
maxIter=10000;
tolFun=1e-10;

r=y-CDOMexp_K(beta,x);
cost=sum(r.^2);

for iter=1:maxIter
    e=350-x;
    ex=exp(beta(2)/1000*e);
    % Analytical Jacobian of the model w.r.t. [b1;b2;b3]
    J=[ex, beta(1)*ex.*e/1000, ones(size(x))];
    JTJ=J'*J;
    JTr=J'*r;
    scale=max(diag(JTJ),eps);

    improved=false;
    for inner=1:60
        H=JTJ+lambda*diag(scale);
        % rcond(H) itself returns NaN (not a small number) once H holds
        % any NaN/Inf, and "NaN<eps" is false -- so a plain rcond check
        % alone silently misses that case. Guard on finiteness first.
        if not(all(isfinite(H(:)))) || rcond(H)<eps
            delta=pinv(H)*JTr;
        else
            delta=H\JTr;
        end
        if not(all(isfinite(delta)))
            lambda=lambda*10;
            if lambda>1e12
                break
            end
            continue
        end
        betaNew=beta+delta;
        if not(all(isfinite(betaNew)))
            lambda=lambda*10;
            if lambda>1e12
                break
            end
            continue
        end
        rNew=y-CDOMexp_K(betaNew,x);
        costNew=sum(rNew.^2);
        if isfinite(costNew) && costNew<cost
            improvement=cost-costNew;
            beta=betaNew;
            r=rNew;
            cost=costNew;
            lambda=max(lambda/10,1e-12);
            improved=true;
            break
        else
            lambda=lambda*10;
            if lambda>1e12
                break
            end
        end
    end

    if not(improved)
        break
    end
    if improvement<tolFun*max(1,cost)
        break
    end
end

end

function baseValidator(in)

n=numel(in);

if not(isbetween(n,1,2))
    error('baseWave must be a scalar or at most two values. E.g. "600" or "[590 600]"')
end

end

function baseValidator_2(in,data)

mima=[min(data.absWave) max(data.absWave)];

if isscalar(in)
    if not(isbetween(in,mima(1),mima(2)))
        error('baseWave must be higher than 585 and equal to or shorther than the longest measured absorbance wavelength')
    end
else
    if not(isbetween(min(in),mima(1),mima(2)))&&not(isbetween(max(in),mima(1),mima(2)))
        error('baseWave must be higher than 585 and equal to or shorther than the longest measured absorbance wavelength')
    end
end


end

function baseValidator_extra(in,data)
ewstep=round(mean(diff(data.absWave)));
ex_start=data.absWave(end)+ewstep;
extrawave=(data.absWave(end)+ewstep:ewstep:ceil(max([data.Ex;data.Em])))';
mima=[min(data.absWave) ceil(max([data.absWave;extrawave]))];


if isscalar(in)
    if not(isbetween(in,mima(1),mima(2)))
        throwAsCaller(MException("processabsorbance:baseWave",['baseWave must be higher than 580 and equal to or shorther than the longest <strong>extrapolated</strong> absorbance wavelength (',num2str(mima(2)),'nm in this specific case)']))
    end
else
    if not(isbetween(min(in),mima(1),mima(2)))||not(isbetween(max(in),mima(1),mima(2)))
        throwAsCaller(MException("processabsorbance:baseWave",['baseWave must be higher than 580 and equal to or shorther than the longest <strong>extrapolated</strong> absorbance wavelength (',num2str(mima(2)),'nm in this specific case)']))
    end
end


end