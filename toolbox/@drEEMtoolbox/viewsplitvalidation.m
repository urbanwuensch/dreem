function viewsplitvalidation(data,fac)
% <a href = "matlab:drEEMtoolbox.doc('viewsplitvalidation')">dataout = viewsplitvalidation(data,fac) (click to access documentation)</a>
%
% <strong>Compare PARAFAC models</strong> of a dataset to validate a model
%
% <strong>INPUTS - Required</strong>
% data (1,1) {mustBeNonempty,drEEMdataset.validate}
% fac (1,1)  {mustBeInteger,drEEMdataset.mustBeModel}
%
% <strong>EXAMPLE(S)</strong>
%       viewsplitvalidation(samples,5)
%
% <a href = "matlab:drEEMtoolbox.doc('viewsplitvalidation')"><strong>-> full documentation</strong></a>


% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,'drEEMdataset'),drEEMdataset.validate(data)}
    fac (1,1) {mustBeNumeric,drEEMdataset.mustBeModel(data,fac)}
end
if isempty(data.split)
    error('data.split is empty. Please read the documentation to follow the workflow of the toolbox.')
end

%% Input argument parsing and initial checks
narginchk(2,2)
overallModel=data;
nSplit=numel(data.split);
splitComparisons=nchoosek(1:nSplit,2);
splitNames=cellstr(strcat(repmat("Split ",nSplit,1),int2str((1:nSplit)')));
ignoreerror=false;
mode='tcc';
%% Define some functions and central variables
vec=@(x) x(:); % Function to unfold data
minimumtcc = 0.95; % Criterion for spectral match
minimumssc = 0.95;
passed=true;
message=[];

%% Reorganize models and names into cells

for k=1:nSplit
    cellOfModels{k}=data.split(k);
    cellOfNames{k}=splitNames{k};
end

if isempty(overallModel) % If no overall Model was provided.
    checkedoverall=false;
    for k=1:nSplit
        cellOfModels{k}=data.split(k);
        cellOfNames{k}=splitNames{k};
    end
    comparisons=splitComparisons;
else % If overall Model was provided, it is added as the last cell.
    checkedoverall=true;
    for k=1:nSplit
        cellOfModels{k}=data.split(k);
        cellOfNames{k}=splitNames{k};
    end
    cellOfModels{k+1}=overallModel;
    cellOfNames{k+1}='Overall';
    comparisons=[splitComparisons;[repmat(k+1,nSplit,1) (1:nSplit)']];
end
nComparisons=size(comparisons,1);

% Check if models are all there.
[pass,errmessage]=modelpresence(cellOfModels,cellOfNames,fac);
if ~pass
    error(sprintf([ '\n  <strong>Could not</strong> perform a splitvalidation because: \n' errmessage])) %#ok<*SPERR>
end
%% Step 1: calculate similarities
similarities=calculatesimilarities(cellOfModels,comparisons,fac,mode);

%% Step 2: Check conditions for validity

for k=1:nComparisons
    simiExtract=squeeze(similarities(k,:,:,:)); % Just so it's easier for developing
    % simiExtract: [m1,m2,em ex]
    matchingExEm(:,:,1)=simiExtract(:,:,1)>minimumssc;
    matchingExEm(:,:,2)=simiExtract(:,:,2)>minimumtcc;
    matchingEx{k}=squeeze(matchingExEm(:,:,2));
    matchingEm{k}=squeeze(matchingExEm(:,:,1));
    matchingExAndEm{k}=matchingEx{k}&matchingEm{k}; % Check that both Ex AND Em are similar enough
    
    %C1: Tells us if the model is valid, C2 and C3 will inform the user why a model is not validated.
    %1: Are there as many (or more) Ex&Em matches as components?
    condition1(k)=sum(vec(matchingExAndEm{k}))>=fac;
    %2: Are there as many (or more) Ex matches as components?
    condition2(k)=sum(vec(matchingEx{k}))>=fac;
    %3: Are there as many (or more) Em matches as components?
    condition3(k)=sum(vec(matchingEm{k}))>=fac;
end
%% Step 3: Diagnosis (determine if passed & prepare error messages for user)

if ~all(condition1)
    passed=false;
    for k=1:nComparisons
        if ~condition1(k)
            if ~condition2(k)
                matchmat=matchingEx{k};
                missmatched=find(~any(matchmat,1));
                for l=1:numel(missmatched)
                    message=[message ['\n   Excitation spectrum of C',num2str(missmatched(l)),' (',cellOfNames{comparisons(k,1)},') does not match any spectrum in ',cellOfNames{comparisons(k,2)}]]; %#ok<*AGROW>
                end
            end
            if ~condition3(k)
                matchmat=matchingEm{k};
                missmatched=find(~any(matchmat,1));
                for l=1:numel(missmatched)
                    message=[message ['\n   Emission spectrum of C',num2str(missmatched(l)),' (',cellOfNames{comparisons(k,1)},') does not match any spectrum in ',cellOfNames{comparisons(k,2)}]]; %#ok<*AGROW>
                end
            end
        end
    end
end

%% Step 4: Align the model components for plotting
[compidx,~]=sortcomponents(cellOfModels{end},cellOfModels,fac);

%% Step 5: Plot
if data.toolboxOptions.uifig
    hf=drEEMtoolbox.dreemuifig;fig=hf;
    hf=uipanel(hf,"Units","normalized","Position",[0.02 0.02 0.96,0.96],"Title",'');
    cm = uicontextmenu(fig);
    uimenu(cm, 'Text', 'Save figure panel', 'MenuSelectedFcn', @(src, event) savepanel(hf));
    hf.ContextMenu = cm;
else
    hf=drEEMtoolbox.dreemfig;
end
set(hf,'Units','normalized');
pos=get(hf,'Position');
pos(3)=fac*0.12+.1;
if pos(3)>=1
    pos(3)=1;
end
movegui(hf,"center")
if passed&&checkedoverall % Passed: Plot lines for all splits and overall model, as well as contours    
    col=lines(nSplit);
    t=tiledlayout(hf,2,fac,'padding','compact');
    for k=1:fac*2
        ax(k)=nexttile(t);
        if data.toolboxOptions.uifig
            ax(k).ContextMenu=cm;
        end
    end
    for k=1:fac
        hold(ax(k),'on')
        for l=1:nSplit
            h(l)=plot(ax(k),data.Em,data.split(l).models(fac).loads{2}(:,compidx(l,k)),'LineWidth',2,'LineStyle','-','Color',col(l,:));
            plot(ax(k),data.Ex,data.split(l).models(fac).loads{3}(:,compidx(l,k)),'LineWidth',2,'LineStyle','-.','Color',col(l,:))
        end
        h(l+1)=plot(ax(k),overallModel.Em,overallModel.models(fac).loads{2}(:,k),'LineWidth',1,'LineStyle','-','Color','k');
        plot(ax(k),overallModel.Ex,overallModel.models(fac).loads{3}(:,k),'LineWidth',1,'LineStyle','-.','Color','k')
        xlabel(ax(k),'Wavelength (nm)')
        ylabel(ax(k),'Loadings')
        title(ax(k),['Comp. ',num2str(k)])
        box(ax(k),'on')
        axis(ax(k),'tight')
        
        contourf(ax(k+fac),overallModel.Ex,overallModel.Em,overallModel.models(fac).loads{2}(:,k)*overallModel.models(fac).loads{3}(:,k)',...
            100,'LineStyle','none')
        hold(ax(k+fac),'on')
        contour(ax(k+fac),overallModel.Ex,overallModel.Em,overallModel.models(fac).loads{2}(:,k)*overallModel.models(fac).loads{3}(:,k)',...
            10,'color','k')
        xlabel(ax(k+fac),'Excitation (nm)')
        ylabel(ax(k+fac),'Emission (nm)')
    end
    legend1=legend(h,[splitNames;{'Overall'}],'location','best');
    legend1.Layout.Tile = 'East';
    try
        legend1.ItemTokenSize=legend1.ItemTokenSize./2;
    end
    t.Title.String=(['Validated ',num2str(fac),'-component PARAFAC model']);
    t.Title.FontWeight = 'bold';
    %t.Title.FontName = 'Source Sans Pro';
elseif ~passed&&checkedoverall % Failed. Plot all splits + overall model
    col=lines(nSplit);
    t=tiledlayout(hf,"flow",'padding','compact','TileSpacing','compact');
    for k=1:fac
        ax(k)=nexttile(t);
        hold(ax(k),'on')
        for l=1:nSplit
            h(l)=plot(ax(k),data.Em,data.split(l).models(fac).loads{2}(:,compidx(l,k)),'LineWidth',2,'LineStyle','-','Color',col(l,:));
            plot(ax(k),data.Ex,data.split(l).models(fac).loads{3}(:,compidx(l,k)),'LineWidth',2,'LineStyle','-.','Color',col(l,:))
        end
        
        h(l+1)=plot(ax(k),overallModel.Em,overallModel.models(fac).loads{2}(:,compidx(end,k)),'LineWidth',1,'LineStyle','-','Color','k');
        plot(ax(k),overallModel.Ex,overallModel.models(fac).loads{3}(:,compidx(end,k)),'LineWidth',1,'LineStyle','-.','Color','k')
        
        title(ax(k),['Comp. ',num2str(k)])
        box(ax(k),'on')
        axis(ax(k),'tight')       
    end
    legend1=legend(h,[splitNames;{'Overall'}],'location','best');
    xlabel(t,'Wavelength (nm)')
    ylabel(t,'Loadings')
    try
        legend1.ItemTokenSize=legend1.ItemTokenSize./2;
    end
    title(t,{'Fail: Comparison between components',' (reordered to match overall model)'})
    % pos=get(hf,'Position');
    % pos(4)=pos(4)./2;
    % set(hf,'Position',pos);
end

%% Step 6: Notify user (this is last because errors might be thrown)

if ~passed
    message=['\n  Splitvalidation <strong>not</strong> successful. Here''s why: \n' message '\n   \n   <strong>Note</strong>: Components in plots may have been reordered. The information here refers to the original indices.'];
    if ~ignoreerror
        error(sprintf(message))
    else
        fprintf(2,sprintf([message '\n']))
    end
end
if ~checkedoverall&&passed
    disp(' ')
    disp(sprintf(['Overall Result = <strong>Validated</strong> for all comparisons, but no comparison with an overall model was made. ' ...
        '\n    To complete the validation, specify input variable ''overallmodel'''])) %#ok<*DSPS>
    pause(1)
    dataout=data;
    dataout.Val_Result='Overall Result = Validated for all comparisons';
    for k=1:nComparisons
        comps{k}=[cellOfNames{comparisons(k,1)}, "vs. ", cellOfNames{comparisons(k,2)}];
    end
    dataout.Comparisons=comps; clearvars comps
    
elseif checkedoverall&&passed
    disp(' ')
    disp('Overall Result= <strong>Validated</strong> for all comparisons')
    pause(1)
    dataout=data;
    dataout.models(fac).status='validated';
    
    for k=1:nComparisons
        comps{k}=[cellOfNames{comparisons(k,1)}, "vs. ", cellOfNames{comparisons(k,2)}];
    end
    

end

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',char(inputname(1)), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
end

end



function [pass,message]=modelpresence(models,mname,fac)
pass=true;
message=[];
nExnEm=[];
for k=1:numel(models)
    try
        m=models{k}.models(fac).loads;
        nExnEm(k,:)=[size(m{3},1) size(m{2},1)];
        if isempty(m)
            pass=false;
            message=[message '''',mname{k},''' does not contain a model with ',num2str(fac),' components \n'];
        end
    catch
        pass=false;
        message=[message '''',mname{k},''' does not contain a model with ',num2str(fac),' components \n'];
    end
end
if ~isempty(nExnEm)
    if numel(unique(nExnEm))>2
       pass=false;
       message=[message '  Some of the datasets (specifically the models you want to compare) differ in their dataset dimensions (Emission or Excitation).'...
           ' That is not allowed, similarities cannot be calculated for that case. \n'];
    end
end
end

function [simi] = calculatesimilarities(cellofmodels,comparisons,fac,mode)
tcc=@(l1,l2) l1'*l2/(sqrt(l1'*l1)*sqrt(l2'*l2)); % Tucker's congruence coefficient
nComparisons=size(comparisons,1);
for k=1:nComparisons
    m1=cellofmodels{comparisons(k,1)};
    m2=cellofmodels{comparisons(k,2)};
    for l=1:fac
        for o=1:fac
            switch mode
                case 'ssc'
                    simi(k,l,o,:)=[ssc(m1.models(fac).loads{2}(:,l),m2.models(fac).loads{2}(:,o)) ...
                        tcc(m1.models(fac).loads{3}(:,l),m2.models(fac).loads{3}(:,o))];
                case 'tcc'
                    simi(k,l,o,:)=[tcc(m1.models(fac).loads{2}(:,l),m2.models(fac).loads{2}(:,o)) ...
                        tcc(m1.models(fac).loads{3}(:,l),m2.models(fac).loads{3}(:,o))];
                otherwise
                    error('Mode must be either ''ssc'' (default) or ''tcc'' (previous default).')
            end
        end
    end
end
end

function [tcc2,shift_penalty,shape_penalty] = ssc(load1,load2)

load1=load1./norm(load1,1);
load2=load2./norm(load2,1);

load1i=load1./norm(load1,Inf);
load2i=load2./norm(load2,Inf);


[~,ml1i]=max(load1i);
[~,ml2i]=max(load2i);
ml1=trapz(load1i);
ml2=trapz(load2i);
shape_penalty=abs(ml2-ml1)./size(load1,1);
shift_penalty=abs(ml2i-ml1i)./size(load1,1);

tcc=load1'*load2/(sqrt(load1'*load1)*sqrt(load2'*load2));
tcc2=tcc-(shape_penalty+shift_penalty);
end

function [compidx,besttcc] = sortcomponents(reference,models,fac)
tcc=@(l1,l2) l1'*l2/(sqrt(l1'*l1)*sqrt(l2'*l2)); % Tucker's congruence coefficients
compidx=zeros(numel(models),fac);
for k=1:numel(models)
    for l=1:fac
        for o=1:fac
            simi(k,l,o,:)=[tcc(reference.models(fac).loads{2}(:,l),models{k}.models(fac).loads{2}(:,o)) ...
                tcc(reference.models(fac).loads{3}(:,l),models{k}.models(fac).loads{3}(:,o))];
        end
    end
    
    
    simiExtract=squeeze(simi(k,:,:,:)); % Extract, just so it's easier to work with
    % simiExtract: [m1,m2,em ex]
    matchingExEm=simiExtract>0.95; % Express it in logical array
    matchingEx=squeeze(matchingExEm(:,:,2));
    matchingEm=squeeze(matchingExEm(:,:,1));
    matchingExAndEm=matchingEx&matchingEm; % Check that both Ex AND Em are similar enough
    
    for l=1:fac
        ci=[];
        besttcc(k,l)=max(sum(simiExtract(l,:,:),3))/2;
        if isscalar(find(matchingExAndEm(l,:))) % Uniequivolval match
            ci=find(matchingExAndEm(l,:));
        elseif numel(find(matchingExAndEm(l,:)))>1 % Take the best when multiple are similar
            [~,ci]=max(sum(simiExtract(l,:,:),3)); 
        elseif not(any(matchingExAndEm(l,:))) % Take the best when none match
            % Edit: Here, the function should not do anything because these
            % bad cases are handled futher down.
            % [val,ci]=max(sum(simiExtract(l,:,:),3));
            % if val<1
            %     ci=[];
            % end
        end
        if ~isempty(ci)
            compidx(k,l)=ci;
        end
    end
    
    
end


% Fix the missing entries in compidx
if all(sum(compidx==0,2)<=1) % When only one is missing, it's obvious
    for k=1:numel(models)
        if any(compidx(k,:)==0)
            compidx(k,compidx(k,:)==0)=setdiff(1:fac,compidx(k,:));
        end
    end
else % This should not be the case unless the comparisons are terrible
    % Order the components by their emission maxima.
    % This is not perfect, especially when the models are bad.
    for k=1:numel(models)
        compidx(k,:)=orderbyemissionmax(models{k},fac);
    end
end


end
function seq = orderbyemissionmax( model,f )
% Order PARAFAC model components by their emission maxima
[~,idx]=max(model.(['Model' num2str(f)]){2});
[~,seq]=sort(idx);
end

function savepanel(panel)

if isempty(panel)
    warning('Could not find a panel in the selected tab. Cannot save as image.')
    return
end
defname=['splitvalidation_results','.png'];

[filename, pathname] = uiputfile({'*.png'; '*.jpg'},...
    'Save Figure As', ...
    defname);


if isequal(filename, 0) || isequal(pathname, 0)
    pathname=pwd;
    filename=defname;
    warning('Did not specify filename and path. Assumed default name in current directory.')
end


warning off
exportgraphics(panel,...
    fullfile(pathname,filename),...
    "BackgroundColor","white",...
    "Resolution",600)
warning on

figure(panel.Parent)

end