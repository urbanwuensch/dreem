classdef RealDataImportTest < DreemTestCase
    % Imports real instrument files from tests/testdata, using the calls of the
    % import tutorials. Data are copied to a temporary folder first, so no file is
    % written into the repository.
    %   dataset 1: Origin project (.opj) for importaqualog / aqualog2nc
    %   dataset 2: Aqualog text export, 10 samples (HE01-HE10): sample EEM, blank EEM,
    %              absorbance; Ex 240:5:600 nm, 125 Em from 211.572 to 618.525 nm

    methods (TestMethodSetup)
        function setup(tc)
            tc.useTempFolder();
        end
    end

    methods (Test)
        %% Aqualog text export (dataset 2)
        function importsAqualogSampleEEMs(tc)
            tc.copyData("dataset 2");
            s = drEEMtoolbox.importeems("* - Waterfall Plot Sample.dat",tc.knownStatus);
            tc.verifyEqual(s.nSample, 10)
            tc.verifyEqual(s.filelist{1}, 'HE01 (01)')
            tc.verifyEqual(s.Ex, (240:5:600)')
            tc.verifyNumElements(s.Em, 125)
            tc.verifyEqual([s.Em(1) s.Em(end)], [211.6 618.5], AbsTol=1e-9)
            tc.verifyFalse(any(all(isnan(s.X),[2 3])), "a sample EEM is entirely missing")
        end

        function importsAqualogAbsorbance(tc)
            tc.copyData("dataset 2");
            a = drEEMtoolbox.importabsorbance("* - Abs Spectra Graphs.dat",tc.knownStatus);
            tc.verifyEqual(a.nSample, 10)
            tc.verifyEqual(a.absWave, (240:5:600)')
            tc.verifyFalse(any(all(isnan(a.abs),2)), "an absorbance spectrum is entirely missing")
        end

        function samplesBlanksAndAbsorbanceShareNames(tc)
            tc.copyData("dataset 2");
            [s,b,a] = tc.importAqualog();
            tc.verifyEqual(b.filelist, s.filelist)
            tc.verifyEqual(a.filelist, s.filelist)
        end

        function realDataThroughTutorialChain(tc)
            % import tutorial + processing tutorial on real files, then a quick PARAFAC
            % on data with missing values from scatter removal
            tc.copyData("dataset 2");
            [s,b,a] = tc.importAqualog();
            [s,b,a] = drEEMtoolbox.alignsamples(s,b,a);
            tc.verifyEqual(s.nSample, 10, "alignsamples removed samples")

            s = drEEMtoolbox.mergemeasurements(s,a,"absorbance");
            s = drEEMtoolbox.processabsorbance(s,plot=false);
            s = drEEMtoolbox.ifecorrection(s,plot=false);
            s = drEEMtoolbox.subtractblanks(s,b,plot=false);
            s = drEEMtoolbox.ramancalibration(s,b,plot=false);
            opt = handlescatterOptions;
            opt.plot = false;
            s = drEEMtoolbox.handlescatter(s,opt);

            tc.verifyEqual(string(s.status.IFEcorrection), "applied by toolbox")
            tc.verifyEqual(string(s.status.blankSubtraction), "applied by toolbox")
            tc.verifyEqual(string(s.status.signalCalibration), "applied by toolbox (RU)")
            tc.verifyEqual(string(s.status.scatterTreatment), "applied by toolbox")
            tc.verifyTrue(any(isnan(s.X),"all"), "expected missing values after scatter removal")

            rng(1,"twister");
            s = drEEMtoolbox.fitparafac(s,"fitoverall",f=2:3,starts=2,convergence=1e-4, ...
                parallelization=false,consoleoutput="none");
            f = drEEMdataset.modelsWithContent(s);
            tc.verifyEqual(sort(f(:))', [2 3])
            tc.verifyGreaterThan(s.models(3).percentExplained, 50)
        end

        %% Origin project (dataset 1)
        function importsOriginProject(tc)
            tc.copyData("dataset 1");
            try
                [s,b] = drEEMtoolbox.importaqualog(pwd);
            catch ME
                % aqualog2nc must be downloaded once; not possible offline or on Intel Macs
                tc.assumeFalse(any(strcmp(ME.identifier, ...
                    ["drEEM:aqualog2ncDownload","drEEM:unsupportedPlatform"])), ME.message)
                rethrow(ME)
            end
            % 20211126_02.opj: 6 samples (6 more are skipped by aqualog2nc for their
            % Experiment Type), Ex 240:5:450, 125 Em from 211.774 to 618.722 nm
            tc.verifyClass(s, "drEEMdataset")
            tc.verifyEqual(s.nSample, 6)
            tc.verifyEqual(s.filelist{1}, 'NABOS9174 (02)')
            tc.verifyEqual(s.Ex, (240:5:450)')
            tc.verifyNumElements(s.Em, 125)
            tc.verifyEqual([s.Em(1) s.Em(end)], [211.774 618.722], AbsTol=1e-3)
            tc.verifyTrue(s.hasAbsorbance)
            tc.verifyClass(b, "drEEMdataset")
            tc.verifyWarningFree(@() drEEMdataset.validate(s))
        end
    end

    methods (Access = private)
        function copyData(tc,name)
            copyfile(fullfile(tc.RepoRoot,"tests","testdata",name,"*"), pwd);
        end

        function [s,b,a] = importAqualog(tc)
            % the calls of import_tutorial_01
            st = tc.knownStatus;
            s = drEEMtoolbox.importeems("* - Waterfall Plot Sample.dat",st);
            b = drEEMtoolbox.importeems("* - Waterfall Plot Blank.dat",st);
            a = drEEMtoolbox.importabsorbance("* - Abs Spectra Graphs.dat",st);
        end
    end
end
