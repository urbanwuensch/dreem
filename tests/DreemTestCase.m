classdef (Abstract) DreemTestCase < matlab.unittest.TestCase
    % Shared setup for drEEM tests: puts the repository's toolbox on the path
    % (ahead of any installed copy), closes figures after each test, and
    % provides helpers that write small synthetic measurement files.
    %
    % Methods are called as drEEMtoolbox.<method>(...) so the drEEMtoolbox
    % constructor (version and update checks, dialogs) never runs.

    properties (SetAccess = private)
        RepoRoot string
    end

    methods (TestClassSetup)
        function requireProjectToolbox(tc)
            tc.RepoRoot = string(fileparts(fileparts(mfilename("fullpath"))));
            loc = string(which("drEEMtoolbox"));
            tc.assertTrue(startsWith(loc, fullfile(tc.RepoRoot,"toolbox")), ...
                "Open the drEEM project (matlab.toml) before running tests. " + ...
                "drEEMtoolbox currently resolves to: " + loc)
        end
    end

    methods (TestMethodTeardown)
        function closeFigures(~)
            delete(findall(groot,"Type","figure"))
        end
    end

    methods (Access = protected)
        function useTempFolder(tc)
            % Importers search pwd, so each test works in its own empty folder
            tc.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end

        function p = examplesFile(tc,name)
            p = fullfile(tc.RepoRoot,"toolbox","examples",name);
        end
    end

    methods (Static, Access = protected)
        function st = knownStatus(ife)
            % A status without "unknown" entries, so no import opens the status GUI
            arguments
                ife (1,1) string = "not applied"
            end
            st = drEEMstatus(spectralCorrection="applied by instrument software", ...
                IFEcorrection=ife, blankSubtraction="not applied", ...
                signalCalibration="not applied", scatterTreatment="not applied", ...
                signalScaling="original scale", absorbanceUnit="absorbance per cm", ...
                suppSpectraInfo="synthetic test scans");
        end

        function X = writeEEMs(names,ex,em)
            % One csv per name: first row = excitation, first column = emission.
            % Returns the written intensities (nSample x nEm x nEx).
            X = zeros(numel(names),numel(em),numel(ex));
            for k = 1:numel(names)
                x = k + (1:numel(em))'*0.01 + (1:numel(ex))*0.001;
                X(k,:,:) = x;
                writematrix([NaN, ex(:)'; em(:), x], names(k));
            end
        end

        function A = writeSpectra(names,axis)
            % One two-column csv per name (axis, signal). Returns nSample x nAxis.
            A = zeros(numel(names),numel(axis));
            for k = 1:numel(names)
                A(k,:) = k*exp(-0.015*(axis(:)'-axis(1)));
                writematrix([axis(:), A(k,:)'], names(k));
            end
        end
    end
end
