classdef ProcessingContractTest < DreemTestCase
    % Properties each processing step must keep, independent of exact numbers.
    % Uses the processing tutorial chain (ProcessingCases.stages).

    properties (Access = private)
        St
    end

    methods (TestClassSetup)
        function prepare(tc)
            tc.St = ProcessingCases.stages(tc.RepoRoot);
        end
    end

    methods (Test)
        %% processabsorbance
        function processabsorbanceRunsOnlyOnce(tc)
            tc.verifyError(@() drEEMtoolbox.processabsorbance(tc.St.A,plot=false), ?MException)
        end

        function baselineCorrectionCentresBaseRegion(tc)
            % correctBase subtracts the mean absorbance at >= baseWave from each spectrum
            d = drEEMtoolbox.processabsorbance(tc.St.S,correctBase=true,baseWave=600, ...
                extrapolate=false,zero=false,plot=false);
            region = d.absWave >= 600;
            tc.assumeTrue(any(region), "absorbance does not reach 600 nm")
            tc.verifyLessThan(max(abs(mean(d.abs(:,region),2,"omitmissing"))), 1e-10)
        end

        function zeroOptionRemovesNegativeAbsorbance(tc)
            d = drEEMtoolbox.processabsorbance(tc.St.S,zero=true,plot=false);
            tc.verifyGreaterThanOrEqual(min(d.abs,[],"all"), 0)
        end

        function extrapolationCoversEmissionRange(tc)
            % extrapolate=true exists so IFE correction doesn't trim long emission wavelengths
            tc.verifyGreaterThanOrEqual(max(tc.St.A.absWave), max(tc.St.A.Em))
        end

        %% ifecorrection
        function ifeCorrectionOnlyIncreasesSignal(tc)
            % Holds for non-negative absorbance only (negative absorbance gives factors < 1)
            a = drEEMtoolbox.processabsorbance(tc.St.S,zero=true,plot=false);
            i = drEEMtoolbox.ifecorrection(a,plot=false);
            [before,after] = overlap(a, i);
            pos = before > 0 & isfinite(before) & isfinite(after);
            tc.verifyGreaterThanOrEqual(min(after(pos)./before(pos)), 1 - 1e-12)
        end

        function ifeCorrectionRunsOnlyOnce(tc)
            tc.verifyError(@() drEEMtoolbox.ifecorrection(tc.St.I,plot=false), ?MException)
        end

        function ifeCorrectionSetsStatus(tc)
            tc.verifyEqual(string(tc.St.I.status.IFEcorrection), "applied by toolbox")
        end

        %% subtractblanks
        function blankSubtractionIsExactDifference(tc)
            I = tc.St.I; B = tc.St.B; Bs = tc.St.Bs;
            tc.assertEqual(Bs.nSample, B.nSample)
            [~,emI] = ismember(Bs.Em,I.Em); [~,exI] = ismember(Bs.Ex,I.Ex);
            [~,emB] = ismember(Bs.Em,B.Em); [~,exB] = ismember(Bs.Ex,B.Ex);
            tc.assertTrue(all(emI) && all(exI) && all(emB) && all(exB), "wavelengths not found")
            tc.verifyEqual(Bs.X, I.X(:,emI,exI) - B.X(:,emB,exB), AbsTol=1e-12)
        end

        function blankSubtractionRunsOnlyOnce(tc)
            tc.verifyError(@() drEEMtoolbox.subtractblanks(tc.St.Bs,tc.St.B,plot=false), ?MException)
        end

        %% ramancalibration
        function ramanCalibrationIsOneFactorPerSample(tc)
            tc.assertEqual(tc.St.R.filelist, tc.St.Bs.filelist)
            verifyOneFactorPerSample(tc, tc.St.Bs.X, tc.St.R.X)
        end

        function qsuIsRamanUnitsTimes494(tc)
            q = drEEMtoolbox.ramancalibration(tc.St.Bs,tc.St.B,convertToQSU=true,plot=false);
            tc.verifyEqual(q.X, 49.4*tc.St.R.X, RelTol=1e-12)
            tc.verifyEqual(string(q.status.signalCalibration), "applied by toolbox (QSU)")
        end

        function ramanCalibrationRunsOnlyOnce(tc)
            tc.verifyError(@() drEEMtoolbox.ramancalibration(tc.St.R,tc.St.B,plot=false), ?MException)
        end

        %% handlescatter
        function scatterTreatmentLeavesNoNegatives(tc)
            tc.assumeTrue(logical(tc.St.opt.negativetozero))
            tc.verifyGreaterThanOrEqual(min(tc.St.H.X,[],"all"), 0)
        end

        function interpolationFillsCutScatter(tc)
            set = @ProcessingCases.setopt;
            cut    = drEEMtoolbox.handlescatter(tc.St.R,set(tc.St.opt,"cutout",[1 1 1 1],"interpolate",[0 0 0 0]));
            filled = drEEMtoolbox.handlescatter(tc.St.R,set(tc.St.opt,"cutout",[1 1 1 1],"interpolate",[1 1 1 1]));
            tc.verifyGreaterThan(nnz(isnan(cut.X)), nnz(isnan(filled.X)))
        end

        function sampleSubsetLeavesOtherSamplesUntouched(tc)
            d = drEEMtoolbox.handlescatter(tc.St.R,ProcessingCases.setopt(tc.St.opt,"samples",1:3));
            tc.verifyEqual(d.X(4:end,:,:), tc.St.R.X(4:end,:,:))
            tc.verifyNotEqual(d.X(1:3,:,:), tc.St.R.X(1:3,:,:))
        end

        %% scalesamples
        function reverseScalingRestoresData(tc)
            r = drEEMtoolbox.scalesamples(drEEMtoolbox.scalesamples(tc.St.H,2),'reverse');
            tc.verifyEqual(r.X, tc.St.H.X, RelTol=1e-12)
        end

        function repeatedScalingStartsFromOriginal(tc)
            once = drEEMtoolbox.scalesamples(tc.St.H,2);
            twice = drEEMtoolbox.scalesamples(once,2);
            tc.verifyEqual(twice.X, once.X, RelTol=1e-12)
        end

        function scalingIsOneFactorPerSample(tc)
            s = drEEMtoolbox.scalesamples(tc.St.H,3);
            verifyOneFactorPerSample(tc, tc.St.H.X, s.X)
        end

        function maxScalingGivesUnitMaximum(tc)
            s = drEEMtoolbox.scalesamples(tc.St.H,'max');
            m = max(reshape(s.X,s.nSample,[]),[],2,"omitmissing");
            tc.verifyEqual(m, ones(size(m)), AbsTol=1e-12)
        end
        function maxScalingIsRecognisedAndReversible(tc)
            s = drEEMtoolbox.scalesamples(tc.St.H,'max');
            tc.verifySubstring(lower(string(s.status.signalScaling)), "scaled to")
            r = drEEMtoolbox.scalesamples(s,'reverse');
            tc.verifyEqual(r.X, tc.St.H.X, RelTol=1e-12)
        end

        %% rmspikes
        function spikeRemovalOnlyDeletesValues(tc)
            d = drEEMtoolbox.rmspikes(tc.St.H,thresholdFactor=10,plot=false);
            kept = ~isnan(d.X);
            tc.verifyEqual(d.X(kept), tc.St.H.X(kept))
            tc.verifyGreaterThanOrEqual(nnz(isnan(d.X)), nnz(isnan(tc.St.H.X)))
        end

        function veryHighThresholdChangesNothing(tc)
            d = drEEMtoolbox.rmspikes(tc.St.H,thresholdFactor=1e6,plot=false);
            tc.verifyEqual(d.X, tc.St.H.X)
        end

        %% zapnoise
        function zapnoiseOnlyAffectsSelectedRegion(tc)
            H = tc.St.H;
            sel = (H.i == H.i(1))';
            d = drEEMtoolbox.zapnoise(H,sel,[],[340 360]);
            ex = drEEMtoolbox.mindist(H.Ex,340):drEEMtoolbox.mindist(H.Ex,360);
            tc.verifyTrue(all(isnan(d.X(sel,:,ex)),"all"))
            tc.verifyEqual(d.X(~sel,:,:), H.X(~sel,:,:))
            outside = true(1,H.nEx); outside(ex) = false;
            tc.verifyEqual(d.X(sel,:,outside), H.X(sel,:,outside))
        end

        %% subdataset
        function subdatasetRemovesExactlyTheSelection(tc)
            H = tc.St.H;
            d = drEEMtoolbox.subdataset(H,outEm=H.Em<300);
            tc.verifyEqual(d.Em, H.Em(H.Em>=300))
            tc.verifyEqual(d.X, H.X(:,H.Em>=300,:))
            tc.verifyWarningFree(@() drEEMdataset.validate(d))
        end

        %% optical indices
        function repeatedIndicesReplaceColumns(tc)
            s1 = drEEMtoolbox.fitslopes(tc.St.A,plot=false,quiet=true);
            s2 = drEEMtoolbox.fitslopes(s1,plot=false,quiet=true);
            tc.verifyEqual(width(s2.opticalMetadata), width(s1.opticalMetadata))
            p1 = drEEMtoolbox.pickpeaks(tc.St.H,plot=false,quiet=true);
            p2 = drEEMtoolbox.pickpeaks(p1,plot=false,quiet=true);
            tc.verifyEqual(width(p2.opticalMetadata), width(p1.opticalMetadata))
        end
    end
end

function [a,b] = overlap(d1,d2)
% X of two datasets on their common wavelengths
[~,em1,em2] = intersect(d1.Em,d2.Em);
[~,ex1,ex2] = intersect(d1.Ex,d2.Ex);
a = d1.X(:,em1,ex1);
b = d2.X(:,em2,ex2);
end

function verifyOneFactorPerSample(tc,before,after)
% after = before / (one constant per sample)
for k = 1:size(before,1)
    r = before(k,:) ./ after(k,:);
    r = r(isfinite(r) & before(k,:) ~= 0);
    tc.verifyLessThan(std(r)/abs(mean(r)), 1e-9, "sample " + k)
end
end
