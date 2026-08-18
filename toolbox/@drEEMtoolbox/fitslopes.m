function dataout = fitslopes(data,options)
% <a href = "matlab:drEEMtoolbox.doc('fitslopes')">dataout = fitslopes(data,options) (click to access documentation)</a>
%
% <strong>Fit slopes to CDOM absorbance data</strong>
%
% <strong>INPUTS - Required</strong>
% data (1,1)              {mustBeA("drEEMdataset"),drEEMdataset.validate}
%
% <strong>INPUTS - Optional</strong>
% LongRange (1,2) {mustBeNumeric} = [300 600]
% rsq (1,1)       {mustBeNumeric,mustBeLessThanOrEqual(1)} = 0.95
% options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
% details         {mustBeNumericOrLogical} = false
% figurefile (1,:) {mustBeText} = ""
%
% <strong>EXAMPLE(S)</strong>
%   1. fit slopes and get an idea how well the fit represents the data
%       samples = tbx.fitslopes(samples,details=true);
%   2. fit slopes but don't show final plots or fit details
%       samples = tbx.fitslopes(samples,plot=false);
%
% <a href = "matlab:drEEMtoolbox.doc('fitslopes')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1)              {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.sanityCheckAbsorbance(data),drEEMdataset.mustContainSamples(data)}
    options.LongRange (1,2) {mustBeNumeric} = [300 600]
    options.rsq (1,1)       {mustBeNumeric,mustBeLessThanOrEqual(options.rsq,1)} = 0.95
    options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
    options.details         {mustBeNumericOrLogical} = false
    options.quiet         {mustBeNumericOrLogical} = false
    options.figurefile (1,:) {mustBeText} = "";
end

% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(1,2)
    else
        disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).')
        options.plot=true;
        options.details=true;
    end
end

if options.quiet
    options.plot = false;
    options.details = false;
end

if isempty(data.abs)
    error('fitslopes fits CDOM absorbance slopes and requires data to do so. data.abs is empty.')
end

%% Extract data for fits
% Find indcies
fitSpecs=struct;
fitSpecs(1).ident='exponential';
fitSpecs(2).ident='S275';
fitSpecs(3).ident='S350';

fitSpecs(1).range=options.LongRange;
fitSpecs(2).range=[275 295];
fitSpecs(3).range=[350 400];

for j=1:numel(fitSpecs)
    fitSpecs(j).indices=drEEMtoolbox.mindist(data.absWave,fitSpecs(j).range(1)):...
        drEEMtoolbox.mindist(data.absWave,fitSpecs(j).range(2));
    fitSpecs(j).absWave=data.absWave(fitSpecs(j).indices);
    fitSpecs(j).abs=data.abs(:,fitSpecs(j).indices);
end


%% Fitting

if not(options.quiet)
    wb=waitbar(0,'Fitting spectral slopes...','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');cnt=0;
    cleanup = onCleanup(@()closeWaitbar(wb));
    setappdata(wb,'canceling',0);
