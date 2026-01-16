function fhandle = reportresidualanalysis(data,ftarget,mdfield)
% <a href = ""matlab:drEEMtoolbox.doc('reportresidualanalysis')">fhandle = reportresidualanalysis(data,ftarget,mdfield) (click to access documentation)</a>
%
% <strong>Perform and export residual analysis</strong>
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
% ftarget   {mustBeNumeric,drEEMdataset.mustBeModel}
% mdfield  
%
% <strong>EXAMPLE(S)</strong>
%   1. Report residual analysis of a bad 3 component model
%       fig = tbx.reportresidualanalysis(samples,3,'i');
%
% <a href = "matlab:drEEMtoolbox.doc('reportresidualanalysis')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data {mustBeA(data,"drEEMdataset")}
    ftarget {mustBeNumeric,drEEMdataset.mustBeModel(data,ftarget)}
    mdfield
end
%% Secondary validation of inputs.
f=drEEMdataset.modelsWithContent(data);

if isempty(f)
    error('This function requires PARAFAC models in the dataset. There are none.')
end
if not(ismember(ftarget,f))
    error(['Input to "ftarget" must point to an existing model. Choices are: ',num2str(f')])
end

% Let's get going.
fldname=inputname(3);
exp=nan(numel(f),2);
for j=1:numel(f)
    res=drEEMmodel.fitresipca(data.models(f(j)),data);
    exp(j,:)=res.explained(1:2);
end

if data.toolboxOptions.uifig
    fh=drEEMtoolbox.dreemuifig;
else
    fh=drEEMtoolbox.dreemfig;
end
fh.Name='drEEM: reportresidualanalysis.m';
t=tiledlayout(fh,"flow");

ax=nexttile(t);%,1,[1 2]);
plot(ax,f,sum(exp,2),'ko-')
axis(ax,"padded")
ylim(ax,[0 100])
hold(ax,"on")
plot(ax,f(f==ftarget),sum(exp(f==ftarget,:),2),'r+',MarkerSize=20)
title(ax,{'% Systematic residuals','(all calculated models, red = seleted)'})
ylabel(ax,'% explained by 2 PCs')
xlabel(ax,'# of PARAFAC components')


finalres=drEEMmodel.fitresipca(data.models(ftarget),data);


ax=nexttile(t);
mdp=mdfield;

scatter(ax,finalres.score(:,1),finalres.score(:,2),25,gcolor(mdp),"filled")
hold(ax,"on")
yline(ax,0,HandleVisibility='off')
xline(ax,0,HandleVisibility='off')
title(ax,{'PCA scores for residuals of',[num2str(ftarget),'-component PARAFAC model']})
ylabel(ax,'Scores PC2')
xlabel(ax,'Scores PC1')
box(ax,'on')

if numel(unique(mdp))<15
    mode='few';
    legend1=glegend(ax,gcolor(unique(mdp)),unique(mdp));
    legend1.Location='eastoutside';
else
    mode='lots';
    legend(ax,'off')
    ncat=numel(unique(mdp));
    if ncat<50
        samples=ncat;
        %stepsize=55;
    elseif ncat<100
        samples=10;
    else
        samples=5;
    end

    switch class(mdp)
        case 'categorical'
            colormap(ax,gcolor(unique(mdp)))
            c=colorbar(ax);
            cats=categories(unique(mdp));
            clim(ax,[1 max(round(linspace(1,numel(cats),samples)))])
            c.Ticks=round(linspace(1,numel(cats),samples));
            c.TickLabels=cats(round(linspace(1,numel(cats),samples)));
            ylabel(c,fldname,'Interpreter','none')
        case 'double'
            colormap(ax,gcolor(unique(mdp)))
            c = colorbar(ax);
            ylabel(c,fldname,'Interpreter','none')
            try
                clim(ax,[min(unique(mdp),[],"omitnan") max(unique(mdp),[],"omitnan")])
            catch ME
                delete(c)
                warning(ME.message)
            end

    end
end





vec=@(x) x(:);
for j=1:2
    ax=nexttile(t);
    lds=squeeze(finalres.loadsEEM(j,:,:));
    [~,h] = contourf(ax,data.Ex,data.Em,...
        lds,200,'LineStyle','none');
    hold(ax,'on')
    contour(ax,data.Ex,data.Em,...
        lds,5,'Color','k');
    hold(ax,'off')

    clim(ax,[prctile(vec(lds),1) prctile(vec(lds),99)])
    levels=h.LevelList;
    n_neg=sum(levels<0);
    n_pos=sum(levels>0);
    colormap(ax,residualcolormap(n_neg,n_pos))
    ylabel(colorbar(ax),'loadings')
    ylabel(ax,'Emission (nm)')
    xlabel(ax,'Exciation (nm)')
    title(ax,['Loadings PC',num2str(j)])
end

title(t,{'Report: PCA analysis of PARAFAC residuals:',...
    ['Overview and in-depth plots for ',num2str(ftarget),'-component PARAFAC model']})
warning off
scifig('width',18,'height',12,'font','Arial','FontSize',9,axes=ax,figure=fh);
% labelplots(-0.05,0.07,'^',ax);
warning on
fhandle=fh;

end

function map = residualcolormap(nneg,npos)

% ncol=ceil(round(ncol)/2);

nmap=[linspace(0,1,nneg)' linspace(0.45,1,nneg)' linspace(0.737,1,nneg)'];
pmap=flipud([flipud(linspace(1,0.686,npos)') flipud(linspace(1,0.208,npos)') flipud(linspace(1,0.278,npos)')]);

map=[nmap;pmap];

end

function [fhandle] = scifig(varargin)
% Format figures for scientific publications.
%
% USEAGE:
%           [fhandle] = scifig(Name,Value)
%
% Name,Value, e.g. scifig('width',8)
%            width:             Width of figure in cm (default: 8cm)
%            height:            Height of figure in cm (default: 7cm)
%            font:              Font to be used in figure (default: Myriad Pro)
%            fontsize:          Font size to be used in figure (default: 8)
%            axes:              if no axes exist, 'nocreate' will not
%                                   create one (default). 'create' will do so.
%
% (c) Urban Wuensch, 2019

%% Parse inputs
params = inputParser;
params.addParameter('width', 8, @isnumeric);
params.addParameter('height', 7, @isnumeric);
params.addParameter('font', 'Source Sans Pro', @ischar);
params.addParameter('fontsize', 8, @isnumeric);
params.addParameter('axes', 'nocreate', @isgraphics);
params.addParameter('figure', 'nocreate');

params.parse(varargin{:});

width = params.Results.width;
height  = params.Results.height;
font  = params.Results.font;
fontsz = params.Results.fontsize;
axcreate = params.Results.axes;

fhandle=params.Results.figure;

%% Configure the figure
% set(fhandle,'InvertHardcopy','off','Color',[1 1 1]);
set(fhandle, 'units', 'centimeters');
% fhandle.Renderer='Painters';
Cpos=get(fhandle,'pos');
set(fhandle,'pos', [Cpos(1) Cpos(2) width height]);
movegui(fhandle,'center');

%% Configure the axes
ax = (findobj(fhandle, 'type', 'axes'));
if isempty(ax)
    switch axcreate
        case 'create'
            ax=axes;
        case 'nocreate'
            %             disp('Empty figure. No axes created. ')
            %             disp('Run this function again once axes have been created to format them properly.')
            return
    end
end
fontsize(fhandle,fontsz,"points")
fontname(fhandle,font)

for n=numel(ax):-1:1
    set(ax(n),'TickDir','both');
    set(ax(n),'LineWidth',0.5);
    pos=get(ax(n),'OuterPosition');
    pos(pos<0)=0;
    set(ax(n),'OuterPosition',pos);
end
end

function h = glegend(ax,gcol,titles)


[~,i] = unique(gcol,'stable','rows');

cols=gcol(i,:);


hold(ax,'on');
for j=1:numel(i)

    h(j)=plot(ax,[nan nan],[nan nan],'LineStyle','none',"Marker",'.','Color',cols(j,:));

end

if isnumeric(titles)
    titles=cellstr(num2str(titles));
end
h=legend(h,titles);
h.ItemTokenSize=[10 6];
end

function colmap = gcolor(g)

if iscell(g)
    if any(cellfun(@(x) isempty(x),g))

        i=cellfun(@(x) isempty(x),g);
        g(i)={'NA'};

        c = categorical(g);

    else
        c = categorical(g);
    end
elseif iscategorical(g)
    g(isundefined(g))=categorical({'missing'});
    c = g;
elseif isnumeric(g)
    c=g;
else
    try
        c=categorical(g);
    catch
        c = g;
        warning('''g'' must be a cell array or a categorical array, or must be convertible to a categorical array.')
    end
end


clearvars g


switch class(c)
    case 'categorical'
        cats = categories(c);
    case 'double'
        cats =unique(c);
        if any(isnan(cats))
            cats(isnan(cats)) = []; % remove all nans
            cats(end+1) = NaN; % add the unique one.
        end
    otherwise
        error(['unknown class: ',char(class(c))])
end

ncats = numel(cats);

if ncats < 7
    cmap = lines(ncats);

elseif ncats>=7&&ncats<12
    cmap = hsv(ncats);

else
    cmap = parula(ncats);

end

colmap = nan(numel(c),3);

for j = 1:ncats
    switch class(c)
        case 'categorical'
            i = c==categorical(cats(j));
        case 'double'
            i = c==cats(j);
            if isnan(cats(j))
                i = isnan(c);
            end
    end
    col=repmat(cmap(j,:),sum(i),1);
    colmap(i,:) = col;
end
end

function [h] = labelplots(xstart,ystart,flip,ax)
% xstart: -0.07 
% ystart: +0.07
% flip: ^ _
%
%%

if nargin==0
    xstart=-0.07;
    ystart=+0.07;
    flip='^';
    figure1=gcf;
    ax = (findobj(figure1, 'type', 'axes'));   %should return a vector of length 2
    ax2 = (findobj(figure1, 'type', 'heatmap'));   %should return a vector of length 2
    ax3 = (findobj(figure1, 'type', 'confusion'));   %should return a vector of length 2
    ax4 = (findobj(figure1, 'type', 'geoaxes'));   %should return a vector of length 2
    ax=[ax ax2 ax3 ax4];
    try
        font=ax(1).FontName;
    catch
        get(gca, 'FontName'); % Heatmaps don't like the try-call, so a gca thing has to work
    end
end

if ~exist('ax','var')
        figure1=gcf;
    ax = (findobj(figure1, 'type', 'axes'));   %should return a vector of length 2
    ax2 = (findobj(figure1, 'type', 'heatmap'));   %should return a vector of length 2
    ax3 = (findobj(figure1, 'type', 'confusion'));   %should return a vector of length 2
    ax4 = (findobj(figure1, 'type', 'geoaxes'));   %should return a vector of length 2
    ax=[ax ax2 ax3 ax4];
    try
        font=ax(1).FontName;
    catch
        get(gca, 'FontName'); % Heatmaps don't like the try-call, so a gca thing has to work
    end
else
    try
        font=ax(1).FontName;
    catch
        get(gca, 'FontName'); % Heatmaps don't like the try-call, so a gca thing has to work
    end
end

switch flip
    case '^'
        lab=fliplr(cellstr(['A':'Z']')');
    case '_'
        lab=fliplr(cellstr(['a':'z']')');
end
lab=lab(end-numel(ax)+1:end);
units=get(gca,'units');

for n=1:numel(ax)
    pause(.01)

    set(ax(n),'units','normalized')
    
    pos=get(ax(n),'Pos');
    npos=[pos(1)+xstart pos(2)+ystart pos(3) pos(4)];
    npos(npos<0)=0;
    npos(npos>1)=1;
    h1=annotation(gcf,'textbox',...
        npos,... %1:Start X 2: Start Y 3:Width 4: Height
        'FitBoxToText','on',...
        'String',['(',lab{n},')']);
    h1.FontSize=9;
    h1.FontName=font;
    h1.LineStyle='none';
    h1.FontWeight='Bold';
    h(n)=h1;
    %set(gca,'Pos',pos);
    
end
set(gca,'units',units)
movegui('center')

end



