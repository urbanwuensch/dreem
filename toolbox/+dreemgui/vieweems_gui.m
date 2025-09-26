classdef vieweems_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        drEEMtoolboxvieweemsUIFigure   matlab.ui.Figure
        MainGrid                       matlab.ui.container.GridLayout
        Panel                          matlab.ui.container.Panel
        GridLayout6                    matlab.ui.container.GridLayout
        DSPECTRAPanel                  matlab.ui.container.Panel
        GridLayout9                    matlab.ui.container.GridLayout
        em                             matlab.ui.control.UIAxes
        ex                             matlab.ui.control.UIAxes
        EXCITATIONEMISSIONMATRIXPanel  matlab.ui.container.Panel
        GridLayout8                    matlab.ui.container.GridLayout
        rotateButton                   matlab.ui.control.StateButton
        datacursorButton               matlab.ui.control.StateButton
        colorlimitpercentilesLabel     matlab.ui.control.Label
        colorLimitSlider               matlab.ui.control.RangeSlider
        eem                            matlab.ui.control.UIAxes
        SettingsPanel                  matlab.ui.container.Panel
        GridLayout                     matlab.ui.container.GridLayout
        SPECTRAFORMATPanel             matlab.ui.container.Panel
        GridLayout5                    matlab.ui.container.GridLayout
        LegendLabel                    matlab.ui.control.Label
        GridLayout11                   matlab.ui.container.GridLayout
        Image3                         matlab.ui.control.Image
        Image2                         matlab.ui.control.Image
        Image                          matlab.ui.control.Image
        showscatterpositionCheckBox    matlab.ui.control.CheckBox
        showabsorbanceCheckBox         matlab.ui.control.CheckBox
        rememberselectionCheckBox      matlab.ui.control.CheckBox
        holdonCheckBox                 matlab.ui.control.CheckBox
        EEMFORMATPanel                 matlab.ui.container.Panel
        GridLayout4                    matlab.ui.container.GridLayout
        showindicesCheckBox            matlab.ui.control.CheckBox
        showCoblePeaksCheckBox         matlab.ui.control.CheckBox
        remembercolorlimitsCheckBox    matlab.ui.control.CheckBox
        rememberrotationCheckBox       matlab.ui.control.CheckBox
        contoursEditField              matlab.ui.control.NumericEditField
        contoursEditFieldLabel         matlab.ui.control.Label
        ColormapDropDown               matlab.ui.control.DropDown
        ColormapDropDownLabel          matlab.ui.control.Label
        SAMPLECONTROLPanel             matlab.ui.container.Panel
        GridLayout3                    matlab.ui.container.GridLayout
        SampleDropDown                 matlab.ui.control.DropDown
        SampleDropDownLabel            matlab.ui.control.Label
        componentsDropDown             matlab.ui.control.DropDown
        componentsDropDownLabel        matlab.ui.control.Label
        DatatypeDropDown               matlab.ui.control.DropDown
        DatatypeDropDownLabel          matlab.ui.control.Label
        GridLayout10                   matlab.ui.container.GridLayout
        Button_2                       matlab.ui.control.Button
        Button                         matlab.ui.control.Button
        Button_3                       matlab.ui.control.Button
        ContextMenu                    matlab.ui.container.ContextMenu
        SavefigurepanelasimageMenu     matlab.ui.container.Menu
    end

    
    properties (Access = private)
        data % The data
        state % information about the state of the app
        plotData % matrix of data that is / will be plotted
        viewangle % rotation of axis
        rclim % relative color limit (0-100%)
        aclim % absolute color limit
        ExEm % Description
        cmapOld % Description
    end
    
    methods (Access = private)
        
        

        
        
        function results = dataExtractor(app)

            switch app.DatatypeDropDown.Value
                case "data"
                    results=app.data.X;
                case "model"
                    c=str2double(app.componentsDropDown.Value);
                    results=nway.modeleval.nmodel(app.data.models(c).loads);
                case "residuals"
                    c=str2double(app.componentsDropDown.Value);
                    X=app.data.X;
                    Xm=nway.modeleval.nmodel(app.data.models(c).loads);
                    results=X-Xm;
            end
            results=squeeze(results(app.state.sample,:,:));
            app.SampleDropDown.Value=app.SampleDropDown.Items(app.state.sample);

            
        end
        
        function ploteem(app)
            x=app.data.Ex;
            y=app.data.Em;
            mat=app.plotData;


             % Start plotting stuff
            hold(app.eem,'off')
            switch app.DatatypeDropDown.Value
                case {'data','model'}
                    % After switch from residuals, restore old colormap
                    if not(isempty(app.cmapOld))
                        app.ColormapDropDown.Value=app.cmapOld;
                        app.cmapOld=[];
                    end
                    app.colorLimitSlider.Enable="on";
                    sc = surfc(app.eem,x,y,mat,...
                        'EdgeColor','none','FaceColor','flat');
                    view(app.eem,app.viewangle)
                    sc(2).ZLocation = 'zmax';
                    sc(2).LineColor='k';
                    sc(2).LineWidth = 0.5;
                    sc(2).LevelList=linspace(min(mat(~isnan(mat))),max(mat(~isnan(mat))),app.contoursEditField.Value);
                    switch app.ColormapDropDown.Value
                        case 'blue-red'
                            colormap(app.eem,app.residualcolormap(50,50))
                        otherwise
                            colormap(app.eem,app.ColormapDropDown.Value);
                    end
                    zlim(app.eem,[min(mat(~isnan(mat))),max(mat(~isnan(mat)))])
                    clim(app.eem,app.aclim)
                    app.ColormapDropDown.Enable='on';
                case 'residuals'
                    app.colorLimitSlider.Enable="off";
                    sc = surfc(app.eem,x,y,mat,'EdgeColor','none','FaceColor','flat');
                    view(app.eem,app.viewangle)
                    app.eem.ZLim(2) = max(mat(~isnan(mat)));
                    sc(2).ZLocation = 'zmax';
                    sc(2).LineColor='k';
                    sc(2).LevelList=linspace(min(mat(~isnan(mat))),max(mat(~isnan(mat))),app.contoursEditField.Value);
                    
                    clim(app.eem,app.aclim)
                    zlim(app.eem,app.aclim)
                    levels=linspace(app.aclim(1),app.aclim(2),100);
                    n_neg=sum(levels<0);
                    n_pos=sum(levels>0);
                    colormap(app.eem,app.residualcolormap(n_neg,n_pos))
                    app.cmapOld=app.ColormapDropDown.Value;
                    app.ColormapDropDown.Value='blue-red';
                    app.ColormapDropDown.Enable='off';
            end
            %title(app.eem,app.data.filelist(app.state.sample))
            colorbar(app.eem)
            
            % store the viewangle after plotting
            app.storeViewangle;

        end
   

        function map = residualcolormap(app,nneg,npos)
            % ncol=ceil(round(ncol)/2);
            nmap=[linspace(0,1,nneg)' linspace(0.45,1,nneg)' linspace(0.737,1,nneg)'];
            pmap=flipud([flipud(linspace(1,0.686,npos)') flipud(linspace(1,0.208,npos)') flipud(linspace(1,0.278,npos)')]);
            map=[nmap;pmap];

        end
        
        function plotPeaks(app)
            % Formatting
            lw=1.5;
            OnOff=app.showCoblePeaksCheckBox.Value;
            col=[0 0 0];
            marker='+';
            markersize=20;
            
            % Definition of peaks
            peaks(1).name=cellstr('B');
            peaks(1).Em=num2cell(305);
            peaks(1).Ex=num2cell(275);
            peaks(2).name=cellstr('T');
            peaks(2).Em=num2cell(340);
            peaks(2).Ex=num2cell(275);
            peaks(3).name=cellstr('A');
            peaks(3).Em=num2cell(400:460);
            peaks(3).Ex=num2cell(260);
            peaks(4).name=cellstr('M');
            peaks(4).Em=num2cell(370:410);
            peaks(4).Ex=num2cell(290:310);
            peaks(5).name=cellstr('C');
            peaks(5).Em=num2cell(420:460);
            peaks(5).Ex=num2cell(320:360);
            peaks(6).name=cellstr('D');
            peaks(6).Em=num2cell(509);
            peaks(6).Ex=num2cell(390);
            peaks(7).name=cellstr('N');
            peaks(7).Em=num2cell(370);
            peaks(7).Ex=num2cell(280);
            if OnOff
                hold(app.eem,'on')
                for j=1:size(peaks,2)
                    if isscalar(peaks(j).Em)&&isscalar(peaks(j).Ex)
                        Labels = peaks(j).name;
                        plot3(app.eem,peaks(j).Ex{1},peaks(j).Em{1},app.eem.ZLim(2),marker,'MarkerSize',markersize,'LineWidth',lw,'Color',col,'DisplayName','PeaksOverlayed')
                        text(app.eem,peaks(j).Ex{1}+0.1,peaks(j).Em{1}+0.1,app.eem.ZLim(2), Labels, 'horizontal','left', 'vertical','bottom','Color',col,'DisplayName','PeaksOverlayed');


                    elseif isscalar(peaks(j).Ex)&&numel(peaks(j).Em)>1
                        idx=drEEMtoolbox.mindist(app.data.Em,peaks(j).Em{1}):drEEMtoolbox.mindist(app.data.Em,peaks(j).Em{end});
                        tempEm=app.data.Em(idx,1);
                        Labels = peaks(j).name;

                        plot3(app.eem,repmat(peaks(j).Ex{1},numel(tempEm)),tempEm,repelem(app.eem.ZLim(2),numel(tempEm),1),'LineWidth',lw,'Color',col,'DisplayName','PeaksOverlayed')
                        text(app.eem,peaks(j).Ex{1}+0.1,peaks(j).Em{1}+0.1,app.eem.ZLim(2), Labels, 'horizontal','left', 'vertical','bottom','Color',col,'DisplayName','PeaksOverlayed');


                    else
                        x1=peaks(j).Ex{1};
                        x2=peaks(j).Ex{end};
                        y1=peaks(j).Em{1};
                        y2=peaks(j).Em{end};
                        x = [x1, x2, x2, x1, x1];
                        y = [y1, y1, y2, y2, y1];
                        Labels = peaks(j).name;
                        plot3(app.eem,x, y , repelem(app.eem.ZLim(2),numel(y),1), 'b-', 'LineWidth', lw,'Color',col,'DisplayName','PeaksOverlayed');
                        text(app.eem,peaks(j).Ex{1}+0.1,peaks(j).Em{1}+0.1,app.eem.ZLim(2), Labels, 'horizontal','left', 'vertical','bottom','Color',col,'DisplayName','PeaksOverlayed');
                    end
                end
                hold(app.eem,'off')
            else
                hc=get(app.eem,'Children');
                for n=1:numel(hc)
                    if ~isempty(strfind(hc(n).DisplayName,'PeaksOverlayed'))
                        delete(hc(n))
                    end
                end
            end
        end
        
        function plotIndices(app)
            onOff=app.showindicesCheckBox.Value;
            indicol=[1 1 1];
            lw=1.5;
            font='Arial';
            z=app.eem.ZLim(2);
            z2=repelem(z,2);
            if onOff
                hold(app.eem,'on')
                plot3(app.eem,[254 254],[435 480],z2,'LineWidth',lw, ...
                    'Color',indicol,'DisplayName','IndicesOverlayed')
                plot3(app.eem,[254 254],[300 345],z2,'LineWidth',lw, ...
                    'Color',indicol,'DisplayName','IndicesOverlayed')
                text(app.eem,275,480,z,{'HIX'},'FontName',font,'FontSize',8, ...
                    'FontWeight','bold','Color',indicol,'DisplayName','IndicesOverlayed')

                plot3(app.eem,310,380,z,'LineStyle','none','Marker','o', ...
                    'MarkerFaceColor',indicol,'MarkerEdgeColor',indicol,'DisplayName','IndicesOverlayed')
                plot3(app.eem,310,430,z,'LineStyle','none','Marker','o', ...
                    'MarkerFaceColor',indicol,'MarkerEdgeColor',indicol,'DisplayName','IndicesOverlayed')
                text(app.eem,320,405,z,{'BIX'},'FontName',font,'FontSize',8, ...
                    'FontWeight','bold','Color',indicol,'DisplayName','IndicesOverlayed')

                plot3(app.eem,370,470,z,'LineStyle','none','Marker','o', ...
                    'MarkerFaceColor',indicol,'MarkerEdgeColor',indicol,'DisplayName','IndicesOverlayed')
                plot3(app.eem,370,520,z,'LineStyle','none','Marker','o', ...
                    'MarkerFaceColor',indicol,'MarkerEdgeColor',indicol,'DisplayName','IndicesOverlayed')
                text(app.eem,385,490,z,{'FI'},'FontName',font,'FontSize',8, ...
                    'FontWeight','bold','Color',indicol,'DisplayName','IndicesOverlayed')
                hold(app.eem,'off')
            else
                hc=get(app.eem,'Children');
                for n=1:numel(hc)
                    if ~isempty(strfind(hc(n).DisplayName,'IndicesOverlayed'))
                        delete(hc(n))
                    end
                end
            end
            
        end
        
        function plotSpectra(app)
            
            yyaxis(app.ex,'left')
            set(app.ex,'YColor','k')
            yyaxis(app.ex,'right')
            set(app.ex,'YColor', [240, 140, 0]./255)
            yyaxis(app.ex,'left')

            % Do absorbance
            if app.showabsorbanceCheckBox.Value
                yyaxis(app.ex,'right')
                plot(app.ex,app.data.absWave,app.data.abs(app.state.sample,:), ...
                    'LineStyle','-','Color', [240, 140, 0]./255, ...
                    'Marker','none','DisplayName','abs')
                app.ex.YLimitMethod='padded';
                app.ex.XLimitMethod="tight";
                set(app.ex,'YTickLabel',app.ex.YTick)
                ylabel(app.ex,'absorbance')
                yyaxis(app.ex,'left')
            else
                yyaxis(app.ex,'right')
                hc=get(app.ex,'Children');
                for n=1:numel(hc)
                    if ~isempty(strfind(hc(n).DisplayName,'abs'))
                        delete(hc(n))
                    end
                end
                set(app.ex,'YTickLabel','')
                ylabel(app.ex,'')
                yyaxis(app.ex,'left')
            end
            
            % Don't do fluorescence without Ex/Em pair
            if isempty(app.ExEm)
                return
            end

            

            if app.holdonCheckBox.Value
                hold(app.ex,'on')
                hold(app.em,'on')
                doScatter=false; % Don't show scatter with hold on (confusing)
            else
                hold(app.ex,'off')
                hold(app.em,'off')
                doScatter=app.showscatterpositionCheckBox.Value;
            end

            % Plot Excitation spectrum
            yyaxis(app.ex,'left')
            set(app.ex,'YColor','k')
            yyaxis(app.ex,'right')
            set(app.ex,'YColor',[1 .4 .4])
            

            yyaxis(app.ex,'left')
            plot(app.ex,app.data.Ex,...
                squeeze(app.plotData(app.data.Em==app.ExEm(1),:)), ...
                '-k','DisplayName',num2str(round(app.ExEm(1))))
            app.ex.YLimMode='auto';
            app.ex.YLimitMethod='padded';
            app.ex.XLimitMethod="tight";
            cylim=get(app.ex,'YLim');
            cxlim=get(app.ex,'XLim');
            y = [cylim(1) cylim(2)];
            
            % Plot scatter position of excitation spectrum
            wl = app.ExEm(1);
            ray1st=[wl wl];
            ray2nd=ray1st/2;

            ram1=(1*10^7*((1*10^7)/(wl)+3382)^-1);
            ram2=(1*10^7*((1*10^7)/(wl/2)+3382)^-1);

            ram1st=[ram1 ram1];
            ram2nd=[ram2 ram2];
            if doScatter
                line(app.ex,ram1st,y,...
                    'DisplayName','Raman', ...
                    'Color','k','LineStyle','-','LineWidth',0.5,'Marker','none');
                line(app.ex,ram2nd,y,...
                    'DisplayName','Raman', ...
                    'Color','k','LineStyle','-','LineWidth',0.5,'Marker','none');
                line(app.ex,ray1st,y,...
                    'DisplayName','Rayleigh', ...
                    'Color','r','LineStyle','-','LineWidth',0.5,'Marker','none');
                line(app.ex,ray2nd,y,...
                    'DisplayName','Rayleigh', ...
                    'Color','r','LineStyle','-','LineWidth',0.5,'Marker','none');
                set(app.ex,'XLim',cxlim);
                set(app.ex,'YLim',cylim);
            end
            
            h=findobj(app.ex,'Type', 'line');
            h=h(not(cellfun(@(x) contains(x,{'Ra','abs'}),(arrayfun(@(x) x.DisplayName,h,'uni',false)))));
            if numel(h)>1
                col=colmaker(app,numel(h));
                set(h, {'color'}, num2cell(col,2));
                legend1 = legend(app.ex,h,'location','best');
                try %#ok<TRYNC>
                    legend1.ItemTokenSize=[10 6];
                end
            end

            title(app.ex,['Ex. spectrum at Em = ',num2str(app.ExEm(1))])





            % Plot Emission spectrum
            plot(app.em,app.data.Em, ...
                squeeze(app.plotData(:,app.data.Ex==app.ExEm(2))), ...
                '-k','DisplayName',num2str(round(app.ExEm(2))))


            app.em.YLimMode='auto';
            app.em.YLimitMethod='padded';
            app.em.XLimitMethod="tight";
            cylim=get(app.em,'YLim');
            cxlim=get(app.em,'XLim');
            y = [0 cylim(2)];

            % Plot scatter position of emission spectrum
            wl = app.ExEm(2);

            ram1=1*10^7*((1*10^7)/(wl)-3382)^-1;
            ram2=(1*10^7*((1*10^7)/(wl)-3382)^-1)*2;

            ram1st=[ram1 ram1];
            ram2nd=[ram2 ram2];
            ray1st=[wl wl];
            ray2nd=[wl*2 wl*2];
            if doScatter
                line(app.em,ram1st,y,...
                    'DisplayName','Raman', ...
                    'Color','k','LineStyle','-','LineWidth',0.5,'Marker','none');
                line(app.em,ram2nd,y,...
                    'DisplayName','Raman', ...
                    'Color','k','LineStyle','-','LineWidth',0.5,'Marker','none');
                line(app.em,ray1st,y,...
                    'DisplayName','Rayleigh', ...
                    'Color','r','LineStyle','-','LineWidth',0.5,'Marker','none');
                line(app.em,ray2nd,y,...
                    'DisplayName','Rayleigh', ...
                    'Color','r','LineStyle','-','LineWidth',0.5,'Marker','none');
                set(app.em,'XLim',cxlim);
                set(app.em,'YLim',cylim);

            end
            h=findobj(app.em,'Type', 'line');
            h=h(not(cellfun(@(x) contains(x,'Ra'),(arrayfun(@(x) x.DisplayName,h,'uni',false)))));
            if numel(h)>1
                col=colmaker(app,numel(h));
                set(h, {'color'}, num2cell(col,2));
                legend1 = legend(app.em,h,'location','best');
                try %#ok<TRYNC>
                    legend1.ItemTokenSize=[10 6];
                end
            end
            title(app.em,['Em. spectrum at Ex = ',num2str(app.ExEm(2))])


        end
        
        
        function clearSpectra(app)
            hc=get(app.ex,'Children');
            hc=[hc;get(app.em,'Children')];
            for n=1:numel(hc)
                delete(hc(n))
            end
            cla(app.ex)
            cla(app.em)
            title(app.ex,''),title(app.em,'')
        end
        
        function cols = colmaker(app,i)
            collist= [0 0 0;...
                0.368627450980392,0.309803921568627,0.635294117647059;...
                0.197386603025884,0.512851710442123,0.740257214831838;...
                0.353920722469962,0.729472517932409,0.656177840632872;...
                0.597784406620190,0.840777034550949,0.644490274269565;...
                0.841701969675001,0.940885130292891,0.609611616709332;...
                0.931851609124017,0.957193786605551,0.661676168589149;...
                0.976267475434952,0.928364732010819,0.658313136694680;...
                0.995493878994122,0.822714483114813,0.482765825462557;...
                0.987654277338283,0.615414278604657,0.339114037801447;...
                0.943815034723900,0.390980258870390,0.266846392952373;...
                0.820562112287474,0.223926402795306,0.309367864350849;...
                0.619607843137255,0.00392156862745098,0.258823529411765];
            cols=collist(1:i,:);
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
            app.drEEMtoolboxvieweemsUIFigure.Units="normalized";
            app.drEEMtoolboxvieweemsUIFigure.Position=[0.15 0.15 0.7 0.6];
            movegui(app.drEEMtoolboxvieweemsUIFigure,'center')
            disableDefaultInteractivity(app.eem)
            removeToolbarExplorationButtons(app.eem)
            app.eem.Toolbar.Visible = 'off';
            app.data=data;
            % Set up data types and associated components
            c=drEEMdataset.modelsWithContent(data);
            if isempty(c)
                app.componentsDropDown.Enable="off";
                app.componentsDropDownLabel.Enable="off";
                app.DatatypeDropDown.Enable="off";
                app.DatatypeDropDownLabel.Enable="off";
            else
                app.componentsDropDown.Items=string(num2str(c));
            end

            % Deal with sample name lists and counter
            fnames = app.data.filelist;
            idx    = cellstr(num2str((1:app.data.nSample)'));
            i      = cellstr(num2str(app.data.i));
            fnames = cellfun(@(a,b,c) [a,': ',b,'(i=',c,')'],idx,fnames,i,uni=false);
            app.SampleDropDown.Items=fnames;
            app.state.dataType=app.DatatypeDropDown.Value;
            app.state.sample=1;
            app.viewangle=[0,90];

            if not(isempty(app.data.abs))
                app.showabsorbanceCheckBox.Value=1;
                app.showabsorbanceCheckBox.Enable="on";
            else
                app.showabsorbanceCheckBox.Value=0;
                app.showabsorbanceCheckBox.Enable="off";
            end

            app.eem.Color=[0.99,0.99,0.99];
            app.ex.Color=[0.99,0.99,0.99];
            app.em.Color=[0.99,0.99,0.99];
            app.plotData=app.dataExtractor;
            rotate3d(app.eem,'on')
            app.triggerNewData;
           

        end

        % Button pushed function: Button_2
        function decreaseByOne(app, event)
            if app.state.sample>1
                app.state.sample=app.state.sample-1;
                app.triggerNewData;
            end
        end

        % Button pushed function: Button
        function increaseByOne(app, event)
            if app.state.sample<app.data.nSample
                app.state.sample=app.state.sample+1;
                app.triggerNewData;
            end
        end

        % Value changed function: SampleDropDown
        function sampleChangedByList(app, event)
            value = app.SampleDropDown.Value;
            value = strsplit(value,{': ','(i='});
            value = value{2};
            idx=matches(app.data.filelist,value);
            app.state.sample=find(idx);
            app.triggerNewData;
        end

        % Value changed function: ColormapDropDown, contoursEditField, 
        % ...and 2 other components
        function triggerRedraw(app, event)
                       
            % Rotation has no callback, so we need to save the viewangles
            app.storeViewangle;
            % Plot the EEM
            app.ploteem;
            % Overlay the Peaks
            app.plotPeaks;
            % Overlay the indices
            app.plotIndices;
            % Plot the spectra
            app.plotSpectra;
        end

        % Value changed function: DatatypeDropDown, componentsDropDown
        function triggerNewData(app, event)
            [az,el]=view(app.eem);
            app.viewangle=[az,el]; % Old rotation state
            app.plotData=app.dataExtractor;
            if app.remembercolorlimitsCheckBox.Value
                app.aclim=[prctile(app.plotData(:),app.rclim(1)),...
                        prctile(app.plotData(:),app.rclim(2))];
            else
                app.colorLimitSlider.Value=[0 100];
                app.setCLim;
            end
            if app.rememberrotationCheckBox.Value
                % Do nothing (keep angles)
            else
                app.viewangle=[0,90];
            end
            
            if app.rememberselectionCheckBox.Value
                % Nothing needs to be done (values are stored)
            else
                app.ExEm=[];
            end
            app.clearSpectra;
            app.triggerRedraw;
        end

        % Value changed function: colorLimitSlider
        function setCLim(app, event)
            value = app.colorLimitSlider.Value;
            app.rclim=value;
            app.aclim=[prctile(app.plotData(:),value(1)),...
                    prctile(app.plotData(:),value(2))];
            clim(app.eem,app.aclim)
            %app.triggerRedraw;
            
        end

        % Value changed function: rememberrotationCheckBox
        function storeViewangle(app, event)
            value = app.rememberrotationCheckBox.Value;
            if value
                [az,el] = view(app.eem);
                app.viewangle=[az,el];
            end
        end

        % Button pushed function: Button_3
        function setExEm(app, event)
            mindist=@(vec,val) find(ismember(abs(vec-val),min(abs(vec-val))));
            
            % Set up figure handle visibility, run ginput, and return state
            fhv = app.drEEMtoolboxvieweemsUIFigure.HandleVisibility;        % Current status
            app.drEEMtoolboxvieweemsUIFigure.HandleVisibility = 'callback'; % Temp change (or, 'on')
            set(0, 'CurrentFigure', app.drEEMtoolboxvieweemsUIFigure)       % Make fig current
            axes(app.eem)
            [x,y] = ginput(1);
            app.drEEMtoolboxvieweemsUIFigure.HandleVisibility = fhv;        % return original state
            
            
            app.ExEm=[app.data.Em(mindist(app.data.Em,y)) app.data.Ex(mindist(app.data.Ex,x))];
            app.plotSpectra;
        end

        % Value changed function: showabsorbanceCheckBox
        function showabsorbanceCheckBoxValueChanged(app, event)
            app.plotSpectra;
        end

        % Value changed function: showscatterpositionCheckBox
        function showscatterpositionCheckBoxValueChanged(app, event)
            app.plotSpectra;
            
        end

        % Value changed function: datacursorButton, rotateButton
        function eemInteractivityCallback(app, event)
            switch event.Source.Text
                case 'rotate'
                    if event.Value
                        rotate3d(app.eem,'on')
                        app.datacursorButton.Value=false;
                        %delete(findobj(app.eem,'Type','DataTip')) % not
                        %sure I really want this
                    else
                        
                    end
                case 'data cursor'
                    if event.Value
                        datacursormode(app.eem,'on')
                        app.rotateButton.Value=false;
                        
                    else

                    end
            end
            if app.datacursorButton.Value
                app.rotateButton.Value=false;
                datacursormode(app.eem,'on')
            elseif app.rotateButton.Value
                app.datacursorButton.Value=false;
                rotate3d(app.eem,'on')
            end
            
        end

        % Callback function
        function SaveasimageMenuSelected(app, event)
            defname=[char(sel.Title),'.png'];

            [filename, pathname] = uiputfile({'*.png'; '*.jpg'},...
                'Save Figure As', ...
                defname);
            

            if isequal(filename, 0) || isequal(pathname, 0)
                pathname=pwd;
                filename=defname;
                warning('Did not specify filename and path. Assumed default name in current directory.')
            end
            
            warning off
                exportgraphics(app.eem,...
                    fullfile(pathname,filename),...
                    "BackgroundColor","white",...
                    "Resolution",600)
            warning on

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create drEEMtoolboxvieweemsUIFigure and hide until all components are created
            app.drEEMtoolboxvieweemsUIFigure = uifigure('Visible', 'off');
            app.drEEMtoolboxvieweemsUIFigure.Position = [100 100 1028 672];
            app.drEEMtoolboxvieweemsUIFigure.Name = 'drEEM toolbox: vieweems';

            % Create MainGrid
            app.MainGrid = uigridlayout(app.drEEMtoolboxvieweemsUIFigure);
            app.MainGrid.ColumnWidth = {300, '1x'};
            app.MainGrid.RowHeight = {'1x'};
            app.MainGrid.Padding = [0 0 0 0];

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.MainGrid);
            app.SettingsPanel.BorderWidth = 0;
            app.SettingsPanel.Layout.Row = 1;
            app.SettingsPanel.Layout.Column = 1;

            % Create GridLayout
            app.GridLayout = uigridlayout(app.SettingsPanel);
            app.GridLayout.RowHeight = {'1x', '1x', '1x'};
            app.GridLayout.Padding = [5 5 5 5];

            % Create SAMPLECONTROLPanel
            app.SAMPLECONTROLPanel = uipanel(app.GridLayout);
            app.SAMPLECONTROLPanel.TitlePosition = 'centertop';
            app.SAMPLECONTROLPanel.Title = 'SAMPLE CONTROL';
            app.SAMPLECONTROLPanel.Layout.Row = 1;
            app.SAMPLECONTROLPanel.Layout.Column = [1 2];
            app.SAMPLECONTROLPanel.FontName = 'Bahnschrift';
            app.SAMPLECONTROLPanel.FontWeight = 'bold';
            app.SAMPLECONTROLPanel.Scrollable = 'on';
            app.SAMPLECONTROLPanel.FontSize = 15;

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.SAMPLECONTROLPanel);
            app.GridLayout3.RowHeight = {22, 22, 22, 22};
            app.GridLayout3.Padding = [5 5 5 5];

            % Create GridLayout10
            app.GridLayout10 = uigridlayout(app.GridLayout3);
            app.GridLayout10.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout10.RowHeight = {'1x'};
            app.GridLayout10.Padding = [0 0 0 0];
            app.GridLayout10.Layout.Row = 1;
            app.GridLayout10.Layout.Column = [1 2];

            % Create Button_3
            app.Button_3 = uibutton(app.GridLayout10, 'push');
            app.Button_3.ButtonPushedFcn = createCallbackFcn(app, @setExEm, true);
            app.Button_3.Icon = 'spectrum.png';
            app.Button_3.Tooltip = {'Select ex / em pair for the visualization of spectra.'; ''; 'A crosshair will appear. Hover over the point of interest and left-click.'; ''; 'Please move the mouse and allow for 1-2s for the crosshair to appear.'};
            app.Button_3.Layout.Row = 1;
            app.Button_3.Layout.Column = 3;
            app.Button_3.Text = '';

            % Create Button
            app.Button = uibutton(app.GridLayout10, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @increaseByOne, true);
            app.Button.Icon = 'next.png';
            app.Button.Tooltip = {'Plot next sample'};
            app.Button.Layout.Row = 1;
            app.Button.Layout.Column = 2;
            app.Button.Text = '';

            % Create Button_2
            app.Button_2 = uibutton(app.GridLayout10, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @decreaseByOne, true);
            app.Button_2.Icon = 'back.png';
            app.Button_2.Tooltip = {'Plot previous sample.'};
            app.Button_2.Layout.Row = 1;
            app.Button_2.Layout.Column = 1;
            app.Button_2.Text = '';

            % Create DatatypeDropDownLabel
            app.DatatypeDropDownLabel = uilabel(app.GridLayout3);
            app.DatatypeDropDownLabel.HorizontalAlignment = 'right';
            app.DatatypeDropDownLabel.Tooltip = {'If models have been fit, modelled data or model residuals can be selected and plotted.'};
            app.DatatypeDropDownLabel.Layout.Row = 3;
            app.DatatypeDropDownLabel.Layout.Column = 1;
            app.DatatypeDropDownLabel.Text = 'Data type';

            % Create DatatypeDropDown
            app.DatatypeDropDown = uidropdown(app.GridLayout3);
            app.DatatypeDropDown.Items = {'data', 'model', 'residuals'};
            app.DatatypeDropDown.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.DatatypeDropDown.Tooltip = {'If models have been fit, modelled data or model residuals can be selected and plotted.'};
            app.DatatypeDropDown.Layout.Row = 3;
            app.DatatypeDropDown.Layout.Column = 2;
            app.DatatypeDropDown.Value = 'data';

            % Create componentsDropDownLabel
            app.componentsDropDownLabel = uilabel(app.GridLayout3);
            app.componentsDropDownLabel.HorizontalAlignment = 'right';
            app.componentsDropDownLabel.Tooltip = {'If models have been fit, any of the fit models can be selected (only affects modelled data and model residuals)'};
            app.componentsDropDownLabel.Layout.Row = 4;
            app.componentsDropDownLabel.Layout.Column = 1;
            app.componentsDropDownLabel.Text = '# components';

            % Create componentsDropDown
            app.componentsDropDown = uidropdown(app.GridLayout3);
            app.componentsDropDown.ValueChangedFcn = createCallbackFcn(app, @triggerNewData, true);
            app.componentsDropDown.Tooltip = {'If models have been fit, any of the fit models can be selected (only affects modelled data and model residuals)'};
            app.componentsDropDown.Layout.Row = 4;
            app.componentsDropDown.Layout.Column = 2;

            % Create SampleDropDownLabel
            app.SampleDropDownLabel = uilabel(app.GridLayout3);
            app.SampleDropDownLabel.HorizontalAlignment = 'right';
            app.SampleDropDownLabel.Tooltip = {'Select any sample from the dataset for visualization.'};
            app.SampleDropDownLabel.Layout.Row = 2;
            app.SampleDropDownLabel.Layout.Column = 1;
            app.SampleDropDownLabel.Text = 'Sample';

            % Create SampleDropDown
            app.SampleDropDown = uidropdown(app.GridLayout3);
            app.SampleDropDown.ValueChangedFcn = createCallbackFcn(app, @sampleChangedByList, true);
            app.SampleDropDown.Tooltip = {'Select any sample from the dataset for visualization.'};
            app.SampleDropDown.Layout.Row = 2;
            app.SampleDropDown.Layout.Column = 2;

            % Create EEMFORMATPanel
            app.EEMFORMATPanel = uipanel(app.GridLayout);
            app.EEMFORMATPanel.TitlePosition = 'centertop';
            app.EEMFORMATPanel.Title = 'EEM FORMAT';
            app.EEMFORMATPanel.Layout.Row = 2;
            app.EEMFORMATPanel.Layout.Column = [1 2];
            app.EEMFORMATPanel.FontName = 'Bahnschrift';
            app.EEMFORMATPanel.FontWeight = 'bold';
            app.EEMFORMATPanel.FontSize = 15;

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.EEMFORMATPanel);
            app.GridLayout4.RowHeight = {22, 22, 22, 22};
            app.GridLayout4.Padding = [5 5 5 5];
            app.GridLayout4.BackgroundColor = [0.9608 0.9608 0.9608];

            % Create ColormapDropDownLabel
            app.ColormapDropDownLabel = uilabel(app.GridLayout4);
            app.ColormapDropDownLabel.HorizontalAlignment = 'right';
            app.ColormapDropDownLabel.Tooltip = {'Select a colormap of your choosing.'};
            app.ColormapDropDownLabel.Layout.Row = 1;
            app.ColormapDropDownLabel.Layout.Column = 1;
            app.ColormapDropDownLabel.Text = 'Colormap';

            % Create ColormapDropDown
            app.ColormapDropDown = uidropdown(app.GridLayout4);
            app.ColormapDropDown.Items = {'turbo', 'parula', 'jet', 'hsv', 'blue-red'};
            app.ColormapDropDown.ValueChangedFcn = createCallbackFcn(app, @triggerRedraw, true);
            app.ColormapDropDown.Tooltip = {'Select a colormap of your choosing.'};
            app.ColormapDropDown.Layout.Row = 1;
            app.ColormapDropDown.Layout.Column = 2;
            app.ColormapDropDown.Value = 'turbo';

            % Create contoursEditFieldLabel
            app.contoursEditFieldLabel = uilabel(app.GridLayout4);
            app.contoursEditFieldLabel.HorizontalAlignment = 'right';
            app.contoursEditFieldLabel.Tooltip = {'Number of contours to show. 0 disables contours.'; ''; 'Note that the app performance is likely bad if more than 50 contours are requested.'};
            app.contoursEditFieldLabel.Layout.Row = 2;
            app.contoursEditFieldLabel.Layout.Column = 1;
            app.contoursEditFieldLabel.Text = '# contours';

            % Create contoursEditField
            app.contoursEditField = uieditfield(app.GridLayout4, 'numeric');
            app.contoursEditField.ValueChangedFcn = createCallbackFcn(app, @triggerRedraw, true);
            app.contoursEditField.Tooltip = {'Number of contours to show. 0 disables contours.'; ''; 'Note that the app performance is likely bad if more than 50 contours are requested.'};
            app.contoursEditField.Layout.Row = 2;
            app.contoursEditField.Layout.Column = 2;
            app.contoursEditField.Value = 20;

            % Create rememberrotationCheckBox
            app.rememberrotationCheckBox = uicheckbox(app.GridLayout4);
            app.rememberrotationCheckBox.ValueChangedFcn = createCallbackFcn(app, @storeViewangle, true);
            app.rememberrotationCheckBox.Tooltip = {'Remember the EEM axis rotation for the next sample.'; ''; 'Option is also required to be set if the EEM of the same sample is redrawn (e.g. when peaks or indices are superimposed)'};
            app.rememberrotationCheckBox.Text = 'remember rotation';
            app.rememberrotationCheckBox.Layout.Row = 3;
            app.rememberrotationCheckBox.Layout.Column = 1;

            % Create remembercolorlimitsCheckBox
            app.remembercolorlimitsCheckBox = uicheckbox(app.GridLayout4);
            app.remembercolorlimitsCheckBox.Tooltip = {'Remember the % colorlimits (slider on the right) when sample is changed.'; ''; 'Can be useful if scatter is present or focus is on baseline or minor peaks.'};
            app.remembercolorlimitsCheckBox.Text = 'remember colorlimits';
            app.remembercolorlimitsCheckBox.Layout.Row = 3;
            app.remembercolorlimitsCheckBox.Layout.Column = 2;

            % Create showCoblePeaksCheckBox
            app.showCoblePeaksCheckBox = uicheckbox(app.GridLayout4);
            app.showCoblePeaksCheckBox.ValueChangedFcn = createCallbackFcn(app, @triggerRedraw, true);
            app.showCoblePeaksCheckBox.Tooltip = {'Superimpose peak-picking (also known as "Coble peaks").'};
            app.showCoblePeaksCheckBox.Text = 'show Coble Peaks';
            app.showCoblePeaksCheckBox.Layout.Row = 4;
            app.showCoblePeaksCheckBox.Layout.Column = 1;

            % Create showindicesCheckBox
            app.showindicesCheckBox = uicheckbox(app.GridLayout4);
            app.showindicesCheckBox.ValueChangedFcn = createCallbackFcn(app, @triggerRedraw, true);
            app.showindicesCheckBox.Tooltip = {'Superimpose widely used fluorescence indices'};
            app.showindicesCheckBox.Text = 'show indices';
            app.showindicesCheckBox.Layout.Row = 4;
            app.showindicesCheckBox.Layout.Column = 2;

            % Create SPECTRAFORMATPanel
            app.SPECTRAFORMATPanel = uipanel(app.GridLayout);
            app.SPECTRAFORMATPanel.TitlePosition = 'centertop';
            app.SPECTRAFORMATPanel.Title = 'SPECTRA FORMAT';
            app.SPECTRAFORMATPanel.Layout.Row = 3;
            app.SPECTRAFORMATPanel.Layout.Column = [1 2];
            app.SPECTRAFORMATPanel.FontName = 'Bahnschrift';
            app.SPECTRAFORMATPanel.FontWeight = 'bold';
            app.SPECTRAFORMATPanel.FontSize = 15;

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.SPECTRAFORMATPanel);
            app.GridLayout5.RowHeight = {22, 22, 22, 22};
            app.GridLayout5.Padding = [0 0 0 0];

            % Create holdonCheckBox
            app.holdonCheckBox = uicheckbox(app.GridLayout5);
            app.holdonCheckBox.Tooltip = {'Allows the visualization of multiple 2D spectra at the same time.'};
            app.holdonCheckBox.Text = 'hold on';
            app.holdonCheckBox.Layout.Row = 1;
            app.holdonCheckBox.Layout.Column = 1;

            % Create rememberselectionCheckBox
            app.rememberselectionCheckBox = uicheckbox(app.GridLayout5);
            app.rememberselectionCheckBox.Tooltip = {'Remember last selected ex / em pair for any subsequent sample. This will automatically draw spectra when the same is changed.'};
            app.rememberselectionCheckBox.Text = 'remember selection';
            app.rememberselectionCheckBox.Layout.Row = 1;
            app.rememberselectionCheckBox.Layout.Column = 2;

            % Create showabsorbanceCheckBox
            app.showabsorbanceCheckBox = uicheckbox(app.GridLayout5);
            app.showabsorbanceCheckBox.ValueChangedFcn = createCallbackFcn(app, @showabsorbanceCheckBoxValueChanged, true);
            app.showabsorbanceCheckBox.Tooltip = {'Draw CDOM absorbance on the right y-axis of the excitation plot. '; ''; 'This does not require any selection of ex / em pairs to be active.'; ''; 'If data.abs (absorbance matrix) is empty, the option is automatically disabled.'};
            app.showabsorbanceCheckBox.Enable = 'off';
            app.showabsorbanceCheckBox.Text = 'show absorbance';
            app.showabsorbanceCheckBox.Layout.Row = 2;
            app.showabsorbanceCheckBox.Layout.Column = 2;

            % Create showscatterpositionCheckBox
            app.showscatterpositionCheckBox = uicheckbox(app.GridLayout5);
            app.showscatterpositionCheckBox.ValueChangedFcn = createCallbackFcn(app, @showscatterpositionCheckBoxValueChanged, true);
            app.showscatterpositionCheckBox.Tooltip = {'Superimpose the wavelength position of Rayleigh and Raman scattering peaks.'};
            app.showscatterpositionCheckBox.Text = 'show scatter position';
            app.showscatterpositionCheckBox.Layout.Row = 2;
            app.showscatterpositionCheckBox.Layout.Column = 1;
            app.showscatterpositionCheckBox.Value = true;

            % Create GridLayout11
            app.GridLayout11 = uigridlayout(app.GridLayout5);
            app.GridLayout11.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout11.RowHeight = {'1x'};
            app.GridLayout11.Padding = [0 0 0 0];
            app.GridLayout11.Tooltip = {'Legend (not interactive)'};
            app.GridLayout11.Layout.Row = 4;
            app.GridLayout11.Layout.Column = [1 2];

            % Create Image
            app.Image = uiimage(app.GridLayout11);
            app.Image.Tooltip = {'Legend (not interactive)'};
            app.Image.Layout.Row = 1;
            app.Image.Layout.Column = 2;
            app.Image.VerticalAlignment = 'top';
            app.Image.ImageSource = 'raman.png';

            % Create Image2
            app.Image2 = uiimage(app.GridLayout11);
            app.Image2.Tooltip = {'Legend (not interactive)'};
            app.Image2.Layout.Row = 1;
            app.Image2.Layout.Column = 3;
            app.Image2.VerticalAlignment = 'top';
            app.Image2.ImageSource = 'rayleigh.png';

            % Create Image3
            app.Image3 = uiimage(app.GridLayout11);
            app.Image3.Tooltip = {'Legend (not interactive)'};
            app.Image3.Layout.Row = 1;
            app.Image3.Layout.Column = 1;
            app.Image3.VerticalAlignment = 'top';
            app.Image3.ImageSource = 'cdom.png';

            % Create LegendLabel
            app.LegendLabel = uilabel(app.GridLayout5);
            app.LegendLabel.HorizontalAlignment = 'center';
            app.LegendLabel.VerticalAlignment = 'bottom';
            app.LegendLabel.Tooltip = {'Legend (not interactive)'};
            app.LegendLabel.Layout.Row = 3;
            app.LegendLabel.Layout.Column = [1 2];
            app.LegendLabel.Text = 'Legend';

            % Create Panel
            app.Panel = uipanel(app.MainGrid);
            app.Panel.BorderType = 'none';
            app.Panel.Layout.Row = 1;
            app.Panel.Layout.Column = 2;

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.Panel);
            app.GridLayout6.ColumnWidth = {'1x'};
            app.GridLayout6.RowHeight = {'1x', '0.6x'};
            app.GridLayout6.Padding = [0 5 5 5];

            % Create EXCITATIONEMISSIONMATRIXPanel
            app.EXCITATIONEMISSIONMATRIXPanel = uipanel(app.GridLayout6);
            app.EXCITATIONEMISSIONMATRIXPanel.Tooltip = {'The fluorescence EEM will be plotted in this panel.'};
            app.EXCITATIONEMISSIONMATRIXPanel.TitlePosition = 'centertop';
            app.EXCITATIONEMISSIONMATRIXPanel.Title = 'EXCITATION EMISSION MATRIX';
            app.EXCITATIONEMISSIONMATRIXPanel.Layout.Row = 1;
            app.EXCITATIONEMISSIONMATRIXPanel.Layout.Column = 1;
            app.EXCITATIONEMISSIONMATRIXPanel.FontName = 'Bahnschrift';
            app.EXCITATIONEMISSIONMATRIXPanel.FontWeight = 'bold';
            app.EXCITATIONEMISSIONMATRIXPanel.FontSize = 15;

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.EXCITATIONEMISSIONMATRIXPanel);
            app.GridLayout8.ColumnWidth = {'1x', 70};
            app.GridLayout8.RowHeight = {22, '1x', 22, 22};
            app.GridLayout8.Padding = [0 5 0 0];

            % Create eem
            app.eem = uiaxes(app.GridLayout8);
            xlabel(app.eem, 'excitation (nm)')
            ylabel(app.eem, 'emission (nm)')
            zlabel(app.eem, 'Z')
            app.eem.PlotBoxAspectRatio = [3 2.48258706467662 1];
            app.eem.BoxStyle = 'full';
            app.eem.Box = 'on';
            app.eem.TickDir = 'out';
            app.eem.Layout.Row = [1 4];
            app.eem.Layout.Column = 1;

            % Create colorLimitSlider
            app.colorLimitSlider = uislider(app.GridLayout8, 'range');
            app.colorLimitSlider.Orientation = 'vertical';
            app.colorLimitSlider.ValueChangedFcn = createCallbackFcn(app, @setCLim, true);
            app.colorLimitSlider.FontColor = [0 0 0];
            app.colorLimitSlider.Tooltip = {'Change the slider to adjust color limits of the EEM.'; ''; 'Can be useful to ignore scatter, highlight weak signals, or compensate for negative values.'; ''; 'Note that the slider is disabled for residual plots. This is expected behavior.'};
            app.colorLimitSlider.Layout.Row = 2;
            app.colorLimitSlider.Layout.Column = 2;

            % Create colorlimitpercentilesLabel
            app.colorlimitpercentilesLabel = uilabel(app.GridLayout8);
            app.colorlimitpercentilesLabel.HandleVisibility = 'off';
            app.colorlimitpercentilesLabel.HorizontalAlignment = 'right';
            app.colorlimitpercentilesLabel.Tooltip = {'Change the slider to adjust color limits of the EEM.'; ''; 'Can be useful to ignore scatter, highlight weak signals, or compensate for negative values.'; ''; 'Note that the slider is disabled for residual plots. This is expected behavior.'};
            app.colorlimitpercentilesLabel.Layout.Row = 1;
            app.colorlimitpercentilesLabel.Layout.Column = [1 2];
            app.colorlimitpercentilesLabel.Text = 'color limit (percentiles)';

            % Create datacursorButton
            app.datacursorButton = uibutton(app.GridLayout8, 'state');
            app.datacursorButton.ValueChangedFcn = createCallbackFcn(app, @eemInteractivityCallback, true);
            app.datacursorButton.Text = 'data cursor';
            app.datacursorButton.Layout.Row = 3;
            app.datacursorButton.Layout.Column = 2;

            % Create rotateButton
            app.rotateButton = uibutton(app.GridLayout8, 'state');
            app.rotateButton.ValueChangedFcn = createCallbackFcn(app, @eemInteractivityCallback, true);
            app.rotateButton.Text = 'rotate';
            app.rotateButton.Layout.Row = 4;
            app.rotateButton.Layout.Column = 2;

            % Create DSPECTRAPanel
            app.DSPECTRAPanel = uipanel(app.GridLayout6);
            app.DSPECTRAPanel.Tooltip = {'This panel is used to plot 2D spectra. That includes CDOM absorbance and FDOM spectra at selected ex / em pairs. For FDOM spectra to show up, ex / em pairs first need to be defined (look for the spectra button)'};
            app.DSPECTRAPanel.TitlePosition = 'centertop';
            app.DSPECTRAPanel.Title = '2D SPECTRA';
            app.DSPECTRAPanel.Layout.Row = 2;
            app.DSPECTRAPanel.Layout.Column = 1;
            app.DSPECTRAPanel.FontName = 'Bahnschrift';
            app.DSPECTRAPanel.FontWeight = 'bold';
            app.DSPECTRAPanel.FontSize = 15;

            % Create GridLayout9
            app.GridLayout9 = uigridlayout(app.DSPECTRAPanel);
            app.GridLayout9.RowHeight = {'1x'};
            app.GridLayout9.Padding = [0 0 0 0];

            % Create ex
            app.ex = uiaxes(app.GridLayout9);
            xlabel(app.ex, 'excitation (nm)')
            ylabel(app.ex, 'signal')
            zlabel(app.ex, 'Z')
            app.ex.Box = 'on';
            app.ex.Layout.Row = 1;
            app.ex.Layout.Column = 1;
            app.ex.Tag = 'ex';
            colormap(app.ex, 'parula')

            % Create em
            app.em = uiaxes(app.GridLayout9);
            xlabel(app.em, 'emission (nm)')
            ylabel(app.em, 'signal')
            zlabel(app.em, 'Z')
            app.em.Box = 'on';
            app.em.Layout.Row = 1;
            app.em.Layout.Column = 2;
            app.em.Tag = 'em';
            colormap(app.em, 'parula')

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.drEEMtoolboxvieweemsUIFigure);

            % Create SavefigurepanelasimageMenu
            app.SavefigurepanelasimageMenu = uimenu(app.ContextMenu);
            app.SavefigurepanelasimageMenu.Text = 'Save figure panel as image';
            
            % Assign app.ContextMenu
            app.em.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.drEEMtoolboxvieweemsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = vieweems_gui(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.drEEMtoolboxvieweemsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.drEEMtoolboxvieweemsUIFigure)
        end
    end
end