classdef setstatus_dreem < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        changestatusUIFigure           matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        Button                         matlab.ui.control.Button
        n_absorbanceUnit               matlab.ui.control.DropDown
        c_absorbanceUnit               matlab.ui.control.DropDown
        absorbanceunitDropDownLabel    matlab.ui.control.Label
        welcomeMessage                 matlab.ui.control.Label
        h_signalScaling                matlab.ui.control.Button
        h_scatterTreatment             matlab.ui.control.Button
        h_signalCalibration            matlab.ui.control.Button
        h_blankSubtraction             matlab.ui.control.Button
        h_IFEcorrection                matlab.ui.control.Button
        h_spectralCorrection           matlab.ui.control.Button
        n_signalScaling                matlab.ui.control.EditField
        newstatusLabel                 matlab.ui.control.Label
        currentstatusLabel             matlab.ui.control.Label
        stepLabel                      matlab.ui.control.Label
        saveexitButton                 matlab.ui.control.Button
        n_scatterTreatment             matlab.ui.control.DropDown
        n_signalCalibration            matlab.ui.control.DropDown
        n_blankSubtraction             matlab.ui.control.DropDown
        n_IFEcorrection                matlab.ui.control.DropDown
        n_spectralCorrection           matlab.ui.control.DropDown
        c_signalScaling                matlab.ui.control.DropDown
        signalscalingDropDownLabel     matlab.ui.control.Label
        c_scatterTreatment             matlab.ui.control.DropDown
        scattertreatmentDropDownLabel  matlab.ui.control.Label
        c_signalCalibration            matlab.ui.control.DropDown
        fluorescencecalibrationLabel   matlab.ui.control.Label
        c_blankSubtraction             matlab.ui.control.DropDown
        blanksubtractionDropDownLabel  matlab.ui.control.Label
        c_IFEcorrection                matlab.ui.control.DropDown
        innerfiltereffectcorrectionDropDownLabel  matlab.ui.control.Label
        c_spectralCorrection           matlab.ui.control.DropDown
        spectralcorrectionDropDownLabel  matlab.ui.control.Label
    end

    
    properties (Access = public)
        data % Description
        inputVarName % Description
        finishedHere
    end
    
    properties (Access = private)
        Property3 % Description
    end
    
    methods (Access = private)
        
        function results = extractPropertyList(app,property)
            m=?drEEMstatus;
            names=arrayfun(@(x) x.Name,m.PropertyList,UniformOutput=false);

            i=contains(names,property);
            if isempty(i)
                error('Non-existent property')
            end
            p=m.PropertyList(i);
            vfs=p.Validation.ValidatorFunctions;
            for j=1:numel(vfs)
                here=func2str(vfs{j});
                if contains(here,"mustBeMember")
                    C=extractBetween(here,'[',']','Boundaries','inclusive');
                    results=eval(C{1});
                end
            end
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, data, basevarname, welcomeMessage)
            arguments
                app
                data
                basevarname
                welcomeMessage (1,:) {mustBeText} = ''
            end
            app.welcomeMessage.Text=[welcomeMessage,' Specify it''s status:'];
            app.data=data;
            app.finishedHere=false;
            app.inputVarName = basevarname;
            flds=["spectralCorrection"...
                "IFEcorrection",...
                "blankSubtraction",...
                "signalCalibration",...
                "scatterTreatment",...
                "signalScaling",...
                "absorbanceUnit"];

            defaultval=["applied by instrument software",...
                "not applied",...
                "not applied",...
                "not applied",...
                "not applied",...
                "original scale",...
                "absorbance per cm"];

            for j=1:numel(flds)
                app.(['c_',char(flds(j))]).Items=string(app.data.status.(flds(j)));
                app.(['c_',char(flds(j))]).Value=app.data.status.(flds(j));

            end
            for j=1:numel(flds)
                if matches(flds(j),"signalScaling")
                    app.(['n_',char(flds(j))]).Value=...
                        app.(['c_',char(flds(j))]).Value;
                    app.(['n_',char(flds(j))]).Value=...
                    defaultval(j);
                else
                app.(['n_',char(flds(j))]).Items=...
                    app.extractPropertyList(flds(j));
                app.(['n_',char(flds(j))]).Value=...
                    defaultval(j);
                end
            end
            movegui(app.changestatusUIFigure,"center")
        end

        % Button pushed function: saveexitButton
        function saveexitButtonPushed(app, event)
             flds=["spectralCorrection"...
                "IFEcorrection",...
                "blankSubtraction",...
                "signalCalibration",...
                "scatterTreatment",...
                "signalScaling",...
                "absorbanceUnit"];
            for j=1:numel(flds)
                app.data.status=...
                    drEEMstatus.change(app.data.status,flds(j),...
                    app.(['n_',char(flds(j))]).Value);
                %app.data.status.(flds(j))=app.(['n_',char(flds(j))]).Value;

            end
            %assignin('base',app.inputVarName,app.data)
            app.finishedHere=true;
        end

        % Button pushed function: h_spectralCorrection
        function h_spectralCorrectionButtonPushed(app, event)
            uialert(app.changestatusUIFigure,['Spectral correction refers to the process' ...
                ' of eliminating intensity biases of optical components in spectrofluormeters.' ...
                'Some instrument sofwares don''t do this automatically, some do. You need to tell us.'],'Information','Icon','info')
        end

        % Button pushed function: h_IFEcorrection
        function h_IFEcorrectionButtonPushed(app, event)
            uialert(app.changestatusUIFigure,['Have inner-filter effects been corrected?' ...
                ' Some instrument softwares allow to do this.'],'Information','Icon','info')
        end

        % Button pushed function: h_blankSubtraction
        function h_blankSubtractionButtonPushed(app, event)
            uialert(app.changestatusUIFigure,['Have blanks been subtracted at this point?' ...
                ' Some instrument softwares will do this for you.'],'Information','Icon','info')
        end

        % Button pushed function: h_signalCalibration
        function h_signalCalibrationButtonPushed(app, event)
            uialert(app.changestatusUIFigure,['Has a Raman or Quinine sulfate signal calibration been carried out?' ...
                ' Some softwares offer such calibrations.'],'Information','Icon','info')
        end

        % Button pushed function: h_scatterTreatment
        function h_scatterTreatmentButtonPushed(app, event)
            uialert(app.changestatusUIFigure,['Has scatter been treated by e.g. replacement with zeros?' ...
                ' Some softwares offer simple scatter removal tools, though inserting zeros results in non-trilinear data!.'],'Information','Icon','info')
        end

        % Button pushed function: h_signalScaling
        function h_signalScalingButtonPushed(app, event)
            uialert(app.changestatusUIFigure,['Has the data been scaled in any way?' ...
                ' This could be division by the maximum signal in an EEM.'],'Information','Icon','info')
        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
            uialert(app.changestatusUIFigure,['In which cuvette has the absorbance been measured' ...
                ' If you''ve processed the data yourself, what is it''s unit?'...
                ' Don''t worry if the dataset does not contain absorbance (i.e. you''ve just loaded EEM data)'],'Information','Icon','info')
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create changestatusUIFigure and hide until all components are created
            app.changestatusUIFigure = uifigure('Visible', 'off');
            colormap(app.changestatusUIFigure, 'turbo');
            app.changestatusUIFigure.Position = [100 100 532 469];
            app.changestatusUIFigure.Name = 'changestatus';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.changestatusUIFigure);
            app.GridLayout.ColumnWidth = {132, 20, '0.8x', '0.8x'};
            app.GridLayout.RowHeight = {35, 35, 35, 35, 35, 35, 35, 35, 35, 35};

            % Create spectralcorrectionDropDownLabel
            app.spectralcorrectionDropDownLabel = uilabel(app.GridLayout);
            app.spectralcorrectionDropDownLabel.HorizontalAlignment = 'right';
            app.spectralcorrectionDropDownLabel.WordWrap = 'on';
            app.spectralcorrectionDropDownLabel.Layout.Row = 3;
            app.spectralcorrectionDropDownLabel.Layout.Column = 1;
            app.spectralcorrectionDropDownLabel.Text = 'spectral correction';

            % Create c_spectralCorrection
            app.c_spectralCorrection = uidropdown(app.GridLayout);
            app.c_spectralCorrection.Layout.Row = 3;
            app.c_spectralCorrection.Layout.Column = 3;

            % Create innerfiltereffectcorrectionDropDownLabel
            app.innerfiltereffectcorrectionDropDownLabel = uilabel(app.GridLayout);
            app.innerfiltereffectcorrectionDropDownLabel.HorizontalAlignment = 'right';
            app.innerfiltereffectcorrectionDropDownLabel.WordWrap = 'on';
            app.innerfiltereffectcorrectionDropDownLabel.Layout.Row = 4;
            app.innerfiltereffectcorrectionDropDownLabel.Layout.Column = 1;
            app.innerfiltereffectcorrectionDropDownLabel.Text = 'inner filter effect correction';

            % Create c_IFEcorrection
            app.c_IFEcorrection = uidropdown(app.GridLayout);
            app.c_IFEcorrection.Layout.Row = 4;
            app.c_IFEcorrection.Layout.Column = 3;

            % Create blanksubtractionDropDownLabel
            app.blanksubtractionDropDownLabel = uilabel(app.GridLayout);
            app.blanksubtractionDropDownLabel.HorizontalAlignment = 'right';
            app.blanksubtractionDropDownLabel.WordWrap = 'on';
            app.blanksubtractionDropDownLabel.Layout.Row = 5;
            app.blanksubtractionDropDownLabel.Layout.Column = 1;
            app.blanksubtractionDropDownLabel.Text = 'blank subtraction';

            % Create c_blankSubtraction
            app.c_blankSubtraction = uidropdown(app.GridLayout);
            app.c_blankSubtraction.Layout.Row = 5;
            app.c_blankSubtraction.Layout.Column = 3;

            % Create fluorescencecalibrationLabel
            app.fluorescencecalibrationLabel = uilabel(app.GridLayout);
            app.fluorescencecalibrationLabel.HorizontalAlignment = 'right';
            app.fluorescencecalibrationLabel.WordWrap = 'on';
            app.fluorescencecalibrationLabel.Layout.Row = 6;
            app.fluorescencecalibrationLabel.Layout.Column = 1;
            app.fluorescencecalibrationLabel.Text = 'fluorescence calibration';

            % Create c_signalCalibration
            app.c_signalCalibration = uidropdown(app.GridLayout);
            app.c_signalCalibration.Layout.Row = 6;
            app.c_signalCalibration.Layout.Column = 3;

            % Create scattertreatmentDropDownLabel
            app.scattertreatmentDropDownLabel = uilabel(app.GridLayout);
            app.scattertreatmentDropDownLabel.HorizontalAlignment = 'right';
            app.scattertreatmentDropDownLabel.WordWrap = 'on';
            app.scattertreatmentDropDownLabel.Layout.Row = 7;
            app.scattertreatmentDropDownLabel.Layout.Column = 1;
            app.scattertreatmentDropDownLabel.Text = 'scatter treatment';

            % Create c_scatterTreatment
            app.c_scatterTreatment = uidropdown(app.GridLayout);
            app.c_scatterTreatment.Layout.Row = 7;
            app.c_scatterTreatment.Layout.Column = 3;

            % Create signalscalingDropDownLabel
            app.signalscalingDropDownLabel = uilabel(app.GridLayout);
            app.signalscalingDropDownLabel.HorizontalAlignment = 'right';
            app.signalscalingDropDownLabel.WordWrap = 'on';
            app.signalscalingDropDownLabel.Layout.Row = 8;
            app.signalscalingDropDownLabel.Layout.Column = 1;
            app.signalscalingDropDownLabel.Text = 'signal scaling';

            % Create c_signalScaling
            app.c_signalScaling = uidropdown(app.GridLayout);
            app.c_signalScaling.Layout.Row = 8;
            app.c_signalScaling.Layout.Column = 3;

            % Create n_spectralCorrection
            app.n_spectralCorrection = uidropdown(app.GridLayout);
            app.n_spectralCorrection.Layout.Row = 3;
            app.n_spectralCorrection.Layout.Column = 4;

            % Create n_IFEcorrection
            app.n_IFEcorrection = uidropdown(app.GridLayout);
            app.n_IFEcorrection.Layout.Row = 4;
            app.n_IFEcorrection.Layout.Column = 4;

            % Create n_blankSubtraction
            app.n_blankSubtraction = uidropdown(app.GridLayout);
            app.n_blankSubtraction.Layout.Row = 5;
            app.n_blankSubtraction.Layout.Column = 4;

            % Create n_signalCalibration
            app.n_signalCalibration = uidropdown(app.GridLayout);
            app.n_signalCalibration.Layout.Row = 6;
            app.n_signalCalibration.Layout.Column = 4;

            % Create n_scatterTreatment
            app.n_scatterTreatment = uidropdown(app.GridLayout);
            app.n_scatterTreatment.Layout.Row = 7;
            app.n_scatterTreatment.Layout.Column = 4;

            % Create saveexitButton
            app.saveexitButton = uibutton(app.GridLayout, 'push');
            app.saveexitButton.ButtonPushedFcn = createCallbackFcn(app, @saveexitButtonPushed, true);
            app.saveexitButton.Layout.Row = 10;
            app.saveexitButton.Layout.Column = 4;
            app.saveexitButton.Text = 'save & exit';

            % Create stepLabel
            app.stepLabel = uilabel(app.GridLayout);
            app.stepLabel.HorizontalAlignment = 'center';
            app.stepLabel.VerticalAlignment = 'bottom';
            app.stepLabel.FontSize = 14;
            app.stepLabel.FontWeight = 'bold';
            app.stepLabel.Layout.Row = 2;
            app.stepLabel.Layout.Column = 1;
            app.stepLabel.Text = 'step';

            % Create currentstatusLabel
            app.currentstatusLabel = uilabel(app.GridLayout);
            app.currentstatusLabel.HorizontalAlignment = 'center';
            app.currentstatusLabel.VerticalAlignment = 'bottom';
            app.currentstatusLabel.FontSize = 14;
            app.currentstatusLabel.FontWeight = 'bold';
            app.currentstatusLabel.Layout.Row = 2;
            app.currentstatusLabel.Layout.Column = 3;
            app.currentstatusLabel.Text = 'current status';

            % Create newstatusLabel
            app.newstatusLabel = uilabel(app.GridLayout);
            app.newstatusLabel.HorizontalAlignment = 'center';
            app.newstatusLabel.VerticalAlignment = 'bottom';
            app.newstatusLabel.FontSize = 14;
            app.newstatusLabel.FontWeight = 'bold';
            app.newstatusLabel.Layout.Row = 2;
            app.newstatusLabel.Layout.Column = 4;
            app.newstatusLabel.Text = 'new status';

            % Create n_signalScaling
            app.n_signalScaling = uieditfield(app.GridLayout, 'text');
            app.n_signalScaling.Layout.Row = 8;
            app.n_signalScaling.Layout.Column = 4;

            % Create h_spectralCorrection
            app.h_spectralCorrection = uibutton(app.GridLayout, 'push');
            app.h_spectralCorrection.ButtonPushedFcn = createCallbackFcn(app, @h_spectralCorrectionButtonPushed, true);
            app.h_spectralCorrection.Layout.Row = 3;
            app.h_spectralCorrection.Layout.Column = 2;
            app.h_spectralCorrection.Text = '?';

            % Create h_IFEcorrection
            app.h_IFEcorrection = uibutton(app.GridLayout, 'push');
            app.h_IFEcorrection.ButtonPushedFcn = createCallbackFcn(app, @h_IFEcorrectionButtonPushed, true);
            app.h_IFEcorrection.Layout.Row = 4;
            app.h_IFEcorrection.Layout.Column = 2;
            app.h_IFEcorrection.Text = '?';

            % Create h_blankSubtraction
            app.h_blankSubtraction = uibutton(app.GridLayout, 'push');
            app.h_blankSubtraction.ButtonPushedFcn = createCallbackFcn(app, @h_blankSubtractionButtonPushed, true);
            app.h_blankSubtraction.Layout.Row = 5;
            app.h_blankSubtraction.Layout.Column = 2;
            app.h_blankSubtraction.Text = '?';

            % Create h_signalCalibration
            app.h_signalCalibration = uibutton(app.GridLayout, 'push');
            app.h_signalCalibration.ButtonPushedFcn = createCallbackFcn(app, @h_signalCalibrationButtonPushed, true);
            app.h_signalCalibration.Layout.Row = 6;
            app.h_signalCalibration.Layout.Column = 2;
            app.h_signalCalibration.Text = '?';

            % Create h_scatterTreatment
            app.h_scatterTreatment = uibutton(app.GridLayout, 'push');
            app.h_scatterTreatment.ButtonPushedFcn = createCallbackFcn(app, @h_scatterTreatmentButtonPushed, true);
            app.h_scatterTreatment.Layout.Row = 7;
            app.h_scatterTreatment.Layout.Column = 2;
            app.h_scatterTreatment.Text = '?';

            % Create h_signalScaling
            app.h_signalScaling = uibutton(app.GridLayout, 'push');
            app.h_signalScaling.ButtonPushedFcn = createCallbackFcn(app, @h_signalScalingButtonPushed, true);
            app.h_signalScaling.Layout.Row = 8;
            app.h_signalScaling.Layout.Column = 2;
            app.h_signalScaling.Text = '?';

            % Create welcomeMessage
            app.welcomeMessage = uilabel(app.GridLayout);
            app.welcomeMessage.HorizontalAlignment = 'center';
            app.welcomeMessage.FontSize = 15;
            app.welcomeMessage.FontWeight = 'bold';
            app.welcomeMessage.Layout.Row = 1;
            app.welcomeMessage.Layout.Column = [1 4];
            app.welcomeMessage.Text = '';

            % Create absorbanceunitDropDownLabel
            app.absorbanceunitDropDownLabel = uilabel(app.GridLayout);
            app.absorbanceunitDropDownLabel.HorizontalAlignment = 'right';
            app.absorbanceunitDropDownLabel.WordWrap = 'on';
            app.absorbanceunitDropDownLabel.Layout.Row = 9;
            app.absorbanceunitDropDownLabel.Layout.Column = 1;
            app.absorbanceunitDropDownLabel.Text = 'absorbance unit';

            % Create c_absorbanceUnit
            app.c_absorbanceUnit = uidropdown(app.GridLayout);
            app.c_absorbanceUnit.Layout.Row = 9;
            app.c_absorbanceUnit.Layout.Column = 3;

            % Create n_absorbanceUnit
            app.n_absorbanceUnit = uidropdown(app.GridLayout);
            app.n_absorbanceUnit.Layout.Row = 9;
            app.n_absorbanceUnit.Layout.Column = 4;

            % Create Button
            app.Button = uibutton(app.GridLayout, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Layout.Row = 9;
            app.Button.Layout.Column = 2;
            app.Button.Text = '?';

            % Show the figure after all components are created
            app.changestatusUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = setstatus_dreem(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.changestatusUIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.changestatusUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.changestatusUIFigure)
        end
    end
end