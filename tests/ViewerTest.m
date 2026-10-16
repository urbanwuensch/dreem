classdef ViewerTest < DreemTestCase
    % Smoke tests for the view* apps on the modelled tutorial dataset: they open
    % without error and save their figure under the requested file name.
    % Saving waits ~3 s per viewer for rendering, so this class takes a while.

    properties (TestParameter)
        viewer = {'vieweems','viewmodels','viewdmr','viewcompcorr','viewhistory', ...
            'viewabsorbance','viewspectralvariance','viewscatter','viewsplitvalidation'}
    end

    properties (Access = private)
        S
    end

    methods (TestClassSetup)
        function loadTutorial(tc)
            tc.S = load(tc.examplesFile("tutorial_parafac_modelled.mat"),"samples").samples;
        end
    end

    methods (Test)
        function opensWithoutError(tc,viewer)
            tc.callViewer(viewer);
            tc.verifyNotEmpty(findall(groot,"Type","figure"), viewer + " opened no figure")
        end

        function savesFigureUnderGivenName(tc,viewer)
            % saveAfterFunctionCall appends "-<calling function>" (and a counter if
            % the file exists), so only the start of the name is fixed
            tc.useTempFolder();
            stem = "fig_" + viewer;
            tc.callViewer(viewer, figurefile=stem + ".png");
            tc.verifyNotEmpty(dir(stem + "*.png"), viewer + " saved no file starting with " + stem)
            tc.verifyEmpty(dir("test*.png"), viewer + " ignored figurefile and saved test*.png")
        end

        function openfluorMatchesFromExampleFile(tc)
            f = which("OpenFluorSearch_384_osPARAFAC_Tapajos_20250223.csv");
            tc.assumeNotEmpty(f, "example OpenFluor file not on path")
            [summary,M] = drEEMtoolbox.viewopenfluormatches(f);
            tc.verifyNotEmpty(summary)
            tc.verifyNotEmpty(M)
        end
    end

    methods (Access = private)
        function callViewer(tc,viewer,varargin)
            % viewdmr and viewsplitvalidation need the number of components
            if any(strcmp(viewer,{'viewdmr','viewsplitvalidation'}))
                feval("drEEMtoolbox."+viewer, tc.S, 5, varargin{:});
            else
                feval("drEEMtoolbox."+viewer, tc.S, varargin{:});
            end
        end
    end
end
