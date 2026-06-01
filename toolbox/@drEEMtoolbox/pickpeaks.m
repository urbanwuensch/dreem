function dataout = pickpeaks( data,options)
% <a href = "matlab:drEEMtoolbox.doc('pickpeaks')">[dataout,picklist,metadata] = pickpeaks( data,options) (click to access documentation)</a>
%
% <strong>Extract peak intensities</strong> and indices from fluorescence EEMs
%
% <strong>Inputs - Required</strong>
% data (1,1)    {mustBeA("drEEMdataset"),drEEMdataset.validate}
%
% <strong>Inputs - Optional</strong>
% options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
% details       {mustBeNumericOrLogical} = false
% figurefile (1,:) {mustBeText} = ""

% <a href = "matlab:drEEMtoolbox.doc('pickpeaks')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
    options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
    options.details  {mustBeNumericOrLogical} = false
    options.quiet {mustBeNumericOrLogical} = false
    options.figurefile (1,:) {mustBeText} = "";
end
% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(1,3)
    else
        disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).')
        options.plot=true;
        options.details=true;
    end
end
Xname = 'X';
if options.quiet
    options.plot = false;
    options.details = false;
end

plt = options.plot;
diagn = options.details;
dataout=data;


%% Definition of peaks: B, T, A, M, C, D, E, N.
peaks(1).name=cellstr('B');
peaks(1).Em=num2cell(305);
peaks(1).Ex=num2cell(275);
peaks(2).name=cellstr('T');
peaks(2).Em=num2cell(340);
peaks(2).Ex=num2cell(275);
peaks(3).name=cellstr('A');
peaks(3).Em=num2cell(400:460);
peaks(3).Ex=num2cell(260);
peaks(4).name=cellstr('M');
peaks(4).Em=num2cell(370:410);
peaks(4).Ex=num2cell(290:310);
peaks(5).name=cellstr('C');
peaks(5).Em=num2cell(420:460);
peaks(5).Ex=num2cell(320:360);
peaks(6).name=cellstr('D');
peaks(6).Em=num2cell(509);
peaks(6).Ex=num2cell(390);
peaks(7).name=cellstr('N');
peaks(7).Em=num2cell(370);
peaks(7).Ex=num2cell(280);

%% Define anon. functs

vec=@(x) x(:);

%% Change resolution of EEMs to 1nm in order to properly calculate and extract peaks and indicies
Exint=1;
Emint=1;
Ex_i=round(data.Ex(1)):Exint:round(data.Ex(end));
Em_i=(round(data.Em(1)):Emint:round(data.Em(end)))';
nEx_i=size(Ex_i,2);
nEm_i=size(Em_i,1);
Xi=zeros(data.nSample,size(Em_i,1),size(Ex_i,2));

if mean(diff(data.Ex))>5
    if not(options.quiet)
        disp('<strong>Excitation increment>5nm</strong>. The performed interpolation might introduce significant biases!')
        pause(2)
    end
end
if mean(diff(data.Em))>10
    if not(options.quiet)
        disp('<strong>Emission increment>10nm</strong>. The performed interpolation might introduce significant biases!')
        pause(2)
    end
end


for i=1:data.nSample
    eem=squeeze(data.(Xname)(i,:,:));
    Xi(i,:,:) = interp2(data.Ex,data.Em,eem,Ex_i,Em_i);
end
data.(Xname)=Xi;
data.nEm=nEm_i;
data.nEx=nEx_i;
data.Ex=Ex_i';
data.Em=Em_i;


%% Check if distance between fluorescence peaks and dataset Ex and Em is too big

if ~any(data.Ex==254)
    if not(options.quiet)
        disp('<strong>Cannot calculate HIX</strong> due to limted spectral coverage.')
    end
    HIX_excl=true;
else
    HIX_excl=false;
end

distEx=nan(1,numel(peaks));
distEm=nan(1,numel(peaks));
for n=1:numel(peaks)
    [~,distEx(n)] = drEEMtoolbox.mindist( data.Ex,peaks(n).Ex{1});
    [~,distEm(n)] = drEEMtoolbox.mindist( data.Em,peaks(n).Em{1});
end

if any(distEx>=5)
    if not(options.quiet)
        disp('<strong>Excessive distance</strong> between peak definitions & measured data (>=5nm: excitation)');
    end
end
if any(distEm>=5)
    if not(options.quiet)
        disp('<strong>Excessive distance</strong> between peak definitions & measured data (>=5nm: emission)');
    end
end


