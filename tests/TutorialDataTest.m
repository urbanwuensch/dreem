classdef TutorialDataTest < DreemTestCase
    % The shipped tutorial datasets still load and validate, and the processing
    % tutorial (without GUIs) still reproduces tutorial_01_processed.mat.

    properties (TestParameter)
        matFile = {"tutorial_01_imported.mat","tutorial_01_processed.mat", ...
            "tutorial_02_importedAndProcessed.mat","parafac_tutorial_01_start.mat", ...
            "tutorial_parafac_modelled.mat"}
    end

    methods (Test)
        function datasetsValidate(tc,matFile)
            S = load(tc.examplesFile(matFile));
            vars = string(fieldnames(S))';
            ds = vars(arrayfun(@(v) isa(S.(v),"drEEMdataset"), vars));
            tc.verifyNotEmpty(ds, matFile + " contains no drEEMdataset")
            for v = ds
                tc.verifyWarningFree(@() drEEMdataset.validate(S.(v)), matFile + ": " + v)
            end
        end

        function processingTutorialRuns(tc)
            samples = tc.runProcessingTutorial();
            tc.verifyEqual(string(samples.status.IFEcorrection),"applied by toolbox")
            tc.verifyEqual(string(samples.status.blankSubtraction),"applied by toolbox")
            tc.verifyEqual(string(samples.status.signalCalibration),"applied by toolbox (RU)")
            tc.verifyEqual(string(samples.status.scatterTreatment),"applied by toolbox")
        end

        function processingTutorialReproducesReference(tc)
            % If this fails after an intended change to a processing method,
            % regenerate tutorial_01_processed.mat with processing_tutorial_01.mlx.
            samples = tc.runProcessingTutorial();
            samples = drEEMtoolbox.subdataset(samples,outEm=samples.Em<300);
            samples = drEEMtoolbox.subdataset(samples,outEx=samples.Ex>450);
            ref = load(tc.examplesFile("tutorial_01_processed.mat"),"samples").samples;

            tc.verifyEqual(samples.filelist,ref.filelist)
            tc.verifyEqual(samples.Ex,ref.Ex)
            tc.verifyEqual(samples.Em,ref.Em)
            tc.verifyEqual(samples.X,ref.X,RelTol=1e-6)
        end
    end

    methods (Access = private)
        function samples = runProcessingTutorial(tc)
            S = load(tc.examplesFile("tutorial_01_imported.mat"),"samples","blanks");
            O = load(tc.examplesFile("processing_tutorial_01_scatterOpts.mat"),"scatteroptions");
            opt = O.scatteroptions;
            opt.plot = false;

            samples = drEEMtoolbox.processabsorbance(S.samples,correctBase=true, ...
                baseWave=600,extrapolate=true,zero=false,plot=false);
            samples = drEEMtoolbox.ifecorrection(samples,plot=false);
            samples = drEEMtoolbox.subtractblanks(samples,S.blanks,plot=false);
            samples = drEEMtoolbox.ramancalibration(samples,S.blanks,plot=false);
            samples = drEEMtoolbox.handlescatter(samples,opt);
        end
    end
end
