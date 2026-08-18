classdef viewcompcorr_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        LeftPanel                      matlab.ui.container.Panel
        GridLayout2                    matlab.ui.container.GridLayout
        MetadatavariableDropDown       matlab.ui.control.DropDown
        MetadatavariableDropDownLabel  matlab.ui.control.Label
        ModelsDropDown                 matlab.ui.control.DropDown
        ModelsDropDownLabel            matlab.ui.control.Label
        RightPanel                     matlab.ui.container.Panel
        GridLayout3                    matlab.ui.container.GridLayout
        canvas                         matlab.ui.container.Panel
        ContextMenu                    matlab.ui.container.ContextMenu
        SavefigurepanelMenu            matlab.ui.container.Menu
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        data
        f
        % Description
    end
    
    methods (Access = private)
        
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
            if not(exist("data","var"))
                delete(app)
                throwAsCaller(MException("drEEM:noData",'Not enough input arguments.'))
            end
            try
                data.validate(data)
            catch
                delete(app)
                throwAsCaller(MException("drEEM:invalidData",'Input is not a valid dataset'))
            end
            movegui(app.UIFigure,"center")
            app.data=data;
            app.f=find(arrayfun(@(x) not(isempty(x.loads{1})),app.data.models));
            app.ModelsDropDown.Items = cellstr(strcat(num2str(app.f),repmat(' - component model',numel(app.f),1)));
            app.MetadatavariableDropDown.Items=data.metadata.Properties.VariableNames;
            if isempty(app.f)
                close(app.UIFigure)
                error('No models in drEEMdataset')
            end

            app.updatePlots

        end

        % Value changed function: MetadatavariableDropDown, ModelsDropDown
        function updatePlots(app, event)
            mdl = app.ModelsDropDown.Value;
            mdl = app.pullModel(mdl);
            md = app.MetadatavariableDropDown.Value;
            md=app.data.metadata.(md);

            scores=app.data.models(mdl).loads{1};

            
            


            t=tiledlayout(app.canvas,'flow');
            combs=nchoosek(1:mdl,2);
            allax=[];
            for j=1:size(combs,1)
                ax=nexttile(t);
                ax.ContextMenu=app.ContextMenu;
                allax(j)=ax;
                xp=scores(:,combs(j,1));
                yp=scores(:,combs(j,2));
                
                h=scatter(ax,xp,yp,...
                    25,app.gcolor(md),"filled");
                box(ax,"on")
                xlabel(ax,['Component ',num2str(combs(j,1))])
                ylabel(ax,['Component ',num2str(combs(j,2))])
            end
            linkprop(allax,'CLim');

             if numel(unique(md))<15
                mode='few';
                legend1=app.glegend(ax,app.gcolor(unique(md)),unique(md));
                legend1.Layout.Tile='east';
            else
                mode='lots';
                legend(ax,'off')
                ncat=numel(unique(md));
                if ncat<50
                    samples=ncat;
                    %stepsize=55;
                elseif ncat<100
                    samples=10;
                else
                    samples=5;
                end
            
                switch class(md)
                    case 'categorical'
                        colormap(ax,app.gcolor(unique(md)))
                        c=colorbar(ax);
                        c.Layout.Tile='east';
                        cats=categories(unique(md));
                        clim(ax,[1 max(round(linspace(1,numel(cats),samples)))])
                        c.Ticks=round(linspace(1,numel(cats),samples));
                        c.TickLabels=cats(round(linspace(1,numel(cats),samples)));
                        ylabel(c,app.MetadatavariableDropDown.Value,'Interpreter','none')
                    case 'double'
                        colormap(ax,app.gcolor(unique(md)))
                        c = colorbar(ax);
                        c.Layout.Tile='east';
                        ylabel(c,app.MetadatavariableDropDown.Value,'Interpreter','none')
                        try
                            clim(ax,[min(unique(md),[],"omitnan") max(unique(md),[],"omitnan")])
                        catch ME
                            delete(c)
                            warning(ME.message)
                        end
                        
                end
            end



        end

        % Menu selected function: SavefigurepanelMenu
        function SavefigurepanelMenuSelected(app, event)
            panel = app.canvas;
            if isempty(panel)
                warning('Could not find a panel in the selected tab. Cannot save as image.')
                return
            end
            defname=['compcorrplot','.png'];

            [filename, pathname] = uiputfile({'*.png'; '*.jpg'},...
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
                warning on
            end
            
            figure(app.UIFigure)
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {428, 428};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 942 428];
            app.UIFigure.Name = 'viewcompcorr: Inspect score correlations in light of available metadata';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.LeftPanel);
            app.GridLayout2.RowHeight = {40, 40, 40, 40, '1x', '1x', '1x'};

            % Create ModelsDropDownLabel
            app.ModelsDropDownLabel = uilabel(app.GridLayout2);
            app.ModelsDropDownLabel.HorizontalAlignment = 'center';
            app.ModelsDropDownLabel.VerticalAlignment = 'bottom';
            app.ModelsDropDownLabel.FontWeight = 'bold';
            app.ModelsDropDownLabel.Layout.Row = 1;
            app.ModelsDropDownLabel.Layout.Column = [1 2];
            app.ModelsDropDownLabel.Text = 'Models';

            % Create ModelsDropDown
            app.ModelsDropDown = uidropdown(app.GridLayout2);
            app.ModelsDropDown.ValueChangedFcn = createCallbackFcn(app, @updatePlots, true);
            app.ModelsDropDown.Layout.Row = 2;
            app.ModelsDropDown.Layout.Column = [1 2];

            % Create MetadatavariableDropDownLabel
            app.MetadatavariableDropDownLabel = uilabel(app.GridLayout2);
            app.MetadatavariableDropDownLabel.HorizontalAlignment = 'center';
            app.MetadatavariableDropDownLabel.VerticalAlignment = 'bottom';
            app.MetadatavariableDropDownLabel.FontWeight = 'bold';
            app.MetadatavariableDropDownLabel.Layout.Row = 3;
            app.MetadatavariableDropDownLabel.Layout.Column = [1 2];
            app.MetadatavariableDropDownLabel.Text = 'Metadata variable';

            % Create MetadatavariableDropDown
            app.MetadatavariableDropDown = uidropdown(app.GridLayout2);
            app.MetadatavariableDropDown.ValueChangedFcn = createCallbackFcn(app, @updatePlots, true);
            app.MetadatavariableDropDown.Layout.Row = 4;
            app.MetadatavariableDropDown.Layout.Column = [1 2];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.RightPanel);
            app.GridLayout3.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout3.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};

            % Create canvas
            app.canvas = uipanel(app.GridLayout3);
            app.canvas.Layout.Row = [1 7];
            app.canvas.Layout.Column = [1 3];

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create SavefigurepanelMenu
            app.SavefigurepanelMenu = uimenu(app.ContextMenu);
            app.SavefigurepanelMenu.MenuSelectedFcn = createCallbackFcn(app, @SavefigurepanelMenuSelected, true);
            app.SavefigurepanelMenu.Text = 'Save figure panel';
            
            % Assign app.ContextMenu
            app.canvas.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = viewcompcorr_gui(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end