%% Peak picking
Cpeak=nan(data.nSample,numel(peaks));
md=struct;
for i=1:data.nSample
    % Running through different scenarios
    % #1: Ex/Em pair
    for n=1:size(peaks,2)
        if isscalar(peaks(n).Em)&&isscalar(peaks(n).Ex)
            Cpeak(i,n)=data.(Xname)(i,drEEMtoolbox.mindist(data.Em,peaks(n).Em{1}),drEEMtoolbox.mindist(data.Ex,peaks(n).Ex{1}));
            % #2: Specific Ex, but Em range
        elseif isscalar(peaks(n).Ex)&&numel(peaks(n).Em)~=1
            tempEm=data.(Xname)(i,drEEMtoolbox.mindist(data.Em,peaks(n).Em{1}):drEEMtoolbox.mindist(data.Em,peaks(n).Em{end}),drEEMtoolbox.mindist(data.Ex,peaks(n).Ex{1}));
            Cpeak(i,n)=max(tempEm,[],'omitnan');
            % #3: Ex and Em range-peaks
        else
            x1=drEEMtoolbox.mindist(data.Ex,peaks(n).Ex{1});
            x2=drEEMtoolbox.mindist(data.Ex,peaks(n).Ex{end});
            y1=drEEMtoolbox.mindist(data.Em,peaks(n).Em{1});
            y2=drEEMtoolbox.mindist(data.Em,peaks(n).Em{end});

            if x1==x2||y1==y2
                Cpeak(i,n)=nan;
                continue
            end

            mat=squeeze(data.(Xname)(i,y1:y2,x1:x2));
            [Cpeak(i,n),idxmax]=max(vec(mat),[],'omitnan');
            [empos, expos] = ind2sub(size(mat), idxmax);
            ex=data.Ex(x1:x2);
            em=data.Em(y1:y2);
            
            md.Ex(i,n)=ex(expos);
            md.Em(i,n)=em(empos);
        end
    end
end

%% Indices
FI=nan(1,data.nSample);
FrI=nan(1,data.nSample);
BIX=nan(1,data.nSample);
HIX=nan(1,data.nSample);
arix=nan(1,data.nSample);
if diagn
    if data.toolboxOptions.uifig
        dfig=drEEMtoolbox.dreemuifig;
    else
        dfig=drEEMtoolbox.dreemfig;
    end
    set(dfig,'units','normalized','pos',[0.1344    0.2537    0.7625    0.3194])
    set(dfig,'name','pickPeaks.m - raw vs. smoothed fluorescence for indicies')
    huic = uicontrol(dfig,'Style', 'pushbutton','String','Next',...
        'Units','normalized','Position', [0.9323 0.0240 0.0604 0.0500],...
        'Callback',{@pltnext});
    uialert(dfig,'Press "next" button (bottom right) to see the next sample. Closing the figure continues the function without detail plots.', ...
        'Information',Icon='Info')

    t=tiledlayout(dfig);
    for j=1:4
        ax(j)=nexttile(t);
    end
