classdef drEEMmodel
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
    properties
        loads (1,3) cell 
        leverages (1,3) cell
        sse (1,3) cell
        status (1,:) {mustBeText} = [""]
        percentExplained (1,1) {mustBeNumeric} = NaN
        error (1,1) {mustBeNumeric}  = NaN
        core (1,1) {mustBeNumeric}  = NaN
        percentUnconverged (1,1) {mustBeNumeric}  = NaN
        componentContribution (1,:) {mustBeNumeric}  = NaN
        initialization (1,:) {mustBeText}  = [""]
        starts (1,1) {mustBeNumeric}  = NaN
        convergence (1,1) {mustBeNumeric}  = NaN
        constraints (1,:) {mustBeText}  = [""]
        toolbox  (1,:) {mustBeText}  = [""]
        modelName (1,:) {mustBeText,mustBeMember(modelName,["PARAFAC","PCA","NPLS"])} = "PARAFAC";
    end

    methods (Static = true)
        function tableout=convert2table(history)
            mustBeA(history,"drEEMmodel")
            flds=fieldnames(history);
            
            conv=struct;
            for j=1:numel(flds)
                for k=1:height(history)
                    conv(k).(flds{j})=history(k).(flds{j});
                end
            end
            tableout=struct2table(conv);

        end

        results = fitresipca(data)
        
    end
end