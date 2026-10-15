classdef ProcessingRegressionTest < DreemTestCase
    % Runs every case in ProcessingCases.all() and compares the result with the
    % fingerprint stored in tests/reference/processing_fingerprints.mat.
    %
    % A failure means a processing result changed. If the change is intended,
    % regenerate the affected references and commit them with the code change:
    %   cd tests; updateProcessingReference("<caseName>"); cd ..

    properties (TestParameter)
        caseName = ProcessingCases.names()
    end

    properties (Access = private)
        Stages
        Reference
    end

    methods (TestClassSetup)
        function prepare(tc)
            f = ProcessingCases.referenceFile(tc.RepoRoot);
            tc.assertTrue(isfile(f), ...
                "No reference fingerprints yet. Run: cd tests; updateProcessingReference; cd ..")
            tc.Reference = load(f).fingerprints;
            tc.Stages = ProcessingCases.stages(tc.RepoRoot);
        end
    end

    methods (Test)
        function matchesReference(tc,caseName)
            tc.assertTrue(isfield(tc.Reference,caseName), caseName + ...
                " has no reference yet. Run: cd tests; updateProcessingReference(""" + caseName + """); cd ..")
            c = ProcessingCases.get(caseName);
            actual = ProcessingCases.fingerprint(c.run(tc.Stages));
            expected = tc.Reference.(caseName);
            for f = string(fieldnames(expected))'
                tc.assertTrue(isfield(actual,f), caseName + ": fingerprint field " + f + " missing")
                if isnumeric(expected.(f))
                    tc.verifyEqual(actual.(f), expected.(f), caseName + ": " + f, RelTol=1e-9, AbsTol=1e-10)
                else
                    tc.verifyEqual(actual.(f), expected.(f), caseName + ": " + f)
                end
            end
        end
    end
end