end
for j=1:3%numel(fitSpecs)
    switch fitSpecs(j).ident
        case 'exponential'
            for i=1:data.nSample
                x=fitSpecs(j).absWave;
                y=fitSpecs(j).abs(i,:);
                results(j,i) = customexpofit(x,y,options); %#ok<*AGROW>
                warning on
                if not(options.quiet)
                    switch results(j,i).outcome
                        case 'error'
                            warning([fitSpecs(j).ident,' fit: <strong>error</strong> for sample ',data.filelist{i}, '; data.i=',num2str(data.i(i))])
                        case 'poor fit'
                            warning([fitSpecs(j).ident,' fit: <strong> poor fit</strong> for sample ',data.filelist{i}, '; data.i=',num2str(data.i(i))])
                        case 'missing data'
                            warning([fitSpecs(j).ident,' fit: <strong>Too much missing data</strong> for sample ',data.filelist{i}, '; data.i=',num2str(data.i(i))])
                    end
                end
                if not(options.quiet)
                    cnt=cnt+1;waitbar(cnt./(data.nSample),wb,'Fitting spectral slopes... (exponential S)');
                end
            end
        case {'S275','S350'}
            for i=1:data.nSample
                y=fitSpecs(j).abs(i,:);
                y=log(y);
                x=fitSpecs(j).absWave;
                results(j,i) = customlmfit(x,real(y'),options);
                if not(options.quiet)
                    switch results(j,i).outcome
                        case 'error'
                            warning([fitSpecs(j).ident,' fit error for sample ',data.filelist{i}, '; data.i=',num2str(data.i(i))])
                        case 'poor fit'
                            warning([fitSpecs(j).ident,' poor fit for sample ',data.filelist{i}, '; data.i=',num2str(data.i(i))])
                        case 'missing data'
                            warning([fitSpecs(j).ident,' fit: <strong>Too much missing data</strong> for sample ',data.filelist{i}, '; data.i=',num2str(data.i(i))])
                    end
                end
                if not(options.quiet)
                    cnt=cnt+1;waitbar(cnt./(data.nSample*2),wb,'Fitting spectral slopes... (short-range S)');
                end
            end
    end
end
if not(options.quiet)
    delete(wb)
end
%% Results extraction from the tables
slopes=nan(data.nSample,3);
for j=1:3
    for k=1:data.nSample
        % If statement catches slopes that could not be calculted (empty structure)
        if not(isempty(results(j,k).Coefficients))
            slopes(k,j)=results(j,k).Coefficients.Estimate(2);
        end
    end
end
slopes=array2table(slopes,"VariableNames",{'exp_slope_microm','S_275_295','S_350_400'});
slopes.Sr=slopes.S_275_295./slopes.S_350_400;
slopes.S_275_295=abs(slopes.S_275_295)*1e3;
slopes.S_350_400=abs(slopes.S_350_400)*1e3;



dataout=data;
[~,ia,~]=intersect(dataout.opticalMetadata.Properties.VariableNames, ...
    slopes.Properties.VariableNames);
dataout.opticalMetadata(:,ia)=[];

dataout.opticalMetadata=[dataout.opticalMetadata,slopes];

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'CDOM slopes determined',options,dataout);

dataout.validate(dataout);


%% Diagnosis plots if desired.
if options.details
    if data.toolboxOptions.uifig
        fig2=drEEMtoolbox.dreemuifig;
        uialert(fig2,['Showing raw, modeled, and residual data for' ...
            ' selected samples. Press "next" button (bottom left) to continue; closing the' ...
            ' figure will conclude the function.'], ...
            'fitslopes diagnosis','Icon','info')
    else
        fig2=drEEMtoolbox.dreemfig;
        disp(['Showing raw, modeled, and residual data for' ...
            ' selected samples. Press "next" button (bottom left) to continue; closing the' ...
            ' figure will conclude the function.'])
    end
    set(fig2,'units','normalized')
    set(fig2,'pos',[0.1365    0.2926    0.6490    0.2852])
    huic = uicontrol(fig2,'Style', 'pushbutton','String','Next',...
        'Units','normalized','Position', [0.9323 0.0240 0.0604 0.0500],...
        'Callback',{@pltnext});
    set(huic,Units='pixel')
    pos=get(huic,'Position');
    pos(4)=30;
    set(huic,"Position",pos)
    t=tiledlayout(fig2,1,3);
    movegui(fig2,'center')

    for j=1:3
        ax(j)=nexttile(t);
    end
     cont=true;
     for n=1:data.nSample
         if cont
             set(fig2,'Name',['Slopefit.m: Data vs. modeled data. Spectrum ',num2str(n),' of ',num2str(data.nSample)])
             try
                 yyaxis(ax(1),'left')
                 cla(ax(1))
                 set(ax(1),'YColor','k')
                 plot(ax(1),data.absWave,data.abs(n,:),'LineWidth',0.5,'Color',[0.5 0.5 0.5]),
                 hold(ax(1),"on")
                 plot(ax(1),fitSpecs(1).absWave,fitSpecs(1).abs(n,:),'Color','k','LineStyle','-','LineWidth',1.5)
                 plot(ax(1),fitSpecs(1).absWave,results(1,n).modelled,'Color',lines(1),'LineStyle','-')
                 ylabel(ax(1),'Absorbance')
                 xlabel(ax(1),'Wavelength (nm)')
                 xlim(ax(1),[options.LongRange(1)-20 options.LongRange(end)+20])
                 yyaxis(ax(1),'right')
                 cla(ax(1))
                 set(ax(1),'YColor', [1       0.663       0.094] )
                 plot(ax(1),fitSpecs(1).absWave,results(1,n).residuals,'Color', [1       0.663       0.094] ,'Marker','none','LineStyle','-')
                 ylabel(ax(1),'fit residual')
                 xlabel(ax(1),'Wavelength (nm)')
                 hold(ax(1),'off')
                 title(ax(1),['S_{',num2str(options.LongRange(1)),'-',num2str(options.LongRange(end)),'} exp. model vs. fitted & residuals'])
             catch
                 yyaxis(ax(1),'right')
                 cla(ax(1))
                 yyaxis(ax(1),'left')
                 cla(ax(1))
                 line(ax(1),nan,nan)
                 legend(ax(1),'No fit possible')
             end

             try
                 yyaxis(ax(2),'left')
                 cla(ax(2))
                 set(ax(2),'YColor','k')
                 plot(ax(2),data.absWave,data.abs(n,:),'LineWidth',0.5,'Color',[0.5 0.5 0.5])
                 hold(ax(2),"on")
                 plot(ax(2),fitSpecs(2).absWave,fitSpecs(2).abs(n,:),'Color','k','LineStyle','-','LineWidth',1.5)
                 plot(ax(2),fitSpecs(2).absWave,results(2,n).modelled,'Color',lines(1),'Marker','none','LineStyle','-')
                 xlim(ax(2),[250 320])
                 ylabel(ax(2),'Absorbance')
                 xlabel(ax(2),'Wavelength (nm)')

                 yyaxis(ax(2),'right')
                 cla(ax(2))
                 set(ax(2),'YColor',[1       0.663       0.094])
                 plot(ax(2),fitSpecs(2).absWave,results(2,n).residuals,'Color',[1       0.663       0.094],'Marker','none','LineStyle','-')
                 hold(ax(2),"off")
                 title(ax(2),'S_{275-295} model vs. fitted & residuals')
                 ylabel(ax(2),'Relative residual')
                 xlabel(ax(2),'Wavelength (nm)')
             catch
                 yyaxis(ax(2),"right")
                 cla(ax(2))
                 yyaxis(ax(2),'left')
                 cla(ax(2))
                 line(ax(2),nan,nan)
                 legend(ax(2),'No fit possible')
             end

             try
                 yyaxis(ax(3),"left")
                 cla(ax(3))
                 set(ax(3),'YColor','k')
                 plot(ax(3),data.absWave,data.abs(n,:), ...
                     'LineWidth',0.5,'Color',[0.5 0.5 0.5]);
                 hold(ax(3),"on")
                 plot(ax(3),fitSpecs(3).absWave,fitSpecs(3).abs(n,:), ...
                     'Color','k','LineStyle','-','LineWidth',1.5);
                 plot(ax(3),fitSpecs(3).absWave,results(3,n).modelled, ...
                     'Color',lines(1),'Marker','none','LineStyle','-');
                 xlim(ax(3),[310 450])
                 ylabel(ax(3),'Absorbance')
                 xlabel(ax(3),'Wavelength (nm)')
                 yyaxis(ax(3),"right")
                 cla(ax(3))
                 set(ax(3),'YColor',[1       0.663       0.094])
                 plot(ax(3),fitSpecs(3).absWave,results(3,n).residuals, ...
                     'Color',[1       0.663       0.094],'Marker','none','LineStyle','-');
                 ylabel(ax(3),'fit residual')
                 xlabel(ax(3),'Wavelength (nm)')
                 hold(ax(3),"off")
                 title(ax(3),'S_{350-400} model vs. fitted & residuals')
                 [ h ] = leg(4,[0.5 0.5 0.5;0 0 0;lines(1);1 0.663 0.094],ax(3));
                 legend1=legend(h,{'Raw','selected','fitted','residual'},NumColumns=4);
                 legend1.Layout.Tile="north";
             catch
                 yyaxis(ax(3),"right")
                 cla(ax(3))
                 yyaxis(ax(3),"left")
                 cla(ax(3))
                 line(ax(3),nan,nan)
                 legend(ax(3),'No fit possible')
             end

             uicontrol(huic)
             uiwait(fig2)
             if ~ishandle(fig2)
                 cont=false;
                 continue
             end
         end
     end
end
%% Plotting of results
switch options.plot
    case true
    if data.toolboxOptions.uifig
        fig1=drEEMtoolbox.dreemuifig;
    else
        fig1=drEEMtoolbox.dreemfig;
    end
    set(fig1,'units','normalized','Name','slopefit: CDOM spectral slopes','pos',[0.35 0.35 0.30 0.25])
    ax=nexttile(tiledlayout(fig1));

    [~,idx]=sort(data.i);

    p(1)=plot(ax,data.i(idx),slopes.exp_slope_microm(idx), ...
        'Color','k',LineStyle='-',Marker='o',LineWidth=0.5,MarkerFaceColor='k');
    xlabel(ax,'# Sample')
    ylabel(ax,['S_{',num2str(options.LongRange(1)),'-',num2str(options.LongRange(end)),'} (µm^{-1})'])
    yyaxis(ax,"right")
    p(2)=plot(ax,data.i(idx),slopes.S_275_295(idx), ...
        'Color',lines(1),LineStyle='-',Marker='o',LineWidth=0.5,MarkerFaceColor=lines(1));
    hold(ax,"on")
    p(3)=plot(ax,data.i(idx),slopes.S_350_400(idx), ...
        'Color','b',LineStyle='-',Marker='o',LineWidth=0.5,MarkerFaceColor=lines(1));
    xlabel(ax,'Sample identifier (.i)'),
    ylabel(ax,'S_{275-295} & S_{350-400} (µm^{-1})')
    set(ax,'YColor','b')
    title(ax,'CDOM spectral slopes (µm^{-1})')
    xlim(ax,[0 max(data.i)])
    legend(ax, ...
        ['S_{',num2str(options.LongRange(1)),'-',num2str(options.LongRange(end)),'nm}'], ...
        'S_{275-295nm}','S_{350-400nm}','location','northoutside',NumColumns=3)

    row1 = dataTipTextRow('Sample',dataout.filelist(idx));
    for k=1:numel(p)
        p(k).DataTipTemplate.DataTipRows(end+1) = row1;
        p(k).DataTipTemplate.DataTipRows(1).Label = '.i';
        p(k).DataTipTemplate.DataTipRows(2).Label = 'slope';
    end

    figurefile=char(options.figurefile);
    if not(isempty(figurefile))
        % Pause for figure rendering
        pause(3)
        try
            dreemgui.saveAfterFunctionCall(fig1,figurefile)
        catch ME
            throwAsCaller(ME)
        end
    end

end

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',char(inputname(1)), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
else
    if nargout==0
        clearvars dataout slopes
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


function [ h ] = leg( numPlots,col,ax)
h = gobjects(numPlots, 1);
for n=1:numPlots
    hold(ax,"on");
    h(n) = line(ax,NaN,NaN,'Marker','o','MarkerSize',5,'MarkerFaceColor',col(n,:),'MarkerEdgeColor','k','LineStyle','none');
end
end

function results = customlmfit(x,y,options)
results=struct;
results.Coefficients=table;
try
    [out,S] = polyfit(x,y,1);
    idx=not(isnan(y));
    if sum(~idx)>ceil(0.7*numel(y))
        error('Too many missing observations')
    end
    sum_of_squares = sum((y-mean(y,"omitmissing")).^2,"omitmissing");
    sum_of_squares_of_residuals = sum((y(idx)-polyval(out,x(idx))).^2);
    Rsquared = 1 - sum_of_squares_of_residuals/sum_of_squares;
    results.Coefficients.Estimate(1)=out(2);
    results.Coefficients.Estimate(2)=out(1);
    results.Coefficients.Properties.RowNames={'Intercept','Slope'};

    results.Rsquared=Rsquared;
    results.fit=out; % store that stuff for later polyval
    results.modelled=exp(polyval(out,x));
    results.residuals=y-polyval(out,x);
    results.outcome='success';
catch
    results=struct;
    results.Coefficients=table;
    results.Coefficients.Estimate(1)=nan;
    results.Coefficients.Estimate(2)=nan;
    results.Coefficients.Properties.RowNames={'Intercept','Slope'};
    results.Rsquared=nan;
    results.fit=nan; % store that stuff for later polyval
    results.modelled=nan(size(y));
    results.residuals=nan(size(y));
    if contains(lasterr,'Too many missing')
        results.outcome='missing data';
    else
        results.outcome='error';
    end
end
if results.Rsquared<options.rsq
    results.Coefficients.Estimate=nan(2,1);
    results.Rsquared=nan;
    results.fit=nan; % store that stuff for later polyval
    results.modelled=nan(size(y));
    results.residuals=nan(size(y));
    results.outcome='poor fit';
end
end

function results=customexpofit(x,y,options)
results=struct;
results.Coefficients=table;
try
    warning off
    beta=CDOMexp_fit(x,y',[mean(y,"omitmissing"); 18; 0]);
    warning on
    idx=not(isnan(y));
    if sum(~idx)>ceil(0.7*numel(y))
        error('Too many missing observations')
    end
    modelled=CDOMexp_K(beta,x)';
    fit=sum(modelled(idx).^2)./sum(y(idx)'.^2,"omitmissing");
    
    results.Coefficients.Estimate(1)=beta(3);
    results.Coefficients.Estimate(2)=beta(2);
    results.Coefficients.Estimate(3)=beta(1);
    results.Coefficients.Properties.RowNames={'K (Intercept)','Slope (S)','center (a350)'};
    results.Rsquared=fit;
    results.fit=beta;% store that stuff for later CDOMexp_K
    results.modelled=modelled;
    results.residuals=y-modelled;
    results.outcome='success';
catch
    results.Coefficients.Estimate(1)=nan;
    results.Coefficients.Estimate(2)=nan;
    results.Coefficients.Estimate(3)=nan;
    results.Coefficients.Properties.RowNames={'K (Intercept)','Slope (S)','center (a350)'};
    results.Rsquared=nan;
    results.fit=[nan nan nan]'; % store that stuff for later polyval
    results.modelled=nan(size(y));
    results.residuals=nan(size(y));
    if contains(lasterr,'Too many missing')
        results.outcome='missing data';
    else
        results.outcome='error';
    end
end

if results.Rsquared<options.rsq
    results.Coefficients.Estimate=nan(3,1);
    results.Rsquared=nan;
    results.fit=[nan nan nan]'; % store that stuff for later polyval
    results.modelled=nan(size(y));
    results.residuals=nan(size(y));
    results.outcome='poor fit';
end

end

function beta = CDOMexp_fit(x,y,beta0)
% CDOMexp_fit: fits the CDOMexp_K model (b1*exp(b2/1000*(350-x))+b3) to
% data with a small Levenberg-Marquardt solver. Written to replace the
% Statistics and Machine Learning Toolbox's nlinfit so that exponential
% slope fitting works without that toolbox installed. Uses only core
% MATLAB (matrix algebra, no toolbox functions). Mirrors the MaxIter=10000
% budget the original nlinfit call used here.
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
        if rcond(H)<eps
            delta=pinv(H)*JTr;
        else
            delta=H\JTr;
        end
        betaNew=beta+delta;
        rNew=y-CDOMexp_K(betaNew,x);
        costNew=sum(rNew.^2);
        if costNew<cost
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

function pltnext(sosurce,event) %#ok<INUSD>
uiresume(sosurce.Parent)
end
function closeWaitbar(h)
delete(h)
end