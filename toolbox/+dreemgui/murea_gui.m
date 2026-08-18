classdef murea_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure  matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        LeftPanel                       matlab.ui.container.Panel
        GridLayout7                     matlab.ui.container.GridLayout
        SettingsPanel                   matlab.ui.container.Panel
        GridLayout8                     matlab.ui.container.GridLayout
        ColormapEEMDropDown             matlab.ui.control.DropDown
        ColormapEEMDropDownLabel        matlab.ui.control.Label
        ExcludelowFDOMCheckBox          matlab.ui.control.CheckBox
        PlotfocusDropDown               matlab.ui.control.DropDown
        PlotfocusDropDownLabel          matlab.ui.control.Label
        PARAFACcomponentsDropDown       matlab.ui.control.DropDown
        PARAFACcomponentsDropDownLabel  matlab.ui.control.Label
        RightPanel                      matlab.ui.container.Panel
        GridLayout4                     matlab.ui.container.GridLayout
        TabGroup                        matlab.ui.container.TabGroup
        OverviewgraphTab                matlab.ui.container.Tab
        GridLayout6                     matlab.ui.container.GridLayout
        OverviewPanel                   matlab.ui.container.Panel
        ScoresloadingsTab               matlab.ui.container.Tab
        GridLayout5                     matlab.ui.container.GridLayout
        ScoresLoadingsPanel             matlab.ui.container.Panel
        ScoresLoadingsGrid              matlab.ui.container.GridLayout
        LoadingsPanel                   matlab.ui.container.Panel
        ScoresPanel                     matlab.ui.container.Panel
        ScoreplotsTab                   matlab.ui.container.Tab
        GridLayout9                     matlab.ui.container.GridLayout
        SelectedEEMPanel                matlab.ui.container.Panel
        GridLayout_2                    matlab.ui.container.GridLayout
        Switch                          matlab.ui.control.Switch
        eem                             matlab.ui.control.UIAxes
        ScoreoverviewPanel              matlab.ui.container.Panel
        gl_detail                       matlab.ui.container.GridLayout
        selectasampleButton             matlab.ui.control.Button
        classboundaryCheckBox           matlab.ui.control.CheckBox
        randomizeorderCheckBox          matlab.ui.control.CheckBox
        alphaEditField                  matlab.ui.control.NumericEditField
        alphaEditFieldLabel             matlab.ui.control.Label
        colorbyLabel                    matlab.ui.control.Label
        xaxisLabel                      matlab.ui.control.Label
        yaxisLabel                      matlab.ui.control.Label
        DropDownColorBy                 matlab.ui.control.DropDown
        DropDownY                       matlab.ui.control.DropDown
        DropDownX                       matlab.ui.control.DropDown
        UIAxes                          matlab.ui.control.UIAxes
        ContextMenu                     matlab.ui.container.ContextMenu
        SavefigurepanelasimageMenu      matlab.ui.container.Menu
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end


    properties (Access = private)
        data (1,1) {mustBeA(data,'drEEMdataset'),drEEMtoolbox.validatedataset(data)} = drEEMdataset;
        dataBackup (1,1) {mustBeA(dataBackup,'drEEMdataset'),drEEMtoolbox.validatedataset(dataBackup)} = drEEMdataset;
        modelName (1,:) {mustBeText,mustBeMember(modelName,["PCA","oPARAFAC","uPARAFAC"])} = "PCA";
        nComp (1,1) {mustBeNumeric} = nan
        plotLayout (1,:) {mustBeText,mustBeMember(plotLayout,["Scores only","Loadings only","Scores & loadings"])} = "Scores & loadings";
        model % Description
        nCompResiModel (1,1) {mustBeNumeric} = 7% Description
        tempstore % Description
        selectedSample (1,1) {mustBeNumeric}% Description
    end

    methods (Access = private)
        function processdata(app)

            dataLocal=app.dataBackup;
            dataLocal=app.interpmissing(dataLocal);
            % Interpolation (forced)...

            dataLocal.X=dataLocal.X-nway.modeleval.nmodel(dataLocal.models(app.nComp).loads);
            switch app.modelName
                case "PCA"
                    tens2mat=@(x,sz1,sz2,sz3) reshape(x,sz1,sz2*sz3);

                    X=dataLocal.X;
                    Xbackup=X;

                    Xunf          = tens2mat(X,dataLocal.nSample,dataLocal.nEm,dataLocal.nEx);
                    Xbackup       = tens2mat(Xbackup,dataLocal.nSample,dataLocal.nEm,dataLocal.nEx);

                    [Xunf,~,s]    = nway.tools.nprocess(Xunf,[1 0],[1 0],[],[],1,-1);
                    [Xbackup]     = nway.tools.nprocess(Xbackup,[1 0],[1 0],[],[],1,-1);

                    s=s{1};
                    if app.ExcludelowFDOMCheckBox.Value
                        dataLocal.userdata.lowdelete=s>5*median(s); % Exclude exceptionally low signal samples
                    else
                        dataLocal.userdata.lowdelete=false(size(Xunf,1),1);
                    end

                    dataLocal.userdata.excl=all(isnan(Xbackup),1); % Exclude variables that are all NaN (scatter)
                    dataLocal.userdata.incl=not(dataLocal.userdata.excl);

                    Xunf(:,dataLocal.userdata.excl) = [];
                    Xbackup(:,dataLocal.userdata.excl) = [];
                    dataLocal.userdata.containsmissing=any(isnan(Xbackup),2); % Just for the sake of controling the checkmarks
                    dataLocal.userdata.low=dataLocal.userdata.lowdelete;
                    dataLocal.userdata.lowdelete = dataLocal.userdata.lowdelete|any(isnan(Xbackup),2); % Mark samples (also samples containing ANY NaN)

                    Xunf(dataLocal.userdata.lowdelete,:) = [];
                    if size(Xunf,1)<app.nCompResiModel
                        app.nCompResiModel=size(Xunf,1);
                        %warning('Seems as if there are very few good samples to work with. Number of PCA components reduced.')
                    end
                    warning off
                    dataLocal.userdata.Xunf=Xunf;
                    dataLocal.userdata.Xbackup=Xbackup;
                case "oPARAFAC"
                    
                case "uPARAFAC"
                    
                    
            end
            app.DropDownX.Items=cellstr(num2str((1:app.nCompResiModel)'));
            app.DropDownY.Items=cellstr(num2str((1:app.nCompResiModel)'));
            app.DropDownX.Value='1';
            app.DropDownY.Value='2';
            app.data=dataLocal;

            app.selectedSample=nan;

        end

        function runmodels(app)
            lev=@(x) diag(x*(x'*x)^-1*x');
            switch app.modelName
                case "PCA"
                    
                    % SVD approach for simplicity sake (avoid toolbox dependencies and
                    % incompatibilities).
                    [U,S,V] = svd(app.data.userdata.Xunf,"econ"); %V = coeff/loads
                    score=app.data.userdata.Xunf*V(:,1:app.nCompResiModel);
                    loads=V;
                    data_ssq=sum(app.data.userdata.Xunf(:).^2);

                    for j=1:app.nCompResiModel
                        Xhat=score(:,j)*loads(:,j)';
                        error_ssq=data_ssq-sum(Xhat(:).^2,"omitmissing");
                        explained(j,1)=100 * (1 - error_ssq / data_ssq );
                    end

                    % [loads, score, ~ , ~ , explained] = pca(Xunf,...
                    %     'NumComponents',app.comp,...
                    %     'Centered',false,...
                    %     'Rows','complete');
                    warning on
                    app.model.loads = loads;
                    for j=1:app.nCompResiModel
                        dat=nan(app.data.nEm*app.data.nEx,1);
                        dat(app.data.userdata.incl)=loads(:,j);
                        app.model.loadsEEM(j,:,:)=reshape(dat,app.data.nEm,app.data.nEx);
                    end

                    app.model.score = score;
                    app.model.explained = explained;
                    app.model.lev=lev(score);
                case "oPARAFAC"
                    [mod,it,err]=nway.models.parafac(app.data.X,app.nCompResiModel,[1e-6,1,0,0,-1,500],[1 0 0]);
                    app.model.score=mod{1};
                    for j=1:app.nCompResiModel
                        app.model.loadsEEM(j,:,:)=mod{2}(:,j)*mod{3}(:,j)';
                    end

                    app.model.explained=nan(1,app.nCompResiModel);
                    measuredSS = sum(app.data.X(:).^2,'omitnan'); % sum of sq. data
                    for l=1:app.nCompResiModel
                        modelledH=nway.modeleval.nmodel([{mod{1}(:,l)} {mod{2}(:,l)} {mod{3}(:,l)}]);
                        app.model.explained(l)=100 * (1 - (sum((app.data.X(:) - modelledH(:)).^2,'omitnan')) / measuredSS);
                    end
                    
                    app.model.lev=lev(mod{1});

                case "uPARAFAC"

            end

        end

        function visualize(app)
            % Overall
            t=tiledlayout(app.OverviewPanel,1,2);
            ax=nexttile(t);
            ev=arrayfun(@(x) x.percentExplained,app.dataBackup.models);
            f=drEEMdataset.modelsWithContent(app.dataBackup);
            ev=ev(f);
            plot(ax,f,ev,'k',LineStyle='-',Marker='o',DisplayName='all')
            hold(ax,"on")
            line(ax,f(f==app.nComp),ev(f==app.nComp),'Marker','diamond', ...
                MarkerFaceColor='r',MarkerEdgeColor='r',DisplayName='selected')
            title(ax,'Explained data (PARAFAC)')
            pbaspect(ax,[1 1 1])
            ylabel(ax,'Explained by PARAFAC models (%)')
            legend(ax,location="best")

            ax=nexttile(t);
            ev=app.model.explained;
            f=1:numel(ev);
            plot(ax,f,ev,'k',LineStyle='-',Marker='o')
            ylim(ax,[0 100])
            ylabel(ax,'% explained residuals (PCA)')

            yyaxis(ax,"right")
            plot(ax,f,cumsum(ev),'r',LineStyle='-',Marker='o')
            ylim(ax,[0 100])
            ylabel(ax,'% cummulative explained residuals (PCA)')
            set(ax,YColor='r')
            title(ax,{['Explained by PCA on residuals of '],[num2str(app.nComp),'-comp. PARAFAC model']})
            pbaspect(ax,[1 1 1])

            % Delete and recreate Plot panel
            delete(app.ScoresLoadingsPanel)
            % Create ScoresLoadingsPanel
            app.ScoresLoadingsPanel = uipanel(app.GridLayout5);
            app.ScoresLoadingsPanel.Layout.Row = 1;
            app.ScoresLoadingsPanel.Layout.Column = 1;
            % Create ScoresLoadingsGrid
            app.ScoresLoadingsGrid = uigridlayout(app.ScoresLoadingsPanel);
            app.ScoresLoadingsGrid.ColumnWidth = {'1x'};

            switch app.plotLayout
                case 'Scores & loadings'
                    app.ScoresLoadingsGrid.RowHeight = {'1x','1x'};

                    % Create ScoresPanel
                    app.ScoresPanel = uipanel(app.ScoresLoadingsGrid);
                    app.ScoresPanel.Title = 'Scores';
                    app.ScoresPanel.Layout.Row = 1;
                    app.ScoresPanel.Layout.Column = 1;
                    app.ScoresPanel.ContextMenu = app.ContextMenu;

                    % Create LoadingsPanel
                    app.LoadingsPanel = uipanel(app.ScoresLoadingsGrid);
                    app.LoadingsPanel.Title = 'Loadings';
                    app.LoadingsPanel.Layout.Row = 2;
                    app.LoadingsPanel.Layout.Column = 1;
                    app.LoadingsPanel.ContextMenu = app.ContextMenu;
                case 'Scores only'
                    app.ScoresLoadingsGrid.RowHeight = {'1x'};
                    % Create ScoresPanel
                    app.ScoresPanel = uipanel(app.ScoresLoadingsGrid);
                    app.ScoresPanel.Title = 'Scores';
                    app.ScoresPanel.Layout.Row = 1;
                    app.ScoresPanel.Layout.Column = 1;
                    app.ScoresPanel.ContextMenu = app.ContextMenu;


                case 'Loadings only'
                    app.ScoresLoadingsGrid.RowHeight = {'1x'};
                    % Create LoadingsPanel
                    app.LoadingsPanel = uipanel(app.ScoresLoadingsGrid);
                    app.LoadingsPanel.Title = 'Loadings';
                    app.LoadingsPanel.Layout.Row = 1;
                    app.LoadingsPanel.Layout.Column = 1;
                    app.LoadingsPanel.ContextMenu = app.ContextMenu;
                otherwise
                    error(' take a look')
            end
            % Scores
            if contains(lower(app.plotLayout),'scores')

                t=tiledlayout(app.ScoresPanel);
                for j=1:app.nCompResiModel
                    ax=nexttile(t);
                    plot(ax,app.model.score(:,j),'k')
                    yline(ax,0,LineStyle='--')
                    title(ax,['PC',num2str(j),' (',num2str(round(app.model.explained(j),1)),'%)'])
                end
                xlabel(t,'Sample #')
                ylabel(t,'Scores')
            end

            % Loadings
            if contains(lower(app.plotLayout),'loadings')
                t=tiledlayout(app.LoadingsPanel);
                for j=1:app.nCompResiModel
                    ax1=nexttile(t);
                    pltdat=squeeze(app.model.loadsEEM(j,:,:));
                    [~,h] = contourf(ax1,app.data.Ex,app.data.Em,pltdat,200,'LineStyle','none');
                    hold(ax1,'on')
                    contour(ax1,app.data.Ex,app.data.Em,pltdat,5,'Color','k');
                    hold(ax1,'off')
                    levels=h.LevelList;
                    n_neg=sum(levels<0);
                    n_pos=sum(levels>0);

                    colormap(ax1,app.residualcolormap(n_neg,n_pos))
                    title(ax1,['PC',num2str(j),' (',num2str(round(app.model.explained(j),1)),'%)'])

                end
                ylabel(t,'Emission (nm)')
                xlabel(t,'Excitation (nm)')
            end


            % Scores detail tab
            app.updatescoreplots
            cla(app.eem)

        end





        function NumberOfComponentsChanged(app,event)
            all = arrayfun(@(x) str2double(x.Text),app.NumberofComponentsMenu.Children);
            sel = str2double(event.Source.Text);
            app.nComp=sel;
            desel = setdiff(all,sel);

            desel = cellstr(num2str(desel));

            for j=1:numel(app.NumberofComponentsMenu.Children)
                child=app.NumberofComponentsMenu.Children(j);
                if any(matches(child.Text,desel))
                    child.Checked='off';
                else
                    child.Checked='on';
                end
            end

            app.processdata
            app.runmodels
            app.visualize

        end

        

        function dataLocal = interpmissing(app,data)
            dataLocal=data;
            missmat=ismissing(dataLocal.X);
            allmiss=squeeze(all(missmat,1));
            f=drEEMdataset.modelsWithContent(dataLocal);

            Xhat=nway.modeleval.nmodel(dataLocal.models(f(end)).loads);

            for j=1:dataLocal.nSample
                localmiss=ismissing(squeeze(dataLocal.X(j,:,:)));
                miss=localmiss&not(allmiss);

                dataLocal.X(j,miss)=Xhat(j,miss);

            end
        end

        function map = residualcolormap(app,nneg,npos)
            % ncol=ceil(round(ncol)/2);
            try
                S = load('CrameriColourMaps7.0.mat','vik');
                map = S.('vik');
                nmap=map(1:128,:);
                pmap=map(129:end,:);
                nmap = interp1(1:size(nmap,1), nmap, linspace(1,size(nmap,1),nneg),'linear');
                pmap = interp1(1:size(pmap,1), pmap, linspace(1,size(pmap,1),npos),'linear');
                map=[nmap;pmap];
            catch
                nmap=[linspace(0,1,nneg)' linspace(0.45,1,nneg)' linspace(0.737,1,nneg)'];
                pmap=flipud([flipud(linspace(1,0.686,npos)') flipud(linspace(1,0.208,npos)') flipud(linspace(1,0.278,npos)')]);
                map=[nmap;pmap];
            end

        end

        function updatescoreplots(app)
            value(1) = app.pullModel(app.DropDownX.Value(1));
            value(2) = app.pullModel(app.DropDownY.Value(1));

            mod=app.model;


            colorbar(app.UIAxes,'off')
            cla(app.UIAxes,'reset')
            mode='lots';
            if matches(app.DropDownColorBy.Value,'nothing')
                h=plot(app.UIAxes,mod.score(:,value(1)),mod.score(:,value(2)),'o','MarkerFaceColor','k','MarkerSize',3);
            else
                fld=app.DropDownColorBy.Value;
                md=app.data.metadata.(fld);

                %md=md(~app.lowdelete);
                i=randperm(size(mod.score,1));
                if app.randomizeorderCheckBox.Value
                    xp = mod.score(i,value(1));
                    yp = mod.score(i,value(2));
                    mdp=md(i);

                else
                    xp=mod.score(:,value(1));
                    yp=mod.score(:,value(2));
                    mdp=md;
                end
                app.tempstore=mdp;
                switch class(mdp)
                    case {'categorical','cell'}
                        %                 h=gscatter(app.UIAxes,xp,yp,mdp,app.gcolor(unique(mdp)),'.',15,'off');
                        h=scatter(app.UIAxes,xp,yp,25, app.gcolor(mdp),'filled');

                    case 'double'
                        h=scatter(app.UIAxes,xp,yp,25, app.gcolor(mdp),'filled');

                end
                

                if numel(unique(mdp))<15
                    mode='few';
                    app.glegend(app.UIAxes,app.gcolor(unique(mdp)),unique(mdp));
                    %legend(h)
                else
                    mode='lots';
                    legend(app.UIAxes,'off')
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
                            colormap(app.UIAxes,app.gcolor(unique(mdp)))
                            c=colorbar(app.UIAxes);
                            cats=categories(unique(mdp));
                            caxis(app.UIAxes,[1 max(round(linspace(1,numel(cats),samples)))])
                            c.Ticks=round(linspace(1,numel(cats),samples));
                            c.TickLabels=cats(round(linspace(1,numel(cats),samples)));
                            ylabel(c,fld,'Interpreter','none')
                        case 'double'
                            colormap(app.UIAxes,app.gcolor(unique(mdp)))
                            c = colorbar(app.UIAxes);
                            ylabel(c,fld,'Interpreter','none')
                            try
                                caxis(app.UIAxes,[min(unique(mdp),[],"omitnan") max(unique(mdp),[],"omitnan")])
                            catch ME
                                delete(c)
                                warning(ME.message)
                            end

                    end
                end

            end
            yline(app.UIAxes,0,'HandleVisibility', 'off')
            xline(app.UIAxes,0,'HandleVisibility', 'off')
            alpha(app.UIAxes,app.alphaEditField.Value)

            h.ButtonDownFcn=@app.mouseClick;


            switch mode
                case 'few'
                    app.classboundaryCheckBox.Enable="on";
                    if app.classboundaryCheckBox.Value
                        try
                            classeshere=unique(mdp);
                            if isnumeric(classeshere)
                                C=classeshere;
                                hold(app.UIAxes,'on')
                                col=app.gcolor(unique(mdp));
                                for j=1:numel(C)
                                    x=xp(mdp==C(j));
                                    y=yp(mdp==C(j));
                                    k = boundary(x,y);
                                    plot(app.UIAxes,x(k),y(k),'Color',col(j,:),'HandleVisibility','off');
                                end
                                hold(app.UIAxes,'off')
                            elseif not(iscategorical(classeshere))
                                classeshere=categorical(classeshere);
                                C = categories(classeshere);
                                hold(app.UIAxes,'on')
                                col=app.gcolor(unique(mdp));
                                for j=1:numel(C)
                                    x=xp(mdp==C{j});
                                    y=yp(mdp==C{j});
                                    k = boundary(x,y);
                                    plot(app.UIAxes,x(k),y(k),'Color',col(j,:),'HandleVisibility','off');
                                end
                                hold(app.UIAxes,'off')
                            elseif iscategorical(classeshere)
                                C = categories(classeshere);
                                hold(app.UIAxes,'on')
                                col=app.gcolor(unique(mdp));
                                for j=1:numel(C)
                                    x=xp(mdp==C{j});
                                    y=yp(mdp==C{j});
                                    k = boundary(x,y);
                                    plot(app.UIAxes,x(k),y(k),'Color',col(j,:),'HandleVisibility','off');
                                end
                                hold(app.UIAxes,'off')
                            end
                        catch
                            disp('Could not draw boundaries with that metadata variable.')
                        end


                        %                 hold(app.UIAxes,'on')
                        %                 col=app.gcolor(unique(mdp));
                        %                 for j=1:numel(C)
                        %                     x=xp(mdp==C{j});
                        %                     y=yp(mdp==C{j});
                        %                     k = boundary(x,y);
                        %                     plot(app.UIAxes,x(k),y(k),'Color',col(j,:),'HandleVisibility','off');
                        %                 end
                        %                 hold(app.UIAxes,'off')
                    end
                case 'lots'
                    app.classboundaryCheckBox.Enable="off";
                    % Do nothing here
            end
            ylabel(app.UIAxes,['PC',num2str(value(2)),' (',num2str(round(mod.explained(value(2)),1)),'%)'])
            xlabel(app.UIAxes,['PC',num2str(value(1)),' (',num2str(round(mod.explained(value(1)),1)),'%)'])

    
        end
        function mouseClick(app,~,~)
            tth = findall(app.UIAxes,'Type','hggroup');  % find any pre-existing data tips
            delete(tth)                                  % remove them
            cp=app.UIAxes.('CurrentPoint')(1,1:2);
            if isscalar(app.UIAxes.Children)
                k = dsearchn([app.UIAxes.Children.XData;app.UIAxes.Children.YData]',cp);
            else
                k = dsearchn([app.UIAxes.Children(end).XData;app.UIAxes.Children(end).YData]',cp);
            end
            app.selectedSample=k;
            app.plotEEM
        end
        function plotEEM(app)
            x=app.data.Ex;
            y=app.data.Em;
            switch app.Switch.Value
                case 'Data'
                    X=app.dataBackup.X;
                case 'Residuals'
                    X=app.data.X;
            end

            k=app.selectedSample;
            if isnan(k)
                return
            end
            mat=squeeze(X(k,:,:));

            sc = surfc(app.eem,x,y,mat,'EdgeColor','none');
            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LineWidth = 0.5;
            if matches(app.Switch.Value,'Residuals')
                sc(2).LineStyle='none';
                sc(2).LevelList=linspace(sc(2).LevelList(1),sc(2).LevelList(end),100);
            end
            view(app.eem,0,90)
            
            app.eem.Title.String=['Selected EEM: ',app.data.filelist{k}];
            app.eem.Title.Interpreter='none';
            
            axes(app.UIAxes)
            pbaspect(app.UIAxes,[1,1,1])

            switch app.Switch.Value
                case 'Data'
                    switch app.ColormapEEMDropDown.Value
                        case {'imola' 'hawaii' 'batlow','-imola' '-hawaii' '-batlow'}
                            map=crameri.makemap(app.ColormapEEMDropDown.Value);
                            colormap(app.eem,map)
                        otherwise
                            colormap(app.eem,app.ColormapEEMDropDown.Value);
                    end
                case 'Residuals'
                    levels=sc(2).LevelList;
                    n_neg=sum(levels<0);
                    n_pos=sum(levels>0);
                    colormap(app.eem,app.residualcolormap(n_neg,n_pos))
            end

        end
        function h = glegend(app,ax,gcol,titles)


            [~,i] = unique(gcol,'stable','rows');

            cols=gcol(i,:);


            hold(ax,'on');
            for j=1:numel(i)

                h(j)=plot(ax,[nan nan],[nan nan],'LineStyle','-','Color',cols(j,:));

            end

            if isnumeric(titles)
                titles=cellstr(num2str(titles));
            end
            h=legend(h,titles);
            h.ItemTokenSize=[10 6];
        end

        function colmap = gcolor(~,g)

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

        function nout = pullModel(~,string)
            string=strsplit(string,'-');
            nout=str2double(string{1});
        end
        

    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, data)

            app.data=data;
            app.dataBackup=data;
            
            % Specify model (no options currently
            app.modelName='PCA';

            % Make submenus based on PARAFAC models
            f=drEEMdataset.modelsWithContent(app.data);
            app.PARAFACcomponentsDropDown.Items=cellstr(num2str(f));
            app.PARAFACcomponentsDropDown.Value=app.PARAFACcomponentsDropDown.Items(1);
            app.nComp=f(1);

            % Populate metdata dropdown
            metafld{1}='nothing';
            % app.metadataconverter;
            metafld=[metafld app.data.metadata.Properties.VariableNames];
            app.DropDownColorBy.Items=metafld;

            % Initialize GUI
            pbaspect(app.eem,[1,1,1])
            app.processdata;
            app.runmodels;
            app.visualize;
        end

        % Value changed function: PARAFACcomponentsDropDown
        function PARAFACcomponentsDropDownValueChanged(app, event)
            value = app.PARAFACcomponentsDropDown.Value;
            app.nComp=app.pullModel(value);
            app.processdata;
            app.runmodels;
            app.visualize;
            if matches(app.TabGroup.SelectedTab.Title,'Overview graph')
                app.TabGroup.SelectedTab=app.TabGroup.Children(2);
            end

        end

        % Value changed function: PlotfocusDropDown
        function PlotfocusDropDownValueChanged(app, event)
            value = app.PlotfocusDropDown.Value;
            app.plotLayout=value;
            app.visualize;
            if matches(app.TabGroup.SelectedTab.Title,'Overview graph')
                app.TabGroup.SelectedTab=app.TabGroup.Children(2);
            end
        end

        % Value changed function: DropDownColorBy, DropDownX, DropDownY, 
        % ...and 1 other component
        function DropDownColorByValueChanged(app, event)
            app.updatescoreplots;

        end

        % Value changed function: Switch
        function SwitchValueChanged(app, event)
            app.plotEEM;
        end

        % Value changed function: ColormapEEMDropDown
        function ColormapEEMDropDownValueChanged(app, event)
            app.plotEEM;
            
        end

        % Menu selected function: SavefigurepanelasimageMenu
        function SavefigurepanelasimageMenuSelectedOverview(app, event)
            panel=app.ContextMenu.UserData;
            defname='MuReA.png';
            [filename, pathname] = uiputfile({'*.png'; '*.jpg'; '*.fig'},...
                'Save Figure As', ...
                defname);
            

            if isequal(filename, 0) || isequal(pathname, 0)
                pathname=pwd;
                filename=defname;
                warning('Did not specify filename and path. Assumed default name in current directory.')
            end
            
            if endsWith(filename,'.fig')
                error('Matlab fig-files are on the to-do list. Please save as image instead.')
                fig1=uifigure;
                newpanel = copyobj(panel, fig1);
                newpanel.Position = [0.1 0.1 0.8 0.8];

                savefig(fig1,fullfile(pathname,filename));
                delete(fig1)
            else
                warning off
                exportgraphics(panel,...
                    fullfile(pathname,filename),...
                    "BackgroundColor","white",...
                    "Resolution",600)
            end
            warning on
            figure(app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure)
        
        end

        % Context menu opening function: ContextMenu
        function ContextMenuOpening(app, event)
            app.ContextMenu.UserData=...
            app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure.CurrentObject;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {512, 512};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {193, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure and hide until all components are created
            app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure = uifigure('Visible', 'off');
            app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure.AutoResizeChildren = 'off';
            app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure.Position = [100 100 899 512];
            app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure.Name = 'drEEM: MuReA (Multivariate Analysis of Model Residuals)';
            app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure);
            app.GridLayout.ColumnWidth = {193, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create GridLayout7
            app.GridLayout7 = uigridlayout(app.LeftPanel);
            app.GridLayout7.ColumnWidth = {'1x'};
            app.GridLayout7.RowHeight = {'1x'};

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.GridLayout7);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.Layout.Row = 1;
            app.SettingsPanel.Layout.Column = 1;
            app.SettingsPanel.FontWeight = 'bold';

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.SettingsPanel);
            app.GridLayout8.ColumnWidth = {'1x'};
            app.GridLayout8.RowHeight = {30, 30, 30, 30, 30, 30, 30, '1x'};

            % Create PARAFACcomponentsDropDownLabel
            app.PARAFACcomponentsDropDownLabel = uilabel(app.GridLayout8);
            app.PARAFACcomponentsDropDownLabel.HorizontalAlignment = 'right';
            app.PARAFACcomponentsDropDownLabel.VerticalAlignment = 'bottom';
            app.PARAFACcomponentsDropDownLabel.Layout.Row = 1;
            app.PARAFACcomponentsDropDownLabel.Layout.Column = 1;
            app.PARAFACcomponentsDropDownLabel.Text = '# PARAFAC components';

            % Create PARAFACcomponentsDropDown
            app.PARAFACcomponentsDropDown = uidropdown(app.GridLayout8);
            app.PARAFACcomponentsDropDown.Items = {''};
            app.PARAFACcomponentsDropDown.ValueChangedFcn = createCallbackFcn(app, @PARAFACcomponentsDropDownValueChanged, true);
            app.PARAFACcomponentsDropDown.Layout.Row = 2;
            app.PARAFACcomponentsDropDown.Layout.Column = 1;
            app.PARAFACcomponentsDropDown.Value = '';

            % Create PlotfocusDropDownLabel
            app.PlotfocusDropDownLabel = uilabel(app.GridLayout8);
            app.PlotfocusDropDownLabel.HorizontalAlignment = 'right';
            app.PlotfocusDropDownLabel.VerticalAlignment = 'bottom';
            app.PlotfocusDropDownLabel.Layout.Row = 3;
            app.PlotfocusDropDownLabel.Layout.Column = 1;
            app.PlotfocusDropDownLabel.Text = 'Plot focus';

            % Create PlotfocusDropDown
            app.PlotfocusDropDown = uidropdown(app.GridLayout8);
            app.PlotfocusDropDown.Items = {'Scores & loadings', 'Scores only', 'Loadings only'};
            app.PlotfocusDropDown.ValueChangedFcn = createCallbackFcn(app, @PlotfocusDropDownValueChanged, true);
            app.PlotfocusDropDown.Layout.Row = 4;
            app.PlotfocusDropDown.Layout.Column = 1;
            app.PlotfocusDropDown.Value = 'Scores & loadings';

            % Create ExcludelowFDOMCheckBox
            app.ExcludelowFDOMCheckBox = uicheckbox(app.GridLayout8);
            app.ExcludelowFDOMCheckBox.Text = 'Exclude low FDOM';
            app.ExcludelowFDOMCheckBox.Layout.Row = 5;
            app.ExcludelowFDOMCheckBox.Layout.Column = 1;

            % Create ColormapEEMDropDownLabel
            app.ColormapEEMDropDownLabel = uilabel(app.GridLayout8);
            app.ColormapEEMDropDownLabel.HorizontalAlignment = 'right';
            app.ColormapEEMDropDownLabel.VerticalAlignment = 'bottom';
            app.ColormapEEMDropDownLabel.Layout.Row = 6;
            app.ColormapEEMDropDownLabel.Layout.Column = 1;
            app.ColormapEEMDropDownLabel.Text = 'Colormap EEM';

            % Create ColormapEEMDropDown
            app.ColormapEEMDropDown = uidropdown(app.GridLayout8);
            app.ColormapEEMDropDown.Items = {'turbo', 'imola', 'hawaii', 'batlow', 'parula', '-imola', '-hawaii', '-batlow'};
            app.ColormapEEMDropDown.ValueChangedFcn = createCallbackFcn(app, @ColormapEEMDropDownValueChanged, true);
            app.ColormapEEMDropDown.Layout.Row = 7;
            app.ColormapEEMDropDown.Layout.Column = 1;
            app.ColormapEEMDropDown.Value = 'turbo';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.RightPanel);
            app.GridLayout4.ColumnWidth = {'1x'};
            app.GridLayout4.RowHeight = {'1x'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout4);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create OverviewgraphTab
            app.OverviewgraphTab = uitab(app.TabGroup);
            app.OverviewgraphTab.Title = 'Overview graph';

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.OverviewgraphTab);
            app.GridLayout6.ColumnWidth = {'1x'};
            app.GridLayout6.RowHeight = {'1x'};

            % Create OverviewPanel
            app.OverviewPanel = uipanel(app.GridLayout6);
            app.OverviewPanel.Layout.Row = 1;
            app.OverviewPanel.Layout.Column = 1;

            % Create ScoresloadingsTab
            app.ScoresloadingsTab = uitab(app.TabGroup);
            app.ScoresloadingsTab.Title = 'Scores & loadings';

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.ScoresloadingsTab);
            app.GridLayout5.ColumnWidth = {'1x'};
            app.GridLayout5.RowHeight = {'1x'};
            app.GridLayout5.Padding = [0 0 0 0];

            % Create ScoresLoadingsPanel
            app.ScoresLoadingsPanel = uipanel(app.GridLayout5);
            app.ScoresLoadingsPanel.Layout.Row = 1;
            app.ScoresLoadingsPanel.Layout.Column = 1;

            % Create ScoresLoadingsGrid
            app.ScoresLoadingsGrid = uigridlayout(app.ScoresLoadingsPanel);
            app.ScoresLoadingsGrid.ColumnWidth = {'1x'};

            % Create ScoresPanel
            app.ScoresPanel = uipanel(app.ScoresLoadingsGrid);
            app.ScoresPanel.Title = 'Scores';
            app.ScoresPanel.Layout.Row = 1;
            app.ScoresPanel.Layout.Column = 1;
            app.ScoresPanel.FontWeight = 'bold';

            % Create LoadingsPanel
            app.LoadingsPanel = uipanel(app.ScoresLoadingsGrid);
            app.LoadingsPanel.Title = 'Loadings';
            app.LoadingsPanel.Layout.Row = 2;
            app.LoadingsPanel.Layout.Column = 1;
            app.LoadingsPanel.FontWeight = 'bold';

            % Create ScoreplotsTab
            app.ScoreplotsTab = uitab(app.TabGroup);
            app.ScoreplotsTab.Title = 'Score plots';

            % Create GridLayout9
            app.GridLayout9 = uigridlayout(app.ScoreplotsTab);
            app.GridLayout9.RowHeight = {'1x'};

            % Create ScoreoverviewPanel
            app.ScoreoverviewPanel = uipanel(app.GridLayout9);
            app.ScoreoverviewPanel.Title = 'Score overview';
            app.ScoreoverviewPanel.Layout.Row = 1;
            app.ScoreoverviewPanel.Layout.Column = 1;
            app.ScoreoverviewPanel.FontWeight = 'bold';

            % Create gl_detail
            app.gl_detail = uigridlayout(app.ScoreoverviewPanel);
            app.gl_detail.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.gl_detail.RowHeight = {30, 30, '1x', 30, 30};

            % Create UIAxes
            app.UIAxes = uiaxes(app.gl_detail);
            title(app.UIAxes, 'Scores plot')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontName = 'Helvetica';
            app.UIAxes.Box = 'on';
            app.UIAxes.TickDir = 'out';
            app.UIAxes.Layout.Row = 3;
            app.UIAxes.Layout.Column = [1 4];

            % Create DropDownX
            app.DropDownX = uidropdown(app.gl_detail);
            app.DropDownX.Items = {''};
            app.DropDownX.ValueChangedFcn = createCallbackFcn(app, @DropDownColorByValueChanged, true);
            app.DropDownX.Tooltip = {'Select which PCA component scores should be plotted on the x-axis.'};
            app.DropDownX.Layout.Row = 2;
            app.DropDownX.Layout.Column = 1;
            app.DropDownX.Value = '';

            % Create DropDownY
            app.DropDownY = uidropdown(app.gl_detail);
            app.DropDownY.Items = {''};
            app.DropDownY.ValueChangedFcn = createCallbackFcn(app, @DropDownColorByValueChanged, true);
            app.DropDownY.Tooltip = {'Select which PCA component scores should be plotted on the y-axis.'};
            app.DropDownY.Layout.Row = 2;
            app.DropDownY.Layout.Column = 2;
            app.DropDownY.Value = '';

            % Create DropDownColorBy
            app.DropDownColorBy = uidropdown(app.gl_detail);
            app.DropDownColorBy.Items = {''};
            app.DropDownColorBy.ValueChangedFcn = createCallbackFcn(app, @DropDownColorByValueChanged, true);
            app.DropDownColorBy.Tooltip = {'Color the scatter plot below by available metadata.'};
            app.DropDownColorBy.Layout.Row = 2;
            app.DropDownColorBy.Layout.Column = 3;
            app.DropDownColorBy.Value = '';

            % Create yaxisLabel
            app.yaxisLabel = uilabel(app.gl_detail);
            app.yaxisLabel.HorizontalAlignment = 'center';
            app.yaxisLabel.VerticalAlignment = 'bottom';
            app.yaxisLabel.Layout.Row = 1;
            app.yaxisLabel.Layout.Column = 2;
            app.yaxisLabel.Text = 'y-axis';

            % Create xaxisLabel
            app.xaxisLabel = uilabel(app.gl_detail);
            app.xaxisLabel.HorizontalAlignment = 'center';
            app.xaxisLabel.VerticalAlignment = 'bottom';
            app.xaxisLabel.Layout.Row = 1;
            app.xaxisLabel.Layout.Column = 1;
            app.xaxisLabel.Text = 'x-axis';

            % Create colorbyLabel
            app.colorbyLabel = uilabel(app.gl_detail);
            app.colorbyLabel.HorizontalAlignment = 'center';
            app.colorbyLabel.VerticalAlignment = 'bottom';
            app.colorbyLabel.Layout.Row = 1;
            app.colorbyLabel.Layout.Column = 3;
            app.colorbyLabel.Text = 'color-by';

            % Create alphaEditFieldLabel
            app.alphaEditFieldLabel = uilabel(app.gl_detail);
            app.alphaEditFieldLabel.HorizontalAlignment = 'right';
            app.alphaEditFieldLabel.Layout.Row = 4;
            app.alphaEditFieldLabel.Layout.Column = 3;
            app.alphaEditFieldLabel.Text = 'alpha';

            % Create alphaEditField
            app.alphaEditField = uieditfield(app.gl_detail, 'numeric');
            app.alphaEditField.Limits = [0 1];
            app.alphaEditField.Tooltip = {'Decrease this value to increase transparency of datapoints in the score plot above.'};
            app.alphaEditField.Layout.Row = 4;
            app.alphaEditField.Layout.Column = 4;
            app.alphaEditField.Value = 0.9;

            % Create randomizeorderCheckBox
            app.randomizeorderCheckBox = uicheckbox(app.gl_detail);
            app.randomizeorderCheckBox.Tag = 'Click to randomly reorder the Score plot above. Can be useful if different categories are superimposed.';
            app.randomizeorderCheckBox.Text = 'randomize order';
            app.randomizeorderCheckBox.Layout.Row = 4;
            app.randomizeorderCheckBox.Layout.Column = [1 2];

            % Create classboundaryCheckBox
            app.classboundaryCheckBox = uicheckbox(app.gl_detail);
            app.classboundaryCheckBox.ValueChangedFcn = createCallbackFcn(app, @DropDownColorByValueChanged, true);
            app.classboundaryCheckBox.Enable = 'off';
            app.classboundaryCheckBox.Text = 'class boundary';
            app.classboundaryCheckBox.Layout.Row = 5;
            app.classboundaryCheckBox.Layout.Column = [1 2];

            % Create selectasampleButton
            app.selectasampleButton = uibutton(app.gl_detail, 'push');
            app.selectasampleButton.Enable = 'off';
            app.selectasampleButton.Visible = 'off';
            app.selectasampleButton.Tooltip = {'After pressing this button, a crosshair will appear when hovering over the score-score plot. After clicking _on_ one of the scatter points, the corresponding EEM appears on the right.'};
            app.selectasampleButton.Layout.Row = 5;
            app.selectasampleButton.Layout.Column = [3 4];
            app.selectasampleButton.Text = 'select a sample';

            % Create SelectedEEMPanel
            app.SelectedEEMPanel = uipanel(app.GridLayout9);
            app.SelectedEEMPanel.Title = 'Selected EEM';
            app.SelectedEEMPanel.Layout.Row = 1;
            app.SelectedEEMPanel.Layout.Column = 2;
            app.SelectedEEMPanel.FontWeight = 'bold';

            % Create GridLayout_2
            app.GridLayout_2 = uigridlayout(app.SelectedEEMPanel);
            app.GridLayout_2.ColumnWidth = {'1x'};
            app.GridLayout_2.RowHeight = {'1x', 30};

            % Create eem
            app.eem = uiaxes(app.GridLayout_2);
            title(app.eem, 'Selected EEM (click on score plot with mouse button)')
            xlabel(app.eem, 'Excitation (nm)')
            ylabel(app.eem, 'Emission (nm)')
            zlabel(app.eem, 'Z')
            app.eem.FontName = 'Helvetica';
            app.eem.Box = 'on';
            app.eem.TickDir = 'out';
            app.eem.Layout.Row = 1;
            app.eem.Layout.Column = 1;

            % Create Switch
            app.Switch = uiswitch(app.GridLayout_2, 'slider');
            app.Switch.Items = {'Data', 'Residuals'};
            app.Switch.ValueChangedFcn = createCallbackFcn(app, @SwitchValueChanged, true);
            app.Switch.Tooltip = {'If a PCA analysis of model residuals has been selected, this switch allows selecting for the raw EEM or the residual EEM.'};
            app.Switch.Layout.Row = 2;
            app.Switch.Layout.Column = 1;
            app.Switch.Value = 'Data';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure);
            app.ContextMenu.ContextMenuOpeningFcn = createCallbackFcn(app, @ContextMenuOpening, true);

            % Create SavefigurepanelasimageMenu
            app.SavefigurepanelasimageMenu = uimenu(app.ContextMenu);
            app.SavefigurepanelasimageMenu.MenuSelectedFcn = createCallbackFcn(app, @SavefigurepanelasimageMenuSelectedOverview, true);
            app.SavefigurepanelasimageMenu.Text = 'Save figure panel as image';
            
            % Assign app.ContextMenu
            app.OverviewPanel.ContextMenu = app.ContextMenu;
            app.ScoresPanel.ContextMenu = app.ContextMenu;
            app.LoadingsPanel.ContextMenu = app.ContextMenu;
            app.gl_detail.ContextMenu = app.ContextMenu;
            app.SelectedEEMPanel.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = murea_gui(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.drEEMMuReAMultivariateAnalysisofModelResidualsUIFigure)
        end
    end
end