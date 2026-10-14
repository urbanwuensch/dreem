classdef MergeMeasurementsTest < DreemTestCase

    properties (Constant)
        Ex = 250:10:350
        Em = 300:5:450
        Wave = 240:2:600
    end

    methods (TestMethodSetup)
        function setup(tc)
            tc.useTempFolder();
        end
    end

    methods (Test)
        function transfersAbsorbanceAndStatus(tc)
            samples = tc.importSamples(["S01","S02","S03"]);
            [absorbance,A] = tc.importAbsorbance(["S01","S02","S03"]);

            merged = drEEMtoolbox.mergemeasurements(samples,absorbance,"absorbance");

            tc.verifyEqual(merged.abs,A,AbsTol=1e-9)
            tc.verifyEqual(merged.absWave,tc.Wave(:))
            tc.verifyEqual(string(merged.status.absorbanceUnit),"absorbance per cm")
            tc.verifyEqual(merged.X,samples.X)                    % fluorescence untouched
            tc.verifyEqual(string(merged.history(end).fname),"mergemeasurements")
        end

        function partialOverlapErrors(tc)
            samples = tc.importSamples(["S01","S02","S03"]);
            absorbance = tc.importAbsorbance(["S01","S02"]);
            tc.verifyError(@() drEEMtoolbox.mergemeasurements(samples,absorbance,"absorbance"), ...
                "drEEM:missingSamples")
        end

        function noCommonSamplesErrors(tc)
            samples = tc.importSamples(["S01","S02"]);
            absorbance = tc.importAbsorbance(["X01","X02"]);
            tc.verifyError(@() drEEMtoolbox.mergemeasurements(samples,absorbance,"absorbance"), ?MException)
        end

        function noreplaceErrorsIfDataExists(tc)
            samples = tc.importSamples(["S01","S02"]);
            absorbance = tc.importAbsorbance(["S01","S02"]);
            merged = drEEMtoolbox.mergemeasurements(samples,absorbance,"absorbance");
            tc.verifyError(@() drEEMtoolbox.mergemeasurements(merged,absorbance,"absorbance","noreplace"), ?MException)
        end

        function refusesAbsorbanceAfterToolboxIFE(tc)
            samples = tc.importSamples(["S01","S02"],"applied by toolbox");
            absorbance = tc.importAbsorbance(["S01","S02"]);
            tc.verifyError(@() drEEMtoolbox.mergemeasurements(samples,absorbance,"absorbance"), "drEEM:Insane")
        end

        function allowsAbsorbanceAfterInstrumentIFE(tc)
            samples = tc.importSamples(["S01","S02"],"applied by instrument software");
            absorbance = tc.importAbsorbance(["S01","S02"]);
            merged = drEEMtoolbox.mergemeasurements(samples,absorbance,"absorbance");
            tc.verifyTrue(merged.hasAbsorbance)
        end

        function replacingFluorescenceDeletesModels(tc)
            S = load(tc.examplesFile("tutorial_parafac_modelled.mat"),"samples");
            tc.assumeNotEmpty(drEEMdataset.modelsWithContent(S.samples), ...
                "tutorial dataset has no models to delete")

            merged = drEEMtoolbox.mergemeasurements(S.samples,S.samples,"fluorescence");

            tc.verifyEmpty(drEEMdataset.modelsWithContent(merged))
            tc.verifyEmpty(merged.split)
        end
    end

    methods (Access = private)
        function data = importSamples(tc,names,ife)
            arguments
                tc
                names string
                ife (1,1) string = "not applied"
            end
            tc.writeEEMs(names+"_EEM.csv",tc.Ex,tc.Em);
            data = drEEMtoolbox.importeems("*_EEM.csv",tc.knownStatus(ife));
        end

        function [data,A] = importAbsorbance(tc,names)
            A = tc.writeSpectra(names+"_ABS.csv",tc.Wave);
            data = drEEMtoolbox.importabsorbance("*_ABS.csv",tc.knownStatus,absColumn=2);
        end
    end
end
