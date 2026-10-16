classdef OriginVsTextImportTest < DreemTestCase
    % The same measurements imported two ways must give the same data:
    %   tests/testdata/dataset 3/samples1.opj   -> importaqualog (aqualog2nc, re-processed raw data)
    %   tests/testdata/dataset 3/*.dat          -> importeems / importabsorbance (Aqualog text export)
    % Known, allowed differences:
    %   - importeems rounds wavelengths to 0.1 nm, the .opj route keeps them exact
    %   - the .opj route sets oversaturated pixels (raw > 65000) to NaN
    % Samples are paired by name, not by position.

    properties (Constant)
        RelTol = 1e-6    % text export has ~15 significant digits
    end

    properties (Access = private)
        Txt
        TxtBlank
        TxtAbs
        Opj
        OpjBlank
    end

    methods (TestClassSetup)
        function importBoth(tc)
            tc.useTempFolder();
            copyfile(fullfile(tc.RepoRoot,"tests","testdata","dataset 3","*"), pwd);
            st = tc.knownStatus;
            tc.Txt      = drEEMtoolbox.importeems("* - Waterfall Plot Sample.dat",st);
            tc.TxtBlank = drEEMtoolbox.importeems("* - Waterfall Plot Blank.dat",st);
            tc.TxtAbs   = drEEMtoolbox.importabsorbance("* - Abs Spectra Graphs.dat",st);
            try
                [tc.Opj,tc.OpjBlank] = drEEMtoolbox.importaqualog(pwd);
            catch ME
                % aqualog2nc must be downloaded once; not possible offline or on Intel Macs
                tc.assumeFalse(any(strcmp(ME.identifier, ...
                    ["drEEM:aqualog2ncDownload","drEEM:unsupportedPlatform"])), ME.message)
                rethrow(ME)
            end
        end
    end

    methods (Test)
        function everyExportedSampleIsInTheProject(tc)
            missing = setdiff(tc.Txt.filelist, tc.Opj.filelist);
            tc.verifyEmpty(missing, "not found in the .opj import: " + strjoin(string(missing),", "))
        end

        function sameWavelengths(tc)
            tc.verifyEqual(tc.Opj.Ex, tc.Txt.Ex, AbsTol=1e-9)
            tc.verifyEqual(tc.Opj.Em, tc.Txt.Em, "emission (text route rounds to 0.1 nm)", AbsTol=0.05)
        end

        function sameSampleEEMs(tc)
            [o,t] = paired(tc, tc.Opj, tc.Txt);
            verifySameValues(tc, o, t, "sample EEMs")
        end

        function sameBlankEEMs(tc)
            [o,t] = paired(tc, tc.OpjBlank, tc.TxtBlank);
            verifySameValues(tc, o, t, "blank EEMs")
        end

        function sameAbsorbance(tc)
            [~,io,it] = intersect(tc.Opj.filelist, tc.TxtAbs.filelist, "stable");
            [w,wo,wt] = intersect(round(tc.Opj.absWave,1), round(tc.TxtAbs.absWave,1));
            tc.assertNotEmpty(w, "no common absorbance wavelengths")
            o = tc.Opj.abs(io,wo);
            t = tc.TxtAbs.abs(it,wt);
            keep = isfinite(o) & isfinite(t);
            tc.verifyEqual(o(keep), t(keep), "absorbance", AbsTol=1e-6, RelTol=tc.RelTol)
        end
    end
end

function [o,t] = paired(tc,opj,txt)
% EEMs of the samples present in both imports, in the same order
[~,io,it] = intersect(opj.filelist, txt.filelist, "stable");
tc.assertNotEmpty(io, "no sample names in common")
tc.assertEqual([opj.nEm opj.nEx], [txt.nEm txt.nEx], "EEM sizes differ")
o = opj.X(io,:,:);
t = txt.X(it,:,:);
end

function verifySameValues(tc,o,t,what)
keep = isfinite(o) & isfinite(t);
% oversaturated pixels are NaN in the .opj route only; they must stay rare
tc.verifyLessThan(nnz(~keep & isfinite(t))/numel(t), 0.01, what + ": too many values missing from the .opj import")
tc.verifyEqual(o(keep), t(keep), what, AbsTol=1e-9, RelTol=tc.RelTol)
end
