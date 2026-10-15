classdef ProcessingCases
    % Option combinations for the processing methods, run on the tutorial data, and
    % compact fingerprints of their results. Shared by ProcessingRegressionTest,
    % ProcessingContractTest and updateProcessingReference.
    %
    % To cover a new option: add a line to ProcessingCases.all(), then run
    %   cd tests; updateProcessingReference("<caseName>"); cd ..

    methods (Static)
        function st = stages(root)
            % The processing tutorial, step by step, without figures
            ex = fullfile(root,"toolbox","examples");
            L = load(fullfile(ex,"tutorial_01_imported.mat"),"samples","blanks");
            O = load(fullfile(ex,"processing_tutorial_01_scatterOpts.mat"),"scatteroptions");
            st.S = L.samples;
            st.B = L.blanks;
            st.opt = O.scatteroptions;
            st.opt.plot = false;
            st.A  = drEEMtoolbox.processabsorbance(st.S,correctBase=true,baseWave=600, ...
                extrapolate=true,zero=false,plot=false);
            st.I  = drEEMtoolbox.ifecorrection(st.A,plot=false);
            st.Bs = drEEMtoolbox.subtractblanks(st.I,st.B,plot=false);
            st.R  = drEEMtoolbox.ramancalibration(st.Bs,st.B,plot=false);
            st.H  = drEEMtoolbox.handlescatter(st.R,st.opt);
        end

        function c = all()
            c = struct("name",{},"run",{});
            set = @ProcessingCases.setopt;

            % processabsorbance (input: imported samples)
            c = add(c,"processabsorbance_defaults",    @(st) drEEMtoolbox.processabsorbance(st.S,plot=false));
            c = add(c,"processabsorbance_noBaseline",  @(st) drEEMtoolbox.processabsorbance(st.S,correctBase=false,plot=false));
            c = add(c,"processabsorbance_zero",        @(st) drEEMtoolbox.processabsorbance(st.S,zero=true,plot=false));
            c = add(c,"processabsorbance_noExtrapol",  @(st) drEEMtoolbox.processabsorbance(st.S,extrapolate=false,plot=false));
            c = add(c,"processabsorbance_base600",     @(st) drEEMtoolbox.processabsorbance(st.S,baseWave=600,plot=false));
            c = add(c,"processabsorbance_baseRange",   @(st) drEEMtoolbox.processabsorbance(st.S,baseWave=[590 600],plot=false));

            % ifecorrection
            c = add(c,"ifecorrection_tutorial",        @(st) st.I);
            c = add(c,"ifecorrection_noExtrapol",      @(st) drEEMtoolbox.ifecorrection( ...
                drEEMtoolbox.processabsorbance(st.S,extrapolate=false,plot=false),plot=false));

            % subtractblanks
            c = add(c,"subtractblanks_tutorial",       @(st) st.Bs);

            % ramancalibration
            c = add(c,"ramancalibration_tutorial",     @(st) st.R);
            c = add(c,"ramancalibration_gauss1",       @(st) drEEMtoolbox.ramancalibration(st.Bs,st.B,method="gauss1",plot=false));
            c = add(c,"ramancalibration_window",       @(st) drEEMtoolbox.ramancalibration(st.Bs,st.B,iStart=380,iEnd=420,plot=false));
            c = add(c,"ramancalibration_ex345",        @(st) drEEMtoolbox.ramancalibration(st.Bs,st.B,ExWave=345,plot=false));
            c = add(c,"ramancalibration_QSU",          @(st) drEEMtoolbox.ramancalibration(st.Bs,st.B,convertToQSU=true,plot=false));

            % handlescatter (input: Raman-calibrated samples)
            c = add(c,"handlescatter_tutorial",        @(st) st.H);
            c = add(c,"handlescatter_defaults",        @(st) drEEMtoolbox.handlescatter(st.R,set(handlescatterOptions,"plot",false)));
            c = add(c,"handlescatter_cutOnly",         @(st) drEEMtoolbox.handlescatter(st.R,set(st.opt,"cutout",[1 1 1 1],"interpolate",[0 0 0 0])));
            c = add(c,"handlescatter_interpolateAll",  @(st) drEEMtoolbox.handlescatter(st.R,set(st.opt,"cutout",[1 1 1 1],"interpolate",[1 1 1 1])));
            c = add(c,"handlescatter_fillmissing",     @(st) drEEMtoolbox.handlescatter(st.R,set(st.opt,"interpolate",[1 1 1 1],"imethod","fillmissing")));
            c = add(c,"handlescatter_keepNegative",    @(st) drEEMtoolbox.handlescatter(st.R,set(st.opt,"negativetozero",false)));
            c = add(c,"handlescatter_d2zero30",        @(st) drEEMtoolbox.handlescatter(st.R,set(st.opt,"d2zero",30)));
            c = add(c,"handlescatter_wide",            @(st) drEEMtoolbox.handlescatter(st.R,set(st.opt,"ray1",[20 20],"ram1",[25 25])));
            c = add(c,"handlescatter_samples1to5",     @(st) drEEMtoolbox.handlescatter(st.R,set(st.opt,"samples",1:5)));
            c = add(c,"handlescatter_ramanShift3400",  @(st) drEEMtoolbox.handlescatter(st.R,st.opt,3400));

            % scalesamples (input: scatter-treated samples)
            c = add(c,"scalesamples_root2",            @(st) drEEMtoolbox.scalesamples(st.H,2));
            c = add(c,"scalesamples_unitVariance",     @(st) drEEMtoolbox.scalesamples(st.H,1));
            c = add(c,"scalesamples_max",              @(st) drEEMtoolbox.scalesamples(st.H,'max'));
            c = add(c,"scalesamples_reverse",          @(st) drEEMtoolbox.scalesamples(drEEMtoolbox.scalesamples(st.H,2),'reverse'));

            % rmspikes
            c = add(c,"rmspikes_tutorial",             @(st) drEEMtoolbox.rmspikes(st.H,thresholdFactor=30,plot=false));
            c = add(c,"rmspikes_threshold10",          @(st) drEEMtoolbox.rmspikes(st.H,thresholdFactor=10,plot=false));
            c = add(c,"rmspikes_interpolate",          @(st) drEEMtoolbox.rmspikes(st.H,thresholdFactor=20,interpolate=true,plot=false));

            % subdataset, zapnoise
            c = add(c,"subdataset_tutorialTrim",       @(st) drEEMtoolbox.subdataset( ...
                drEEMtoolbox.subdataset(st.H,outEm=st.H.Em<300),outEx=st.H.Ex>450));
            c = add(c,"subdataset_samples",            @(st) drEEMtoolbox.subdataset(st.H,outSample=(1:st.H.nSample)<=3));
            c = add(c,"zapnoise_firstSample",          @(st) drEEMtoolbox.zapnoise(st.H,(st.H.i==st.H.i(1))',[],[340 360]));

            % optical indices
            c = add(c,"fitslopes_defaults",            @(st) drEEMtoolbox.fitslopes(st.A,plot=false,quiet=true));
            c = add(c,"fitslopes_range300to500",       @(st) drEEMtoolbox.fitslopes(st.A,LongRange=[300 500],plot=false,quiet=true));
            c = add(c,"fitslopes_rsq090",              @(st) drEEMtoolbox.fitslopes(st.A,rsq=0.9,plot=false,quiet=true));
            c = add(c,"pickpeaks_defaults",            @(st) drEEMtoolbox.pickpeaks(st.H,plot=false,quiet=true));
        end

        function n = names()
            c = ProcessingCases.all();
            n = cellstr([c.name]);
        end

        function c = get(name)
            c = ProcessingCases.all();
            c = c([c.name]==string(name));
        end

        function o = setopt(o,varargin)
            % Copy of an options object with some properties changed
            for k = 1:2:numel(varargin)
                o.(varargin{k}) = varargin{k+1};
            end
        end

        function fp = fingerprint(ds)
            % Small summary that changes whenever values, missing numbers, axes,
            % samples, status or optical indices change
            fp = struct();
            fp.filelist = string(ds.filelist);
            fp.Ex = ds.Ex;
            fp.Em = ds.Em;
            fp.sizeX = size(ds.X);
            fp = addArray(fp,"X",ds.X);
            fp.absWave = ds.absWave;
            fp = addArray(fp,"abs",ds.abs);
            [values,props] = drEEMstatus.getCurrent(ds.status);
            fp.status = string(props) + ": " + string(values);
            om = ds.opticalMetadata;
            if isempty(om)
                fp.opticalNames = string.empty;
                fp.opticalSums = [];
            else
                num = varfun(@isnumeric,om,"OutputFormat","uniform");
                fp.opticalNames = string(om.Properties.VariableNames(num));
                fp.opticalSums = sum(table2array(om(:,num)),1,"omitmissing");
            end
            fp.lastStep = string(ds.history(end).fname);
        end

        function f = referenceFile(root)
            f = fullfile(root,"tests","reference","processing_fingerprints.mat");
        end
    end
end

function c = add(c,name,fn)
c(end+1) = struct("name",name,"run",fn);
end

function fp = addArray(fp,name,A)
x = double(A(:));
w = cos((1:numel(x))'*0.37);   % position-dependent weights: catches values that moved
fp.(name+"_nan")    = nnz(isnan(x));
fp.(name+"_nanPos") = sum(find(isnan(x)));
fp.(name+"_sum")    = sum(x,"omitmissing");
fp.(name+"_sumsq")  = sum(x.^2,"omitmissing");
fp.(name+"_wsum")   = sum(x.*w,"omitmissing");
end
