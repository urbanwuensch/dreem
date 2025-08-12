function viewspectralvariance(data)
% <a href = "matlab:drEEMtoolbox.doc('viewspectralvariance')">spectralvariance(data) (click to access documentation)</a>
%
% <strong>Inspect the spectral variability</strong> of a drEEMdataset
%
% <strong>INPUTS - Required</strong>
% data      {mustBeA("drEEMdataset")}
%
% <strong>EXAMPLE(S)</strong>
%   spectralvariance(data);
%
% <a href = "matlab:drEEMtoolbox.doc('viewspectralvariance')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1)              {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
end

if containsfluorescence(data)&&containsabsorbance(data)
    pltcase=1;
    dat=data.X;
elseif containsfluorescence(data)&&~containsabsorbance(data)
    pltcase=2;
    dat=data.X;
elseif containsabsorbance(data)&&~containsfluorescence(data)
    pltcase=3;
else
    pltcase=10;
end

if pltcase==10
   error('Refer to function help. Could not find necessary fields in the dataset.')
end



if pltcase==1||pltcase==2
    [X,~,fscales]=nprocess(dat,[0 0 0],[1 0 0],[],[],1,-1);
    fdom=squeeze(std(X,'omitmissing'));
end
if pltcase==1||pltcase==3
    [Y,~,~]=nprocess(data.abs,[0 0],[1 0],[],[],1,-1);
    cdom=std(Y,'omitmissing');
end
fscales{1}(isinf(fscales{1}))=nan;
if any(fscales{1}>5*median(fscales{1}))
    warning('Some samples have very little signal (e.g. blanks) and thus likely negatively impact the the spectralvariance plots')
    disp(['Consider removing the sample(s):  ',num2str(find(fscales{1}>5*median(fscales{1},2)))])
    disp('If no blanks (or similar) samples are present, the issue may be samples with high fluorescence values instead.')
end

%% Figure setup
if data.toolboxOptions.uifig
    hf=drEEMtoolbox.dreemuifig;
else
    hf=drEEMtoolbox.dreemfig;
end
set(hf,'unit','normalized');
pos=get(hf,'Position');
set(hf,'Position',[pos(1:2) 0.5 0.3]);
movegui(hf,'center');
pos=[0.13,0.44,0.28,0.48;0.45,0.44,0.12,0.48;0.62,0.44,0.28,0.48;0.62,0.13,0.28,0.17];
ax = gobjects(size(pos,1),1);
for n=1:size(pos,1)
    ax(n)=axes(hf,'pos',pos(n,:));
end
ax([3 2])=ax(2:3);


% CDOM absorbance
for n=1:numel(ax)
    hold(ax(n),'on')
end
if pltcase==1||pltcase==3
    %yyaxis(ax(1),'left'),set(ax(1),'YColor',[1 .2 .2 0.5])
    ylabel(ax(1),'Unit scaled absorbance')
    %h1=plot(ax(1),data.absWave,Y,'Color',[1 .2 .2 0.5],'LineWidth',1,'LineStyle','-','Marker','none');%./sum(Y,2)
    %yyaxis(ax(1),'right'),set(ax(1),'YColor',[0 0 0 0.8])
    h2=plot(ax(1),data.absWave,cdom,'Color',[0 0 0 0.8],'LineWidth',2,'LineStyle','-','Marker','none');
    %legend(ax(1),[h1(1), h2],{'All spectra (unit scaled)','Standard deviation'})
    legend(ax(1),h2,{'Standard deviation'})
end
axis(ax(1),'tight')
xlabel(ax(1),'Absorbance wavelength (nm)')
ylabel(ax(1),'Std. dev. absorbance')
title(ax(1),'CDOM absorbance')

% FDOM EEMs
if pltcase==1||pltcase==2
    pltdata=squeeze(fdom);%./squeeze(mfdom);
    pltdata(pltdata==0)=nan;
    ploteem(ax(2),pltdata,data.Ex,data.Em)
    set(ax(2),ColorScale='log')
end
c=colorbar(ax(2));
ylabel(c,'Std. dev. fluorescence (log scale)')
title(ax(2),'FDOM fluorescence')
set(ax(2),'units','pixel')
set(ax(2),'YTickLabel','','XTickLabel','')
refylim=get(ax(2),'YLim');
refxlim=get(ax(2),'XLim');

if pltcase==1||pltcase==2
    pltvec=squeeze(sum(X,3,'omitnan'));
    normvec=(mean(max(squeeze(sum(X,3,"omitmissing"))))*2);
    pltvec=pltvec./normvec;
    pltvec(pltvec==0)=nan;
    
    plot(ax(3),pltvec,data.Em,'Color',[1 .2 .2 0.5],'LineWidth',1)
    hold(ax(3),'on')
    plot(ax(3),sum(fdom,2,"omitmissing")./max(sum(fdom,2,"omitmissing")),data.Em,'Color','k','LineWidth',2)
end
set(ax(3),'XDir','reverse')
set(ax(3),'units','pixel')
refpos=get(ax(2),'pos');
pos1=get(ax(3),'pos');
ylim(ax(3),refylim)
set(ax(3),'XTickLabel','')

offs=refpos(1)-(pos1(1)+pos1(3));
set(ax(3),'pos',[pos1(1)+offs refpos(2) pos1(3) refpos(4)])
ylabel(ax(3),'Emission (nm)')

% ax4=subplot(4,5,[19 20]);
if pltcase==1||pltcase==2
    pltvec=squeeze(sum(X,2,"omitmissing"))./(mean(max(squeeze(sum(X,2,"omitmissing"))))*2);
    pltvec(pltvec==0)=nan;
    
    plot(ax(4),data.Ex,pltvec,'Color',[1 .2 .2 0.5],'LineWidth',1)
    hold(ax(4),'on')
    plot(ax(4),data.Ex,sum(fdom,"omitmissing")./max(sum(fdom,"omitmissing")),'Color','k','LineWidth',2)
end
set(ax(4),'units','pixel')
xlim(ax(4),refxlim)
set(ax(4),'YTickLabel','')
refpos=get(ax(2),'pos');
pos2=get(ax(4),'pos');
offs=refpos(2)-(pos2(2)+pos2(4));
set(ax(4),'pos',[refpos(1) pos2(2)+offs refpos(3) pos2(4)])
xlabel(ax(4),'Excitation (nm)')

pos2=get(ax(4),'pos');
height2=pos2(4);
pos1=get(ax(3),'pos');
height1=pos1(3);
diff=height1-height2;
set(ax(3),'pos',[pos1(1)+diff pos1(2) pos1(3)-diff pos1(4)])

for n=1:4
    set(ax(n),'units','normalized')
    box(ax,'on')
end

linkaxes([ax(2),ax(3)],'y')
linkaxes([ax(2),ax(4)],'x')

end


function result = containsabsorbance(data)
if not(isempty(data.abs))
    result=true;
else
    result=false;
end
end

function result = containsfluorescence(data)
if not(isempty(data.X))
    result=true;
else
    result=false;
end
end

function ploteem(ax,mat,x,y)
sc = surfc(ax,x,y,mat,...
    'EdgeColor','none','FaceColor','flat');
view(ax,[19 44.5])
sc(2).ZLocation = 'zmax';
sc(2).LineColor='k';
sc(2).LineWidth = 0.5;
sc(2).LevelList=linspace(min(mat(~isnan(mat))),max(mat(~isnan(mat))),20);
zlim(ax,[min(mat(~isnan(mat))),max(mat(~isnan(mat)))])
clim(ax,[min(mat(~isnan(mat))),max(mat(~isnan(mat)))])

end