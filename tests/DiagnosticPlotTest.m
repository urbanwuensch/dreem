classdef DiagnosticPlotTest < DreemTestCase
    % Smoke tests for the code paths users see: diagnostic mode (no output argument,
    % forces plots) and plot=true, on the processing tutorial chain. Only checks that
    % nothing errors and that a figure appears; figures are closed after each test.
    %
    % Not covered because they block until a person closes a window:
    %   handlescatter with options.plot=true, and diagnostic mode of rmspikes,
    %   pickpeaks and fitslopes (they force details=true, which uses uiwait).

    properties (Access = private)
        St
    end

    methods (TestClassSetup)
        function prepare(tc)
            tc.St = ProcessingCases.stages(tc.RepoRoot);
        end
    end

    methods (Test)
        %% diagnostic mode (no output argument)
        function processabsorbanceDiagnostic(tc)
            drEEMtoolbox.processabsorbance(tc.St.S);
            tc.verifyFigureShown()
        end

        function ifecorrectionDiagnostic(tc)
            drEEMtoolbox.ifecorrection(tc.St.A);
            tc.verifyFigureShown()
        end

        function subtractblanksDiagnostic(tc)
            drEEMtoolbox.subtractblanks(tc.St.I,tc.St.B);
            tc.verifyFigureShown()
        end

        function ramancalibrationDiagnostic(tc)
            drEEMtoolbox.ramancalibration(tc.St.Bs,tc.St.B);
            tc.verifyFigureShown()
        end

        function alignsamplesDiagnostic(tc)
            % pass variables: alignsamples labels its diagnosis with the input names
            samples = tc.St.S;
            blanks = tc.St.B;
            drEEMtoolbox.alignsamples(samples,blanks);
        end

        function scalesamplesHelp(tc)
            drEEMtoolbox.scalesamples(tc.St.H,'help');
            tc.verifyFigureShown()
        end

        %% plot=true with an output (details stays false, so nothing blocks)
        function rmspikesPlot(tc)
            d = drEEMtoolbox.rmspikes(tc.St.H,thresholdFactor=30,plot=true); %#ok<NASGU>
            tc.verifyFigureShown()
        end

        function pickpeaksPlot(tc)
            d = drEEMtoolbox.pickpeaks(tc.St.H,plot=true); %#ok<NASGU>
            tc.verifyFigureShown()
        end

        function fitslopesPlot(tc)
            d = drEEMtoolbox.fitslopes(tc.St.A,plot=true); %#ok<NASGU>
            tc.verifyFigureShown()
        end
    end

    methods (Access = private)
        function verifyFigureShown(tc)
            tc.verifyNotEmpty(findall(groot,"Type","figure"), "no figure was opened")
        end
    end
end
