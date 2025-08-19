classdef viewdmr_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        viewdmrUIFigure                 matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        LeftPanel                       matlab.ui.container.Panel
        GridLayout3                     matlab.ui.container.GridLayout
        ExportallButton                 matlab.ui.control.Button
        ExportcurrentButton             matlab.ui.control.Button
        prevButton                      matlab.ui.control.Button
        nextButton                      matlab.ui.control.Button
        KeepaxisviewsCheckBox           matlab.ui.control.CheckBox
        ResidualsofmaxintensitySpinner  matlab.ui.control.Spinner
        ResidualsofmaxintensitySpinnerLabel  matlab.ui.control.Label
        SampleDropDown                  matlab.ui.control.DropDown
        SampleDropDownLabel             matlab.ui.control.Label
        ModelDropDown                   matlab.ui.control.DropDown
        ModelDropDownLabel              matlab.ui.control.Label
        RightPanel                      matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        residuals                       matlab.ui.control.UIAxes
        modelled                        matlab.ui.control.UIAxes
        measured                        matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        data % Description
        f
        view % Description
    end
    
    methods (Access = private)


        function map = residualcolormap(app,nneg,npos)

            % ncol=ceil(round(ncol)/2);

            nmap=[linspace(0,1,nneg)' linspace(0.45,1,nneg)' linspace(0.737,1,nneg)'];
            pmap=flipud([flipud(linspace(1,0.686,npos)') flipud(linspace(1,0.208,npos)') flipud(linspace(1,0.278,npos)')]);

            map=[nmap;pmap];

        end
        
        function fig = drawExportFigure(app,sample)
            fig=figure(Visible="off");
            fig.Visible='off';
            set(fig, 'units', 'centimeters');
            Cpos=get(fig,'pos');
            set(fig,'pos', [Cpos(1) Cpos(2) 18 5]);

            t=tiledlayout(fig,1,3,"TileSpacing","compact","Padding","tight");
            for j=1:3
                ax(j)=nexttile(t);
            end

            m = app.ModelDropDown.Value;
            s = sample;

            m = str2double(m(1));
            s = matches(app.data.filelist,s);

            dt = squeeze(app.data.X(s,:,:));
            md = nway.modeleval.nmodel(app.data.models(m).loads);
            md = squeeze(md(s,:,:));
            rs = dt - md;

            x = app.data.Ex;
            y = app.data.Em;
            
            

            sc = surfc(ax(1),x,y,dt,EdgeColor='none',FaceColor='flat');
            
            

            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LineWidth = 0.5;
            sc(2).LevelList=linspace(min(dt(~isnan(dt))),max(dt(~isnan(dt))),20); % app.contoursEditField.Value
            zlim(ax(1),[min(dt(~isnan(dt))),max(dt(~isnan(dt)))])
            clim(ax(1),[min(dt(~isnan(dt))),max(dt(~isnan(dt)))])


            sc = surfc(ax(2),x,y,md,'EdgeColor','none','FaceColor','flat');

            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LineWidth = 0.5;
            sc(2).LevelList=linspace(min(md(~isnan(md))),max(md(~isnan(md))),20); % app.contoursEditField.Value
            %zlim(app.modelled,[min(md(~isnan(md))),max(md(~isnan(md)))])
            clim(ax(2),[min(dt(~isnan(dt))),max(dt(~isnan(dt)))])

            sc = surfc(ax(3),x,y,rs,'EdgeColor','none','FaceColor','flat');
            
            app.residuals.ZLim(2) = max(dt(~isnan(dt)))*app.ResidualsofmaxintensitySpinner.Value/100;
            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LevelList=linspace(min(rs(~isnan(rs))),app.residuals.ZLim(2),20); %app.contoursEditField.Value
            CLim=[min(rs(~isnan(rs))) app.residuals.ZLim(2)];
            clim(ax(3),CLim)
            zlim(ax(3),CLim)
            levels=linspace(CLim(1),CLim(2),100);
            n_neg=sum(levels<0);
            n_pos=sum(levels>0);
            
            colormap(ax(3),residualcolormap(app,n_neg,n_pos))
            
            xlim(ax(1),[app.data.Ex(1) app.data.Ex(end)])
            xlim(ax(2),[app.data.Ex(1) app.data.Ex(end)])
            xlim(ax(3),[app.data.Ex(1) app.data.Ex(end)])
            ylim(ax(1),[app.data.Em(1) app.data.Em(end)])
            ylim(ax(2),[app.data.Em(1) app.data.Em(end)])
            ylim(ax(3),[app.data.Em(1) app.data.Em(end)])
            view(ax(1),0,90)
            view(ax(2),0,90)
            view(ax(3),0,90)
            xlabel(t,'Excitation (nm)')
            ylabel(t,'Emission (nm)')
            colorbar(ax(1))
            colorbar(ax(2))
            colorbar(ax(3))
            set(ax(2),YTickLabel='')
            set(ax(3),YTickLabel='')
            title(ax(1),[sample,' meas.'])
            title(ax(2),[sample,' mod.'])
            title(ax(3),[sample,' res.'])
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, eem, f)
            if not(exist("eem","var"))
                delete(app)
                throwAsCaller(MException("drEEM:noData",'Not enough input arguments.'))
            end
            try
                eem.validate(eem)
            catch
                delete(app)
                throwAsCaller(MException("drEEM:invalidData",'Input is not a valid dataset'))
            end
            app.data=eem;
            app.view=[0,90;0,90;0,90];
            app.f...
                =find(arrayfun(@(x) not(isempty(x.loads{1})),eem.models));
            if isempty(app.f)
                close(app.viewdmrUIFigure)
                error('No models present.')
            end

            app.ModelDropDown.Items = cellstr(strcat(num2str(app.f),repmat(' - component model',numel(app.f),1)));
            
            if not(isnan(f))
                drEEMdataset.mustBeModel(eem,f)
                app.ModelDropDown.Value(1) = num2str(f);
            end
            app.SampleDropDown.Items = eem.filelist;
            linkaxes([app.measured,app.modelled,app.residuals],'xy')
            linkaxes([app.measured,app.modelled],'z')
            app.plotNewSample
            colorbar(app.measured)
            colorbar(app.modelled)
            colorbar(app.residuals)
        end

        % Value changed function: ModelDropDown, 
        % ...and 2 other components
        function plotNewSample(app, event)
            if app.KeepaxisviewsCheckBox.Value
                [app.view(1,1),app.view(1,2)]=view(app.measured); %#ok<*ADPROPLC>
                [app.view(2,1),app.view(2,2)]=view(app.modelled);
                [app.view(3,1),app.view(3,2)]=view(app.residuals);
            end
            
            m = app.ModelDropDown.Value;
            s = app.SampleDropDown.Value;

            m = str2double(m(1));
            s = matches(app.data.filelist,s);

            dt = squeeze(app.data.X(s,:,:));
            md = nway.modeleval.nmodel(app.data.models(m).loads);
            md = squeeze(md(s,:,:));
            rs = dt - md;

            x = app.data.Ex;
            y = app.data.Em;
            
            

            [az,el] = view(app.measured);
            sc = surfc(app.measured,x,y,dt,EdgeColor='none',FaceColor='flat');
            
            

            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LineWidth = 0.5;
            sc(2).LevelList=linspace(min(dt(~isnan(dt))),max(dt(~isnan(dt))),20); % app.contoursEditField.Value
            zlim(app.measured,[min(dt(~isnan(dt))),max(dt(~isnan(dt)))])
            clim(app.measured,[min(dt(~isnan(dt))),max(dt(~isnan(dt)))])


            sc = surfc(app.modelled,x,y,md,'EdgeColor','none','FaceColor','flat');

            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LineWidth = 0.5;
            sc(2).LevelList=linspace(min(md(~isnan(md))),max(md(~isnan(md))),20); % app.contoursEditField.Value
            %zlim(app.modelled,[min(md(~isnan(md))),max(md(~isnan(md)))])
            clim(app.modelled,[min(dt(~isnan(dt))),max(dt(~isnan(dt)))])

            sc = surfc(app.residuals,x,y,rs,'EdgeColor','none','FaceColor','flat');
            
            app.residuals.ZLim(2) = max(dt(~isnan(dt)))*app.ResidualsofmaxintensitySpinner.Value/100;
            sc(2).ZLocation = 'zmax';
            sc(2).LineColor='k';
            sc(2).LevelList=linspace(min(rs(~isnan(rs))),app.residuals.ZLim(2),20); %app.contoursEditField.Value
            CLim=[min(rs(~isnan(rs))) app.residuals.ZLim(2)];
            clim(app.residuals,CLim)
            zlim(app.residuals,CLim)
            levels=linspace(CLim(1),CLim(2),100);
            n_neg=sum(levels<0);
            n_pos=sum(levels>0);
            
            colormap(app.residuals,residualcolormap(app,n_neg,n_pos))
            
            xlim(app.measured,[app.data.Ex(1) app.data.Ex(end)])
            xlim(app.modelled,[app.data.Ex(1) app.data.Ex(end)])
            xlim(app.residuals,[app.data.Ex(1) app.data.Ex(end)])
            ylim(app.measured,[app.data.Em(1) app.data.Em(end)])
            ylim(app.modelled,[app.data.Em(1) app.data.Em(end)])
            ylim(app.residuals,[app.data.Em(1) app.data.Em(end)])
            if app.KeepaxisviewsCheckBox.Value
                view(app.measured,app.view(1,:))
                view(app.modelled,app.view(2,:))
                view(app.residuals,app.view(3,:))
            else
                view(app.measured,0,90)
                view(app.modelled,0,90)
                view(app.residuals,0,90)
            end
            
            colorbar(app.measured)
            colorbar(app.modelled)
            colorbar(app.residuals)

        end

        % Button pushed function: nextButton
        function nextButtonPushed(app, event)
            i=app.SampleDropDown.ValueIndex;
            if i==app.data.nSample
                return
            end
            i=i+1;
            app.SampleDropDown.Value=app.SampleDropDown.Items(i);
            app.plotNewSample
        end

        % Button pushed function: prevButton
        function prevButtonPushed(app, event)
            i=app.SampleDropDown.ValueIndex;
            if i==1
                return
            end
            i=i-1;
            app.SampleDropDown.Value=app.SampleDropDown.Items(i);
            app.plotNewSample
        end

        % Button pushed function: ExportallButton, ExportcurrentButton
        function ExportButtonPushed(app, event)
            
            
                switch event.Source.Text
                    case 'Export current'
                        fig=app.drawExportFigure(app.SampleDropDown.Value);
                        fname=['dataModelResidual_',app.SampleDropDown.Value,'.png'];
                        exportgraphics(fig,fname,"Resolution",600)
                        close(fig)
                        uialert(app.viewdmrUIFigure, ...
                            ['Figure exported (',fname,')'],'Export successful.','Icon','info')
                    case 'Export all'
                        fname='dataModelResidual_all.pdf';
                        if exist('dataModelResidual_all.pdf','file')
                            delete('dataModelResidual_all.pdf')
                        end
                        uialert(app.viewdmrUIFigure, ...
                                'Export initiated. This will take a moment, please be patient','Export initiated.','Icon','warning')
                        for j=1:app.data.nSample
                            fig=app.drawExportFigure(app.data.filelist{j});
                            exportgraphics(fig,fname,"Resolution",600,Append=true)
                            close(fig)
                            
                        end
                        uialert(app.viewdmrUIFigure, ...
                                ['Figure exported (',fname,')'],'Export successful.','Icon','info')
                end
          

             


        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.viewdmrUIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {429, 429};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {153, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create viewdmrUIFigure and hide until all components are created
            app.viewdmrUIFigure = uifigure('Visible', 'off');
            app.viewdmrUIFigure.AutoResizeChildren = 'off';
            colormap(app.viewdmrUIFigure, 'turbo');
            app.viewdmrUIFigure.Position = [100 100 1485 429];
            app.viewdmrUIFigure.Name = 'viewdmr: View data, modelled data, and residuals of PARAFAC models';
            app.viewdmrUIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.viewdmrUIFigure.WindowStyle = 'alwaysontop';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.viewdmrUIFigure);
            app.GridLayout.ColumnWidth = {153, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.LeftPanel);
            app.GridLayout3.RowHeight = {20, 30, 20, 30, 40, 40, 40, 30, 40};

            % Create ModelDropDownLabel
            app.ModelDropDownLabel = uilabel(app.GridLayout3);
            app.ModelDropDownLabel.HorizontalAlignment = 'center';
            app.ModelDropDownLabel.VerticalAlignment = 'bottom';
            app.ModelDropDownLabel.Layout.Row = 1;
            app.ModelDropDownLabel.Layout.Column = [1 2];
            app.ModelDropDownLabel.Text = 'Model';

            % Create ModelDropDown
            app.ModelDropDown = uidropdown(app.GridLayout3);
            app.ModelDropDown.ValueChangedFcn = createCallbackFcn(app, @plotNewSample, true);
            app.ModelDropDown.Layout.Row = 2;
            app.ModelDropDown.Layout.Column = [1 2];

            % Create SampleDropDownLabel
            app.SampleDropDownLabel = uilabel(app.GridLayout3);
            app.SampleDropDownLabel.HorizontalAlignment = 'center';
            app.SampleDropDownLabel.VerticalAlignment = 'bottom';
            app.SampleDropDownLabel.Layout.Row = 3;
            app.SampleDropDownLabel.Layout.Column = [1 2];
            app.SampleDropDownLabel.Text = 'Sample';

            % Create SampleDropDown
            app.SampleDropDown = uidropdown(app.GridLayout3);
            app.SampleDropDown.ValueChangedFcn = createCallbackFcn(app, @plotNewSample, true);
            app.SampleDropDown.Layout.Row = 4;
            app.SampleDropDown.Layout.Column = [1 2];

            % Create ResidualsofmaxintensitySpinnerLabel
            app.ResidualsofmaxintensitySpinnerLabel = uilabel(app.GridLayout3);
            app.ResidualsofmaxintensitySpinnerLabel.HorizontalAlignment = 'center';
            app.ResidualsofmaxintensitySpinnerLabel.VerticalAlignment = 'bottom';
            app.ResidualsofmaxintensitySpinnerLabel.Layout.Row = 5;
            app.ResidualsofmaxintensitySpinnerLabel.Layout.Column = [1 2];
            app.ResidualsofmaxintensitySpinnerLabel.Text = {'Residuals'; '% of max. intensity'};

            % Create ResidualsofmaxintensitySpinner
            app.ResidualsofmaxintensitySpinner = uispinner(app.GridLayout3);
            app.ResidualsofmaxintensitySpinner.ValueChangedFcn = createCallbackFcn(app, @plotNewSample, true);
            app.ResidualsofmaxintensitySpinner.Layout.Row = 6;
            app.ResidualsofmaxintensitySpinner.Layout.Column = [1 2];
            app.ResidualsofmaxintensitySpinner.Value = 10;

            % Create KeepaxisviewsCheckBox
            app.KeepaxisviewsCheckBox = uicheckbox(app.GridLayout3);
            app.KeepaxisviewsCheckBox.Text = 'Keep axis views';
            app.KeepaxisviewsCheckBox.Layout.Row = 7;
            app.KeepaxisviewsCheckBox.Layout.Column = [1 2];
            app.KeepaxisviewsCheckBox.Value = true;

            % Create nextButton
            app.nextButton = uibutton(app.GridLayout3, 'push');
            app.nextButton.ButtonPushedFcn = createCallbackFcn(app, @nextButtonPushed, true);
            app.nextButton.Layout.Row = 8;
            app.nextButton.Layout.Column = 2;
            app.nextButton.Text = 'next';

            % Create prevButton
            app.prevButton = uibutton(app.GridLayout3, 'push');
            app.prevButton.ButtonPushedFcn = createCallbackFcn(app, @prevButtonPushed, true);
            app.prevButton.Layout.Row = 8;
            app.prevButton.Layout.Column = 1;
            app.prevButton.Text = 'prev.';

            % Create ExportcurrentButton
            app.ExportcurrentButton = uibutton(app.GridLayout3, 'push');
            app.ExportcurrentButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportcurrentButton.WordWrap = 'on';
            app.ExportcurrentButton.Layout.Row = 9;
            app.ExportcurrentButton.Layout.Column = 1;
            app.ExportcurrentButton.Text = 'Export current';

            % Create ExportallButton
            app.ExportallButton = uibutton(app.GridLayout3, 'push');
            app.ExportallButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportallButton.WordWrap = 'on';
            app.ExportallButton.Layout.Row = 9;
            app.ExportallButton.Layout.Column = 2;
            app.ExportallButton.Text = 'Export all';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.RightPanel);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout2.RowHeight = {'1x'};

            % Create measured
            app.measured = uiaxes(app.GridLayout2);
            title(app.measured, 'data')
            xlabel(app.measured, 'Excitation (nm)')
            ylabel(app.measured, 'Emission (nm)')
            zlabel(app.measured, 'Z')
            app.measured.TickDir = 'both';
            app.measured.Layout.Row = 1;
            app.measured.Layout.Column = 1;
            colormap(app.measured, 'turbo')

            % Create modelled
            app.modelled = uiaxes(app.GridLayout2);
            title(app.modelled, 'model')
            xlabel(app.modelled, 'Excitation (nm)')
            ylabel(app.modelled, 'Emission (nm)')
            zlabel(app.modelled, 'Z')
            app.modelled.TickDir = 'both';
            app.modelled.Layout.Row = 1;
            app.modelled.Layout.Column = 2;
            colormap(app.modelled, 'turbo')

            % Create residuals
            app.residuals = uiaxes(app.GridLayout2);
            title(app.residuals, 'residuals')
            xlabel(app.residuals, 'Excitation (nm)')
            ylabel(app.residuals, 'Emission (nm)')
            zlabel(app.residuals, 'Z')
            app.residuals.TickDir = 'both';
            app.residuals.Layout.Row = 1;
            app.residuals.Layout.Column = 3;
            colormap(app.residuals, 'turbo')

            % Show the figure after all components are created
            app.viewdmrUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = viewdmr_gui(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.viewdmrUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.viewdmrUIFigure)
        end
    end
end