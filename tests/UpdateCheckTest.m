classdef UpdateCheckTest < DreemTestCase
    % drEEMtoolbox.updatecheck decides about updates without any dialog; it must never
    % error. Network-dependent tests are skipped (not failed) when offline.

    properties (Constant)
        ZenodoURL = 'https://zenodo.org/api/records/17182160/versions/latest'
        BadURL    = 'https://zenodo.org/api/records/0/versions/latest'
    end

    methods (TestMethodSetup)
        function keepCheckDate(tc)
            % updatecheck writes this preference; restore it afterwards
            if ispref('drEEM','lastUpdateCheck')
                old = getpref('drEEM','lastUpdateCheck');
                tc.addTeardown(@setpref,'drEEM','lastUpdateCheck',old);
            else
                tc.addTeardown(@rmpref,'drEEM','lastUpdateCheck');
            end
            setpref('drEEM','lastUpdateCheck',NaT);   % start every test as "not checked yet"
        end
    end

    methods (Test)
        %% never errors, returns '' when there's nothing to offer
        function unreachableRecordReturnsEmpty(tc)
            tc.verifyEmpty(drEEMtoolbox.updatecheck(tc.BadURL,true))
        end

        function unexpectedResponseReturnsEmpty(tc)
            % valid JSON, but not a Zenodo record
            tc.verifyEmpty(drEEMtoolbox.updatecheck( ...
                'https://api.github.com/repos/urbanwuensch/dreem/releases/latest',true))
        end

        function alreadyCheckedTodayReturnsEmpty(tc)
            setpref('drEEM','lastUpdateCheck',datetime('today'));
            tc.verifyEmpty(drEEMtoolbox.updatecheck(tc.BadURL,false))
        end

        function failedCheckWaitsUntilTomorrow(tc)
            drEEMtoolbox.updatecheck(tc.BadURL,false);
            tc.verifyEqual(getpref('drEEM','lastUpdateCheck'), datetime('today'))
        end

        function noDialogWithoutUpdate(tc)
            tc.verifyWarningFree(@() drEEMtoolbox.interactiveupdate(''))
        end

        %% decisions (need Zenodo)
        function newerInstallGetsNoUpdate(tc)
            tc.assumeOnline();
            tc.verifyEmpty(drEEMtoolbox.updatecheck(tc.ZenodoURL,true,[9 99 99],[]))
        end

        function sameVersionGetsNoUpdate(tc)
            tc.assumeOnline();
            tc.verifyEmpty(drEEMtoolbox.updatecheck(tc.ZenodoURL,true,[2 26 9],[2 26 9]))
        end

        function olderInstallGetsInstallableURL(tc)
            tc.assumeOnline();
            url = drEEMtoolbox.updatecheck(tc.ZenodoURL,true,[1 0 0],[]);
            tc.verifyTrue(contains(url,'.mltbx'), "update URL: " + string(url))
        end

        function publishedVersionIsInstallable(tc)
            % the latest Zenodo version must have a .mltbx and a plain version number
            rec = tc.assumeOnline();
            files = rec.files;
            if iscell(files), files = [files{:}]; end
            tc.verifyTrue(any(endsWith(string({files.key}),".mltbx")), "no .mltbx in latest Zenodo version")
            tc.verifyMatches(string(rec.metadata.version), "^v?\d+\.\d+\.\d+$", ...
                "Zenodo version field must be a plain version number")
        end
    end

    methods (Access = private)
        function rec = assumeOnline(tc)
            try
                rec = webread(tc.ZenodoURL, weboptions(ContentType="json",Timeout=10));
            catch
                tc.assumeFail("Zenodo not reachable")
            end
        end
    end
end