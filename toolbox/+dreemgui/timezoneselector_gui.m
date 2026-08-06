classdef timezoneselector_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        mainmessage          matlab.ui.control.Label
        savecloseButton      matlab.ui.control.Button
        RegionDropDown       matlab.ui.control.DropDown
        RegionDropDownLabel  matlab.ui.control.Label
        AreaDropDown         matlab.ui.control.DropDown
        AreaDropDownLabel    matlab.ui.control.Label
    end

    
    properties (Access = public)
        timezone (1,:) {mustBeText} = "";
        finished {mustBeA(finished,'logical')} = false
    end
    
    methods (Access = private)
        
        function tz = localtimezone(app)
            t = datetime('now','TimeZone','local');
            tz = t.TimeZone;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, message)
            arguments
                app
                message (1,:) {mustBeText} = ''
            end
            if not(isempty(char(message)))
                message=[char(message),': Select your timezone and confirm'];
            else
                message='Select your timezone and confirm';
            end
            app.mainmessage.Text=message;
            movegui(app.UIFigure,"center")

            default=app.localtimezone;
            default=strsplit(default,'/');

            app.AreaDropDown.Value=default{1};
            app.AreaDropDownValueChanged;
            app.RegionDropDown.Value=default{2};
            
        end

        % Value changed function: AreaDropDown
        function AreaDropDownValueChanged(app, event)
            value = app.AreaDropDown.Value;
            app.RegionDropDown.Items=...
                erase(timezones(value).Name,[char(value),'/']);
             
        end

        % Button pushed function: savecloseButton
        function savecloseButtonPushed(app, event)
            app.UIFigureCloseRequest
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.timezone=[app.AreaDropDown.Value,'/',app.RegionDropDown.Value];
            app.finished=true;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 369 168];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.WindowStyle = 'alwaysontop';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {30, 30, 30, 30};

            % Create AreaDropDownLabel
            app.AreaDropDownLabel = uilabel(app.GridLayout);
            app.AreaDropDownLabel.HorizontalAlignment = 'center';
            app.AreaDropDownLabel.VerticalAlignment = 'bottom';
            app.AreaDropDownLabel.FontWeight = 'bold';
            app.AreaDropDownLabel.Layout.Row = 2;
            app.AreaDropDownLabel.Layout.Column = [1 2];
            app.AreaDropDownLabel.Text = 'Area';

            % Create AreaDropDown
            app.AreaDropDown = uidropdown(app.GridLayout);
            app.AreaDropDown.Items = {'Africa', 'Asia', 'Europe', 'America', 'Atlantic', 'Indian', 'Antarctica', 'Australia', 'Pacific', 'Arctic', 'Etc'};
            app.AreaDropDown.ValueChangedFcn = createCallbackFcn(app, @AreaDropDownValueChanged, true);
            app.AreaDropDown.Layout.Row = 3;
            app.AreaDropDown.Layout.Column = [1 2];
            app.AreaDropDown.Value = 'Africa';

            % Create RegionDropDownLabel
            app.RegionDropDownLabel = uilabel(app.GridLayout);
            app.RegionDropDownLabel.HorizontalAlignment = 'center';
            app.RegionDropDownLabel.VerticalAlignment = 'bottom';
            app.RegionDropDownLabel.FontWeight = 'bold';
            app.RegionDropDownLabel.Layout.Row = 2;
            app.RegionDropDownLabel.Layout.Column = [3 4];
            app.RegionDropDownLabel.Text = 'Region';

            % Create RegionDropDown
            app.RegionDropDown = uidropdown(app.GridLayout);
            app.RegionDropDown.Items = {''};
            app.RegionDropDown.Layout.Row = 3;
            app.RegionDropDown.Layout.Column = [3 4];
            app.RegionDropDown.Value = '';

            % Create savecloseButton
            app.savecloseButton = uibutton(app.GridLayout, 'push');
            app.savecloseButton.ButtonPushedFcn = createCallbackFcn(app, @savecloseButtonPushed, true);
            app.savecloseButton.Layout.Row = 4;
            app.savecloseButton.Layout.Column = [3 4];
            app.savecloseButton.Text = 'save & close';

            % Create mainmessage
            app.mainmessage = uilabel(app.GridLayout);
            app.mainmessage.HorizontalAlignment = 'center';
            app.mainmessage.FontWeight = 'bold';
            app.mainmessage.Layout.Row = 1;
            app.mainmessage.Layout.Column = [1 4];
            app.mainmessage.Text = 'Select your timezone and confirm';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = timezoneselector_gui(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

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