classdef viewscatter_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        CONTROLPANELPanel              matlab.ui.container.Panel
        GridLayout8                    matlab.ui.container.GridLayout
        applycloseButton               matlab.ui.control.Button
        GridLayout9                    matlab.ui.container.GridLayout
        savesettingsButton             matlab.ui.control.Button
        plotSwitch                     matlab.ui.control.Switch
        plotSwitchLabel                matlab.ui.control.Label
        applyButton                    matlab.ui.control.Button
        testonLabel                    matlab.ui.control.Label
        saveLabel                      matlab.ui.control.Label
        SampleDropDown                 matlab.ui.control.DropDown
        Button_2                       matlab.ui.control.Button
        Button                         matlab.ui.control.Button
        VISUALIZATIONPanel             matlab.ui.container.Panel
        GridLayout2                    matlab.ui.container.GridLayout
        TabGroup                       matlab.ui.container.TabGroup
        scattercenteredspectraTab      matlab.ui.container.Tab
        GridLayout5                    matlab.ui.container.GridLayout
        secram                         matlab.ui.control.UIAxes
        secray                         matlab.ui.control.UIAxes
        firstram                       matlab.ui.control.UIAxes
        firstray                       matlab.ui.control.UIAxes
        excitationemissionmatrixTab    matlab.ui.container.Tab
        GridLayout3                    matlab.ui.container.GridLayout
        eem                            matlab.ui.control.UIAxes
        SCATTERTREATMENTSETTINGSPanel  matlab.ui.container.Panel
        GridLayout4                    matlab.ui.container.GridLayout
        miscellaneoussettingsPanel     matlab.ui.container.Panel
        GridLayout7                    matlab.ui.container.GridLayout
        InterpolationSwitch            matlab.ui.control.Switch
        interpolationSwitchLabel       matlab.ui.control.Label
        d2zero                         matlab.ui.control.Spinner
        nmdistancetozeroSpinnerLabel   matlab.ui.control.Label
        n2z                            matlab.ui.control.CheckBox
        ndorderscatterPanel            matlab.ui.container.Panel
        GridLayout6_2                  matlab.ui.container.GridLayout
        rm2a                           matlab.ui.control.Spinner
        rm2b                           matlab.ui.control.Spinner
        ry2a                           matlab.ui.control.Spinner
        ry2b                           matlab.ui.control.Spinner
        aboveLabel_2                   matlab.ui.control.Label
        belowLabel_2                   matlab.ui.control.Label
        int_rm2                        matlab.ui.control.CheckBox
        cut_rm2                        matlab.ui.control.CheckBox
        int_ry2                        matlab.ui.control.CheckBox
        cut_ry2                        matlab.ui.control.CheckBox
        RamanLabel_2                   matlab.ui.control.Label
        RayleighLabel_2                matlab.ui.control.Label
        intLabel_2                     matlab.ui.control.Label
        cutLabel_2                     matlab.ui.control.Label
        storderscatterPanel            matlab.ui.container.Panel
        GridLayout6                    matlab.ui.container.GridLayout
        rm1a                           matlab.ui.control.Spinner
        rm1b                           matlab.ui.control.Spinner
        ry1a                           matlab.ui.control.Spinner
        ry1b                           matlab.ui.control.Spinner
        aboveLabel                     matlab.ui.control.Label
        belowLabel                     matlab.ui.control.Label
        int_rm1                        matlab.ui.control.CheckBox
        cut_rm1                        matlab.ui.control.CheckBox
        int_ry1                        matlab.ui.control.CheckBox
        cut_ry1                        matlab.ui.control.CheckBox
        RamanLabel                     matlab.ui.control.Label
        RayleighLabel                  matlab.ui.control.Label
        intLabel                       matlab.ui.control.Label
        cutLabel                       matlab.ui.control.Label
    end

    
    properties (Access = private)
        sample % current sample
        options % Description
        dataOriginal % Description
        dataCurrentOriginal
        dataCurrentCut
        
    end
    
    properties (Access = public)
        dataTreated % Description
        finishedHere % Description
        deleteThis % Description
    end
    
    methods (Access = private)
        
        function ploteem(app)


            switch app.plotSwitch.Value
                case 'raw'
                    datain=app.dataCurrentOriginal;
                case 'treated'
                    datain=app.dataCurrentCut;
            end

            x=datain.Ex;
            y=datain.Em;
            mat=squeeze(datain.X);


            % Start plotting stuff
            hold(app.eem,'off')
            sc = surfc(app.eem,x,y,mat,...
                'EdgeColor','none','FaceColor','flat');
            sc(2).ZLocation = "zmax";
            sc(2).LineColor='k';
            sc(2).LineWidth = 0.5;
            sc(2).LevelList=linspace(min(mat(~isnan(mat))),max(mat(~isnan(mat))),20);
            colormap(app.eem,"turbo");
            zlim(app.eem,[min(mat(~isnan(mat))),max(mat(~isnan(mat)))])
            %clim(app.eem,app.aclim)
            title(app.eem,app.SampleDropDown.Items(app.sample))
            colorbar(app.eem)
            view(app.eem,0,90)


        end
        

        function [dataout] = synchronizeeem(app,data,type,mode)


            switch mode
                case 'apply'
                    sign=@(x,y) minus(x,y);
                case 'reverse'
                    sign=@(x,y) plus(x,y);
            end

            switch type
                case 'ray1'
                    for n=1:data.nEx
                        em(n,:) = sign(data.Em,data.Ex(n));
                    end
                case 'ray2'
                    for n=1:data.nEx
                        em(n,:) = sign(data.Em,data.Ex(n)*2);
                    end
                case 'ram1'
                    for n=1:data.nEx
                        em(n,:) = sign(data.Em,(1e7*((1e7)/(data.Ex(n))-3382)^-1));
                    end
                case 'ram2'
                    for n=1:data.nEx
                        em(n,:)=data.Em - ((1e7*((1e7)/(data.Ex(n))-3382)^-1)*2);
                    end
                otherwise
                    error('Input to ''type'' must be one of these: ray1 ray2 ram1 ram2')
            end

            minmax=[min(em(:)) max(em(:))];

            dem=app.rcvec(minmax(1):mean(diff(data.Em)):minmax(2),'column');

            Xn=nan(data.nSample,numel(dem),data.nEx);

            for n=1:data.nSample
                for i=1:data.nEx
                    Xn(n,:,i)=interp1(em(i,:),...
                        squeeze(data.X(n,:,i)),...
                        dem);
                end
            end

            dataout=data;
            dataout.Em=dem;
            dataout.nEm=numel(dem);
            dataout.X=Xn;


        end
        
        
        function gui2options(app)
            opt=handlescatterOptions;

            if app.ry1b.Value>app.d2zero.Value
                app.d2zero.Value=app.ry1b.Value;
            end

            opt.ray1           = [app.ry1b.Value app.ry1a.Value];
            opt.ram1           = [app.rm1b.Value app.rm1a.Value];
            opt.ray2           = [app.ry2b.Value app.ry2a.Value];
            opt.ram2           = [app.rm2b.Value app.rm2a.Value];
            opt.cutout         = [app.cut_ry1.Value app.cut_rm1.Value app.cut_ry2.Value app.cut_rm2.Value];
            opt.interpolate    = [app.int_ry1.Value app.int_rm1.Value app.int_ry2.Value app.int_rm2.Value];
            opt.d2zero         = app.d2zero.Value;
            opt.negativetozero = app.n2z.Value;
            opt.samples        = 'all';
            opt.iopt           = 'normal';
            opt.plot           = false;
            if matches(app.InterpolationSwitch.Value,'inpaint')
                opt.imethod    = 'inpaint';
            else
                opt.imethod    = 'fillmissing';
            end
            app.options            = opt;
        end

        function options2gui(app)
            opt=app.options;

            app.ry1b.Value=opt.ray1(1);
            app.ry1a.Value=opt.ray1(2);

            app.rm1b.Value = opt.ram1(1);
            app.rm1a.Value = opt.ram1(2);

            app.ry2b.Value = opt.ray2(1);
            app.ry2a.Value = opt.ray2(2);

            app.rm2b.Value = opt.ram2(1);
            app.rm2a.Value = opt.ram2(2);

            app.cut_ry1.Value = opt.cutout(1);
            app.cut_rm1.Value = opt.cutout(2);
            app.cut_ry2.Value = opt.cutout(3);
            app.cut_rm2.Value = opt.cutout(4);

            app.int_ry1.Value = opt.interpolate(1);
            app.int_rm1.Value = opt.interpolate(2);
            app.int_ry2.Value = opt.interpolate(3);
            app.int_rm2.Value = opt.interpolate(4);

            app.d2zero.Value = opt.d2zero;

            app.n2z.Value = opt.negativetozero;


            if matches(opt.imethod,'inpaint')
                app.InterpolationSwitch.Value    = 'inpaint';
            else
                app.InterpolationSwitch.Value    = 'fillmissing';
            end
        end
        

        
        function plotspectra(app)
            types={'ray1','ram1','ray2','ram2'};
            typen={'firstray','firstram','secray','secram'};
            switch app.plotSwitch.Value
                case 'raw'
                    datacut=app.dataCurrentOriginal;
                case 'treated'
                    datacut=app.dataCurrentCut;
            end
            
            for n=1:numel(types)
                temp=squeeze(app.synchronizeeem(datacut,types{n},'apply'));
                mat=temp.X;
                plot(app.(typen{n}),temp.Em,...
                    squeeze(mat),'Color',[0 0 0 0.6])
                xlim(app.(typen{n}),[-40 40])
                xline(app.(typen{n}),0,'Color','r','LineStyle','--')
                %set(app.(typen{n}),'YScale',app.plotscaleSwitch.Value)
                grid(app.(typen{n}),'on')
                if matches(app.plotSwitch.Value,'raw')
                    xline(app.(typen{n}),[-app.options.(types{n})(1) app.options.(types{n})(2)],'r-')
                end
            end
            
        end
        
        function vout = rcvec(~,v,rc)
            % Make row or column vector
            % v: vector
            % rc: either 'row' ([1:5])or 'column' ([1:5]')
            sz=size(v);
            if ~any(sz==1)
                error('Input is not a vector')
            end

            switch rc
                case 'row'
                    if ~[sz(1)<sz(2)]
                        vout=v';
                    else
                        vout=v;
                    end
                case 'column'
                    if ~[sz(1)>sz(2)]
                        vout=v';
                    else
                        vout=v;
                    end
                otherwise
                    error('Input ''rc'' not recognized. Options are: ''row'' and ''column''.')
            end
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
            app.finishedHere=false;
            app.UIFigure.Units="normalized";
            app.UIFigure.Position=[0.15 0.15 0.7 0.8];
            movegui(app.UIFigure,'center')
            drEEMdataset.validate(data)

            pidx=drEEMhistory.searchhistory(data.history,"handlescatter","last");
            if not(isempty(pidx))
                disp('Existing options found. These will be transfered to the GUI')
                app.options=data.history(pidx).details;
                app.options2gui;
            end

            app.dataOriginal=data;
            app.SampleDropDown.Items=app.dataOriginal.filelist;
            app.sample=1;
            app.SampleDropDown.Value=app.SampleDropDown.Items(app.sample);
            app.triggerNewData;
        end

        % Button pushed function: Button_2
        function decreaseByOne(app, event)
            if app.sample>1
                app.sample=app.sample-1;
                app.triggerNewData;
            end
        end

        % Button pushed function: Button
        function increaseByOne(app, event)
            if app.sample<app.dataOriginal.nSample
                app.sample=app.sample+1;
                app.triggerNewData;
            end
        end

        % Value changed function: SampleDropDown
        function sampleChangedByList(app, event)
            value = app.SampleDropDown.Value;
            idx=matches(app.SampleDropDown.Items,value);
            app.sample=find(idx);
            app.triggerNewData;
        end

        % Callback function: TabGroup, plotSwitch
        function triggerRedraw(app, event)
           switch app.TabGroup.SelectedTab.Title
               case 'excitation-emission matrix'
                   app.ploteem;
               case 'scatter-centered spectra'
                   app.plotspectra;
           end
            
        end

        % Value changed function: InterpolationSwitch, cut_rm1, cut_rm2, 
        % ...and 16 other components
        function triggerNewData(app, event)
            
            app.VISUALIZATIONPanel.Title=['VISUALIZATION: ',...
                char(app.SampleDropDown.Items(app.sample))];
            app.SampleDropDown.Value=char(app.SampleDropDown.Items(app.sample));
            del=ismember(app.dataOriginal.i,app.dataOriginal.i(setdiff(1:app.dataOriginal.nSample,app.sample)));

            cut=drEEMtoolbox.subdataset(app.dataOriginal,outSample=del);
            app.gui2options;
            treated=drEEMtoolbox.handlescatter(cut,app.options);
            app.dataCurrentOriginal=cut;
            app.dataCurrentCut=treated;
            
            app.triggerRedraw;
            
        end

        % Button pushed function: applyButton
        function applyAndSwitchFocus(app, event)
            app.plotSwitch.Value='treated';
            app.triggerNewData;
        end

        % Button pushed function: applycloseButton
        function applycloseButtonPushed(app, event)
            app.dataTreated=drEEMtoolbox.handlescatter(app.dataOriginal,app.options);
            app.finishedHere=true;
            app.deleteThis=msgbox('If you launched viewscatter by itself, this functionality is not supported. Call ''handlescatter(data,''gui'') isntead.', ...
                "Icon","error");
        end

        % Button pushed function: savesettingsButton
        function savesettingsButtonPushed(app, event)
            assignin('base','scatteroptions',app.options)
            uialert(app.UIFigure, ...
                'Settings saved to the workspace, look for variable ''scatteroptions''', ...
                'settings saved to workspace', ...
                Icon='success')
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            colormap(app.UIFigure, 'turbo');
            app.UIFigure.Position = [100 100 920 648];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.HandleVisibility = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {300, '1x'};
            app.GridLayout.RowHeight = {130, '0.7x'};
            app.GridLayout.Padding = [5 5 5 5];

            % Create SCATTERTREATMENTSETTINGSPanel
            app.SCATTERTREATMENTSETTINGSPanel = uipanel(app.GridLayout);
            app.SCATTERTREATMENTSETTINGSPanel.TitlePosition = 'centertop';
            app.SCATTERTREATMENTSETTINGSPanel.Title = 'SCATTER TREATMENT SETTINGS';
            app.SCATTERTREATMENTSETTINGSPanel.Layout.Row = 2;
            app.SCATTERTREATMENTSETTINGSPanel.Layout.Column = 1;
            app.SCATTERTREATMENTSETTINGSPanel.FontName = 'Bahnschrift';
            app.SCATTERTREATMENTSETTINGSPanel.FontWeight = 'bold';
            app.SCATTERTREATMENTSETTINGSPanel.FontSize = 16;

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.SCATTERTREATMENTSETTINGSPanel);
            app.GridLayout4.ColumnWidth = {'1x'};
            app.GridLayout4.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout4.Padding = [5 5 5 5];

            % Create storderscatterPanel
            app.storderscatterPanel = uipanel(app.GridLayout4);
            app.storderscatterPanel.TitlePosition = 'centertop';
            app.storderscatterPanel.Title = '1st order scatter';
            app.storderscatterPanel.Layout.Row = 1;
            app.storderscatterPanel.Layout.Column = 1;
            app.storderscatterPanel.FontName = 'Bahnschrift';

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.storderscatterPanel);
            app.GridLayout6.ColumnWidth = {'1x', 22, 22, '1x', '1x'};
            app.GridLayout6.RowHeight = {22, 22, 22};
            app.GridLayout6.Padding = [5 5 5 5];

            % Create cutLabel
            app.cutLabel = uilabel(app.GridLayout6);
            app.cutLabel.Layout.Row = 1;
            app.cutLabel.Layout.Column = 2;
            app.cutLabel.Text = 'cut';

            % Create intLabel
            app.intLabel = uilabel(app.GridLayout6);
            app.intLabel.Layout.Row = 1;
            app.intLabel.Layout.Column = 3;
            app.intLabel.Text = 'int.';

            % Create RayleighLabel
            app.RayleighLabel = uilabel(app.GridLayout6);
            app.RayleighLabel.Layout.Row = 2;
            app.RayleighLabel.Layout.Column = 1;
            app.RayleighLabel.Text = 'Rayleigh';

            % Create RamanLabel
            app.RamanLabel = uilabel(app.GridLayout6);
            app.RamanLabel.Layout.Row = 3;
            app.RamanLabel.Layout.Column = 1;
            app.RamanLabel.Text = 'Raman';

            % Create cut_ry1
            app.cut_ry1 = uicheckbox(app.GridLayout6);
            app.cut_ry1.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.cut_ry1.Text = '';
            app.cut_ry1.Layout.Row = 2;
            app.cut_ry1.Layout.Column = 2;
            app.cut_ry1.Value = true;

            % Create int_ry1
            app.int_ry1 = uicheckbox(app.GridLayout6);
            app.int_ry1.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.int_ry1.Text = '';
            app.int_ry1.Layout.Row = 2;
            app.int_ry1.Layout.Column = 3;

            % Create cut_rm1
            app.cut_rm1 = uicheckbox(app.GridLayout6);
            app.cut_rm1.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.cut_rm1.Text = '';
            app.cut_rm1.Layout.Row = 3;
            app.cut_rm1.Layout.Column = 2;

            % Create int_rm1
            app.int_rm1 = uicheckbox(app.GridLayout6);
            app.int_rm1.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.int_rm1.Text = '';
            app.int_rm1.Layout.Row = 3;
            app.int_rm1.Layout.Column = 3;

            % Create belowLabel
            app.belowLabel = uilabel(app.GridLayout6);
            app.belowLabel.HorizontalAlignment = 'center';
            app.belowLabel.Layout.Row = 1;
            app.belowLabel.Layout.Column = 4;
            app.belowLabel.Text = 'below';

            % Create aboveLabel
            app.aboveLabel = uilabel(app.GridLayout6);
            app.aboveLabel.HorizontalAlignment = 'center';
            app.aboveLabel.Layout.Row = 1;
            app.aboveLabel.Layout.Column = 5;
            app.aboveLabel.Text = 'above';

            % Create ry1b
            app.ry1b = uispinner(app.GridLayout6);
            app.ry1b.Limits = [0 100];
            app.ry1b.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.ry1b.Layout.Row = 2;
            app.ry1b.Layout.Column = 4;
            app.ry1b.Value = 5;

            % Create ry1a
            app.ry1a = uispinner(app.GridLayout6);
            app.ry1a.Limits = [0 100];
            app.ry1a.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.ry1a.Layout.Row = 2;
            app.ry1a.Layout.Column = 5;
            app.ry1a.Value = 5;

            % Create rm1b
            app.rm1b = uispinner(app.GridLayout6);
            app.rm1b.Limits = [0 100];
            app.rm1b.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.rm1b.Layout.Row = 3;
            app.rm1b.Layout.Column = 4;
            app.rm1b.Value = 5;

            % Create rm1a
            app.rm1a = uispinner(app.GridLayout6);
            app.rm1a.Limits = [0 100];
            app.rm1a.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.rm1a.Layout.Row = 3;
            app.rm1a.Layout.Column = 5;
            app.rm1a.Value = 5;

            % Create ndorderscatterPanel
            app.ndorderscatterPanel = uipanel(app.GridLayout4);
            app.ndorderscatterPanel.TitlePosition = 'centertop';
            app.ndorderscatterPanel.Title = '2nd order scatter';
            app.ndorderscatterPanel.Layout.Row = 2;
            app.ndorderscatterPanel.Layout.Column = 1;
            app.ndorderscatterPanel.FontName = 'Bahnschrift';

            % Create GridLayout6_2
            app.GridLayout6_2 = uigridlayout(app.ndorderscatterPanel);
            app.GridLayout6_2.ColumnWidth = {'1x', 22, 22, '1x', '1x'};
            app.GridLayout6_2.RowHeight = {22, 22, 22};
            app.GridLayout6_2.Padding = [5 5 5 5];

            % Create cutLabel_2
            app.cutLabel_2 = uilabel(app.GridLayout6_2);
            app.cutLabel_2.Layout.Row = 1;
            app.cutLabel_2.Layout.Column = 2;
            app.cutLabel_2.Text = 'cut';

            % Create intLabel_2
            app.intLabel_2 = uilabel(app.GridLayout6_2);
            app.intLabel_2.Layout.Row = 1;
            app.intLabel_2.Layout.Column = 3;
            app.intLabel_2.Text = 'int.';

            % Create RayleighLabel_2
            app.RayleighLabel_2 = uilabel(app.GridLayout6_2);
            app.RayleighLabel_2.Layout.Row = 2;
            app.RayleighLabel_2.Layout.Column = 1;
            app.RayleighLabel_2.Text = 'Rayleigh';

            % Create RamanLabel_2
            app.RamanLabel_2 = uilabel(app.GridLayout6_2);
            app.RamanLabel_2.Layout.Row = 3;
            app.RamanLabel_2.Layout.Column = 1;
            app.RamanLabel_2.Text = 'Raman';

            % Create cut_ry2
            app.cut_ry2 = uicheckbox(app.GridLayout6_2);
            app.cut_ry2.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.cut_ry2.Text = '';
            app.cut_ry2.Layout.Row = 2;
            app.cut_ry2.Layout.Column = 2;

            % Create int_ry2
            app.int_ry2 = uicheckbox(app.GridLayout6_2);
            app.int_ry2.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.int_ry2.Text = '';
            app.int_ry2.Layout.Row = 2;
            app.int_ry2.Layout.Column = 3;

            % Create cut_rm2
            app.cut_rm2 = uicheckbox(app.GridLayout6_2);
            app.cut_rm2.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.cut_rm2.Text = '';
            app.cut_rm2.Layout.Row = 3;
            app.cut_rm2.Layout.Column = 2;

            % Create int_rm2
            app.int_rm2 = uicheckbox(app.GridLayout6_2);
            app.int_rm2.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.int_rm2.Text = '';
            app.int_rm2.Layout.Row = 3;
            app.int_rm2.Layout.Column = 3;

            % Create belowLabel_2
            app.belowLabel_2 = uilabel(app.GridLayout6_2);
            app.belowLabel_2.HorizontalAlignment = 'center';
            app.belowLabel_2.Layout.Row = 1;
            app.belowLabel_2.Layout.Column = 4;
            app.belowLabel_2.Text = 'below';

            % Create aboveLabel_2
            app.aboveLabel_2 = uilabel(app.GridLayout6_2);
            app.aboveLabel_2.HorizontalAlignment = 'center';
            app.aboveLabel_2.Layout.Row = 1;
            app.aboveLabel_2.Layout.Column = 5;
            app.aboveLabel_2.Text = 'above';

            % Create ry2b
            app.ry2b = uispinner(app.GridLayout6_2);
            app.ry2b.Limits = [0 100];
            app.ry2b.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.ry2b.Layout.Row = 2;
            app.ry2b.Layout.Column = 4;
            app.ry2b.Value = 5;

            % Create ry2a
            app.ry2a = uispinner(app.GridLayout6_2);
            app.ry2a.Limits = [0 100];
            app.ry2a.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.ry2a.Layout.Row = 2;
            app.ry2a.Layout.Column = 5;
            app.ry2a.Value = 5;

            % Create rm2b
            app.rm2b = uispinner(app.GridLayout6_2);
            app.rm2b.Limits = [0 100];
            app.rm2b.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.rm2b.Layout.Row = 3;
            app.rm2b.Layout.Column = 4;

            % Create rm2a
            app.rm2a = uispinner(app.GridLayout6_2);
            app.rm2a.Limits = [0 100];
            app.rm2a.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.rm2a.Layout.Row = 3;
            app.rm2a.Layout.Column = 5;

            % Create miscellaneoussettingsPanel
            app.miscellaneoussettingsPanel = uipanel(app.GridLayout4);
            app.miscellaneoussettingsPanel.TitlePosition = 'centertop';
            app.miscellaneoussettingsPanel.Title = 'miscellaneous settings';
            app.miscellaneoussettingsPanel.Layout.Row = 3;
            app.miscellaneoussettingsPanel.Layout.Column = 1;
            app.miscellaneoussettingsPanel.FontName = 'Bahnschrift';

            % Create GridLayout7
            app.GridLayout7 = uigridlayout(app.miscellaneoussettingsPanel);
            app.GridLayout7.RowHeight = {22, 22, 22};

            % Create n2z
            app.n2z = uicheckbox(app.GridLayout7);
            app.n2z.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.n2z.Text = 'set negative fluorescence values to zero';
            app.n2z.Layout.Row = 1;
            app.n2z.Layout.Column = [1 2];
            app.n2z.Value = true;

            % Create nmdistancetozeroSpinnerLabel
            app.nmdistancetozeroSpinnerLabel = uilabel(app.GridLayout7);
            app.nmdistancetozeroSpinnerLabel.HorizontalAlignment = 'right';
            app.nmdistancetozeroSpinnerLabel.Layout.Row = 2;
            app.nmdistancetozeroSpinnerLabel.Layout.Column = 2;
            app.nmdistancetozeroSpinnerLabel.Text = 'nm distance to zero';

            % Create d2zero
            app.d2zero = uispinner(app.GridLayout7);
            app.d2zero.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.d2zero.Layout.Row = 2;
            app.d2zero.Layout.Column = 1;
            app.d2zero.Value = 20;

            % Create interpolationSwitchLabel
            app.interpolationSwitchLabel = uilabel(app.GridLayout7);
            app.interpolationSwitchLabel.HorizontalAlignment = 'center';
            app.interpolationSwitchLabel.Layout.Row = 3;
            app.interpolationSwitchLabel.Layout.Column = 2;
            app.interpolationSwitchLabel.Text = 'interpolation';

            % Create InterpolationSwitch
            app.InterpolationSwitch = uiswitch(app.GridLayout7, 'slider');
            app.InterpolationSwitch.Items = {'vector', 'inpaint'};
            app.InterpolationSwitch.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.InterpolationSwitch.Layout.Row = 3;
            app.InterpolationSwitch.Layout.Column = 1;
            app.InterpolationSwitch.Value = 'inpaint';

            % Create VISUALIZATIONPanel
            app.VISUALIZATIONPanel = uipanel(app.GridLayout);
            app.VISUALIZATIONPanel.TitlePosition = 'centertop';
            app.VISUALIZATIONPanel.Title = 'VISUALIZATION';
            app.VISUALIZATIONPanel.Layout.Row = [1 2];
            app.VISUALIZATIONPanel.Layout.Column = 2;
            app.VISUALIZATIONPanel.FontName = 'Bahnschrift';
            app.VISUALIZATIONPanel.FontWeight = 'bold';
            app.VISUALIZATIONPanel.FontSize = 16;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.VISUALIZATIONPanel);
            app.GridLayout2.ColumnWidth = {'1x'};
            app.GridLayout2.RowHeight = {'1x'};
            app.GridLayout2.Padding = [5 5 5 5];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout2);
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @triggerRedraw, true);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create scattercenteredspectraTab
            app.scattercenteredspectraTab = uitab(app.TabGroup);
            app.scattercenteredspectraTab.Title = 'scatter-centered spectra';

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.scattercenteredspectraTab);

            % Create firstray
            app.firstray = uiaxes(app.GridLayout5);
            title(app.firstray, '1st order Rayleigh')
            xlabel(app.firstray, 'nm from center')
            ylabel(app.firstray, 'signal')
            zlabel(app.firstray, 'Z')
            app.firstray.Box = 'on';
            app.firstray.TickDir = 'both';
            app.firstray.Layout.Row = 1;
            app.firstray.Layout.Column = 1;

            % Create firstram
            app.firstram = uiaxes(app.GridLayout5);
            title(app.firstram, '1st order Raman')
            xlabel(app.firstram, 'nm from center')
            ylabel(app.firstram, 'signal')
            zlabel(app.firstram, 'Z')
            app.firstram.Box = 'on';
            app.firstram.TickDir = 'both';
            app.firstram.Layout.Row = 1;
            app.firstram.Layout.Column = 2;

            % Create secray
            app.secray = uiaxes(app.GridLayout5);
            title(app.secray, '2nd order Rayleigh')
            xlabel(app.secray, 'nm from center')
            ylabel(app.secray, 'signal')
            zlabel(app.secray, 'Z')
            app.secray.Box = 'on';
            app.secray.TickDir = 'both';
            app.secray.Layout.Row = 2;
            app.secray.Layout.Column = 1;

            % Create secram
            app.secram = uiaxes(app.GridLayout5);
            title(app.secram, '2nd order Raman')
            xlabel(app.secram, 'nm from center')
            ylabel(app.secram, 'signal')
            zlabel(app.secram, 'Z')
            app.secram.Box = 'on';
            app.secram.TickDir = 'both';
            app.secram.Layout.Row = 2;
            app.secram.Layout.Column = 2;

            % Create excitationemissionmatrixTab
            app.excitationemissionmatrixTab = uitab(app.TabGroup);
            app.excitationemissionmatrixTab.Title = 'excitation-emission matrix';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.excitationemissionmatrixTab);
            app.GridLayout3.ColumnWidth = {'1x'};
            app.GridLayout3.RowHeight = {'1x'};

            % Create eem
            app.eem = uiaxes(app.GridLayout3);
            xlabel(app.eem, 'excitation (nm)')
            ylabel(app.eem, 'emission (nm)')
            zlabel(app.eem, 'Z')
            app.eem.PlotBoxAspectRatio = [1.4 1 1];
            app.eem.Box = 'on';
            app.eem.TickDir = 'both';
            app.eem.Layout.Row = 1;
            app.eem.Layout.Column = 1;

            % Create CONTROLPANELPanel
            app.CONTROLPANELPanel = uipanel(app.GridLayout);
            app.CONTROLPANELPanel.TitlePosition = 'centertop';
            app.CONTROLPANELPanel.Title = 'CONTROL PANEL';
            app.CONTROLPANELPanel.Layout.Row = 1;
            app.CONTROLPANELPanel.Layout.Column = 1;
            app.CONTROLPANELPanel.FontName = 'Bahnschrift';
            app.CONTROLPANELPanel.FontWeight = 'bold';
            app.CONTROLPANELPanel.FontSize = 16;

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.CONTROLPANELPanel);
            app.GridLayout8.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.GridLayout8.RowHeight = {22, 22, 22};

            % Create Button
            app.Button = uibutton(app.GridLayout8, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @increaseByOne, true);
            app.Button.Icon = 'next.png';
            app.Button.Tooltip = {'Plot next sample'};
            app.Button.Layout.Row = 1;
            app.Button.Layout.Column = 3;
            app.Button.Text = '';

            % Create Button_2
            app.Button_2 = uibutton(app.GridLayout8, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @decreaseByOne, true);
            app.Button_2.Icon = 'back.png';
            app.Button_2.Tooltip = {'Plot previous sample.'};
            app.Button_2.Layout.Row = 1;
            app.Button_2.Layout.Column = 2;
            app.Button_2.Text = '';

            % Create SampleDropDown
            app.SampleDropDown = uidropdown(app.GridLayout8);
            app.SampleDropDown.ValueChangedFcn = createCallbackFcn(app, @sampleChangedByList, true);
            app.SampleDropDown.Tooltip = {'Select any sample from the dataset for visualization.'};
            app.SampleDropDown.Layout.Row = 1;
            app.SampleDropDown.Layout.Column = 4;

            % Create saveLabel
            app.saveLabel = uilabel(app.GridLayout8);
            app.saveLabel.HorizontalAlignment = 'right';
            app.saveLabel.Layout.Row = 2;
            app.saveLabel.Layout.Column = 1;
            app.saveLabel.Text = 'save:';

            % Create testonLabel
            app.testonLabel = uilabel(app.GridLayout8);
            app.testonLabel.HorizontalAlignment = 'right';
            app.testonLabel.Layout.Row = 1;
            app.testonLabel.Layout.Column = 1;
            app.testonLabel.Text = 'test on:';

            % Create applyButton
            app.applyButton = uibutton(app.GridLayout8, 'push');
            app.applyButton.ButtonPushedFcn = createCallbackFcn(app, @applyAndSwitchFocus, true);
            app.applyButton.Layout.Row = 1;
            app.applyButton.Layout.Column = 5;
            app.applyButton.Text = 'apply';

            % Create plotSwitchLabel
            app.plotSwitchLabel = uilabel(app.GridLayout8);
            app.plotSwitchLabel.HorizontalAlignment = 'center';
            app.plotSwitchLabel.Layout.Row = 3;
            app.plotSwitchLabel.Layout.Column = 1;
            app.plotSwitchLabel.Text = 'plot:';

            % Create plotSwitch
            app.plotSwitch = uiswitch(app.GridLayout8, 'slider');
            app.plotSwitch.Items = {'raw', 'treated'};
            app.plotSwitch.ValueChangedFcn = createCallbackFcn(app, @triggerRedraw, true);
            app.plotSwitch.Layout.Row = 3;
            app.plotSwitch.Layout.Column = [2 4];
            app.plotSwitch.Value = 'treated';

            % Create GridLayout9
            app.GridLayout9 = uigridlayout(app.GridLayout8);
            app.GridLayout9.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout9.RowHeight = {'1x'};
            app.GridLayout9.Padding = [0 0 0 0];
            app.GridLayout9.Layout.Row = 2;
            app.GridLayout9.Layout.Column = [2 4];

            % Create savesettingsButton
            app.savesettingsButton = uibutton(app.GridLayout9, 'push');
            app.savesettingsButton.ButtonPushedFcn = createCallbackFcn(app, @savesettingsButtonPushed, true);
            app.savesettingsButton.Layout.Row = 1;
            app.savesettingsButton.Layout.Column = [1 2];
            app.savesettingsButton.Text = 'save settings';

            % Create applycloseButton
            app.applycloseButton = uibutton(app.GridLayout8, 'push');
            app.applycloseButton.ButtonPushedFcn = createCallbackFcn(app, @applycloseButtonPushed, true);
            app.applycloseButton.Layout.Row = 2;
            app.applycloseButton.Layout.Column = [4 5];
            app.applycloseButton.Text = 'apply & close';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = viewscatter_gui(varargin)

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