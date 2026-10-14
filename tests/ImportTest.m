classdef ImportTest < DreemTestCase
    % importeems / importabsorbance / importscans on small synthetic csv files

    properties (Constant)
        Ex = 250:10:350
        Em = 300:5:450
        Wave = 240:2:600
        Axis = 360:1:450
    end

    methods (TestMethodSetup)
        function setup(tc)
            tc.useTempFolder();
        end
    end

    methods (Test)
        function importeemsReadsAllSamples(tc)
            X = tc.writeEEMs(["S01_EEM.csv","S02_EEM.csv","S03_EEM.csv"],tc.Ex,tc.Em);
            data = drEEMtoolbox.importeems("*_EEM.csv",tc.knownStatus);

            tc.verifyEqual(data.nSample,3)
            tc.verifyEqual(data.filelist,{'S01';'S02';'S03'})
            tc.verifyEqual(data.Ex,tc.Ex(:))
            tc.verifyEqual(data.Em,tc.Em(:))
            tc.verifyEqual(data.X,X,AbsTol=1e-9)
            tc.verifyEqual(string(data.status.blankSubtraction),"not applied")
        end

        function importabsorbanceReadsAllSamples(tc)
            A = tc.writeSpectra(["S01_ABS.csv","S02_ABS.csv"],tc.Wave);
            data = drEEMtoolbox.importabsorbance("*_ABS.csv",tc.knownStatus,absColumn=2);

            tc.verifyEqual(data.filelist,{'S01';'S02'})
            tc.verifyEqual(data.absWave,tc.Wave(:))
            tc.verifyEqual(data.abs,A,AbsTol=1e-9)
            tc.verifyEqual(string(data.status.absorbanceUnit),"absorbance per cm")
        end

        function importscansReadsAllSamples(tc)
            A = tc.writeSpectra(["B01_RAM.csv","B02_RAM.csv"],tc.Axis);
            data = drEEMtoolbox.importscans("*_RAM.csv",tc.knownStatus);

            tc.verifyEqual(data.filelist,{'B01';'B02'})
            tc.verifyEqual(data.suppSpectraAxis,tc.Axis(:))
            tc.verifyEqual(data.suppSpectra,A,AbsTol=1e-9)
        end

        function importscansSkipsMismatchedAxis(tc)
            tc.writeSpectra(["B01_RAM.csv","B02_RAM.csv"],tc.Axis);
            tc.writeSpectra("B03_RAM.csv",tc.Axis+0.5);   % sorts last, axis differs

            lastwarn("");
            data = drEEMtoolbox.importscans("*_RAM.csv",tc.knownStatus);

            tc.verifySubstring(lastwarn,"Skipped")
            tc.verifyEqual(data.filelist,{'B01';'B02'})
            tc.verifyEqual(data.i,[1;2])
        end

        function noOutputIsDiagnosticMode(tc)
            tc.writeEEMs("S01_EEM.csv",tc.Ex,tc.Em);
            tc.verifyWarningFree(@() drEEMtoolbox.importeems("*_EEM.csv",tc.knownStatus))
        end

        function missingFilesError(tc)
            tc.verifyError(@() drEEMtoolbox.importeems("*_nothing.csv",tc.knownStatus), ?MException)
        end
    end
end
