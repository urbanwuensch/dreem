classdef FittingTest < DreemTestCase
    % PARAFAC, split validation, Fmax, model projection and PCA on synthetic
    % EEMs with a known 3-component structure (SyntheticData.parafacDataset).

    properties (Access = private)
        Data
        Truth
        Fitted
    end

    methods (TestClassSetup)
        function fitOnce(tc)
            old = rng;
            tc.addTeardown(@rng,old);
            rng(1,"twister");
            [tc.Data,tc.Truth] = SyntheticData.parafacDataset(20);
            tc.Fitted = drEEMtoolbox.fitparafac(tc.Data,"fitoverall",f=2:4,starts=4, ...
                convergence=1e-8,parallelization=false,consoleoutput="none");
        end
    end

    methods (Test)
        %% PARAFAC
        function parafacStoresRequestedModels(tc)
            f = drEEMdataset.modelsWithContent(tc.Fitted);
            tc.verifyEqual(sort(f(:))', [2 3 4])
        end

        function parafacRecoversKnownComponents(tc)
            m = tc.Fitted.models(3);
            tc.verifyGreaterThan(m.percentExplained, 99.99)
            [~,tEm] = SyntheticData.match(tc.Truth.B, m.loads{2});
            [~,tEx] = SyntheticData.match(tc.Truth.C, m.loads{3});
            tc.verifyGreaterThan(min(tEm), 0.999, "emission loadings")
            tc.verifyGreaterThan(min(tEx), 0.999, "excitation loadings")
        end

        function parafacCoreConsistencyHighAtTrueRank(tc)
            tc.verifyGreaterThan(tc.Fitted.models(3).core, 95)
        end

        function explainedVarianceGrowsWithComponents(tc)
            tc.verifyLessThan(tc.Fitted.models(2).percentExplained, tc.Fitted.models(3).percentExplained)
        end

        function parafacIsNonnegativeByDefault(tc)
            L = tc.Fitted.models(3).loads;
            tc.verifyGreaterThanOrEqual(min([L{1}(:);L{2}(:);L{3}(:)]), -1e-12)
        end

        function parafacRefusesUnknownScatterState(tc)
            d = tc.Data;
            d.status = drEEMstatus;   % everything "unknown"
            tc.verifyError(@() drEEMtoolbox.fitparafac(d,"fitoverall",f=2,starts=1, ...
                parallelization=false,consoleoutput="none"), ?MException)
        end

        %% Fmax
        function fmaxFollowsDefinition(tc)
            m = tc.Fitted.models(3);
            fm = drEEMtoolbox.scores2fmax(tc.Fitted,3);
            tc.verifyEqual(fm, m.loads{1}.*max(m.loads{2}).*max(m.loads{3}), RelTol=1e-12)
        end

        function fmaxMatchesTrueFmax(tc)
            % Fmax doesn't depend on PARAFAC's arbitrary scaling, so it must match the truth
            fm = drEEMtoolbox.scores2fmax(tc.Fitted,3);
            p = SyntheticData.match(tc.Truth.B, tc.Fitted.models(3).loads{2});
            tc.verifyEqual(fm(:,p), tc.Truth.fmax, RelTol=1e-3)
        end

        %% Split validation
        function blindSplitUsesEverySampleOnce(tc)
            s = drEEMtoolbox.splitdataset(tc.Fitted,"blind");
            tc.verifyNumElements(s.split, 2)
            names = [s.split(1).filelist; s.split(2).filelist];
            tc.verifyEqual(sort(names), sort(tc.Fitted.filelist))
        end

        function splitValidationPassesForTrueRank(tc)
            s = drEEMtoolbox.splitdataset(tc.Fitted,"blind");
            s = drEEMtoolbox.fitparafac(s,"fitsplits",f=3,starts=4,convergence=1e-8, ...
                parallelization=false,consoleoutput="none");
            tc.verifyTrue(drEEMtoolbox.silentvalidation(s,3))
        end

        %% OpenFluor export + projection
        function projectedModelReproducesFittedModel(tc)
            tc.useTempFolder();
            drEEMtoolbox.export2openfluor(tc.Fitted,3,"synthetic3C.txt");
            p = drEEMtoolbox.projectmodel(tc.Data,"synthetic3C.txt");
            tc.verifyEqual(p.models(3).percentExplained, tc.Fitted.models(3).percentExplained, AbsTol=1e-3)
            tc.verifyEqual(drEEMtoolbox.scores2fmax(p,3), drEEMtoolbox.scores2fmax(tc.Fitted,3), RelTol=1e-3)
        end

        %% PCA
        function pcaExplainsTrueRank(tc)
            p = drEEMtoolbox.fitpca(tc.Data,maxcomp=5,interpolateMissing=false);
            m = p.models(5);
            tc.verifyEqual(string(m.modelName), "PCA")
            tc.verifySize(m.loads{1}, [tc.Data.nSample 5])
            tc.verifyGreaterThan(sum(m.componentContribution(1:3)), 99.99)
        end

        function pcaDoesNotChangeTheData(tc)
            % A fit should not alter the EEMs it returns
            d = tc.Data;
            d.X(:,1:3,:) = NaN;   % missing numbers, as after scatter removal
            p = drEEMtoolbox.fitpca(d,maxcomp=3,interpolateMissing=true);
            tc.verifyEqual(p.X, d.X)
        end
    end
end
