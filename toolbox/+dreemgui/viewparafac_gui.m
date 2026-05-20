classdef viewmodels_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        viewmodelsDiagnosePARAFACmodelsUIFigure  matlab.ui.Figure
        GridLayout5                  matlab.ui.container.GridLayout
        TabGroup                     matlab.ui.container.TabGroup
        OverviewTab                  matlab.ui.container.Tab
        GridLayout4                  matlab.ui.container.GridLayout
        Panel_2                      matlab.ui.container.Panel
        GridLayout10                 matlab.ui.container.GridLayout
        var                          matlab.ui.control.UIAxes
        core                         matlab.ui.control.UIAxes
        UITable                      matlab.ui.control.Table
        ScoresloadingsTab            matlab.ui.container.Tab
        GridLayout7                  matlab.ui.container.GridLayout
        scoresloadscanvas            matlab.ui.container.Panel
        SpectralloadingsTab          matlab.ui.container.Tab
        GridLayout8                  matlab.ui.container.GridLayout
        loadstab                     matlab.ui.container.Panel
        LoadingsleveragesTab         matlab.ui.container.Tab
        GridLayout                   matlab.ui.container.GridLayout
        Panel                        matlab.ui.container.Panel
        GridLayout9                  matlab.ui.container.GridLayout
        leex                         matlab.ui.control.UIAxes
        leem                         matlab.ui.control.UIAxes
        les                          matlab.ui.control.UIAxes
        loex                         matlab.ui.control.UIAxes
        loem                         matlab.ui.control.UIAxes
        scs                          matlab.ui.control.UIAxes
        LinelegendCheckBox           matlab.ui.control.CheckBox
        lldrop                       matlab.ui.control.DropDown
        ErrorsleveragesTab           matlab.ui.container.Tab
        GridLayout_2                 matlab.ui.container.GridLayout
        Panel_3                      matlab.ui.container.Panel
        GridLayout11                 matlab.ui.container.GridLayout
        elex                         matlab.ui.control.UIAxes
        elem                         matlab.ui.control.UIAxes
        elsam                        matlab.ui.control.UIAxes
        eldrop                       matlab.ui.control.DropDown
        FingerprintplotsTab          matlab.ui.container.Tab
        GridLayout2                  matlab.ui.container.GridLayout
        NumberofcontousSpinner       matlab.ui.control.Spinner
        NumberofcontousSpinnerLabel  matlab.ui.control.Label
        ColormapDropDown             matlab.ui.control.DropDown
        ColormapLabel                matlab.ui.control.Label
        ShowRamanandRayleighscatterlocationCheckBox  matlab.ui.control.CheckBox
        fingerpanel                  matlab.ui.container.Panel
        fingerdrop                   matlab.ui.control.DropDown
        SSETab                       matlab.ui.container.Tab
        GridLayout3                  matlab.ui.container.GridLayout
        Panel_4                      matlab.ui.container.Panel
        GridLayout12                 matlab.ui.container.GridLayout
        sseex                        matlab.ui.control.UIAxes
        sseem                        matlab.ui.control.UIAxes
        ssesam                       matlab.ui.control.UIAxes
        ssedrop                      matlab.ui.control.DropDown
        ScorecorrelationTab          matlab.ui.container.Tab
        GridLayout6                  matlab.ui.container.GridLayout
        viewcorrelationsvsmetadataButton  matlab.ui.control.Button
        corrcanvas                   matlab.ui.container.Panel
        ContextMenu                  matlab.ui.container.ContextMenu
        SavefigurepanelMenu          matlab.ui.container.Menu
        ContextMenu2                 matlab.ui.container.ContextMenu
        SavefigurepanelMenu_2        matlab.ui.container.Menu
    end


    properties (Access = private)
        f % Components
        ncomp % Number of components
        models % the dataset structure
        ScoresloadingsTabGrid
        fingergrid
        data % Description
        tabStates % Description
        fsel % Description
    end

    methods (Access = private)

        function f=findcomponents(~,model)
            f=find(arrayfun(@(x) not(isempty(x.loads{1})),model.models));
        end

        function color=cmap(~)
            % color=[1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,0.979591836734694,0.979591836734694;1,0.959183673469388,0.959183673469388;1,0.938775510204082,0.938775510204082;1,0.918367346938776,0.918367346938776;1,0.897959183673469,0.897959183673469;1,0.877551020408163,0.877551020408163;1,0.857142857142857,0.857142857142857;1,0.836734693877551,0.836734693877551;1,0.816326530612245,0.816326530612245;1,0.795918367346939,0.795918367346939;1,0.775510204081633,0.775510204081633;1,0.755102040816327,0.755102040816327;1,0.734693877551020,0.734693877551020;1,0.714285714285714,0.714285714285714;1,0.693877551020408,0.693877551020408;1,0.673469387755102,0.673469387755102;1,0.653061224489796,0.653061224489796;1,0.632653061224490,0.632653061224490;1,0.612244897959184,0.612244897959184;1,0.591836734693878,0.591836734693878;1,0.571428571428571,0.571428571428571;1,0.551020408163265,0.551020408163265;1,0.530612244897959,0.530612244897959;1,0.510204081632653,0.510204081632653;1,0.489795918367347,0.489795918367347;1,0.469387755102041,0.469387755102041;1,0.448979591836735,0.448979591836735;1,0.428571428571429,0.428571428571429;1,0.408163265306122,0.408163265306122;1,0.387755102040816,0.387755102040816;1,0.367346938775510,0.367346938775510;1,0.346938775510204,0.346938775510204;1,0.326530612244898,0.326530612244898;1,0.306122448979592,0.306122448979592;1,0.285714285714286,0.285714285714286;1,0.265306122448980,0.265306122448980;1,0.244897959183674,0.244897959183674;1,0.224489795918367,0.224489795918367;1,0.204081632653061,0.204081632653061;1,0.183673469387755,0.183673469387755;1,0.163265306122449,0.163265306122449;1,0.142857142857143,0.142857142857143;1,0.122448979591837,0.122448979591837;1,0.102040816326531,0.102040816326531;1,0.0816326530612245,0.0816326530612245;1,0.0612244897959183,0.0612244897959183;1,0.0408163265306123,0.0408163265306123;1,0.0204081632653061,0.0204081632653061;1,0,0];
            color=[1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,1,1;1,0.977272727272727,0.977272727272727;1,0.954545454545455,0.954545454545455;1,0.931818181818182,0.931818181818182;1,0.909090909090909,0.909090909090909;1,0.886363636363636,0.886363636363636;1,0.863636363636364,0.863636363636364;1,0.840909090909091,0.840909090909091;1,0.818181818181818,0.818181818181818;1,0.795454545454545,0.795454545454545;1,0.772727272727273,0.772727272727273;1,0.750000000000000,0.750000000000000;1,0.727272727272727,0.727272727272727;1,0.704545454545455,0.704545454545455;1,0.681818181818182,0.681818181818182;1,0.659090909090909,0.659090909090909;1,0.636363636363636,0.636363636363636;1,0.613636363636364,0.613636363636364;1,0.590909090909091,0.590909090909091;1,0.568181818181818,0.568181818181818;1,0.545454545454545,0.545454545454545;1,0.522727272727273,0.522727272727273;1,0.500000000000000,0.500000000000000;1,0.477272727272727,0.477272727272727;1,0.454545454545455,0.454545454545455;1,0.431818181818182,0.431818181818182;1,0.409090909090909,0.409090909090909;1,0.386363636363636,0.386363636363636;1,0.363636363636364,0.363636363636364;1,0.340909090909091,0.340909090909091;1,0.318181818181818,0.318181818181818;1,0.295454545454545,0.295454545454545;1,0.272727272727273,0.272727272727273;1,0.250000000000000,0.250000000000000;1,0.227272727272727,0.227272727272727;1,0.204545454545455,0.204545454545455;1,0.181818181818182,0.181818181818182;1,0.159090909090909,0.159090909090909;1,0.136363636363636,0.136363636363636;1,0.113636363636364,0.113636363636364;1,0.0909090909090909,0.0909090909090909;1,0.0681818181818182,0.0681818181818182;1,0.0454545454545454,0.0454545454545454;1,0.0227272727272727,0.0227272727272727;1,0,0;1,0,0;0.850000000000000,0,0.200000000000000;0.700000000000000,0,0.400000000000000;0.550000000000000,0,0.600000000000000;0.400000000000000,0,0.800000000000000];
        end

        function [vout] = rcvec(~,v,rc)
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


        
        function [ modelout,neworder] = reordercomponents(app, model,varargin )
            % Order PARAFAC model components by their emission maximum
            % Doc to follow

            %% Input parsing
            if nargin==1
                method='emmax';
                f=app.f;
            elseif nargin>1
                % 2 varargs 1st:
                for n=1:numel(varargin)
                    if isnumeric(varargin{n})
                        f=varargin{n};
                    elseif ischar(varargin{n})
                        method=varargin{n};
                    end
                end

                if not(exist('method','var'))
                    method='emmax';
                end

                if not(exist('f','var'))
                    f=find(arrayfun(@(x) not(isempty(x.loads)),model.models));
                end

                if nargin>3
                    error('reordercomponents only parses three input arguments.')
                end
            end


            clearvars cnt
            modelout=model;
            neworder=cell(max(f),1);
            for j=1:numel(f)
                n=f(j);
                % if isempty(model.models(n).loads)
                %     disp(modelout.models)
                %     error('reodercomponents:fields',...
                %         'The dataset does not contain a model with the specified number of factors')
                % end

                M = modelout.models(n).loads;
                Csize = modelout.models(n).componentContribution;
                switch method
                    case 'emmax'
                        [~,idx]=max(M{2});
                        [~,seq]=sort(idx);
                    case 'emmaxinv'
                        [~,idx]=max(M{2});
                        [~,seq]=sort(idx,'descend');
                    case 'waveem'
                        waveem=mean(modelout.Em.*M{2});
                        [~,seq]=sort(waveem);
                    case 'apparentstokes'
                        [~,idx]=max(M{2});
                        Em_pos=1./model.Em(idx).*1E7;
                        [~,idx]=max(M{3});
                        Ex_pos=1./model.Ex(idx).*1E7;
                        astokes=Ex_pos-Em_pos;
                        astokes=astokes.*1.23981E-4;
                        [~,seq]=sort(astokes);
                    case 'contribution'
                        [~,seq]=sort(diag(M{1}'*M{1}),'descend');
                    otherwise
                        error('''method'' must be one of the following: [emmax|waveem|apparentstokes|contribution]')
                end
                neworder{n}=seq;

                Mnew=cell(1,3);

                CsizeNew=Csize(seq);
                for i=1:numel(M)
                    Mnew{i}=M{i}(:,seq);
                end

                modelout.models(n).loads = Mnew;
                modelout.models(n).componentContribution = CsizeNew;
            end


            % In case f was just one specific component, neworder need not be a cell array
            if n==1
                neworder=neworder{1};
            end

            % message={'emmax','emission maximum';...
            %     'waveem','weigted average emission maximum';...
            %     'apparentstokes','apparent Stokes shift (max. Ex/Em)';...
            %     'contribution','component contribution (drEEM/N-way default)'};
            % 
            % midx=contains(message(:,1),method);

            %disp(sprintf(['\nModels with [',num2str(f'),'] components reordered according to the ',message{midx,2},'\n'])) %#ok<DSPS>

        end
        
        function paintScoresandLoadingsCanvas(app)
            Ylab=[cellstr(repmat('Scores',numel(app.f),1));cellstr(repmat('Loadings',2*app.ncomp,1))];
            Xlab=[cellstr(repmat('Sample',numel(app.f),1));cellstr(repmat('Emission (nm)',app.ncomp,1));cellstr(repmat('Excitation (nm)',app.ncomp,1))];
            fld=[cellstr(repmat('i',numel(app.f),1));cellstr(repmat('Em',app.ncomp,1));cellstr(repmat('Ex',app.ncomp,1))];
            fa=repmat(app.f,3,1)';
            da=repelem(1:3,1,app.ncomp)';
            tit=cellstr(strcat(num2str(app.f),repmat(' - component model',app.ncomp,1)));
            lstyle=[cellstr(repmat('none',app.ncomp,1));cellstr(repmat('-',2*app.ncomp,1))];

            t=tiledlayout(app.scoresloadscanvas,3,app.ncomp,'padding','compact','TileSpacing','compact');
            for j = 1 : 3*app.ncomp
                ax=nexttile(t);
                plot(ax,app.data.(fld{j}),app.models(fa(j)).loads{da(j)},'LineStyle',lstyle{j},'Marker','.')
                ax.YLabel.String = Ylab{j};
                ax.XLabel.String = Xlab{j};
                if j<=numel(tit)
                    title(ax,tit{j})
                end
                axis(ax,'tight')
                ax.ContextMenu=app.ContextMenu2;
            end
            app.ScoresloadingsTab.Tag='painted';

            legend1=legend(ax,cellstr(num2str((1:size(app.models(fa(j)).loads{da(j)},2))')));
            legend1.ItemTokenSize=legend1.ItemTokenSize./3;
            legend1.Layout.Tile='east';

        end
        
        function paintCorrCanvas(app)
            t=tiledlayout(app.corrcanvas,'flow','padding','compact','TileSpacing','compact');
            fcor=app.f;
            fcor(fcor==1)=[];

            for n=1:numel(fcor)
                comparisons=nchoosek(1:fcor(n),2);
                rsq{n}=nan(fcor(n));
                for k=1:size(comparisons,1)
                    x=app.models(fcor(n)).loads{1}(:,comparisons(k,1));
                    y=app.models(fcor(n)).loads{1}(:,comparisons(k,2));
                    [~,S] = polyfit(x,y,1);
                    rsq{n}(comparisons(k,1),comparisons(k,2))=1 - (S.normr/norm(y - mean(y)))^2;
                end
            end
            app.ScorecorrelationTab.Tag='painted';

            for n=1:numel(fcor)
                cormap=rsq{n};
                ax=nexttile(t);
                heatmap(t,round(cormap,2),'MissingDataColor','k',...
                    'Title',[num2str(fcor(n)),'-component model'],...
                    'Colormap',app.cmap,'ColorLimits',[0 1]);
                %ax.ContextMenu=app.ContextMenu2;
            end
        end
        
        function paintLoadingsTab(app)
            t = tiledlayout(app.loadstab,app.ncomp,max(app.f),'padding','compact','TileSpacing','compact');
            for n=1:app.ncomp*max(app.f),ax(n)=nexttile(t);ax(n).ContextMenu=app.ContextMenu2;end
            cnt=1;
            for n=1:numel(app.f)
                ncomp=app.f(n);
                [temp,idx]=app.reordercomponents(app.data,'emmaxinv');
                [~,B,C] = nway.modeleval.fac2let(temp.models(ncomp).loads);
                for i=1:max(app.f)
                    if i<=ncomp
                        hold(ax(cnt),'on')
                        plot(ax(cnt),app.data.Em,B(:,i),'LineStyle','-','Color',[.3 .3 .3])
                        plot(ax(cnt),app.data.Ex,C(:,i),'LineStyle','-.','Color',[.3 .3 .3])
                        box(ax(cnt),'on')
                        cnt = cnt + 1;
                    else
                        delete(ax(cnt))
                        cnt = cnt + 1;
                    end
                end
            end

            ylabel(t,'Loadings (comp. reordered by em. max.)')
            xlabel(t,'Wavelength (nm)')
            %title(t,'Loadings overview (components reordered by decreasing emission maximum)')
            app.SpectralloadingsTab.Tag='painted';
        end
    end



    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, models, startTab, f)
            arguments
                app
                models (1,1) {mustBeA(models,'drEEMdataset'),drEEMdataset.validate(models)}
                startTab (1,:) {mustBeText,...
                    mustBeMember(startTab,["Overview","Scores & loadings",...
                    "Spectral loadings","Loadings & leverages","Errors & leverages", ...
                    "Fingerprint plots","SSE","Score correlation"])} = "Overview"
                f (1,1) {mustBeNumeric} = NaN
            end
            %% GUI format stuff (app and default tab)
            app.viewmodelsDiagnosePARAFACmodelsUIFigure.Visible='off';
            movegui(app.viewmodelsDiagnosePARAFACmodelsUIFigure,'center')
            app.viewmodelsDiagnosePARAFACmodelsUIFigure.Visible='on';
            warning off
            app.viewmodelsDiagnosePARAFACmodelsUIFigure.Units = "normalized";
            app.TabGroup.Units="normalized";
            app.TabGroup.Position=[0 0 1 1];
            warning on
            disableDefaultInteractivity(app.core)
            disableDefaultInteractivity(app.var)
            
            %% Assign the basic properties
            app.data=models;
            app.f=find(arrayfun(@(x) not(isempty(x.loads{1})),models.models));
            app.ncomp=numel(app.f);
            if app.ncomp==0
                close(app.viewmodelsDiagnosePARAFACmodelsUIFigure)
                error('Can''t seem to find any models')
            end
            
            app.models=models.models;
            m=models.models;
            m=m(app.f);

            %% Make the dropdown menues
            app.lldrop.Items = cellstr(strcat(num2str(app.f),repmat(' - component model',app.ncomp,1)));
            app.eldrop.Items = cellstr(strcat(num2str(app.f),repmat(' - component model',app.ncomp,1)));
            app.fingerdrop.Items = cellstr(strcat(num2str(app.f),repmat(' - component model',app.ncomp,1)));
            app.ssedrop.Items = cellstr(strcat(num2str(app.f),repmat(' - component model',app.ncomp,1)));
            
            if not(isnan(f))
                drEEMdataset.mustBeModel(models,f)
                app.lldrop.Value(1) = num2str(f);
                app.eldrop.Value(1) = num2str(f);
                app.fingerdrop.Value(1) = num2str(f);
                app.ssedrop.Value(1) = num2str(f);
            end
            %% Change to default tab
            
            selected=matches({app.TabGroup.Children.Title},startTab);
            app.TabGroup.SelectedTab=app.TabGroup.Children(selected);
            app.TabGroupSelectionChanged(app)
            
            %% Core and var plots
            cc=nan(app.ncomp,1);
            ve=nan(app.ncomp,1);
            for n=1:numel(app.f)
                comp(n,1)=app.f(n);
                cc(n,1) = app.models(app.f(n)).core;
                ve(n,1) = app.models(app.f(n)).percentExplained;
            end
            comp(comp==0)=nan;
            plot(app.core,comp,cc, ...
                'LineWidth',1,'Marker','o','MarkerFaceColor','k', ...
                'MarkerEdgeColor','k',Color='k')
            yline(app.core,0,'Color','r')
            plot(app.var,comp,ve, ...
                'LineWidth',1,'Marker','o','MarkerFaceColor','k', ...
                'MarkerEdgeColor','k',Color='k')
            ylabel(app.core,'% core consistency')
            ylabel(app.var,'% explained variance')
            xlabel(app.core,'Number of components')
            xlabel(app.var,'Number of components')

            set(app.core,'XTick',app.f)
            set(app.var,'XTick',app.f)

            
            
            %% UI table 

            
            flds={'No. comp.','status','% expl.','SSE','core','% unconverged','initialization','starts','conv. crit.','constraints','toolbox'};
            t1=table;t1.('No. comp.')=app.f;
            t=drEEMmodel.convert2table(m);

            t=t(:,[4 5 6 7 8 10 : 14]);
            t=[t1 t];
            t.Properties.VariableNames=flds;
            
            txt=cellstr(num2str(t.("conv. crit."),'%e'));
            txtn=cell(size(txt));
            for j=1:numel(txt)
                th=txt{j};
                th=strsplit(th,'e');
                th=['1^{',th{end},'}'];
                txtn{j}=th;
            end
            t.("conv. crit.")=txtn;clearvars txt txtn
            
            app.UITable.ColumnName=flds;
            app.UITable.Data=t;

            % table styles (comfort features, can be turned off if they
            % cause trouble)
            
            % Exponent notation for convergence
            s = uistyle("Interpreter","tex");
            addStyle(app.UITable,s,"column",9);

            % Diagnosis of convergence criteria
            conv=drEEMmodel.convert2table(m).("convergence");
            for j=1:height(conv)
                if conv(j)>1e-4
                    s2 = uistyle("Icon","error","IconAlignment","rightmargin");
                elseif conv(j)<=1e-4&&conv(j)>=1e-6
                    s2 = uistyle("Icon","warning","IconAlignment","rightmargin");
                elseif conv(j)<1e-6
                    s2 = uistyle("Icon","success","IconAlignment","rightmargin");
                end
                addStyle(app.UITable,s2,'cell',[j,9])
            end
            
            % Bring validation status to attention of user.
            fs={'not yet validated','not validated','validated'};
            for j = 1 : numel(fs)
                switch fs{j}
                    case 'not yet validated'
                         s  = uistyle("Icon","warning","IconAlignment","rightmargin");
                    case 'not validated'
                        s  = uistyle("Icon","error","IconAlignment","rightmargin");
                    case 'validated'
                        s  = uistyle("Icon","success","IconAlignment","rightmargin");
                end
                idx=matches(app.UITable.Data.status,fs{j});
                if any(idx)
                    addStyle(app.UITable,s,'cell',[find(idx),repelem(2,sum(idx),1)])
                end
            end

            % Percent unconverged attention
            pu=app.UITable.Data.("% unconverged");
            for j=1:height(pu)
                if pu(j)==0
                    s2 = uistyle("Icon","success","IconAlignment","rightmargin");
                elseif pu(j)>0&&pu(j)<=30
                    s2 = uistyle("Icon","warning","IconAlignment","rightmargin");
                elseif pu(j)>30
                    s2 = uistyle("Icon","error","IconAlignment","rightmargin");
                end
                addStyle(app.UITable,s2,'cell',[j,6])
            end

        end

        % Value changed function: LinelegendCheckBox, lldrop
        function lldropValueChanged(app, event)
            value = app.lldrop.Value;
            value=erase(value,' ');
            f=str2double(value(1));
            factors=app.models(f).loads;
            lev=app.models(f).leverages;
           

            plotdat=[factors lev];
            xax=repmat({app.data.i app.data.Em app.data.Ex},1,2);
            lspec={'-' '-' '-' 'none' 'none' 'none'};
            mstyle={'.' '.' '.' '+' '+' '+'};
            ax={'scs','loem','loex','les','leem','leex'};
            for n=1:6
                plot(app.(ax{n}),xax{n},plotdat{n}, ...
                    LineStyle=lspec{n},Marker=mstyle{n})
                axis(app.(ax{n}),'tight')
                grid(app.(ax{n}),'on')

            end

            if app.LinelegendCheckBox.Value
                legend1=legend(app.loex,cellstr(num2str((1:size(plotdat{3},2))')));
                try legend1.ItemTokenSize=legend1.ItemTokenSize./3;end %#ok<TRYNC>
            else
                legend(app.loex,'hide')
            end
        end

        % Value changed function: ColormapDropDown, 
        % ...and 2 other components
        function fingerdropValueChanged(app, event)
            value = app.fingerdrop.Value;
            value=erase(value,' ');
            f=str2double(value(1));
            factors=app.models(f).loads;
            app.fingergrid = tiledlayout(app.fingerpanel,'flow','padding','normal','TileSpacing','compact');

            scatter{1}=@(x) 1*10^7*((1*10^7)/(x)-3382)^-1;
            scatter{2}=@(x) (1*10^7*((1*10^7)/(x)-3382)^-1)*2;

            scatter{3}=@(x) x;
            scatter{4}=@(x) x*2;


            for n=1:f
                ax(n)=nexttile(app.fingergrid);
                hold(ax(n),'on')
                pbaspect(ax(n),[1 1 1])
            end

            for n=1:f
                contourf(ax(n),app.data.Ex,app.data.Em,factors{2}(:,n).*factors{3}(:,n)',100,'LineStyle','none','DisplayName','contourf');
                contour(ax(n),app.data.Ex,app.data.Em,factors{2}(:,n).*factors{3}(:,n)',app.NumberofcontousSpinner.Value,'Color','k','DisplayName','contourf');
                grid(ax(n),'on')
                title(ax(n),['C',num2str(n)])
                if app.ShowRamanandRayleighscatterlocationCheckBox.Value
                    for k=1:numel(scatter)
                        line(ax(n),[min(app.data.Ex) max(app.data.Ex)],[scatter{k}(min(app.data.Ex)) scatter{k}(max(app.data.Ex))],'Color','r')
                    end
                end
                xlim(ax(n),[min(app.data.Ex) max(app.data.Ex)])
                ylim(ax(n),[min(app.data.Em) max(app.data.Em)])
                switch app.ColormapDropDown.Value
                    case {'turbo','parula'}
                        colormap(ax(n),app.ColormapDropDown.Value)
                    otherwise
                        map=crameri.makemap(app.ColormapDropDown.Value);
                        colormap(ax(n),map)
                end

            end
            xlabel(app.fingergrid,'Excitation (nm)')
            ylabel(app.fingergrid,'Emission (nm)')

        end

        % Value changed function: ssedrop
        function ssedropValueChanged(app, event)
            value = app.ssedrop.Value;
            value=erase(value,' ');
            f=str2double(value(1));
            err=app.models(f).sse;
            xax={app.data.i app.data.Em app.data.Ex};

            lspec={'-' '-' '-' };
            mstyle={'.' '.' '.'};

            ax=[app.ssesam;app.sseem;app.sseex];
            for n=1:3
                plot(ax(n),xax{n},err{n},'LineStyle',lspec{n},'Marker',mstyle{n},Color='k')
                axis(ax(n),'padded')
                ylim(ax(n),[0 inf])
                pbaspect(ax(n),[1 1 1])
            end
        end

        % Value changed function: eldrop
        function eldropValueChanged(app, event)
            value = app.eldrop.Value;
            value=erase(value,' ');
            f=str2double(value(1));
            err=app.models(f).sse;
            lev=app.models(f).leverages;
            cax={app.data.i app.data.Em app.data.Ex};

            ax=[app.elsam;app.elem;app.elex];
            for n=1:3
                scatter(ax(n),lev{n},err{n},25,cax{n},'filled')
                colorbar(ax(n))
                axis(ax(n),'padded')
                ylim(ax(n),[0 inf])
                pbaspect(ax(n),[1 1 1])
            end
            
        end

        % Button pushed function: viewcorrelationsvsmetadataButton
        function viewcorrelationsvsmetadataButtonPushed(app, event)
            dreemgui.viewcompcorr_gui(app.data)
        end

        % Selection change function: TabGroup
        function TabGroupSelectionChanged(app, event)
            selectedTab = app.TabGroup.SelectedTab;
            if matches(selectedTab.Tag,'painted')
                return
            else
                switch selectedTab.Title
                    case 'Scores & loadings'
                        app.paintScoresandLoadingsCanvas
                    case 'Spectral loadings'
                        app.paintLoadingsTab
                    case 'Score correlation'
                        app.paintCorrCanvas
                    case 'Loadings & leverages'
                        lldropValueChanged(app)
                    case 'Errors & leverages'
                        eldropValueChanged(app)
                    case 'Fingerprint plots'
                        fingerdropValueChanged(app)
                    case 'SSE'
                        ssedropValueChanged(app)
                end
            end
        end

        % Menu selected function: SavefigurepanelMenu, 
        % ...and 1 other component
        function SavefigurepanelMenuSelected(app, event)
            sel=app.TabGroup.SelectedTab;
            panel = findobj(sel, 'Type', 'uipanel');
            if isempty(panel)
                warning('Could not find a panel in the selected tab. Cannot save as image.')
                return
            end
            defname=[char(sel.Title),'.png'];

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
            
            figure(app.viewmodelsDiagnosePARAFACmodelsUIFigure)
        end

        % Value changed function: 
        % ShowRamanandRayleighscatterlocationCheckBox
        function ShowRamanandRayleighscatterlocationCheckBoxValueChanged(app, event)
            value = app.ShowRamanandRayleighscatterlocationCheckBox.Value;
            app.fingerdropValueChanged
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create viewmodelsDiagnosePARAFACmodelsUIFigure and hide until all components are created
            app.viewmodelsDiagnosePARAFACmodelsUIFigure = uifigure('Visible', 'off');
            app.viewmodelsDiagnosePARAFACmodelsUIFigure.Position = [92 92 946 529];
            app.viewmodelsDiagnosePARAFACmodelsUIFigure.Name = 'viewmodels: Diagnose PARAFAC models';

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.viewmodelsDiagnosePARAFACmodelsUIFigure);
            app.GridLayout5.ColumnWidth = {'1x'};
            app.GridLayout5.RowHeight = {'1x'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout5);
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create OverviewTab
            app.OverviewTab = uitab(app.TabGroup);
            app.OverviewTab.Title = 'Overview';

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.OverviewTab);
            app.GridLayout4.RowHeight = {'0.5x', '1x'};

            % Create UITable
            app.UITable = uitable(app.GridLayout4);
            app.UITable.ColumnName = '';
            app.UITable.RowName = {};
            app.UITable.Layout.Row = 1;
            app.UITable.Layout.Column = [1 2];

            % Create Panel_2
            app.Panel_2 = uipanel(app.GridLayout4);
            app.Panel_2.BackgroundColor = [1 1 1];
            app.Panel_2.Layout.Row = 2;
            app.Panel_2.Layout.Column = [1 2];

            % Create GridLayout10
            app.GridLayout10 = uigridlayout(app.Panel_2);
            app.GridLayout10.RowHeight = {'1x'};
            app.GridLayout10.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create core
            app.core = uiaxes(app.GridLayout10);
            title(app.core, 'Core consistency')
            xlabel(app.core, 'Number of components')
            ylabel(app.core, '% core consistency')
            zlabel(app.core, 'Z')
            app.core.FontName = 'Helvetica';
            app.core.Box = 'on';
            app.core.Layout.Row = 1;
            app.core.Layout.Column = 1;
            colormap(app.core, 'parula')

            % Create var
            app.var = uiaxes(app.GridLayout10);
            title(app.var, 'Explained variance')
            xlabel(app.var, 'Number of components')
            ylabel(app.var, '% explained variance')
            zlabel(app.var, 'Z')
            app.var.FontName = 'Helvetica';
            app.var.Box = 'on';
            app.var.Layout.Row = 1;
            app.var.Layout.Column = 2;
            colormap(app.var, 'parula')

            % Create ScoresloadingsTab
            app.ScoresloadingsTab = uitab(app.TabGroup);
            app.ScoresloadingsTab.Title = 'Scores & loadings';

            % Create GridLayout7
            app.GridLayout7 = uigridlayout(app.ScoresloadingsTab);
            app.GridLayout7.ColumnWidth = {30, '1x'};
            app.GridLayout7.RowHeight = {'1x'};

            % Create scoresloadscanvas
            app.scoresloadscanvas = uipanel(app.GridLayout7);
            app.scoresloadscanvas.BackgroundColor = [0.9412 0.9412 0.9412];
            app.scoresloadscanvas.Layout.Row = 1;
            app.scoresloadscanvas.Layout.Column = [1 2];

            % Create SpectralloadingsTab
            app.SpectralloadingsTab = uitab(app.TabGroup);
            app.SpectralloadingsTab.Title = 'Spectral loadings';

            % Create GridLayout8
            app.GridLayout8 = uigridlayout(app.SpectralloadingsTab);
            app.GridLayout8.ColumnWidth = {'1x'};
            app.GridLayout8.RowHeight = {'1x'};

            % Create loadstab
            app.loadstab = uipanel(app.GridLayout8);
            app.loadstab.BackgroundColor = [0.9412 0.9412 0.9412];
            app.loadstab.Layout.Row = 1;
            app.loadstab.Layout.Column = 1;

            % Create LoadingsleveragesTab
            app.LoadingsleveragesTab = uitab(app.TabGroup);
            app.LoadingsleveragesTab.Title = 'Loadings & leverages';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.LoadingsleveragesTab);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout.RowHeight = {30, '1x', '1x'};

            % Create lldrop
            app.lldrop = uidropdown(app.GridLayout);
            app.lldrop.ValueChangedFcn = createCallbackFcn(app, @lldropValueChanged, true);
            app.lldrop.Layout.Row = 1;
            app.lldrop.Layout.Column = 2;

            % Create LinelegendCheckBox
            app.LinelegendCheckBox = uicheckbox(app.GridLayout);
            app.LinelegendCheckBox.ValueChangedFcn = createCallbackFcn(app, @lldropValueChanged, true);
            app.LinelegendCheckBox.Text = 'Line legend';
            app.LinelegendCheckBox.Layout.Row = 1;
            app.LinelegendCheckBox.Layout.Column = 3;
            app.LinelegendCheckBox.Value = true;

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.BackgroundColor = [1 1 1];
            app.Panel.Layout.Row = [2 3];
            app.Panel.Layout.Column = [1 3];

            % Create GridLayout9
            app.GridLayout9 = uigridlayout(app.Panel);
            app.GridLayout9.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout9.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create scs
            app.scs = uiaxes(app.GridLayout9);
            title(app.scs, 'Scores: samples')
            xlabel(app.scs, 'Sample identifier (data.i)')
            ylabel(app.scs, 'Scores')
            zlabel(app.scs, 'Z')
            app.scs.FontName = 'Helvetica';
            app.scs.Box = 'on';
            app.scs.Layout.Row = 1;
            app.scs.Layout.Column = 1;
            colormap(app.scs, 'parula')

            % Create loem
            app.loem = uiaxes(app.GridLayout9);
            title(app.loem, 'Loadings: emission')
            xlabel(app.loem, 'Wavelength (nm)')
            ylabel(app.loem, 'Loadings')
            zlabel(app.loem, 'Z')
            app.loem.FontName = 'Helvetica';
            app.loem.Box = 'on';
            app.loem.Layout.Row = 1;
            app.loem.Layout.Column = 2;
            colormap(app.loem, 'parula')

            % Create loex
            app.loex = uiaxes(app.GridLayout9);
            title(app.loex, 'Loadings: excitation')
            xlabel(app.loex, 'Wavelength (nm)')
            ylabel(app.loex, 'Loadings')
            zlabel(app.loex, 'Z')
            app.loex.FontName = 'Helvetica';
            app.loex.Box = 'on';
            app.loex.Layout.Row = 1;
            app.loex.Layout.Column = 3;
            colormap(app.loex, 'parula')

            % Create les
            app.les = uiaxes(app.GridLayout9);
            title(app.les, 'Leverage: samples')
            xlabel(app.les, 'Sample identifier (data.i)')
            ylabel(app.les, 'Leverage')
            zlabel(app.les, 'Z')
            app.les.FontName = 'Helvetica';
            app.les.Box = 'on';
            app.les.Layout.Row = 2;
            app.les.Layout.Column = 1;
            colormap(app.les, 'parula')

            % Create leem
            app.leem = uiaxes(app.GridLayout9);
            title(app.leem, 'Leverage: emission')
            xlabel(app.leem, 'Wavelength (nm)')
            ylabel(app.leem, 'Leverage')
            zlabel(app.leem, 'Z')
            app.leem.FontName = 'Helvetica';
            app.leem.Box = 'on';
            app.leem.Layout.Row = 2;
            app.leem.Layout.Column = 2;
            colormap(app.leem, 'parula')

            % Create leex
            app.leex = uiaxes(app.GridLayout9);
            title(app.leex, 'Leverage: excitation')
            xlabel(app.leex, 'Wavelength (nm)')
            ylabel(app.leex, 'Leverage')
            zlabel(app.leex, 'Z')
            app.leex.FontName = 'Helvetica';
            app.leex.Box = 'on';
            app.leex.Layout.Row = 2;
            app.leex.Layout.Column = 3;
            colormap(app.leex, 'parula')

            % Create ErrorsleveragesTab
            app.ErrorsleveragesTab = uitab(app.TabGroup);
            app.ErrorsleveragesTab.Title = 'Errors & leverages';

            % Create GridLayout_2
            app.GridLayout_2 = uigridlayout(app.ErrorsleveragesTab);
            app.GridLayout_2.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout_2.RowHeight = {30, '1x', '1x'};
            app.GridLayout_2.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create eldrop
            app.eldrop = uidropdown(app.GridLayout_2);
            app.eldrop.ValueChangedFcn = createCallbackFcn(app, @eldropValueChanged, true);
            app.eldrop.Layout.Row = 1;
            app.eldrop.Layout.Column = 2;

            % Create Panel_3
            app.Panel_3 = uipanel(app.GridLayout_2);
            app.Panel_3.BackgroundColor = [1 1 1];
            app.Panel_3.Layout.Row = [2 3];
            app.Panel_3.Layout.Column = [1 3];

            % Create GridLayout11
            app.GridLayout11 = uigridlayout(app.Panel_3);
            app.GridLayout11.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout11.RowHeight = {'1x'};
            app.GridLayout11.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create elsam
            app.elsam = uiaxes(app.GridLayout11);
            title(app.elsam, 'samples')
            xlabel(app.elsam, 'leverages')
            ylabel(app.elsam, 'sum of squared errors')
            zlabel(app.elsam, 'Z')
            app.elsam.FontName = 'Helvetica';
            app.elsam.Box = 'on';
            app.elsam.Layout.Row = 1;
            app.elsam.Layout.Column = 1;
            colormap(app.elsam, 'parula')

            % Create elem
            app.elem = uiaxes(app.GridLayout11);
            title(app.elem, 'emission')
            xlabel(app.elem, 'leverages')
            ylabel(app.elem, 'sum of squared errors')
            zlabel(app.elem, 'Z')
            app.elem.FontName = 'Helvetica';
            app.elem.Box = 'on';
            app.elem.Layout.Row = 1;
            app.elem.Layout.Column = 2;
            colormap(app.elem, 'parula')

            % Create elex
            app.elex = uiaxes(app.GridLayout11);
            title(app.elex, 'excitation')
            xlabel(app.elex, 'leverages')
            ylabel(app.elex, 'sum of squared errors')
            zlabel(app.elex, 'Z')
            app.elex.FontName = 'Helvetica';
            app.elex.Box = 'on';
            app.elex.Layout.Row = 1;
            app.elex.Layout.Column = 3;
            colormap(app.elex, 'parula')

            % Create FingerprintplotsTab
            app.FingerprintplotsTab = uitab(app.TabGroup);
            app.FingerprintplotsTab.Title = 'Fingerprint plots';

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.FingerprintplotsTab);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout2.RowHeight = {30, '1x'};
            app.GridLayout2.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create fingerdrop
            app.fingerdrop = uidropdown(app.GridLayout2);
            app.fingerdrop.ValueChangedFcn = createCallbackFcn(app, @fingerdropValueChanged, true);
            app.fingerdrop.Layout.Row = 1;
            app.fingerdrop.Layout.Column = 5;

            % Create fingerpanel
            app.fingerpanel = uipanel(app.GridLayout2);
            app.fingerpanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.fingerpanel.Layout.Row = 2;
            app.fingerpanel.Layout.Column = [1 6];

            % Create ShowRamanandRayleighscatterlocationCheckBox
            app.ShowRamanandRayleighscatterlocationCheckBox = uicheckbox(app.GridLayout2);
            app.ShowRamanandRayleighscatterlocationCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowRamanandRayleighscatterlocationCheckBoxValueChanged, true);
            app.ShowRamanandRayleighscatterlocationCheckBox.Text = 'Show Raman and Rayleigh scatter location';
            app.ShowRamanandRayleighscatterlocationCheckBox.Layout.Row = 1;
            app.ShowRamanandRayleighscatterlocationCheckBox.Layout.Column = 6;

            % Create ColormapLabel
            app.ColormapLabel = uilabel(app.GridLayout2);
            app.ColormapLabel.HorizontalAlignment = 'right';
            app.ColormapLabel.Layout.Row = 1;
            app.ColormapLabel.Layout.Column = 1;
            app.ColormapLabel.Text = 'Colormap:';

            % Create ColormapDropDown
            app.ColormapDropDown = uidropdown(app.GridLayout2);
            app.ColormapDropDown.Items = {'turbo', 'roma', 'imola', 'hawaii', 'batlow', 'parula', '-imola', '-hawaii', '-batlow'};
            app.ColormapDropDown.ValueChangedFcn = createCallbackFcn(app, @fingerdropValueChanged, true);
            app.ColormapDropDown.Layout.Row = 1;
            app.ColormapDropDown.Layout.Column = 2;
            app.ColormapDropDown.Value = 'turbo';

            % Create NumberofcontousSpinnerLabel
            app.NumberofcontousSpinnerLabel = uilabel(app.GridLayout2);
            app.NumberofcontousSpinnerLabel.HorizontalAlignment = 'right';
            app.NumberofcontousSpinnerLabel.Layout.Row = 1;
            app.NumberofcontousSpinnerLabel.Layout.Column = 3;
            app.NumberofcontousSpinnerLabel.Text = 'Number of contous:';

            % Create NumberofcontousSpinner
            app.NumberofcontousSpinner = uispinner(app.GridLayout2);
            app.NumberofcontousSpinner.Limits = [0 50];
            app.NumberofcontousSpinner.ValueChangedFcn = createCallbackFcn(app, @fingerdropValueChanged, true);
            app.NumberofcontousSpinner.Layout.Row = 1;
            app.NumberofcontousSpinner.Layout.Column = 4;
            app.NumberofcontousSpinner.Value = 15;

            % Create SSETab
            app.SSETab = uitab(app.TabGroup);
            app.SSETab.Title = 'SSE';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.SSETab);
            app.GridLayout3.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout3.RowHeight = {30, '1x'};
            app.GridLayout3.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create ssedrop
            app.ssedrop = uidropdown(app.GridLayout3);
            app.ssedrop.ValueChangedFcn = createCallbackFcn(app, @ssedropValueChanged, true);
            app.ssedrop.Layout.Row = 1;
            app.ssedrop.Layout.Column = 2;

            % Create Panel_4
            app.Panel_4 = uipanel(app.GridLayout3);
            app.Panel_4.BackgroundColor = [0.9412 0.9412 0.9412];
            app.Panel_4.Layout.Row = 2;
            app.Panel_4.Layout.Column = [1 3];

            % Create GridLayout12
            app.GridLayout12 = uigridlayout(app.Panel_4);
            app.GridLayout12.ColumnWidth = {'1x', '1x', '1x'};
            app.GridLayout12.RowHeight = {'1x'};
            app.GridLayout12.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create ssesam
            app.ssesam = uiaxes(app.GridLayout12);
            title(app.ssesam, 'Samples')
            xlabel(app.ssesam, 'Samples')
            ylabel(app.ssesam, 'SSE')
            zlabel(app.ssesam, 'Z')
            app.ssesam.FontName = 'Helvetica';
            app.ssesam.Box = 'on';
            app.ssesam.Layout.Row = 1;
            app.ssesam.Layout.Column = 1;
            colormap(app.ssesam, 'parula')

            % Create sseem
            app.sseem = uiaxes(app.GridLayout12);
            title(app.sseem, 'Emission')
            xlabel(app.sseem, 'Wavelength (nm)')
            ylabel(app.sseem, 'SSE')
            zlabel(app.sseem, 'Z')
            app.sseem.FontName = 'Helvetica';
            app.sseem.Box = 'on';
            app.sseem.Layout.Row = 1;
            app.sseem.Layout.Column = 2;
            colormap(app.sseem, 'parula')

            % Create sseex
            app.sseex = uiaxes(app.GridLayout12);
            title(app.sseex, 'Excitation')
            xlabel(app.sseex, 'Wavelength (nm)')
            ylabel(app.sseex, 'SSE')
            zlabel(app.sseex, 'Z')
            app.sseex.FontName = 'Helvetica';
            app.sseex.Box = 'on';
            app.sseex.Layout.Row = 1;
            app.sseex.Layout.Column = 3;
            colormap(app.sseex, 'parula')

            % Create ScorecorrelationTab
            app.ScorecorrelationTab = uitab(app.TabGroup);
            app.ScorecorrelationTab.Title = 'Score correlation';

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.ScorecorrelationTab);
            app.GridLayout6.ColumnWidth = {'1x', 200};
            app.GridLayout6.RowHeight = {30, '1x'};

            % Create corrcanvas
            app.corrcanvas = uipanel(app.GridLayout6);
            app.corrcanvas.BackgroundColor = [0.9412 0.9412 0.9412];
            app.corrcanvas.Layout.Row = 2;
            app.corrcanvas.Layout.Column = [1 2];

            % Create viewcorrelationsvsmetadataButton
            app.viewcorrelationsvsmetadataButton = uibutton(app.GridLayout6, 'push');
            app.viewcorrelationsvsmetadataButton.ButtonPushedFcn = createCallbackFcn(app, @viewcorrelationsvsmetadataButtonPushed, true);
            app.viewcorrelationsvsmetadataButton.Layout.Row = 1;
            app.viewcorrelationsvsmetadataButton.Layout.Column = 2;
            app.viewcorrelationsvsmetadataButton.Text = 'view correlations vs. metadata';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.viewmodelsDiagnosePARAFACmodelsUIFigure);

            % Create SavefigurepanelMenu
            app.SavefigurepanelMenu = uimenu(app.ContextMenu);
            app.SavefigurepanelMenu.MenuSelectedFcn = createCallbackFcn(app, @SavefigurepanelMenuSelected, true);
            app.SavefigurepanelMenu.Text = 'Save figure panel';
            
            % Assign app.ContextMenu
            app.Panel_2.ContextMenu = app.ContextMenu;
            app.GridLayout10.ContextMenu = app.ContextMenu;
            app.scoresloadscanvas.ContextMenu = app.ContextMenu;
            app.loadstab.ContextMenu = app.ContextMenu;
            app.Panel.ContextMenu = app.ContextMenu;
            app.GridLayout9.ContextMenu = app.ContextMenu;
            app.GridLayout_2.ContextMenu = app.ContextMenu;
            app.GridLayout11.ContextMenu = app.ContextMenu;
            app.fingerpanel.ContextMenu = app.ContextMenu;
            app.Panel_4.ContextMenu = app.ContextMenu;
            app.GridLayout12.ContextMenu = app.ContextMenu;
            app.corrcanvas.ContextMenu = app.ContextMenu;

            % Create ContextMenu2
            app.ContextMenu2 = uicontextmenu(app.viewmodelsDiagnosePARAFACmodelsUIFigure);

            % Create SavefigurepanelMenu_2
            app.SavefigurepanelMenu_2 = uimenu(app.ContextMenu2);
            app.SavefigurepanelMenu_2.MenuSelectedFcn = createCallbackFcn(app, @SavefigurepanelMenuSelected, true);
            app.SavefigurepanelMenu_2.Text = 'Save figure panel';
            
            % Assign app.ContextMenu2
            app.core.ContextMenu = app.ContextMenu2;
            app.var.ContextMenu = app.ContextMenu2;
            app.scs.ContextMenu = app.ContextMenu2;
            app.loem.ContextMenu = app.ContextMenu2;
            app.loex.ContextMenu = app.ContextMenu2;
            app.les.ContextMenu = app.ContextMenu2;
            app.leem.ContextMenu = app.ContextMenu2;
            app.leex.ContextMenu = app.ContextMenu2;
            app.elsam.ContextMenu = app.ContextMenu2;
            app.elem.ContextMenu = app.ContextMenu2;
            app.elex.ContextMenu = app.ContextMenu2;
            app.ssesam.ContextMenu = app.ContextMenu2;
            app.sseem.ContextMenu = app.ContextMenu2;
            app.sseex.ContextMenu = app.ContextMenu2;

            % Show the figure after all components are created
            app.viewmodelsDiagnosePARAFACmodelsUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = viewmodels_gui(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.viewmodelsDiagnosePARAFACmodelsUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.viewmodelsDiagnosePARAFACmodelsUIFigure)
        end
    end
end