end
for i=1:data.nSample
    
        % Extract scans
        EmScan370=data.(Xname)(i,:,drEEMtoolbox.mindist(data.Ex,370)); % FluI
        EmScan310=data.(Xname)(i,:,drEEMtoolbox.mindist(data.Ex,310)); %FreshI
        if ~HIX_excl
            EmScan254=data.(Xname)(i,:,drEEMtoolbox.mindist(data.Ex,254)); % HIX
        end
        EmScan320=data.(Xname)(i,:,drEEMtoolbox.mindist(data.Ex,320)); % ARIX

        % NaN interp
        EmScan370=naninterp(EmScan370,'PCHIP');
        EmScan310=naninterp(EmScan310,'PCHIP');
        if ~HIX_excl
            EmScan254=naninterp(EmScan254,'PCHIP');
        end
        EmScan320=naninterp(EmScan320,'PCHIP');

        % Smoothing
        EmScan370s = smoothdata(EmScan370,21,'sgolay',2);
        EmScan310s = smoothdata(EmScan310,21,'sgolay',2);
        if ~HIX_excl
            EmScan254s = smoothdata(EmScan254,21,'sgolay',2);
        end
        EmScan320s = smoothdata(EmScan320,21,'sgolay',2);

    try % Fluorescence index
        
        if all(isnan(EmScan370))
            error('Nothing there')
        end
        
        if diagn
            cla(ax(1))
            hold(ax(1),"on")
            h1=plot(ax(1),data.Em,EmScan370,'LineStyle','none','Marker','+','Color','k');
            h2=plot(ax(1),data.Em,EmScan370s,'LineWidth',1.7);
            axis(ax(1),"tight")
            cylim=get(ax(1),'YLim');
            ylim(ax(1),[0 cylim(2)])
            cylim=get(ax(1),'YLim');
            plot(ax(1),[470 470],cylim,'r','LineStyle','--')
            plot(ax(1),[520 520],cylim,'r','LineStyle','--')
            title(ax(1),'em at ex = 370 (Fl.index)')
            legend([h1 h2],{'raw','smoothed'},'location','best')
            box(ax(1),"on")
        end
        
        Val1=EmScan370s(drEEMtoolbox.mindist(data.Em,470));
        Val2=EmScan370s(drEEMtoolbox.mindist(data.Em,520));
        FI(i)=Val1/Val2;
    catch
        FI(i)=nan;
    end
    try % Freshness index
        

        if all(isnan(EmScan310))
            error('Nothing there')
        end

        
        if diagn
            cla(ax(2))
            hold(ax(2),"on")
            plot(ax(2),data.Em,EmScan310,'LineStyle','none','Marker','+','Color','k');
            plot(ax(2),data.Em,EmScan310s,'LineWidth',1.7)
            axis(ax(2),"tight")
            cylim=get(ax(2),'YLim');
            ylim(ax(2),[0 cylim(2)])
            cylim=get(ax(2),'YLim');
            plot(ax(2),[380 380],cylim,'r','LineStyle','--')
            y = [cylim(1) cylim(2) cylim(2) cylim(1)];
            x = [420 420 435 435];
            patch(ax(2),x,y,'red','FaceAlpha',0.5)
            title(ax(2),'em at ex = 310 (Freshness index)')
            box(ax(2),"on")
        end

        Val1=EmScan310s(drEEMtoolbox.mindist(data.Em,380));
        Val2=max(EmScan310s(drEEMtoolbox.mindist(data.Em,420):drEEMtoolbox.mindist(data.Em,435)),[],'omitnan');
        FrI(i)=Val1/Val2;
    catch
        FrI(i)=nan;
    end
    try % Humification index
        if ~HIX_excl
            if all(isnan(EmScan254))
                error('Nothing there')
            end

            
            if diagn
                cla(ax(3))
                hold(ax(3),"on")
                plot(ax(3),data.Em,EmScan254,'LineStyle','none','Marker','+','Color','k');
                plot(ax(3),data.Em,EmScan254s,'LineWidth',1.7)
                axis(ax(3),"tight")
                cylim=get(ax(3),'YLim');
                ylim(ax(3),[0 cylim(2)])
                cylim=get(ax(3),'YLim');
                y = [cylim(1) cylim(2) cylim(2) cylim(1)];
                x = [435 435 480 480];
                patch(ax(3),x,y,'red','FaceAlpha',0.5)

                y = [cylim(1) cylim(2) cylim(2) cylim(1)];
                x = [300 300 345 345];
                patch(ax(3),x,y,'red','FaceAlpha',0.5)

                title(ax(3),'em at ex = 254 (HIX)')
                box(ax(3),"on")
            end

            Val1=sum(EmScan254s(drEEMtoolbox.mindist(data.Em,435):drEEMtoolbox.mindist(data.Em,480)),'omitnan');
            Val2=sum(EmScan254s(drEEMtoolbox.mindist(data.Em,300):drEEMtoolbox.mindist(data.Em,345)),'omitnan')+...
                sum(EmScan254s(drEEMtoolbox.mindist(data.Em,435):drEEMtoolbox.mindist(data.Em,480)),'omitnan');
            HIX(i)=Val1/Val2;

        end

    catch
        HIX(i)=NaN;
    end

    try % BIX
        Val1=EmScan310s(drEEMtoolbox.mindist(data.Em,380));
        Val2=EmScan310s(drEEMtoolbox.mindist(data.Em,430));
        BIX(i)=Val1/Val2;
    catch
        BIX(i)=nan;
    end

    try % ARIX
        if all(isnan(EmScan320))
            error('Nothing there')
        end

        
        if diagn
            cla(ax(4))
            hold(ax(4),"on")
            plot(ax(4),data.Em,EmScan320,'LineStyle','none','Marker','+','Color','k');
            plot(ax(4),data.Em,EmScan320s,'LineWidth',1.7)
            axis(ax(4),"tight")
            cylim=get(ax(4),'YLim');
            ylim(ax(4),[0 cylim(2)])
            cylim=get(ax(4),'YLim');
            xline(ax(4),390)
            xline(ax(4),520)
            title(ax(4),'em at ex = 320 (ARIX)')
            box(ax(4),"on")
        end
        Val1=EmScan320s(drEEMtoolbox.mindist(data.Em,520));
        Val2=EmScan320s(drEEMtoolbox.mindist(data.Em,390));
        arix(i)=Val1/Val2;
    catch
        arix(i)=nan;
    end

    if diagn
        title(t,['Spectrum ',num2str(i),' of ',num2str(data.nSample)])
        uicontrol(huic)
        uiwait(dfig)
        if ~ishandle(dfig); diagn=false; end % disables diagnosis option when plot is closed by user
    end
