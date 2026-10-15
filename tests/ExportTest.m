classdef ExportTest < DreemTestCase
    % exportresults, export2zip and export2openfluor on the modelled tutorial dataset.
    % Checks that files are complete and that exported numbers equal the dataset.

    properties (Access = private)
        S
    end

    methods (TestClassSetup)
        function loadTutorial(tc)
            tc.S = load(tc.examplesFile("tutorial_parafac_modelled.mat"),"samples").samples;
        end
    end

    methods (TestMethodSetup)
        function setup(tc)
            tc.useTempFolder();
        end
    end

    methods (Test)
        %% exportresults
        function exportresultsWritesExpectedSheets(tc)
            drEEMtoolbox.exportresults(tc.S,5,"results");
            tc.assertTrue(isfile("results.xlsx"))
            expected = ["dataset history","dataset status","scatter treatment","Peaks & indicies", ...
                "PARAFAC model overview","5C Fl. max.","5C ex loadings","5C em loadings"];
            missing = setdiff(expected, sheetnames("results.xlsx"));
            tc.verifyEmpty(missing, "missing sheets: " + strjoin(missing,", "))
        end

        function exportresultsFmaxEqualsScores2fmax(tc)
            drEEMtoolbox.exportresults(tc.S,5,"results");
            t = readtable("results.xlsx",Sheet="5C Fl. max.");
            tc.verifyEqual(string(t.sample), string(tc.S.filelist))
            tc.verifyEqual(t{:,2:end}, drEEMtoolbox.scores2fmax(tc.S,5), RelTol=1e-9)
        end

        function exportresultsLoadingsEqualModel(tc)
            drEEMtoolbox.exportresults(tc.S,5,"results");
            em = readtable("results.xlsx",Sheet="5C em loadings");
            ex = readtable("results.xlsx",Sheet="5C ex loadings");
            tc.verifyEqual(em{:,1}, tc.S.Em, RelTol=1e-12)
            tc.verifyEqual(em{:,2:end}, tc.S.models(5).loads{2}, RelTol=1e-9)
            tc.verifyEqual(ex{:,1}, tc.S.Ex, RelTol=1e-12)
            tc.verifyEqual(ex{:,2:end}, tc.S.models(5).loads{3}, RelTol=1e-9)
        end

        %% export2zip
        function export2zipContainsAllParts(tc)
            here = pwd;
            drEEMtoolbox.export2zip(tc.S,"data.zip");
            tc.verifyEqual(pwd, here, "export2zip changed the current folder")
            tc.verifyFalse(isfolder("drEEMexportTemporary"), "temporary folder left behind")
            unzip("data.zip","unzipped");
            for f = ["README.txt","dataset_history.xlsx","dataset_status.csv", ...
                    "dataset_metadata.csv","drEEM_versionInformation.csv","dataset_dreem.mat"]
                tc.verifyTrue(isfile(fullfile("unzipped",f)), "missing " + f)
            end
            for k = 1:tc.S.nSample
                tc.verifyTrue(isfile(fullfile("unzipped","EEMs",tc.S.filelist{k}+".csv")), ...
                    "missing EEM of " + tc.S.filelist{k})
            end
        end

        function export2zipEEMsEqualDataset(tc)
            drEEMtoolbox.export2zip(tc.S,"data.zip");
            unzip("data.zip","unzipped");
            for k = [1 tc.S.nSample]
                M = readmatrix(fullfile("unzipped","EEMs",tc.S.filelist{k}+".csv"));
                tc.verifyEqual(M(1,2:end)', tc.S.Ex, RelTol=1e-12)
                tc.verifyEqual(M(2:end,1), tc.S.Em, RelTol=1e-12)
                tc.verifyEqual(M(2:end,2:end), squeeze(tc.S.X(k,:,:)), RelTol=1e-10, AbsTol=1e-12)
            end
            L = load(fullfile("unzipped","dataset_dreem.mat"));
            tc.verifyEqual(L.dataExported.X, tc.S.X)
        end

        %% export2openfluor
        function export2openfluorCanBeProjectedBack(tc)
            drEEMtoolbox.export2openfluor(tc.S,5,"model5C.txt");
            tc.assertTrue(isfile("model5C.txt"))
            p = drEEMtoolbox.projectmodel(tc.S,"model5C.txt");
            % Loadings are interpolated to whole wavelengths for OpenFluor, so allow some loss
            tc.verifyEqual(p.models(5).percentExplained, tc.S.models(5).percentExplained, AbsTol=0.5)
        end
    end
end
