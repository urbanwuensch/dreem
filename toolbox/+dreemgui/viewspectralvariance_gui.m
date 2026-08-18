classdef viewspectralvariance_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        viewspectralvarianceUIFigure  matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        FluorescencePanel             matlab.ui.container.Panel
        GridLayoutFDOM                matlab.ui.container.GridLayout
        excitation                    matlab.ui.control.UIAxes
        emission                      matlab.ui.control.UIAxes
        eem                           matlab.ui.control.UIAxes
        AbsorbancePanel               matlab.ui.container.Panel
        GridLayoutCDOM                matlab.ui.container.GridLayout
        absorbance                    matlab.ui.control.UIAxes
        ContextMenu                   matlab.ui.container.ContextMenu
        SavecurrentpanelMenu          matlab.ui.container.Menu
        ContextMenu2                  matlab.ui.container.ContextMenu
        SavecurrentPanelMenu          matlab.ui.container.Menu
    end


    properties (Access = private)
        data % Description
    end
    
    methods (Access = private)

        function result = containsabsorbance(~,data)
            if not(isempty(data.abs))
                result=true;
            else
                result=false;
            end
        end

        function result = containsfluorescence(~,data)
            if not(isempty(data.X))
                result=true;
            else
                result=false;
            end
        end
        
        function ploteem(~,ax,mat,x,y)
            sc = surfc(ax,x,y,mat,...
                'EdgeColor','none','FaceColor','flat');
            %view(ax,[19 44.5])
            view(ax,[0 90])
            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LineWidth = 0.5;
            sc(2).LevelList=linspace(min(mat(~isnan(mat))),max(mat(~isnan(mat))),20);
            zlim(ax,[min(mat(~isnan(mat))),max(mat(~isnan(mat)))])
            clim(ax,[min(mat(~isnan(mat))),max(mat(~isnan(mat)))])
            
        end

        function savepanel(app,panel)

            if isempty(panel)
                warning('Could not find a panel in the selected tab. Cannot save as image.')
                return
            end
            defname='viewspectralvariance.png';

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
                warning on
            end

            figure(app.viewspectralvarianceUIFigure)
        end

    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, data)
            app.data=data;
            if app.containsfluorescence(data)&&app.containsabsorbance(data)
                pltcase=1;
                dat=data.X;
            elseif app.containsfluorescence(data)&&~app.containsabsorbance(data)
                pltcase=2;
                dat=data.X;
            elseif app.containsabsorbance(data)&&~app.containsfluorescence(data)
                pltcase=3;
            else
                pltcase=10;
            end

            if pltcase==10
                error('Refer to function help. Could not find necessary fields in the dataset.')
            end



            if pltcase==1||pltcase==2
                [X,~,fscales]=nway.tools.nprocess(dat,[0 0 0],[1 0 0],[],[],1,-1);
                fscales{1}(isinf(fscales{1}))=nan;
                fdom=squeeze(std(X,'omitmissing'));
                if any(fscales{1}>5*median(fscales{1}))
                    warning('Some samples have very little signal (e.g. blanks) and thus likely negatively impact the the spectralvariance plots')
                    disp(['Consider removing the sample(s):  ',num2str(find(fscales{1}>5*median(fscales{1},2)))])
                    disp('If no blanks (or similar) samples are present, the issue may be samples with high fluorescence values instead.')
                end
            end
            if pltcase==1||pltcase==3
                [Y,~,~]=nway.tools.nprocess(data.abs,[0 0],[1 0],[],[],1,-1);
                cdom=std(Y,'omitmissing');
            end
            
            

            hold(app.absorbance,"on");
            if pltcase==1||pltcase==3
                
                h1=plot(app.absorbance,data.absWave,Y,'Color',[1 .2 .2 0.5],'LineWidth',1,'LineStyle','-','Marker','none');%./sum(Y,2)
                yyaxis(app.absorbance,'right'),set(app.absorbance,'YColor',[0 0 0 0.8])
                h2=plot(app.absorbance,data.absWave,cdom,'Color',[0 0 0 0.8],'LineWidth',2,'LineStyle','-','Marker','none');
                legend(app.absorbance,[h1(1), h2],{'All spectra (unit scaled)','Standard deviation'})
                %legend(app.absorbance,h2,{'Standard deviation'})

                for k=1:numel(h1)
                    row1 = dataTipTextRow('Sample',repelem(data.filelist(k),numel(data.absWave),1));
                    h1(k).DataTipTemplate.DataTipRows(end+1) = row1;
                    h1(k).DataTipTemplate.DataTipRows(1).Label = 'Wave';
                    h1(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
                end
                for k=1:numel(h2)
                    %row1 = dataTipTextRow('Overall',repelem({'Standard deviation'},numel(data.absWave),1));
                    %h2(k).DataTipTemplate.DataTipRows(end+1) = row1;
                    h2(k).DataTipTemplate.DataTipRows(1).Label = 'Wave';
                    h2(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
                end

            end
            axis(app.absorbance,'tight')

            % FDOM EEMs
            if pltcase==1||pltcase==2
                pltdata=squeeze(fdom);%./squeeze(mfdom);
                pltdata(pltdata==0)=nan;
                app.ploteem(app.eem,pltdata,data.Ex,data.Em);
                %set(app.eem);
            end
            % c=colorbar(app.eem);
            % ylabel(c,'Std. dev. fluorescence (log scale)')
            %set(app.eem,'units','pixel')
            set(app.eem,'YTickLabel','','XTickLabel','')
            refylim=get(app.eem,'YLim');
            refxlim=get(app.eem,'XLim');

            if pltcase==1||pltcase==2
                pltvec=squeeze(sum(X,3,'omitnan'));
                normvec=(mean(max(squeeze(sum(X,3,"omitmissing"))))*2);
                pltvec=pltvec./normvec;
                pltvec(pltvec==0)=nan;

                h1=plot(app.emission,pltvec,data.Em,'Color',[1 .2 .2 0.5],'LineWidth',1);
                hold(app.emission,'on')
                h2=plot(app.emission,sum(fdom,2,"omitmissing")./max(sum(fdom,2,"omitmissing")),data.Em,'Color','k','LineWidth',2);

                for k=1:numel(h1)
                    row1 = dataTipTextRow('Sample',repelem(data.filelist(k),data.nEm,1));
                    h1(k).DataTipTemplate.DataTipRows(end+1) = row1;
                    h1(k).DataTipTemplate.DataTipRows(1).Label = 'Em';
                    h1(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
                end
                for k=1:numel(h2)
                    %row1 = dataTipTextRow('Overall',repelem({'Standard deviation'},numel(data.absWave),1));
                    %h2(k).DataTipTemplate.DataTipRows(end+1) = row1;
                    h2(k).DataTipTemplate.DataTipRows(1).Label = 'Em';
                    h2(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
                end
            end
            set(app.emission,'XDir','reverse')
            %set(app.emission,'units','pixel')
            %refpos=get(app.emission,'pos');
            %pos1=get(app.emission,'pos');
            ylim(app.emission,refylim)
            %set(app.emission,'XTickLabel','')

            %offs=refpos(1)-(pos1(1)+pos1(3));
           % set(app.emission,'pos',[pos1(1)+offs refpos(2) pos1(3) refpos(4)])

            % ax4=subplot(4,5,[19 20]);
            if pltcase==1||pltcase==2
                pltvec=squeeze(sum(X,2,"omitmissing"))./(mean(max(squeeze(sum(X,2,"omitmissing"))))*2);
                pltvec(pltvec==0)=nan;

                h1=plot(app.excitation,data.Ex,pltvec,'Color',[1 .2 .2 0.5],'LineWidth',1);
                hold(app.excitation,'on')
                h2=plot(app.excitation,data.Ex,sum(fdom,"omitmissing")./max(sum(fdom,"omitmissing")),'Color','k','LineWidth',2);

                for k=1:numel(h1)
                    row1 = dataTipTextRow('Sample',repelem(data.filelist(k),data.nEx,1));
                    h1(k).DataTipTemplate.DataTipRows(end+1) = row1;
                    h1(k).DataTipTemplate.DataTipRows(1).Label = 'Ex';
                    h1(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
                end
                for k=1:numel(h2)
                    %row1 = dataTipTextRow('Overall',repelem({'Standard deviation'},numel(data.absWave),1));
                    %h2(k).DataTipTemplate.DataTipRows(end+1) = row1;
                    h2(k).DataTipTemplate.DataTipRows(1).Label = 'Ex';
                    h2(k).DataTipTemplate.DataTipRows(2).Label = 'Int';
                end
            end
            
            xlim(app.excitation,refxlim)
            set(app.excitation,'YTickLabel','')

            linkaxes([app.eem,app.emission],'y')
            linkaxes([app.eem,app.excitation],'x')

            ylim(app.eem,[min(data.Em),max(data.Em)])
            xlim(app.eem,[min(data.Ex),max(data.Ex)])

            movegui(app.viewspectralvarianceUIFigure,'center')
        end

        % Menu selected function: SavecurrentpanelMenu
        function SaveAbsorbancePanelMenuSelected(app, event)
            app.savepanel(app.AbsorbancePanel);
        end

        % Menu selected function: SavecurrentPanelMenu
        function SaveCluorescencePanelMenuSelected(app, event)
            app.savepanel(app.FluorescencePanel);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create viewspectralvarianceUIFigure and hide until all components are created
            app.viewspectralvarianceUIFigure = uifigure('Visible', 'off');
            app.viewspectralvarianceUIFigure.Position = [100 100 1058 456];
            app.viewspectralvarianceUIFigure.Name = 'viewspectralvariance';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.viewspectralvarianceUIFigure);
            app.GridLayout.RowHeight = {'1x'};

            % Create AbsorbancePanel
            app.AbsorbancePanel = uipanel(app.GridLayout);
            app.AbsorbancePanel.TitlePosition = 'centertop';
            app.AbsorbancePanel.Title = 'Absorbance';
            app.AbsorbancePanel.Layout.Row = 1;
            app.AbsorbancePanel.Layout.Column = 1;
            app.AbsorbancePanel.FontWeight = 'bold';
            app.AbsorbancePanel.FontSize = 14;

            % Create GridLayoutCDOM
            app.GridLayoutCDOM = uigridlayout(app.AbsorbancePanel);
            app.GridLayoutCDOM.ColumnWidth = {'1x'};
            app.GridLayoutCDOM.RowHeight = {'1x', 150};
            app.GridLayoutCDOM.ColumnSpacing = 0;
            app.GridLayoutCDOM.RowSpacing = 0;
            app.GridLayoutCDOM.Padding = [0 0 0 0];

            % Create absorbance
            app.absorbance = uiaxes(app.GridLayoutCDOM);
            xlabel(app.absorbance, 'Absorbance wavelength')
            ylabel(app.absorbance, 'Absorbance, scaled to unit variance')
            zlabel(app.absorbance, 'Z')
            app.absorbance.TickDirMode = 'manual';
            app.absorbance.Layout.Row = 1;
            app.absorbance.Layout.Column = 1;
            colormap(app.absorbance, 'parula')

            % Create FluorescencePanel
            app.FluorescencePanel = uipanel(app.GridLayout);
            app.FluorescencePanel.TitlePosition = 'centertop';
            app.FluorescencePanel.Title = 'Fluorescence';
            app.FluorescencePanel.Layout.Row = 1;
            app.FluorescencePanel.Layout.Column = 2;
            app.FluorescencePanel.FontWeight = 'bold';
            app.FluorescencePanel.FontSize = 14;

            % Create GridLayoutFDOM
            app.GridLayoutFDOM = uigridlayout(app.FluorescencePanel);
            app.GridLayoutFDOM.ColumnWidth = {150, '1x'};
            app.GridLayoutFDOM.RowHeight = {'1x', 150};
            app.GridLayoutFDOM.ColumnSpacing = 0;
            app.GridLayoutFDOM.RowSpacing = 0;
            app.GridLayoutFDOM.Padding = [0 0 0 0];

            % Create eem
            app.eem = uiaxes(app.GridLayoutFDOM);
            app.eem.XTick = [];
            app.eem.XTickLabel = '';
            app.eem.YTick = [];
            app.eem.YTickLabel = '';
            app.eem.TickDirMode = 'manual';
            app.eem.Layout.Row = 1;
            app.eem.Layout.Column = 2;
            colormap(app.eem, 'parula')

            % Create emission
            app.emission = uiaxes(app.GridLayoutFDOM);
            ylabel(app.emission, 'Emission (nm)')
            zlabel(app.emission, 'Z')
            app.emission.XTickLabel = '';
            app.emission.TickDirMode = 'manual';
            app.emission.Layout.Row = 1;
            app.emission.Layout.Column = 1;
            colormap(app.emission, 'parula')

            % Create excitation
            app.excitation = uiaxes(app.GridLayoutFDOM);
            xlabel(app.excitation, 'Excitation (nm)')
            zlabel(app.excitation, 'Z')
            app.excitation.TickDirMode = 'manual';
            app.excitation.Layout.Row = 2;
            app.excitation.Layout.Column = 2;
            colormap(app.excitation, 'parula')

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.viewspectralvarianceUIFigure);

            % Create SavecurrentpanelMenu
            app.SavecurrentpanelMenu = uimenu(app.ContextMenu);
            app.SavecurrentpanelMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveAbsorbancePanelMenuSelected, true);
            app.SavecurrentpanelMenu.Text = 'Save current panel';
            
            % Assign app.ContextMenu
            app.GridLayoutCDOM.ContextMenu = app.ContextMenu;

            % Create ContextMenu2
            app.ContextMenu2 = uicontextmenu(app.viewspectralvarianceUIFigure);

            % Create SavecurrentPanelMenu
            app.SavecurrentPanelMenu = uimenu(app.ContextMenu2);
            app.SavecurrentPanelMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveCluorescencePanelMenuSelected, true);
            app.SavecurrentPanelMenu.Text = 'Save current Panel';
            
            % Assign app.ContextMenu2
            app.GridLayoutFDOM.ContextMenu = app.ContextMenu2;

            % Show the figure after all components are created
            app.viewspectralvarianceUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = viewspectralvariance_gui(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.viewspectralvarianceUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.viewspectralvarianceUIFigure)
        end
    end
end