end


%% Results
VarName=[peaks.name]';
VarName{end+1}='FluI';
VarName{end+1}='FrI';
VarName{end+1}='BIX';
VarName{end+1}='HIX';
VarName{end+1}='ARIX';

metadata=table;
metadata.C=[md.Ex(:,5) md.Em(:,5)];
metadata.M=[md.Ex(:,4) md.Em(:,4)];
if ~HIX_excl
    picklist=array2table([Cpeak FI' FrI' BIX' HIX',arix'],...
        'VariableNames',VarName);
else
    picklist=array2table([Cpeak FI' FrI' BIX',arix'],...
        'VariableNames',VarName([1:end-2,end]));
end

if plt
    if data.toolboxOptions.uifig
        f=drEEMtoolbox.dreemuifig;
    else
        f=drEEMtoolbox.dreemfig;
    end
    set(f,'units','normalized','Name','pickPeaks: Extracted intensities of predefined fluorescence peaks','pos',[0.2594    0.2296    0.4448    0.5130])
    t=tiledlayout(f);
    ax=nexttile(t);
    hold(ax,'on')
    for n=1:numel(peaks)
        p=plot(ax,dataout.i,Cpeak(:,n),'LineWidth',1.5);

        row1 = dataTipTextRow('Sample',dataout.filelist);
        for k=1:numel(p)
            p(k).DataTipTemplate.DataTipRows(end+1) = row1;
            p(k).DataTipTemplate.DataTipRows(1).Label = '.i';
            p(k).DataTipTemplate.DataTipRows(2).Label = 'peak int.';
        end
    end
    legend(ax,[peaks.name]','location','bestoutside');
    title(ax,'Fluorescence peaks')
    xlabel(ax,'.i of the sample (i = identifier)')
    axis(ax,'tight')

    ax=nexttile(t);
    hold(ax,'on')
    p(1)=plot(ax,dataout.i,FI,'LineWidth',1.5);
    p(2)=plot(ax,dataout.i,FrI,'LineWidth',1.5);
    p(3)=plot(ax,dataout.i,BIX,'LineWidth',1.5);
    p(4)=plot(ax,dataout.i,arix,'LineWidth',1.5);
    if ~HIX_excl
        p(5)=plot(ax,dataout.i,HIX,'LineWidth',1.5);
        legend(ax,'Fluorescence index','Freshness index' ,'Biological index','Humification index','Aromaticity index', ...
            'location','bestoutside')
    else
        legend(ax,'Fluorescence index','Freshness index','Biological index','Aromaticity index', ...
            'location','bestoutside')
    end
    
    row1 = dataTipTextRow('Sample',dataout.filelist);
    for k=1:numel(p)
        p(k).DataTipTemplate.DataTipRows(end+1) = row1;
        p(k).DataTipTemplate.DataTipRows(1).Label = '.i';
        p(k).DataTipTemplate.DataTipRows(2).Label = 'index val.';
    end

    title(ax,'Fluorescence indicies')
    xlabel(ax,'.i of the sample (i = identifier)')
    hold(ax,'off')
    axis(ax,'tight')

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
[C,ia,ib]=intersect(dataout.opticalMetadata.Properties.VariableNames, ...
    picklist.Properties.VariableNames);
dataout.opticalMetadata(:,ia)=[];
dataout.opticalMetadata=[dataout.opticalMetadata,picklist];

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'Bulk fluorescence peaks extracted.',options,dataout);

dataout.validate(dataout);


% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',char(inputname(1)), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
else
    if nargout==0
        clearvars dataout picklist metadata
    end
end

end




function X = naninterp(X,method)
% Interpolate over NaNs
X(isnan(X)) = interp1(find(~isnan(X)), X(~isnan(X)), find(isnan(X)),method);
end

%%
function pltnext(sosurce,event) %#ok<INUSD>
uiresume(sosurce.Parent)
end

%%
function endfunc(~,~,hfig)
close(hfig)
end
