classdef viewabsorbance_gui < matlab.apps.AppBase
    %VIEWABSORBANCE_GUI Visually inspect absorbance spectra
    %   <a href = "matlab:doc viewabsorbance">viewabsorbance(data)</a>
    %   
    %   <strong>Inputs - Required</strong>
    %   data (1,1) {mustBeA("drEEMdataset"),drEEMdataset.validate}

    % Properties that correspond to app components
    properties (Access = public)
        viewabsorbanceUIFigure          matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        LeftPanel                       matlab.ui.container.Panel
        GridLayout3                     matlab.ui.container.GridLayout
        SPECTRAFORMATPanel              matlab.ui.container.Panel
        GridLayout6                     matlab.ui.container.GridLayout
        colorbyDropDown                 matlab.ui.control.DropDown
        colorbyDropDownLabel            matlab.ui.control.Label
        DisplayUnitDropDown             matlab.ui.control.DropDown
        DisplayUnitDropDownLabel        matlab.ui.control.Label
        HighlightslopesCheckBox         matlab.ui.control.CheckBox
        Switch                          matlab.ui.control.Switch
        SAMPLECONTROLPanel              matlab.ui.container.Panel
        GridLayout5                     matlab.ui.container.GridLayout
        SampleDropDown                  matlab.ui.control.DropDown
        nshownDropDown                  matlab.ui.control.DropDown
        nshownDropDownLabel             matlab.ui.control.Label
        Button                          matlab.ui.control.Button
        Button_2                        matlab.ui.control.Button
        RightPanel                      matlab.ui.container.Panel
        GridLayout8                     matlab.ui.container.GridLayout
        TabGroup                        matlab.ui.container.TabGroup
        spectra                         matlab.ui.container.Tab
        GridLayout10                    matlab.ui.container.GridLayout
        missingDisclosure               matlab.ui.control.Label
        cdom                            matlab.ui.control.UIAxes
        slopes                          matlab.ui.container.Tab
        GridLayout11                    matlab.ui.container.GridLayout
        slopesPanel                     matlab.ui.container.Panel
        source                          matlab.ui.container.Tab
        GridLayout9                     matlab.ui.container.GridLayout
        GridLayout12                    matlab.ui.container.GridLayout
        autochthonousdilutionlineLabel  matlab.ui.control.Label
        allochthonousdilutionlineLabel  matlab.ui.control.Label
        Label                           matlab.ui.control.Label
        loglogscaleButton               matlab.ui.control.StateButton
        allo                            matlab.ui.control.Spinner
        AllochthonousendmemberSSpinnerLabel  matlab.ui.control.Label
        auto                            matlab.ui.control.Spinner
        AutochthonousendmemberSSpinnerLabel  matlab.ui.control.Label
        sourcediagram                   matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        slopesTable % Description
        data % Description
        state % Description
        maxA375 % Description
    end
    
    methods (Access = private)
        
        function sampleChangedByList(app, event)
            value = app.SampleDropDown.Value;
            value = strsplit(value,{': ',' (i='});
            value = value{2};
            idx=matches(app.data.filelist,value);
            app.state.sample=find(idx);
            app.CDOMspectra;
        end
        
        function CDOMspectra(app)

            localData=app.absorbanceConverter(app.data,app.data.status.absorbanceUnit,app.DisplayUnitDropDown.Value);
            
            cla(app.cdom)
            colorbar(app.cdom,"off")
            yline(app.cdom,0,Color='r',LineWidth=2),hold(app.cdom,'on')
            switch app.nshownDropDown.Value
                case 'one'
                    plot(app.cdom,localData.absWave,localData.abs(app.state.sample,:),Color='k',LineWidth=1.5);
                    if app.HighlightslopesCheckBox.Value
                        hold(app.cdom,"on")

                        e_idx=localData.absWave>300&localData.absWave<600;
                        s1_idx=localData.absWave>275&localData.absWave<295;
                        s2_idx=localData.absWave>350&localData.absWave<400;

                        expsel=localData.abs(app.state.sample,e_idx);
                        s275sel=localData.abs(app.state.sample,s1_idx);
                        s350sel=localData.abs(app.state.sample,s2_idx);

                        plot(app.cdom,localData.absWave(e_idx),expsel,LineWidth=2,color='r')
                        plot(app.cdom,localData.absWave(s1_idx),s275sel,LineWidth=3,color='b')
                        plot(app.cdom,localData.absWave(s2_idx),s350sel,LineWidth=3,color='b')

                    end
                case 'all'
                    if matches(app.colorbyDropDown.Value,'nothing')
                        app.missingDisclosure.Visible="off";
                        plot(app.cdom,localData.absWave,localData.abs,Color='k',LineWidth=1.5);
                    else
                        fld=app.colorbyDropDown.Value;
                        md=localData.metadata.(fld);
                        switch class(md)
                            case {'categorical','cell','double'}
                                h=plot(app.cdom,localData.absWave,localData.abs,Color='k',LineWidth=1.5);
                                col=app.gcolor(md);
                                set(h, {'color'}, num2cell(col,2));
                            otherwise
                                error('unknown metadata class')
                        end

                        if numel(unique(md))<15
                            mode='few';
                            app.glegend(app.cdom,app.gcolor(unique(md)),unique(md));
                            
                        else
                            mode='lots';
                            app.missingDisclosure.Visible="on";
                            legend(app.cdom,'off')
                            ncat=numel(unique(md));
                            if ncat<50
                                samples=ncat;
                            elseif ncat<100
                                samples=10;
                            else
                                samples=5;
                            end

                            switch class(md)
                                case 'categorical'
                                    colormap(app.cdom,app.gcolor(unique(md)))
                                    c=colorbar(app.cdom);
                                    cats=categories(unique(md));
                                    clim(app.cdom,[1 max(round(linspace(1,numel(cats),samples)))])
                                    c.Ticks=round(linspace(1,numel(cats),samples));
                                    c.TickLabels=cats(round(linspace(1,numel(cats),samples)));
                                    ylabel(c,fld,'Interpreter','none')
                                case 'double'
                                    colormap(app.cdom,app.gcolor(unique(md)))
                                    c = colorbar(app.cdom);
                                    ylabel(c,fld,'Interpreter','none')
                                    try
                                        clim(app.cdom,[min(unique(md),[],"omitnan") max(unique(md),[],"omitnan")])
                                    catch ME
                                        delete(c)
                                        warning(ME.message)
                                    end

                            end
                        end

                    end
            end
            switch app.Switch.Value
                case 'linear'
                    set(app.cdom,YScale='linear')
                case 'log'
                    warning off
                    set(app.cdom,YScale='log')
                    warning on
            end
            ylabel(app.cdom,app.DisplayUnitDropDown.Value)
            
        end
        
        function a375vS(app)
            cla(app.sourcediagram)
            colorbar(app.sourcediagram,'off')
            legend(app.sourcediagram,'off')
            m = @(x) app.auto.Value + 1.1./x; % Model with marine endmember
            mt = @(x) app.allo.Value + 1.1./x; % Model with the terrestrial endmember
            pred= linspace(0.03,app.maxA375,500);
            
            hm(1)=plot(app.sourcediagram,pred,m(pred),Color=[0 0.6 1], ...
                DisplayName='autochthonous dilution line',LineWidth=2);
            hold(app.sourcediagram,"on")
            hm(2)=plot(app.sourcediagram,pred,mt(pred),Color=[0.675 0.557 0.251], ...
                DisplayName='allochthonous dilution line',LineWidth=2);

            localData=app.absorbanceConverter(app.data,app.data.status.absorbanceUnit,"naperian absorption coefficient");
            a375=localData.abs(:,drEEMtoolbox.mindist(app.data.absWave,375));
                        

            if matches(app.colorbyDropDown.Value,'nothing')
                scatter(app.sourcediagram,a375,app.data.opticalMetadata.exp_slope_microm,35,'k',"filled",MarkerEdgeColor='k');
            else
                fld=app.colorbyDropDown.Value;
                md=app.data.metadata.(fld);

                if numel(unique(md))<15
                    %'few';
                    scatter(app.sourcediagram,a375,app.data.opticalMetadata.exp_slope_microm,35,app.gcolor(md),"filled",MarkerEdgeColor='k');
                    app.glegend(app.sourcediagram,app.gcolor(unique(md)),unique(md));

                else
                    %'lots';
                    scatter(app.sourcediagram,a375,app.data.opticalMetadata.exp_slope_microm,35,md,"filled",MarkerEdgeColor='k');
                    legend(app.sourcediagram,'off')
                    ncat=numel(unique(md));
                    if ncat<50
                        samples=ncat;
                    elseif ncat<100
                        samples=10;
                    else
                        samples=5;
                    end

                    switch class(md)
                        case 'categorical'
                            %colormap(app.sourcediagram,app.gcolor(unique(md)))
                            c=colorbar(app.sourcediagram);
                            cats=categories(unique(md));
                            clim(app.sourcediagram,[1 max(round(linspace(1,numel(cats),samples)))])
                            c.Ticks=round(linspace(1,numel(cats),samples));
                            c.TickLabels=cats(round(linspace(1,numel(cats),samples)));
                            ylabel(c,fld,'Interpreter','none')
                        case 'double'
                            %colormap(app.sourcediagram,app.gcolor(unique(md)))
                            c = colorbar(app.sourcediagram);
                            ylabel(c,fld,'Interpreter','none')
                            try
                                clim(app.sourcediagram,[min(unique(md),[],"omitnan") max(unique(md),[],"omitnan")])
                            catch ME
                                delete(c)
                                warning(ME.message)
                            end

                    end
                end

            end

            %legend(hm,Location="northoutside",NumColumns=2)
            if app.loglogscaleButton.Value
                set(app.sourcediagram,yScale='log',xscale='log')
            else
                set(app.sourcediagram,yScale='linear',xscale='linear')
            end
            set(app.sourcediagram,YLim=[app.auto.Value-2 max(mt(pred)+1)])
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
            
            switch class(c)
                case 'categorical'
                    idx=ismissing(c);
                case 'double'
                    idx=ismissing(c);
            end

            colmap(idx,:)=repmat([0 0 0],sum(idx),1);

        end
        
        function h = glegend(app,ax,gcol,titles)


            [~,i] = unique(gcol,'stable','rows');

            cols=gcol(i,:);


            hold(ax,'on');
            for j=1:numel(i)

                h(j)=plot(ax,[nan nan],[nan nan], ...
                    LineStyle='-',Color=cols(j,:), ...
                    LineWidth=4);

            end
            
            if isnumeric(titles)
                titles=cellstr(num2str(titles));
            end
            h=legend(h,titles);
            h.ItemTokenSize=[10 6];
        end
        
        function dataout = absorbanceConverter(app,data,unitIn,unitOut)
            arguments
                app
                data (1,1) {mustBeA(data,'drEEMdataset')}
                unitIn (1,:) {mustBeText(unitIn),mustBeMember(unitIn,["absorbance per cm","absorbance per 5 cm","absorbance per 10 cm","Napierian absorption coefficient","Linear decadic absorption coefficient"])}
                unitOut (1,:) {mustBeText(unitOut),mustBeMember(unitOut,["per cm","decadal absorption coefficient","naperian absorption coefficient"])}
            end
            dataout=data;
            switch unitIn
                case "absorbance per cm"
                    switch unitOut
                        case "per cm"
                            return
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs./0.01;
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./0.01.*2.303;
                    end
                case "absorbance per 5 cm"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs./5;
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs./5./0.01;
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./5./0.01.*2.303;
                    end
                case "absorbance per 10 cm"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs./10;
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs./10./0.01;
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./10./0.01.*2.303;
                    end
                case "Napierian absorption coefficient"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs.*0.01./2.303;
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs.*2.303;
                        case "naperian absorption coefficient"
                            return
                    end
                case "Linear decadic absorption coefficient"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs.*0.01;
                        case "decadal absorption coefficient"
                            return
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./2.303;
                    end
            end
        end
        
        function slopesPlots(app)
            dataHere=app.data;
            t=tiledlayout(app.slopesPanel);

            ax=nexttile(t);
            boxchart(ax, ...
                [dataHere.opticalMetadata.exp_slope_microm, ...
                dataHere.opticalMetadata.S_275_295, ...
                dataHere.opticalMetadata.S_350_400], ...
                BoxFaceColor='k')
            ylabel(ax,'Slope values (µm^{-1})',Interpreter='tex')
            set(ax,XTick=categorical(1:3),XTickLabel={'S','S_{275-295}','S_{350-400}'})
            ax=nexttile(t);
            plot(ax,dataHere.i,dataHere.opticalMetadata.exp_slope_microm, ...
                Marker='.',LineStyle='none',MarkerSize=20,MarkerEdgeColor='k')
            ylabel(ax,'S (µm^{-1})',Interpreter='tex')
            title(ax,'S',Interpreter='tex')
            ax=nexttile(t);
            plot(ax,dataHere.i,dataHere.opticalMetadata.S_275_295, ...
                Marker='.',LineStyle='none',MarkerSize=20,MarkerEdgeColor='k')
            ylabel(ax,'S_{275-295} (µm^{-1})',Interpreter='tex')
            title(ax,'S_{275-295}',Interpreter='tex')

            ax=nexttile(t);
            plot(ax,dataHere.i,dataHere.opticalMetadata.S_350_400, ...
                Marker='.',LineStyle='none',MarkerSize=20,MarkerEdgeColor='k')
            ylabel(ax,'S_{350-400} (µm^{-1})',Interpreter='tex')
            title(ax,'S_{350-400}',Interpreter='tex')
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
            movegui(app.viewabsorbanceUIFigure,"center")
            data=drEEMtoolbox.fitslopes(data,plot=false,details=false,quiet=true);
            app.data=data;
            temp=app.absorbanceConverter(data,data.status.absorbanceUnit,"naperian absorption coefficient");
            app.maxA375=max(temp.abs(:,drEEMtoolbox.mindist(data.absWave,375)),[],"omitmissing");

            metafld=[{'nothing'} app.data.metadata.Properties.VariableNames];
            app.colorbyDropDown.Items=metafld;
            fnames = app.data.filelist;
            idx    = cellstr(num2str((1:app.data.nSample)'));
            i      = cellstr(num2str(app.data.i));
            fnames = cellfun(@(a,b,c) [a,': ',b,' (i=',c,')'],idx,fnames,i,uni=false);
            app.SampleDropDown.Items=fnames;
            app.SampleDropDown.Items;
            app.nshownDropDownValueChanged;
            app.sampleChangedByList;
            app.CDOMspectra;
            app.a375vS;
            app.slopesPlots;

            

            



            
        end

        % Button pushed function: Button_2
        function decreaseByOne(app, event)
            if app.state.sample>1
                app.state.sample=app.state.sample-1;
                app.CDOMspectra;

                app.SampleDropDown.Value=app.SampleDropDown.Items{app.state.sample};
            end
        end

        % Button pushed function: Button
        function increaseByOne(app, event)
            if app.state.sample<app.data.nSample
                app.state.sample=app.state.sample+1;
                app.CDOMspectra;
                
                app.SampleDropDown.Value=app.SampleDropDown.Items{app.state.sample};
            end
        end

        % Value changed function: Switch
        function SwitchValueChanged(app, event)
            app.CDOMspectra;
        end

        % Value changed function: nshownDropDown
        function nshownDropDownValueChanged(app, event)
            switch app.nshownDropDown.Value
                case 'one'
                    app.SampleDropDown.Enable="on";
                    app.Button_2.Enable="on";
                    app.Button.Enable="on";
                    app.HighlightslopesCheckBox.Enable="on";
                case 'all'
                    app.SampleDropDown.Enable="off";
                    app.Button_2.Enable="off";
                    app.Button.Enable="off";
                    app.HighlightslopesCheckBox.Enable="off";
                    app.HighlightslopesCheckBox.Value=false;
            end
            app.CDOMspectra;
            
        end

        % Value changed function: DisplayUnitDropDown
        function DisplayUnitDropDownValueChanged(app, event)
            app.CDOMspectra;
        end

        % Value changed function: colorbyDropDown
        function colorbyDropDownValueChanged(app, event)
            app.CDOMspectra;
            app.a375vS;
            
        end

        % Value changed function: allo, auto, loglogscaleButton
        function autoValueChanged(app, event)
            app.a375vS;
            
        end

        % Value changed function: HighlightslopesCheckBox
        function HighlightslopesCheckBoxValueChanged(app, event)
            app.CDOMspectra;
            
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.viewabsorbanceUIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {489, 489};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {260, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create viewabsorbanceUIFigure and hide until all components are created
            app.viewabsorbanceUIFigure = uifigure('Visible', 'off');
            app.viewabsorbanceUIFigure.AutoResizeChildren = 'off';
            colormap(app.viewabsorbanceUIFigure, 'turbo');
            app.viewabsorbanceUIFigure.Position = [100 100 828 489];
            app.viewabsorbanceUIFigure.Name = 'viewabsorbance';
            app.viewabsorbanceUIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.viewabsorbanceUIFigure);
            app.GridLayout.ColumnWidth = {260, '1x'};
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
            app.GridLayout3.ColumnWidth = {241};
            app.GridLayout3.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout3.Padding = [0 10 0 10];

            % Create SAMPLECONTROLPanel
            app.SAMPLECONTROLPanel = uipanel(app.GridLayout3);
            app.SAMPLECONTROLPanel.Title = 'SAMPLE CONTROL';
            app.SAMPLECONTROLPanel.Layout.Row = 1;
            app.SAMPLECONTROLPanel.Layout.Column = 1;
            app.SAMPLECONTROLPanel.FontName = 'Bahnschrift';
            app.SAMPLECONTROLPanel.FontWeight = 'bold';
            app.SAMPLECONTROLPanel.FontSize = 15;

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.SAMPLECONTROLPanel);
            app.GridLayout5.RowHeight = {30, 30, 30};

            % Create Button_2
            app.Button_2 = uibutton(app.GridLayout5, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @decreaseByOne, true);
            app.Button_2.Icon = 'back.png';
            app.Button_2.Tooltip = {'Plot previous sample.'};
            app.Button_2.Layout.Row = 2;
            app.Button_2.Layout.Column = 1;
            app.Button_2.Text = '';

            % Create Button
            app.Button = uibutton(app.GridLayout5, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @increaseByOne, true);
            app.Button.Icon = 'next.png';
            app.Button.Tooltip = {'Plot next sample'};
            app.Button.Layout.Row = 2;
            app.Button.Layout.Column = 2;
            app.Button.Text = '';

            % Create nshownDropDownLabel
            app.nshownDropDownLabel = uilabel(app.GridLayout5);
            app.nshownDropDownLabel.HorizontalAlignment = 'right';
            app.nshownDropDownLabel.Layout.Row = 3;
            app.nshownDropDownLabel.Layout.Column = 1;
            app.nshownDropDownLabel.Text = 'n shown';

            % Create nshownDropDown
            app.nshownDropDown = uidropdown(app.GridLayout5);
            app.nshownDropDown.Items = {'all', 'one'};
            app.nshownDropDown.ValueChangedFcn = createCallbackFcn(app, @nshownDropDownValueChanged, true);
            app.nshownDropDown.Layout.Row = 3;
            app.nshownDropDown.Layout.Column = 2;
            app.nshownDropDown.Value = 'all';

            % Create SampleDropDown
            app.SampleDropDown = uidropdown(app.GridLayout5);
            app.SampleDropDown.Layout.Row = 1;
            app.SampleDropDown.Layout.Column = [1 2];

            % Create SPECTRAFORMATPanel
            app.SPECTRAFORMATPanel = uipanel(app.GridLayout3);
            app.SPECTRAFORMATPanel.Title = 'SPECTRA FORMAT';
            app.SPECTRAFORMATPanel.Layout.Row = [2 3];
            app.SPECTRAFORMATPanel.Layout.Column = 1;
            app.SPECTRAFORMATPanel.FontName = 'Bahnschrift';
            app.SPECTRAFORMATPanel.FontWeight = 'bold';
            app.SPECTRAFORMATPanel.FontSize = 15;

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.SPECTRAFORMATPanel);
            app.GridLayout6.RowHeight = {30, 30, 30, 30};

            % Create Switch
            app.Switch = uiswitch(app.GridLayout6, 'slider');
            app.Switch.Items = {'linear', 'log'};
            app.Switch.ValueChangedFcn = createCallbackFcn(app, @SwitchValueChanged, true);
            app.Switch.Layout.Row = 1;
            app.Switch.Layout.Column = [1 2];
            app.Switch.Value = 'linear';

            % Create HighlightslopesCheckBox
            app.HighlightslopesCheckBox = uicheckbox(app.GridLayout6);
            app.HighlightslopesCheckBox.ValueChangedFcn = createCallbackFcn(app, @HighlightslopesCheckBoxValueChanged, true);
            app.HighlightslopesCheckBox.Text = 'Highlight slopes';
            app.HighlightslopesCheckBox.Layout.Row = 2;
            app.HighlightslopesCheckBox.Layout.Column = [1 2];

            % Create DisplayUnitDropDownLabel
            app.DisplayUnitDropDownLabel = uilabel(app.GridLayout6);
            app.DisplayUnitDropDownLabel.HorizontalAlignment = 'right';
            app.DisplayUnitDropDownLabel.Layout.Row = 3;
            app.DisplayUnitDropDownLabel.Layout.Column = 1;
            app.DisplayUnitDropDownLabel.Text = 'Display Unit';

            % Create DisplayUnitDropDown
            app.DisplayUnitDropDown = uidropdown(app.GridLayout6);
            app.DisplayUnitDropDown.Items = {'per cm', 'decadal absorption coefficient', 'naperian absorption coefficient'};
            app.DisplayUnitDropDown.ValueChangedFcn = createCallbackFcn(app, @DisplayUnitDropDownValueChanged, true);
            app.DisplayUnitDropDown.Layout.Row = 3;
            app.DisplayUnitDropDown.Layout.Column = 2;
            app.DisplayUnitDropDown.Value = 'per cm';

            % Create colorbyDropDownLabel
            app.colorbyDropDownLabel = uilabel(app.GridLayout6);
            app.colorbyDropDownLabel.HorizontalAlignment = 'right';
            app.colorbyDropDownLabel.Layout.Row = 4;
            app.colorbyDropDownLabel.Layout.Column = 1;
            app.colorbyDropDownLabel.Text = 'color by';

            % Create colorbyDropDown
            app.colorbyDropDown = uidropdown(app.GridLayout6);
            app.colorbyDropDown.ValueChangedFcn = createCallbackFcn(app, @colorbyDropDownValueChanged, true);
            app.colorbyDropDown.Layout.Row = 4;
            app.colorbyDropDown.Layout.Column = 2;

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.RightPanel);
            app.GridLayout8.ColumnWidth = {'1x'};
            app.GridLayout8.RowHeight = {'1x'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout8);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create spectra
            app.spectra = uitab(app.TabGroup);
            app.spectra.Title = 'ABSORBANCE SPECTRA';

            % Create GridLayout10
            app.GridLayout10 = uigridlayout(app.spectra);
            app.GridLayout10.ColumnWidth = {'1x'};
            app.GridLayout10.RowHeight = {30, '1x'};

            % Create cdom
            app.cdom = uiaxes(app.GridLayout10);
            xlabel(app.cdom, 'Wavelength (nm)')
            zlabel(app.cdom, 'Z')
            app.cdom.Box = 'on';
            app.cdom.TickDir = 'both';
            app.cdom.Layout.Row = 2;
            app.cdom.Layout.Column = 1;

            % Create missingDisclosure
            app.missingDisclosure = uilabel(app.GridLayout10);
            app.missingDisclosure.HorizontalAlignment = 'right';
            app.missingDisclosure.VerticalAlignment = 'bottom';
            app.missingDisclosure.FontSize = 10;
            app.missingDisclosure.FontWeight = 'bold';
            app.missingDisclosure.FontAngle = 'italic';
            app.missingDisclosure.Visible = 'off';
            app.missingDisclosure.Layout.Row = 1;
            app.missingDisclosure.Layout.Column = 1;
            app.missingDisclosure.Text = 'black lines = missing metadata (ignore colorbar space)';

            % Create slopes
            app.slopes = uitab(app.TabGroup);
            app.slopes.Title = 'SLOPES';

            % Create GridLayout11
            app.GridLayout11 = uigridlayout(app.slopes);
            app.GridLayout11.ColumnWidth = {'1x'};
            app.GridLayout11.RowHeight = {'1x'};

            % Create slopesPanel
            app.slopesPanel = uipanel(app.GridLayout11);
            app.slopesPanel.Layout.Row = 1;
            app.slopesPanel.Layout.Column = 1;

            % Create source
            app.source = uitab(app.TabGroup);
            app.source.Title = 'OTHER';

            % Create GridLayout9
            app.GridLayout9 = uigridlayout(app.source);
            app.GridLayout9.ColumnWidth = {'1x'};
            app.GridLayout9.RowHeight = {'1x'};

            % Create GridLayout12
            app.GridLayout12 = uigridlayout(app.GridLayout9);
            app.GridLayout12.ColumnWidth = {'1x', '1x', 70, '1x', 70};
            app.GridLayout12.RowHeight = {30, 30, '1x', '1x'};
            app.GridLayout12.Layout.Row = 1;
            app.GridLayout12.Layout.Column = 1;

            % Create sourcediagram
            app.sourcediagram = uiaxes(app.GridLayout12);
            title(app.sourcediagram, 'CDOM Source diagram')
            xlabel(app.sourcediagram, 'Naperian absorption coefficient at 375 nm (m^{-1})')
            ylabel(app.sourcediagram, 'S (µm^{-1})')
            zlabel(app.sourcediagram, 'Z')
            app.sourcediagram.Box = 'on';
            app.sourcediagram.TickDir = 'both';
            app.sourcediagram.Layout.Row = [3 4];
            app.sourcediagram.Layout.Column = [1 5];

            % Create AutochthonousendmemberSSpinnerLabel
            app.AutochthonousendmemberSSpinnerLabel = uilabel(app.GridLayout12);
            app.AutochthonousendmemberSSpinnerLabel.HorizontalAlignment = 'right';
            app.AutochthonousendmemberSSpinnerLabel.WordWrap = 'on';
            app.AutochthonousendmemberSSpinnerLabel.Layout.Row = 1;
            app.AutochthonousendmemberSSpinnerLabel.Layout.Column = 2;
            app.AutochthonousendmemberSSpinnerLabel.Text = 'Autochthonous endmember S';

            % Create auto
            app.auto = uispinner(app.GridLayout12);
            app.auto.Step = 0.1;
            app.auto.Limits = [1 10];
            app.auto.ValueChangedFcn = createCallbackFcn(app, @autoValueChanged, true);
            app.auto.Layout.Row = 1;
            app.auto.Layout.Column = 3;
            app.auto.Value = 7.4;

            % Create AllochthonousendmemberSSpinnerLabel
            app.AllochthonousendmemberSSpinnerLabel = uilabel(app.GridLayout12);
            app.AllochthonousendmemberSSpinnerLabel.HorizontalAlignment = 'right';
            app.AllochthonousendmemberSSpinnerLabel.WordWrap = 'on';
            app.AllochthonousendmemberSSpinnerLabel.Layout.Row = 1;
            app.AllochthonousendmemberSSpinnerLabel.Layout.Column = 4;
            app.AllochthonousendmemberSSpinnerLabel.Text = 'Allochthonous endmember S';

            % Create allo
            app.allo = uispinner(app.GridLayout12);
            app.allo.Step = 0.1;
            app.allo.Limits = [10 25];
            app.allo.ValueChangedFcn = createCallbackFcn(app, @autoValueChanged, true);
            app.allo.Layout.Row = 1;
            app.allo.Layout.Column = 5;
            app.allo.Value = 17.4;

            % Create loglogscaleButton
            app.loglogscaleButton = uibutton(app.GridLayout12, 'state');
            app.loglogscaleButton.ValueChangedFcn = createCallbackFcn(app, @autoValueChanged, true);
            app.loglogscaleButton.Text = 'log-log scale';
            app.loglogscaleButton.Layout.Row = 1;
            app.loglogscaleButton.Layout.Column = 1;

            % Create Label
            app.Label = uilabel(app.GridLayout12);
            app.Label.Layout.Row = 4;
            app.Label.Layout.Column = 1;

            % Create allochthonousdilutionlineLabel
            app.allochthonousdilutionlineLabel = uilabel(app.GridLayout12);
            app.allochthonousdilutionlineLabel.HorizontalAlignment = 'center';
            app.allochthonousdilutionlineLabel.FontWeight = 'bold';
            app.allochthonousdilutionlineLabel.FontColor = [0.6706 0.5608 0.251];
            app.allochthonousdilutionlineLabel.Layout.Row = 2;
            app.allochthonousdilutionlineLabel.Layout.Column = [4 5];
            app.allochthonousdilutionlineLabel.Text = 'allochthonous dilution line';

            % Create autochthonousdilutionlineLabel
            app.autochthonousdilutionlineLabel = uilabel(app.GridLayout12);
            app.autochthonousdilutionlineLabel.HorizontalAlignment = 'center';
            app.autochthonousdilutionlineLabel.FontWeight = 'bold';
            app.autochthonousdilutionlineLabel.FontColor = [0 0.6 1];
            app.autochthonousdilutionlineLabel.Layout.Row = 2;
            app.autochthonousdilutionlineLabel.Layout.Column = [1 2];
            app.autochthonousdilutionlineLabel.Text = 'autochthonous dilution line';

            % Show the figure after all components are created
            app.viewabsorbanceUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = viewabsorbance_gui(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.viewabsorbanceUIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.viewabsorbanceUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.viewabsorbanceUIFigure)
        end
    end
end