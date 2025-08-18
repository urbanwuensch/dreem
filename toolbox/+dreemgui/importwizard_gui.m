classdef importwizard_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        drEEMImportWizardUIFigure       matlab.ui.Figure
        Toolbar                         matlab.ui.container.Toolbar
        PushTool                        matlab.ui.container.toolbar.PushTool
        pathselector                    matlab.ui.container.toolbar.PushTool
        loadMetadata                    matlab.ui.container.toolbar.PushTool
        ImportsampleabsorbanceCheckBox  matlab.ui.container.toolbar.ToggleTool
        ImportblankEEMsCheckBox         matlab.ui.container.toolbar.ToggleTool
        ImportsampleEEMsCheckBox        matlab.ui.container.toolbar.ToggleTool
        validateToggleButton            matlab.ui.container.toolbar.PushTool
        ImportToggleButton              matlab.ui.container.toolbar.PushTool
        saveToWorkspaceButton           matlab.ui.container.toolbar.PushTool
        GridLayout                      matlab.ui.container.GridLayout
        ApplogPanel                     matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        console                         matlab.ui.control.ListBox
        TabGroup                        matlab.ui.container.TabGroup
        EEMsTab                         matlab.ui.container.Tab
        GridLayoutEEMs                  matlab.ui.container.GridLayout
        FInstrumentTemplateDropDown     matlab.ui.control.DropDown
        InstrumenttemplateDropDownLabel  matlab.ui.control.Label
        FilePatternEEMBlank             matlab.ui.control.EditField
        FilePatternBlankLabel           matlab.ui.control.Label
        FilePatternEEMSample            matlab.ui.control.EditField
        FilePatternSamplesLabel         matlab.ui.control.Label
        numHeaderLinesSample            matlab.ui.control.NumericEditField
        StartimportingfromlineEditFieldLabel  matlab.ui.control.Label
        colWaveSample                   matlab.ui.control.DropDown
        FirstcolumncontainswavelengthDropDownLabel  matlab.ui.control.Label
        rowWaveSample                   matlab.ui.control.DropDown
        FirstrowcontainswavelengthDropDownLabel  matlab.ui.control.Label
        columnIsExcitationSample        matlab.ui.control.DropDown
        ColumnscontainDropDownLabel     matlab.ui.control.Label
        AbsorbancespectraTab            matlab.ui.container.Tab
        GridLayoutSample_2              matlab.ui.container.GridLayout
        InstrumenttemplateDropDown      matlab.ui.control.DropDown
        InstrumenttemplateDropDownLabel_2  matlab.ui.control.Label
        WavelengthinformationisstoredincolumnEditField  matlab.ui.control.NumericEditField
        WavelengthinformationisstoredincolumnEditFieldLabel  matlab.ui.control.Label
        AbsorbanceinformationisstoredincolumnEditField  matlab.ui.control.NumericEditField
        AbsorbanceinformationisstoredincolumnEditFieldLabel  matlab.ui.control.Label
        FilePatternAbsorbance           matlab.ui.control.EditField
        FilePatternEditFieldLabel_3     matlab.ui.control.Label
        numHeaderLinesAbsorbance        matlab.ui.control.NumericEditField
        StartimportingfromlineEditFieldLabel_3  matlab.ui.control.Label
        MetadataspreadsheetTab          matlab.ui.container.Tab
        GridLayout3                     matlab.ui.container.GridLayout
        HTML                            matlab.ui.control.HTML
        SuccessrateGauge                matlab.ui.control.LinearGauge
        SuccessrateGaugeLabel           matlab.ui.control.Label
        MetadataStatusLamp              matlab.ui.control.Lamp
        StatusLabel                     matlab.ui.control.Label
        metadataColumnsDropdown         matlab.ui.control.DropDown
        SpreadsheetcolumncontainingfilenamesDropDownLabel  matlab.ui.control.Label
    end

    
    properties (Access = private)
        samples {mustBeA(samples,'drEEMdataset')} = drEEMdataset% Description
        blanks {mustBeA(blanks,'drEEMdataset')} = drEEMdataset % Description
        absorbance {mustBeA(absorbance,'drEEMdataset')} = drEEMdataset % Description
        folder (1,:) {mustBeFolder} = pwd;
        importGo {mustBeA(importGo,'logical')} = false; % Description
        testGo {mustBeA(testGo,'logical')} = true; % DescriptionDescription
        originalFolder (1,:) {mustBeFolder} = pwd;
        metadata {mustBeA(metadata,'table')} = table % Description
        rowWave {mustBeNumericOrLogical} = false % Description
        colWave {mustBeNumericOrLogical} = false % Description
        subapp % Description
    end
    
    methods (Access = private)
        
        function updateconsole(app,message,type)
            arguments
                app
                message {mustBeText}
                type {mustBeMember(type,["message","warning","error","information"])}
            end
            if not(exist("type","var"))
                color='k';
                fw='normal';
            else
                switch type
                    case 'message'
                        color=[0         0.4         0.2];
                        fw='bold';
                    case 'warning'
                        color=[1         0.6           0];
                        fw='bold';
                    case 'error'
                        color=[1         0.4         0.4];
                        fw='bold';
                    case 'information'
                        color=[.6         0.6         0.6];
                        fw='normal';
                end
            end
            n=numel(app.console.Items);
            n=n+1;
            time=char(datetime('now'));time=time(end-7:end);
            app.console.Items{1,end+1} = [time,': ',message];
            s = uistyle(FontColor=color,FontWeight=fw);
            addStyle(app.console,s,"item",n)
            scroll(app.console, 'bottom');drawnow
        end
        
        function stateCheck(app)
            
            if app.testGo
                app.validateToggleButton.Enable="on";
            else
                app.validateToggleButton.Enable="off";
            end

            if app.importGo
                app.ImportToggleButton.Enable="on";
            end
            if app.ImportblankEEMsCheckBox.State
                app.FilePatternEEMBlank.Enable=true;
            else
                app.FilePatternEEMBlank.Enable=false;
            end
            if app.ImportsampleEEMsCheckBox.State
                app.FilePatternEEMSample.Enable=true;
            else
                app.FilePatternEEMSample.Enable=false;
            end
            if app.ImportsampleabsorbanceCheckBox.State
                app.FilePatternAbsorbance.Enable=true;
            else
                app.FilePatternAbsorbance.Enable=false;
            end

            % if not(app.ImportsampleEEMsCheckBox.State&&app.ImportblankEEMsCheckBox.State)
            %     for j=1:numel(app.GridLayoutEEMs.Children)
            %         app.GridLayoutEEMs.Children(j).Enable=false;
            %     end
            % else
            %     for j=1:numel(app.GridLayoutEEMs.Children)
            %         app.GridLayoutEEMs.Children(j).Enable=true;
            %     end
            % end

            
        end
        
        function testEEMs(app)
            if app.ImportsampleEEMsCheckBox.State
                if contains(app.columnIsExcitationSample.Value,'Excitation')
                    columnIsExcitation=true;
                else
                    columnIsExcitation=false;
                end
                if strcmp(app.colWaveSample.Value,'true')
                   app.colWave=true;
                end
                if strcmp(app.rowWaveSample.Value,'true')
                    app.rowWave=true;
                end
                try
                    cd(app.folder)
                    drEEMtoolbox.importeems(app.FilePatternEEMSample.Value, ...
                        columnWave=app.colWave, ...
                        rowWave=app.rowWave, ...
                        columnIsExcitation=columnIsExcitation, ...
                        NumHeaderLines=app.numHeaderLinesSample.Value-1)
                    nsample=numel(dir(app.FilePatternEEMSample.Value));
                    cd(app.originalFolder)
                    app.updateconsole(['Test passed (',num2str(nsample),' sample EEMs)'],'message');
                    app.importGo=true;

                catch ME
                    app.updateconsole(['Settings not valid: ',ME.message,'(',num2str(ME.stack(1).line),')'],'error');
                    app.importGo=false;
                    cd(app.originalFolder)
                end
            end
            
            if app.ImportblankEEMsCheckBox.State
                if contains(app.columnIsExcitationSample.Value,'Excitation')
                    columnIsExcitation=true;
                else
                    columnIsExcitation=false;
                end
                if strcmp(app.colWaveSample.Value,'true')
                   app.colWave=true;
                end
                if strcmp(app.rowWaveSample.Value,'true')
                    app.rowWave=true;
                end
                try
                    cd(app.folder)
                    drEEMtoolbox.importeems(app.FilePatternEEMBlank.Value, ...
                        columnWave=app.colWave, ...
                        rowWave=app.rowWave, ...
                        columnIsExcitation=columnIsExcitation, ...
                        NumHeaderLines=app.numHeaderLinesSample.Value-1);
                    nsample=numel(dir(app.FilePatternEEMBlank.Value));
                    cd(app.originalFolder)
                    app.updateconsole(['Test passed (',num2str(nsample),' blank EEMs)'],'message');
                    app.importGo=true;
                catch ME
                    app.updateconsole(['Settings not valid: ',ME.message,'(',num2str(ME.stack(1).line),')'],'error');
                    app.importGo=false;
                    cd(app.originalFolder)
                end
            end

        end
        
        function testAbsorbance(app)
            if app.ImportsampleabsorbanceCheckBox.State
                try
                    cd(app.folder)
                    drEEMtoolbox.importabsorbance(app.FilePatternAbsorbance.Value, ...
                        waveColumn=app.WavelengthinformationisstoredincolumnEditField.Value, ...
                        absColumn=app.AbsorbanceinformationisstoredincolumnEditField.Value, ...
                        NumHeaderLines=app.numHeaderLinesAbsorbance.Value-1);
                    nsample=numel(dir(app.FilePatternAbsorbance.Value));
                    cd(app.originalFolder)
                    app.updateconsole(['Test passed (',num2str(nsample),' absorbance scans)'],'message');
                    app.importGo=true;
                catch ME
                    app.updateconsole(['Settings not valid: ',ME.message,'(',num2str(ME.stack(1).line),')'],'error');
                    app.importGo=false;
                    cd(app.originalFolder)
                end
            end
        end
        
        function CheckIfFiles(app)
            nblank=0;
            nsample=0;
            nabs=0;
            message='Found ';
            cd(app.folder)
            if app.ImportblankEEMsCheckBox.State
                nblank=numel(dir(app.FilePatternEEMBlank.Value));
                message=[message,num2str(nblank),' blank EEMs '];
            end
            if app.ImportsampleEEMsCheckBox.State
                nsample=numel(dir(app.FilePatternEEMSample.Value));
                message=[message,num2str(nsample),' sample EEMs '];
            end
            if app.ImportsampleabsorbanceCheckBox.State
                nabs=numel(dir(app.FilePatternAbsorbance.Value));
                message=[message,num2str(nabs),' absorbance scans '];
            end
            cd(app.originalFolder)
            
            if any([nblank,nsample,nabs]>0)
                app.validateToggleButton.Enable="on";
                app.testGo=true;
                app.updateconsole(message,'message')
            else
                app.validateToggleButton.Enable="off";
                app.testGo=false;
                app.updateconsole('No samples in current folder','warning')
            end
            
        end
        
        function [best,bestp]=metakeysearcher(app)
            keys=app.metadata.Properties.VariableNames;
            ninter=zeros(numel(keys),1);
            for j=1:numel(keys)
                if iscell(app.metadata.(keys{j}))
                    C=intersect(app.samples.filelist,app.metadata.(keys{j}));
                    ninter(j)=numel(C);
                else
                    ninter(j)=0;
                end
            end

            [bestp,best]=max(ninter);
            bestp=(bestp./app.samples.nSample)*100;
            best=keys(best);

            
        end
        
        function requestWaveInfo(app,source)
            app.subapp=struct;
            app.subapp.fig=uifigure("Position",[0 0 300 180],'Tag',source);
            app.subapp.fig.WindowStyle = "modal";
            app.subapp.fig.Resize='off';
            app.subapp.fig.CloseRequestFcn=createCallbackFcn(app,@test,true);
            movegui(app.subapp.fig,"center")
            app.subapp.gridlayout = uigridlayout(app.subapp.fig,[4 3]);
            app.subapp.gridlayout.RowHeight = {22,22,22,22,22};
            app.subapp.gridlayout.ColumnWidth = {150,70,80};
            switch source
                case 'rowWave'
                    app.subapp.label=uilabel(app.subapp.gridlayout, ...
                        "Text",'Specify row wavelengts (as they are logged!)');
                case 'colWave'
                    app.subapp.label=uilabel(app.subapp.gridlayout, ...
                        "Text",'Specify row wavelengts (as they are logged!)');
            end
            app.subapp.label.Layout.Column=[1 3];
            app.subapp.label.Layout.Row=1;
            app.subapp.label.FontWeight='bold';

            app.subapp.label=uilabel(app.subapp.gridlayout, ...
                "Text",'wavelength start');
            app.subapp.label.Tooltip=['Specify the wavelength of the first ' ...
                'listed observation. This can be a longer or shorter than the last observation' ...
                ' depending on whether observations are listed increasing' ...
                ' or decreasing'];
            app.subapp.label.Layout.Column=1;
            app.subapp.label.Layout.Row=2;

            app.subapp.uispinnerLow=uispinner(app.subapp.gridlayout, ...
                "Limits",[200 1000],"Value",240,"Step",1);
            app.subapp.uispinnerLow.Layout.Column=2;
            app.subapp.uispinnerLow.Layout.Row=2;

            app.subapp.label=uilabel(app.subapp.gridlayout, ...
                "Text",'wavelength end');
           app.subapp.label.Tooltip=['Specify the wavelength of the last ' ...
                'listed observation. This can be a longer or shorter than the first observation' ...
                ' depending on whether observations are listed increasing' ...
                ' or decreasing'];
            app.subapp.label.Layout.Column=1;
            app.subapp.label.Layout.Row=3;

            app.subapp.uispinnerHigh=uispinner(app.subapp.gridlayout, ...
                "Limits",[200 1000],"Value",800,"Step",1);
            app.subapp.uispinnerHigh.Layout.Column=2;
            app.subapp.uispinnerHigh.Layout.Row=3;

            app.subapp.label=uilabel(app.subapp.gridlayout, ...
                "Text",'wavelength increment');
            app.subapp.label.Tooltip=['Provide the increment between observations.' ...
                ' If increasing from first to last (left-right or top bottom),' ...
                ' this is a positive number. ' ...
                'If decreasing, specifiy the number with a minus in front.'];
            app.subapp.label.Layout.Column=1;
            app.subapp.label.Layout.Row=4;

            app.subapp.uispinnerInc=uispinner(app.subapp.gridlayout, ...
                "Limits",[-20 20],"Value",3,"Step",1);
            app.subapp.uispinnerInc.Layout.Column=2;
            app.subapp.uispinnerInc.Layout.Row=4;
            
            app.subapp.OKbutton=uibutton(app.subapp.gridlayout, ...
                Text='save & close');
            app.subapp.OKbutton.Layout.Column=[1 2];
            app.subapp.OKbutton.Layout.Row=5;
            app.subapp.OKbutton.ButtonPushedFcn=createCallbackFcn(app,@test,true);
            
        end
        
        function test(app,event)
            
            results=app.subapp.uispinnerLow.Value:app.subapp.uispinnerInc.Value:app.subapp.uispinnerHigh.Value;
            if matches(app.subapp.fig.Tag,'rowWave')
                app.rowWave=results;
                app.updateconsole( ...
                    ['Row wavelenth information saved (',...
                    num2str(app.subapp.uispinnerLow.Value),' : ', ...
                    num2str(app.subapp.uispinnerInc.Value),' : ', ...
                    num2str(app.subapp.uispinnerHigh.Value),')'],'message')
            elseif matches(app.subapp.fig.Tag,'colWave')
                app.colWave=results;
                app.updateconsole( ...
                    ['Column wavelenth information saved (',...
                    num2str(app.subapp.uispinnerLow.Value),' : ', ...
                    num2str(app.subapp.uispinnerInc.Value),' : ', ...
                    num2str(app.subapp.uispinnerHigh.Value),')'],'message')
            end
            delete(app.subapp.fig)
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.originalFolder=pwd;
            movegui(app.drEEMImportWizardUIFigure,"center")
            
            app.stateCheck;
            app.updateconsole('App started. Select import folder to get started.','message')
            app.CheckIfFiles;
        end

        % Callback function: validateToggleButton
        function validateToggleButtonPushed(app, event)
            app.testEEMs;
            app.testAbsorbance;
            app.stateCheck;
        end

        % Callback function: ImportToggleButton
        function ImportToggleButtonPushed(app, event)
            %% Load
            % Absorbance
            if app.ImportsampleabsorbanceCheckBox.State
                cd(app.folder)
                app.absorbance=drEEMtoolbox.importabsorbance(app.FilePatternAbsorbance.Value, ...
                        waveColumn=app.WavelengthinformationisstoredincolumnEditField.Value, ...
                        absColumn=app.AbsorbanceinformationisstoredincolumnEditField.Value, ...
                        NumHeaderLines=app.numHeaderLinesAbsorbance.Value-1, ...
                        changeStatusMessage='New absorbance dataset!');
                cd(app.originalFolder)
                app.updateconsole('Absorbance data loaded.','message');
                app.saveToWorkspaceButton.Enable="on";
            end

            % Blanks
            if app.ImportblankEEMsCheckBox.State
                if contains(app.columnIsExcitationSample.Value,'Excitation')
                    columnIsExcitation=true;
                else
                    columnIsExcitation=false;
                end
                if strcmp(app.colWaveSample.Value,'true')
                   app.colWave=true;
                end
                if strcmp(app.rowWaveSample.Value,'true')
                    app.rowWave=true;
                end
                cd(app.folder)
                app.blanks=drEEMtoolbox.importeems(app.FilePatternEEMBlank.Value, ...
                    columnWave=app.colWave, ...
                    rowWave=app.rowWave, ...
                    columnIsExcitation=columnIsExcitation, ...
                    NumHeaderLines=app.numHeaderLinesSample.Value-1, ...
                        changeStatusMessage='New blank EEM dataset!');
                cd(app.originalFolder)
                app.updateconsole('Blank EEMs loaded.','message');
                app.saveToWorkspaceButton.Enable="on";
            end

            % Samples
            if app.ImportsampleEEMsCheckBox.State
                if contains(app.columnIsExcitationSample.Value,'Excitation')
                    columnIsExcitation=true;
                else
                    columnIsExcitation=false;
                end
                if strcmp(app.colWaveSample.Value,'true')
                   app.colWave=true;
                end
                if strcmp(app.rowWaveSample.Value,'true')
                    app.rowWave=true;
                end
                cd(app.folder)
                app.samples=drEEMtoolbox.importeems(app.FilePatternEEMSample.Value, ...
                    columnWave=app.colWave, ...
                    rowWave=app.rowWave, ...
                    columnIsExcitation=columnIsExcitation, ...
                    NumHeaderLines=app.numHeaderLinesSample.Value-1, ...
                        changeStatusMessage='New sample EEM dataset!');
                cd(app.originalFolder)
                app.updateconsole('Sample EEMs loaded.','message');
                app.saveToWorkspaceButton.Enable="on";
            end
            
            %% Assemble
            cnt=1;
            takeit=[app.ImportsampleabsorbanceCheckBox.State,app.ImportsampleEEMsCheckBox.State,app.ImportblankEEMsCheckBox.State];
            datasetnames={'absorbance','samples','blanks'};
            for j=1:3
                if takeit(j)
                    datasets{cnt}=eval(['app.',datasetnames{j}]);
                    cnt=cnt+1;
                end
            end
            if cnt>2
                [datasets{:}]=drEEMtoolbox.alignsamples(datasets{:});
                app.updateconsole('All loaded datasets were aligned according to their filenames','message');
                cnt=1;
                for j=1:3
                    if takeit(j)
                        eval(['app.',datasetnames{j},' = datasets{cnt};']);
                        cnt=cnt+1;
                    end
                end
            end

            
            if app.ImportsampleabsorbanceCheckBox.State&&app.ImportsampleEEMsCheckBox.State
                app.samples.absWave=app.absorbance.absWave;
                app.samples.abs=app.absorbance.abs;
                app.absorbance=drEEMdataset;
                app.updateconsole('Absorbance was transferred to the sample EEM dataset','message');
            elseif app.ImportsampleabsorbanceCheckBox.State&&app.ImportblankEEMsCheckBox.State
                app.blanks.absWave=app.absorbance.absWave;
                app.blanks.abs=app.absorbance.abs;
                app.absorbance=drEEMdataset;
                app.updateconsole('Absorbance was transferred to the blank EEM dataset','message');
            end

            if not(isempty(app.metadata))
                [out,sp]=app.metakeysearcher;
                app.SuccessrateGauge.Value=sp;
                app.SuccessrateGauge.Limits=[sp-5 100];
                app.SuccessrateGaugeLabel.Text=['Success rate (',num2str(round(sp,1)),'%)'];
                try
                    app.metadataColumnsDropdown.Value=out;
                end
                try
                    app.samples=drEEMtoolbox.associatemetadata(app.samples,app.metadata,app.metadataColumnsDropdown.Value);
                    app.MetadataStatusLamp.Color=[0,1,0];
                    app.MetadataStatusLamp.Tooltip='Table loaded and associated with sample EEMs';
                    app.updateconsole(['Metadata merged into sample EEM dataset (',num2str(round(sp,1)),'% of samples successfully associated)'],'message')
                catch ME
                    app.MetadataStatusLamp.Color=[1 0 0];
                    app.MetadataStatusLamp.Tooltip='Table loaded and but an error was encountered during merging with dataset';
                    app.updateconsole(['Error during metadata merging: ',ME.message,'(',num2str(ME.stack(1).line),')'],'error');
                end
            end

        end

        % Callback function: pathselector
        function pathselectorClicked(app, event)
            try
                app.folder = uigetdir(pwd, ...
                        'Select import directory');
                app.updateconsole(['Import folder: ',app.folder],'message')
            catch
                app.updateconsole('Folder not changed. Try again','error')
            end
            app.CheckIfFiles;
            figure(app.drEEMImportWizardUIFigure)
            app.stateCheck;
        end

        % Callback function: ImportblankEEMsCheckBox, 
        % ...and 2 other components
        function ToggleChanged(app, event)
            app.stateCheck
        end

        % Callback function: loadMetadata
        function loadMetadataClicked(app, event)
           [file,location] = uigetfile({'*.xlsx';'*.xls';'*.csv'},'Select metadata table to import');
           figure(app.drEEMImportWizardUIFigure)
           if not(isfile(fullfile(location,file)))
               return
           end
           try
            app.metadata=readtable(fullfile(location,file),VariableNamingRule="preserve");
            app.updateconsole('Metadata table loaded successfully.','message')
            app.MetadataStatusLamp.Color=[1.00,0.91,0.39];
            app.MetadataStatusLamp.Tooltip='Table loaded, but not yet associated with dataset';
           catch ME
               app.updateconsole(['Error during table import: ',ME.message,'(',num2str(ME.stack(1).line),')'],'error');
               app.MetadataStatusLamp.Color=[1 0 0];
            app.MetadataStatusLamp.Tooltip='Table could not be loaded.';
           end
           app.metadataColumnsDropdown.Items=app.metadata.Properties.VariableNames;
           if app.samples.nSample>0
               best=app.metakeysearcher;
               app.metadataColumnsDropdown.Value=best;
           end
        end

        % Callback function:
        % AbsorbanceinformationisstoredincolumnEditField, 
        % ...and 7 other components
        function StateChanged(app, event)
            app.importGo=false;

             if matches(app.rowWaveSample.Value,'false')
                 if islogical(app.rowWave)
                    app.requestWaveInfo('rowWave');
                 end
             else
                 app.rowWave=false;
             end

            if matches(app.colWaveSample.Value,'false')
                if islogical(app.colWave)
                    app.requestWaveInfo('colWave');
                end
            else
                app.colWave=false;
            end
            
        end

        % Value changed function: FilePatternAbsorbance, 
        % ...and 2 other components
        function FilePatternChanged(app, event)
            app.CheckIfFiles;
            
        end

        % Callback function: saveToWorkspaceButton
        function saveToWorkspaceButtonClicked(app, event)
        message='Datasets exported: ';
            if app.absorbance.nSample>0
                assignin('base','absorbance',app.absorbance)
                message=[message,'absorbance '];
            end
            if app.samples.nSample>0
                assignin('base','samples',app.samples)
                message=[message,'samples '];
            end
            if app.blanks.nSample>0
                assignin('base','blanks',app.blanks)
                message=[message,'blanks '];
            end
            app.updateconsole(message,'message')
            
        end

        % Callback function: PushTool
        function PushToolClicked(app, event)
            doc importwizard
            app.updateconsole('''doc importwizard'' executed. Help browser should have opened.','message')
        end

        % Close request function: drEEMImportWizardUIFigure
        function drEEMImportWizardUIFigureCloseRequest(app, event)
            if any([app.absorbance.nSample,app.samples.nSample,app.blanks.nSample]>0)
                selection = uiconfirm(app.drEEMImportWizardUIFigure, ...
                    "Save to workspace before closing?","Confirm Close", ...
                    "Options",["Yes","No","Cancel"],...
                    "DefaultOption",3,"CancelOption",3,...
                    "Icon","warning");
                switch selection
                    case 'Cancel'
                        return
                    case 'Yes'
                        app.saveToWorkspaceButtonClicked
                        delete(app)
                    case 'No'
                        delete(app)
                end
            else
                delete(app)
            end
            
            
        end

        % Value changed function: FInstrumentTemplateDropDown
        function FInstrumentTemplateDropDownValueChanged(app, event)
            value = app.FInstrumentTemplateDropDown.Value;
            switch value
                case "Horiba AquaLog (HJY Export)"
                    app.FilePatternEEMSample.Value = '* - Waterfall Plot Sample.dat';
                    app.FilePatternEEMBlank.Value = '* - Waterfall Plot Blank.dat';
                    app.columnIsExcitationSample.Value='Excitation';
                    app.rowWaveSample.Value='true';
                    app.colWaveSample.Value='true';
                    app.numHeaderLinesSample.Value=1;
                case "Horiba AquaLog (SampleQ)"
                    app.FilePatternEEMSample.Value = '*SEM.dat';
                    app.FilePatternEEMBlank.Value = '*BEM.dat';
                    app.columnIsExcitationSample.Value='Excitation';
                    app.rowWaveSample.Value='true';
                    app.colWaveSample.Value='true';
                    app.numHeaderLinesSample.Value=1;
                case "Horiba Fluoromax"
                    app.FilePatternEEMSample.Value = '*.dat';
                    app.FilePatternEEMBlank.Value = '*.dat';
                    app.columnIsExcitationSample.Value='Excitation';
                    app.rowWaveSample.Value='true';
                    app.colWaveSample.Value='false';
                    app.numHeaderLinesSample.Value=1;
                case "Agilent Cary Eclipse"
                    app.FilePatternEEMSample.Value = '*.csv';
                    app.FilePatternEEMBlank.Value = '*.csv';
                    app.columnIsExcitationSample.Value='Excitation';
                    app.rowWaveSample.Value='true';
                    app.colWaveSample.Value='true';
                    app.numHeaderLinesSample.Value=1;
                otherwise
                    app.updateconsole('List inconsistent with function.','error')
            end
            app.CheckIfFiles;
            app.StateChanged;
        end

        % Value changed function: InstrumenttemplateDropDown
        function AInstrumentTemplateDropDownValueChanged(app, event)
            value = app.InstrumenttemplateDropDown.Value;
            switch value
                case "Horiba AquaLog (HJY Export)"
                    app.FilePatternAbsorbance.Value="* (01) - Abs Spectra Graphs.dat";
                    app.WavelengthinformationisstoredincolumnEditField.Value=1;
                    app.AbsorbanceinformationisstoredincolumnEditField.Value=10;
                    app.numHeaderLinesAbsorbance.Value=1;
                case "Horiba AquaLog (SampleQ)"
                    app.FilePatternAbsorbance.Value="*ABS.dat";
                    app.WavelengthinformationisstoredincolumnEditField.Value=1;
                    app.AbsorbanceinformationisstoredincolumnEditField.Value=2;
                    app.numHeaderLinesAbsorbance.Value=1;
            otherwise
                    app.updateconsole('List inconsistent with function.','error')
            end
            app.StateChanged;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create drEEMImportWizardUIFigure and hide until all components are created
            app.drEEMImportWizardUIFigure = uifigure('Visible', 'off');
            app.drEEMImportWizardUIFigure.AutoResizeChildren = 'off';
            colormap(app.drEEMImportWizardUIFigure, 'turbo');
            app.drEEMImportWizardUIFigure.Position = [100 100 590 422];
            app.drEEMImportWizardUIFigure.Name = 'drEEM: Import-Wizard';
            app.drEEMImportWizardUIFigure.Icon = 'logo.png';
            app.drEEMImportWizardUIFigure.Resize = 'off';
            app.drEEMImportWizardUIFigure.CloseRequestFcn = createCallbackFcn(app, @drEEMImportWizardUIFigureCloseRequest, true);

            % Create Toolbar
            app.Toolbar = uitoolbar(app.drEEMImportWizardUIFigure);

            % Create PushTool
            app.PushTool = uipushtool(app.Toolbar);
            app.PushTool.ClickedCallback = createCallbackFcn(app, @PushToolClicked, true);
            app.PushTool.Icon = 'question-inquiry-icon.png';

            % Create pathselector
            app.pathselector = uipushtool(app.Toolbar);
            app.pathselector.Tooltip = {'Change import folder (default is current working directory)'};
            app.pathselector.ClickedCallback = createCallbackFcn(app, @pathselectorClicked, true);
            app.pathselector.Icon = 'open-folder-outline-icon.png';
            app.pathselector.Separator = 'on';

            % Create loadMetadata
            app.loadMetadata = uipushtool(app.Toolbar);
            app.loadMetadata.Tooltip = {'Specify metadata spreadsheet'};
            app.loadMetadata.ClickedCallback = createCallbackFcn(app, @loadMetadataClicked, true);
            app.loadMetadata.Icon = 'excel-file-icon.png';

            % Create ImportsampleabsorbanceCheckBox
            app.ImportsampleabsorbanceCheckBox = uitoggletool(app.Toolbar);
            app.ImportsampleabsorbanceCheckBox.State = 'on';
            app.ImportsampleabsorbanceCheckBox.Tooltip = {'Import Absorbance?'};
            app.ImportsampleabsorbanceCheckBox.ClickedCallback = createCallbackFcn(app, @ToggleChanged, true);
            app.ImportsampleabsorbanceCheckBox.Icon = 'a-alphabet-icon.png';
            app.ImportsampleabsorbanceCheckBox.Separator = 'on';

            % Create ImportblankEEMsCheckBox
            app.ImportblankEEMsCheckBox = uitoggletool(app.Toolbar);
            app.ImportblankEEMsCheckBox.State = 'on';
            app.ImportblankEEMsCheckBox.Tooltip = {'Import blank EEMs?'};
            app.ImportblankEEMsCheckBox.ClickedCallback = createCallbackFcn(app, @ToggleChanged, true);
            app.ImportblankEEMsCheckBox.Icon = 'b-alphabet-icon.png';

            % Create ImportsampleEEMsCheckBox
            app.ImportsampleEEMsCheckBox = uitoggletool(app.Toolbar);
            app.ImportsampleEEMsCheckBox.State = 'on';
            app.ImportsampleEEMsCheckBox.Tooltip = {'Import sample EEMs?'};
            app.ImportsampleEEMsCheckBox.ClickedCallback = createCallbackFcn(app, @ToggleChanged, true);
            app.ImportsampleEEMsCheckBox.Icon = 's-alphabet-icon.png';

            % Create validateToggleButton
            app.validateToggleButton = uipushtool(app.Toolbar);
            app.validateToggleButton.Tooltip = {'Validate settings (runs import in diagnostics mode)'};
            app.validateToggleButton.ClickedCallback = createCallbackFcn(app, @validateToggleButtonPushed, true);
            app.validateToggleButton.Enable = 'off';
            app.validateToggleButton.Icon = 'check-mark-box-icon.png';
            app.validateToggleButton.Separator = 'on';

            % Create ImportToggleButton
            app.ImportToggleButton = uipushtool(app.Toolbar);
            app.ImportToggleButton.Tooltip = {'Import and assemble dataset(s).'};
            app.ImportToggleButton.ClickedCallback = createCallbackFcn(app, @ImportToggleButtonPushed, true);
            app.ImportToggleButton.Enable = 'off';
            app.ImportToggleButton.Icon = 'download-file-icon.png';

            % Create saveToWorkspaceButton
            app.saveToWorkspaceButton = uipushtool(app.Toolbar);
            app.saveToWorkspaceButton.Tooltip = {'Save to workspace'};
            app.saveToWorkspaceButton.ClickedCallback = createCallbackFcn(app, @saveToWorkspaceButtonClicked, true);
            app.saveToWorkspaceButton.Enable = 'off';
            app.saveToWorkspaceButton.Icon = 'save-outline-icon.png';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.drEEMImportWizardUIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout.RowHeight = {310, '1x'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.AutoResizeChildren = 'off';
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = [1 3];

            % Create EEMsTab
            app.EEMsTab = uitab(app.TabGroup);
            app.EEMsTab.AutoResizeChildren = 'off';
            app.EEMsTab.Title = 'EEMs';

            % Create GridLayoutEEMs
            app.GridLayoutEEMs = uigridlayout(app.EEMsTab);
            app.GridLayoutEEMs.ColumnWidth = {190, '1x'};
            app.GridLayoutEEMs.RowHeight = {30, 30, 30, 30, 30, 30, 30};

            % Create ColumnscontainDropDownLabel
            app.ColumnscontainDropDownLabel = uilabel(app.GridLayoutEEMs);
            app.ColumnscontainDropDownLabel.HorizontalAlignment = 'right';
            app.ColumnscontainDropDownLabel.Tooltip = {'Do the columns in each file contain the emission or excitation information?'};
            app.ColumnscontainDropDownLabel.Layout.Row = 4;
            app.ColumnscontainDropDownLabel.Layout.Column = 1;
            app.ColumnscontainDropDownLabel.Text = 'Columns contain';

            % Create columnIsExcitationSample
            app.columnIsExcitationSample = uidropdown(app.GridLayoutEEMs);
            app.columnIsExcitationSample.Items = {'Excitation', 'Emission'};
            app.columnIsExcitationSample.ValueChangedFcn = createCallbackFcn(app, @StateChanged, true);
            app.columnIsExcitationSample.Tooltip = {'Do the columns in each file contain the emission or excitation information?'};
            app.columnIsExcitationSample.Layout.Row = 4;
            app.columnIsExcitationSample.Layout.Column = 2;
            app.columnIsExcitationSample.Value = 'Excitation';

            % Create FirstrowcontainswavelengthDropDownLabel
            app.FirstrowcontainswavelengthDropDownLabel = uilabel(app.GridLayoutEEMs);
            app.FirstrowcontainswavelengthDropDownLabel.HorizontalAlignment = 'right';
            app.FirstrowcontainswavelengthDropDownLabel.Tooltip = {'Does the first row contain wavelength information? '; ''; 'If not (i.e. false is selected), a second window will open asking you to provide this information.'};
            app.FirstrowcontainswavelengthDropDownLabel.Layout.Row = 5;
            app.FirstrowcontainswavelengthDropDownLabel.Layout.Column = 1;
            app.FirstrowcontainswavelengthDropDownLabel.Text = 'First row contains wavelength';

            % Create rowWaveSample
            app.rowWaveSample = uidropdown(app.GridLayoutEEMs);
            app.rowWaveSample.Items = {'true', 'false'};
            app.rowWaveSample.ValueChangedFcn = createCallbackFcn(app, @StateChanged, true);
            app.rowWaveSample.Tooltip = {'Does the first row contain wavelength information? '; ''; 'If not (i.e. false is selected), a second window will open asking you to provide this information.'};
            app.rowWaveSample.Layout.Row = 5;
            app.rowWaveSample.Layout.Column = 2;
            app.rowWaveSample.Value = 'true';

            % Create FirstcolumncontainswavelengthDropDownLabel
            app.FirstcolumncontainswavelengthDropDownLabel = uilabel(app.GridLayoutEEMs);
            app.FirstcolumncontainswavelengthDropDownLabel.HorizontalAlignment = 'right';
            app.FirstcolumncontainswavelengthDropDownLabel.Tooltip = {'Does the first column contain wavelength information? '; ''; 'If not (i.e. false is selected), a second window will open asking you to provide this information.'};
            app.FirstcolumncontainswavelengthDropDownLabel.Layout.Row = 6;
            app.FirstcolumncontainswavelengthDropDownLabel.Layout.Column = 1;
            app.FirstcolumncontainswavelengthDropDownLabel.Text = 'First column contains wavelength';

            % Create colWaveSample
            app.colWaveSample = uidropdown(app.GridLayoutEEMs);
            app.colWaveSample.Items = {'true', 'false'};
            app.colWaveSample.ValueChangedFcn = createCallbackFcn(app, @StateChanged, true);
            app.colWaveSample.Tooltip = {'Does the first column contain wavelength information? '; ''; 'If not (i.e. false is selected), a second window will open asking you to provide this information.'};
            app.colWaveSample.Layout.Row = 6;
            app.colWaveSample.Layout.Column = 2;
            app.colWaveSample.Value = 'true';

            % Create StartimportingfromlineEditFieldLabel
            app.StartimportingfromlineEditFieldLabel = uilabel(app.GridLayoutEEMs);
            app.StartimportingfromlineEditFieldLabel.HorizontalAlignment = 'right';
            app.StartimportingfromlineEditFieldLabel.Layout.Row = 7;
            app.StartimportingfromlineEditFieldLabel.Layout.Column = 1;
            app.StartimportingfromlineEditFieldLabel.Text = 'Start importing from line';

            % Create numHeaderLinesSample
            app.numHeaderLinesSample = uieditfield(app.GridLayoutEEMs, 'numeric');
            app.numHeaderLinesSample.Limits = [0 Inf];
            app.numHeaderLinesSample.ValueChangedFcn = createCallbackFcn(app, @StateChanged, true);
            app.numHeaderLinesSample.Layout.Row = 7;
            app.numHeaderLinesSample.Layout.Column = 2;
            app.numHeaderLinesSample.Value = 1;

            % Create FilePatternSamplesLabel
            app.FilePatternSamplesLabel = uilabel(app.GridLayoutEEMs);
            app.FilePatternSamplesLabel.HorizontalAlignment = 'right';
            app.FilePatternSamplesLabel.Tooltip = {'Specify the file name pattern that identifies sample EEMs'; ''; 'Take care of leading or trailing spaces'; ''; 'The leading "*" is a wildcard designed to ignore letters coming before it'};
            app.FilePatternSamplesLabel.Layout.Row = 2;
            app.FilePatternSamplesLabel.Layout.Column = 1;
            app.FilePatternSamplesLabel.Text = 'File Pattern Samples';

            % Create FilePatternEEMSample
            app.FilePatternEEMSample = uieditfield(app.GridLayoutEEMs, 'text');
            app.FilePatternEEMSample.ValueChangedFcn = createCallbackFcn(app, @FilePatternChanged, true);
            app.FilePatternEEMSample.Tooltip = {'Specify the file name pattern that identifies sample EEMs'; ''; 'Take care of leading or trailing spaces'; ''; 'The leading "*" is a wildcard designed to ignore letters coming before it'};
            app.FilePatternEEMSample.Layout.Row = 2;
            app.FilePatternEEMSample.Layout.Column = 2;
            app.FilePatternEEMSample.Value = '* - Waterfall Plot Sample.dat';

            % Create FilePatternBlankLabel
            app.FilePatternBlankLabel = uilabel(app.GridLayoutEEMs);
            app.FilePatternBlankLabel.HorizontalAlignment = 'right';
            app.FilePatternBlankLabel.Tooltip = {'Specify the file name pattern that identifies blank EEMs'; ''; 'Take care of leading or trailing spaces'; ''; 'The leading "*" is a wildcard designed to ignore letters coming before it'};
            app.FilePatternBlankLabel.Layout.Row = 3;
            app.FilePatternBlankLabel.Layout.Column = 1;
            app.FilePatternBlankLabel.Text = 'File Pattern Blank';

            % Create FilePatternEEMBlank
            app.FilePatternEEMBlank = uieditfield(app.GridLayoutEEMs, 'text');
            app.FilePatternEEMBlank.ValueChangedFcn = createCallbackFcn(app, @FilePatternChanged, true);
            app.FilePatternEEMBlank.ValueChangingFcn = createCallbackFcn(app, @StateChanged, true);
            app.FilePatternEEMBlank.Tooltip = {'Specify the file name pattern that identifies blank EEMs'; ''; 'Take care of leading or trailing spaces'; ''; 'The leading "*" is a wildcard designed to ignore letters coming before it'};
            app.FilePatternEEMBlank.Layout.Row = 3;
            app.FilePatternEEMBlank.Layout.Column = 2;
            app.FilePatternEEMBlank.Value = '* - Waterfall Plot Blank.dat';

            % Create InstrumenttemplateDropDownLabel
            app.InstrumenttemplateDropDownLabel = uilabel(app.GridLayoutEEMs);
            app.InstrumenttemplateDropDownLabel.HorizontalAlignment = 'right';
            app.InstrumenttemplateDropDownLabel.Tooltip = {'Select your instrument to quickly preselect options below'};
            app.InstrumenttemplateDropDownLabel.Layout.Row = 1;
            app.InstrumenttemplateDropDownLabel.Layout.Column = 1;
            app.InstrumenttemplateDropDownLabel.Text = 'Instrument template';

            % Create FInstrumentTemplateDropDown
            app.FInstrumentTemplateDropDown = uidropdown(app.GridLayoutEEMs);
            app.FInstrumentTemplateDropDown.Items = {'Horiba AquaLog (HJY Export)', 'Horiba AquaLog (SampleQ)', 'Horiba Fluoromax', 'Agilent Cary Eclipse'};
            app.FInstrumentTemplateDropDown.ValueChangedFcn = createCallbackFcn(app, @FInstrumentTemplateDropDownValueChanged, true);
            app.FInstrumentTemplateDropDown.Tooltip = {'Select your instrument to quickly preselect options below'};
            app.FInstrumentTemplateDropDown.Layout.Row = 1;
            app.FInstrumentTemplateDropDown.Layout.Column = 2;
            app.FInstrumentTemplateDropDown.Value = 'Horiba AquaLog (HJY Export)';

            % Create AbsorbancespectraTab
            app.AbsorbancespectraTab = uitab(app.TabGroup);
            app.AbsorbancespectraTab.AutoResizeChildren = 'off';
            app.AbsorbancespectraTab.Title = 'Absorbance spectra';

            % Create GridLayoutSample_2
            app.GridLayoutSample_2 = uigridlayout(app.AbsorbancespectraTab);
            app.GridLayoutSample_2.RowHeight = {30, 30, 30, 30, 30};

            % Create StartimportingfromlineEditFieldLabel_3
            app.StartimportingfromlineEditFieldLabel_3 = uilabel(app.GridLayoutSample_2);
            app.StartimportingfromlineEditFieldLabel_3.HorizontalAlignment = 'right';
            app.StartimportingfromlineEditFieldLabel_3.Layout.Row = 5;
            app.StartimportingfromlineEditFieldLabel_3.Layout.Column = 1;
            app.StartimportingfromlineEditFieldLabel_3.Text = 'Start importing from line';

            % Create numHeaderLinesAbsorbance
            app.numHeaderLinesAbsorbance = uieditfield(app.GridLayoutSample_2, 'numeric');
            app.numHeaderLinesAbsorbance.Limits = [1 Inf];
            app.numHeaderLinesAbsorbance.ValueChangedFcn = createCallbackFcn(app, @StateChanged, true);
            app.numHeaderLinesAbsorbance.Layout.Row = 5;
            app.numHeaderLinesAbsorbance.Layout.Column = 2;
            app.numHeaderLinesAbsorbance.Value = 1;

            % Create FilePatternEditFieldLabel_3
            app.FilePatternEditFieldLabel_3 = uilabel(app.GridLayoutSample_2);
            app.FilePatternEditFieldLabel_3.HorizontalAlignment = 'right';
            app.FilePatternEditFieldLabel_3.Tooltip = {'Specify the file name pattern that identifies absorbance files'; ''; 'Take care of leading or trailing spaces'; ''; 'The leading "*" is a wildcard designed to ignore letters coming before it'};
            app.FilePatternEditFieldLabel_3.Layout.Row = 2;
            app.FilePatternEditFieldLabel_3.Layout.Column = 1;
            app.FilePatternEditFieldLabel_3.Text = 'File Pattern';

            % Create FilePatternAbsorbance
            app.FilePatternAbsorbance = uieditfield(app.GridLayoutSample_2, 'text');
            app.FilePatternAbsorbance.ValueChangedFcn = createCallbackFcn(app, @FilePatternChanged, true);
            app.FilePatternAbsorbance.Tooltip = {'Specify the file name pattern that identifies absorbance files'; ''; 'Take care of leading or trailing spaces'; ''; 'The leading "*" is a wildcard designed to ignore letters coming before it'};
            app.FilePatternAbsorbance.Layout.Row = 2;
            app.FilePatternAbsorbance.Layout.Column = 2;
            app.FilePatternAbsorbance.Value = '* (01) - Abs Spectra Graphs.dat';

            % Create AbsorbanceinformationisstoredincolumnEditFieldLabel
            app.AbsorbanceinformationisstoredincolumnEditFieldLabel = uilabel(app.GridLayoutSample_2);
            app.AbsorbanceinformationisstoredincolumnEditFieldLabel.HorizontalAlignment = 'right';
            app.AbsorbanceinformationisstoredincolumnEditFieldLabel.Layout.Row = 4;
            app.AbsorbanceinformationisstoredincolumnEditFieldLabel.Layout.Column = 1;
            app.AbsorbanceinformationisstoredincolumnEditFieldLabel.Text = 'Absorbance information is stored in column';

            % Create AbsorbanceinformationisstoredincolumnEditField
            app.AbsorbanceinformationisstoredincolumnEditField = uieditfield(app.GridLayoutSample_2, 'numeric');
            app.AbsorbanceinformationisstoredincolumnEditField.ValueChangedFcn = createCallbackFcn(app, @StateChanged, true);
            app.AbsorbanceinformationisstoredincolumnEditField.Layout.Row = 4;
            app.AbsorbanceinformationisstoredincolumnEditField.Layout.Column = 2;
            app.AbsorbanceinformationisstoredincolumnEditField.Value = 10;

            % Create WavelengthinformationisstoredincolumnEditFieldLabel
            app.WavelengthinformationisstoredincolumnEditFieldLabel = uilabel(app.GridLayoutSample_2);
            app.WavelengthinformationisstoredincolumnEditFieldLabel.HorizontalAlignment = 'right';
            app.WavelengthinformationisstoredincolumnEditFieldLabel.Layout.Row = 3;
            app.WavelengthinformationisstoredincolumnEditFieldLabel.Layout.Column = 1;
            app.WavelengthinformationisstoredincolumnEditFieldLabel.Text = 'Wavelength information is stored in column';

            % Create WavelengthinformationisstoredincolumnEditField
            app.WavelengthinformationisstoredincolumnEditField = uieditfield(app.GridLayoutSample_2, 'numeric');
            app.WavelengthinformationisstoredincolumnEditField.ValueChangedFcn = createCallbackFcn(app, @StateChanged, true);
            app.WavelengthinformationisstoredincolumnEditField.Layout.Row = 3;
            app.WavelengthinformationisstoredincolumnEditField.Layout.Column = 2;
            app.WavelengthinformationisstoredincolumnEditField.Value = 1;

            % Create InstrumenttemplateDropDownLabel_2
            app.InstrumenttemplateDropDownLabel_2 = uilabel(app.GridLayoutSample_2);
            app.InstrumenttemplateDropDownLabel_2.HorizontalAlignment = 'right';
            app.InstrumenttemplateDropDownLabel_2.Layout.Row = 1;
            app.InstrumenttemplateDropDownLabel_2.Layout.Column = 1;
            app.InstrumenttemplateDropDownLabel_2.Text = 'Instrument template';

            % Create InstrumenttemplateDropDown
            app.InstrumenttemplateDropDown = uidropdown(app.GridLayoutSample_2);
            app.InstrumenttemplateDropDown.Items = {'Horiba AquaLog (HJY Export)', 'Horiba AquaLog (SampleQ)'};
            app.InstrumenttemplateDropDown.ValueChangedFcn = createCallbackFcn(app, @AInstrumentTemplateDropDownValueChanged, true);
            app.InstrumenttemplateDropDown.Layout.Row = 1;
            app.InstrumenttemplateDropDown.Layout.Column = 2;
            app.InstrumenttemplateDropDown.Value = 'Horiba AquaLog (HJY Export)';

            % Create MetadataspreadsheetTab
            app.MetadataspreadsheetTab = uitab(app.TabGroup);
            app.MetadataspreadsheetTab.Title = 'Metadata spreadsheet';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.MetadataspreadsheetTab);
            app.GridLayout3.ColumnWidth = {250, '1x'};
            app.GridLayout3.RowHeight = {30, 30, 30, 30};

            % Create SpreadsheetcolumncontainingfilenamesDropDownLabel
            app.SpreadsheetcolumncontainingfilenamesDropDownLabel = uilabel(app.GridLayout3);
            app.SpreadsheetcolumncontainingfilenamesDropDownLabel.HorizontalAlignment = 'right';
            app.SpreadsheetcolumncontainingfilenamesDropDownLabel.Layout.Row = 1;
            app.SpreadsheetcolumncontainingfilenamesDropDownLabel.Layout.Column = 1;
            app.SpreadsheetcolumncontainingfilenamesDropDownLabel.Text = 'Spreadsheet column containing filenames';

            % Create metadataColumnsDropdown
            app.metadataColumnsDropdown = uidropdown(app.GridLayout3);
            app.metadataColumnsDropdown.Items = {''};
            app.metadataColumnsDropdown.Layout.Row = 1;
            app.metadataColumnsDropdown.Layout.Column = 2;
            app.metadataColumnsDropdown.Value = '';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.GridLayout3);
            app.StatusLabel.HorizontalAlignment = 'right';
            app.StatusLabel.Layout.Row = 2;
            app.StatusLabel.Layout.Column = 1;
            app.StatusLabel.Text = 'Status:';

            % Create MetadataStatusLamp
            app.MetadataStatusLamp = uilamp(app.GridLayout3);
            app.MetadataStatusLamp.Tooltip = {'Metadata file not yet provided'};
            app.MetadataStatusLamp.Layout.Row = 2;
            app.MetadataStatusLamp.Layout.Column = 2;
            app.MetadataStatusLamp.Color = [0.8 0.8 0.8];

            % Create SuccessrateGaugeLabel
            app.SuccessrateGaugeLabel = uilabel(app.GridLayout3);
            app.SuccessrateGaugeLabel.HorizontalAlignment = 'right';
            app.SuccessrateGaugeLabel.Layout.Row = 3;
            app.SuccessrateGaugeLabel.Layout.Column = 1;
            app.SuccessrateGaugeLabel.Text = 'Success rate (%):';

            % Create SuccessrateGauge
            app.SuccessrateGauge = uigauge(app.GridLayout3, 'linear');
            app.SuccessrateGauge.MinorTicks = [0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 98 100];
            app.SuccessrateGauge.BackgroundColor = [0.9412 0.9412 0.9412];
            app.SuccessrateGauge.Layout.Row = 3;
            app.SuccessrateGauge.Layout.Column = 2;

            % Create HTML
            app.HTML = uihtml(app.GridLayout3);
            app.HTML.HTMLSource = '<hr></hr>';
            app.HTML.Layout.Row = 4;
            app.HTML.Layout.Column = [1 2];

            % Create ApplogPanel
            app.ApplogPanel = uipanel(app.GridLayout);
            app.ApplogPanel.AutoResizeChildren = 'off';
            app.ApplogPanel.Title = 'App log';
            app.ApplogPanel.Layout.Row = 2;
            app.ApplogPanel.Layout.Column = [1 3];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.ApplogPanel);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout2.Padding = [2 2 2 2];

            % Create console
            app.console = uilistbox(app.GridLayout2);
            app.console.Items = {};
            app.console.Layout.Row = [1 2];
            app.console.Layout.Column = [1 3];
            app.console.Value = {};

            % Show the figure after all components are created
            app.drEEMImportWizardUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = importwizard_gui

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.drEEMImportWizardUIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.drEEMImportWizardUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.drEEMImportWizardUIFigure)
        end
    end
end