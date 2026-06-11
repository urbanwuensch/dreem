classdef horibaRawdata
    % Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
    % Chalmers University of Technology
    % Department of Architecture and Civil Engineering
    % Sven Hultins Gata 6
    % 41296 Gothenburg (Sweden)
    properties
        AbsI1darkSample
        Abs_horiba
        AbsI1Sample
        Abs_wave
        AbsI1darkBlank
        AbsI1Blank
        Ex
        Em
        S1Blank
        S1DarkBlank
        MCorrect
        R1Blank
        AbsR1Blank
        R1DarkBlank
        AbsR1darkBlank
        XCorrect
        AbsXCorrect
        S1Sample
        S1DarkSample
        R1Sample
        AbsR1Sample
        R1DarkSample
        AbsR1darkSample
        integrationtime
        Em_parkpos
        Em_PixelBin
        CCD_gain
        filelist (:,1) cell
        opjfile
        nSample
        history (:,1) drEEMhistory
    end
    methods
        function dataout = fixfilename(data,wrong,corrected,mode)
            arguments
                data {mustBeA(data,'horibaRawdata')}
                wrong (1,:) {mustBeText}
                corrected (1,:) {mustBeText}
                mode {mustBeText(mode),mustBeMember(mode,["matches","contains"])} = "matches";
            end

            switch mode
                case "matches"
                    wrong_i=matches(data.filelist,char(wrong));
                case "contains"
                    wrong_i=contains(data.filelist,char(wrong));
            end
            if isempty(wrong_i)
                error('Your input to "wrong" yielded no results. Check the string...')
            elseif sum(wrong_i)>2
                error('Your input to "wrong" yielded multiple results. Check the string or change the "mode" option...')
            end
            data.filelist(wrong_i)={char(corrected)};

            dataout=data;
            
            % drEEMhistory entry
            idx=height(dataout.history)+1;
            dataout.history(idx,1)=...
                drEEMhistory.addEntry(mfilename,['Replaced filelist entry "',char(wrong),'" with "',char(corrected),'"'],[],dataout);


        end

    end
end