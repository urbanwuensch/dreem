classdef OpticalIndicesTest < DreemTestCase
    % fitslopes and pickpeaks on synthetic data with known answers

    methods (Test)
        %% fitslopes: writeSpectra writes k*exp(-0.015*(lambda-240)), i.e. S = 15 per um
        function fitslopesRecoversKnownSlope(tc)
            om = tc.slopesFor(240:2:600);
            tc.verifyEqual(om.S_275_295, [15;15], RelTol=1e-6)
            tc.verifyEqual(om.S_350_400, [15;15], RelTol=1e-6)
            tc.verifyEqual(om.Sr, [1;1], RelTol=1e-6)
            tc.verifyEqual(om.exp_slope_microm, [15;15], RelTol=1e-3)
        end

        function fitslopesLongRangeOption(tc)
            om = tc.slopesFor(240:2:600, [300 500]);
            tc.verifyEqual(om.exp_slope_microm, [15;15], RelTol=1e-3)
        end

        %% pickpeaks: constant EEMs give every peak = the constant, ratios = 1, HIX = 0.5
        function pickpeaksOnConstantEEMs(tc)
            c = [2;3];
            d = SyntheticData.constantDataset(c, 240:5:400, 300:4:560);
            om = drEEMtoolbox.pickpeaks(d,plot=false,quiet=true).opticalMetadata;
            for peak = ["B","T","A","M","C","D","N"]
                tc.verifyEqual(om.(peak), c, "peak " + peak, RelTol=1e-12)
            end
            for index = ["FluI","FrI","BIX","ARIX"]
                tc.verifyEqual(om.(index), [1;1], index, RelTol=1e-12)
            end
            tc.verifyEqual(om.HIX, [0.5;0.5], RelTol=1e-12)
        end

        function pickpeaksScalesWithIntensity(tc)
            % Peaks are proportional to intensity, indices are not
            [d,~] = SyntheticData.parafacDataset(4);
            d2 = d;
            d2.X = 10*d.X;
            p1 = drEEMtoolbox.pickpeaks(d,plot=false,quiet=true).opticalMetadata;
            p2 = drEEMtoolbox.pickpeaks(d2,plot=false,quiet=true).opticalMetadata;
            tc.verifyEqual(p2.C, 10*p1.C, RelTol=1e-9)
            tc.verifyEqual(p2.FluI, p1.FluI, RelTol=1e-9)
            tc.verifyEqual(p2.HIX, p1.HIX, RelTol=1e-9)
        end
    end

    methods (Access = private)
        function om = slopesFor(tc,wave,longRange)
            arguments
                tc
                wave
                longRange (1,2) double = [300 600]
            end
            tc.useTempFolder();
            tc.writeSpectra(["S01_ABS.csv","S02_ABS.csv"],wave);
            d = drEEMtoolbox.importabsorbance("*_ABS.csv",tc.knownStatus,absColumn=2);
            om = drEEMtoolbox.fitslopes(d,LongRange=longRange,plot=false,quiet=true).opticalMetadata;
        end
    end
end
