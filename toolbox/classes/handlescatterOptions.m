classdef handlescatterOptions
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
    properties
        cutout (1,4) double = [1 1 1 1]
        interpolate (1,4) double = [0 0 0 0]
        negativetozero ...
            (1,:) {mustBeNumericOrLogical} = true
        ray1 (1,2) double = [10 10]
        ram1 (1,2) double = [15 15]
        ray2 (1,2) double = [5 5]
        ram2 (1,2) double = [5 5]
        d2zero (1,1) double = 60
        imethod ...
            (1,:) {mustBeText,mustBeMember(imethod,["inpaint","fillmissing"])} = "inpaint"
        iopt ...
            (1,:) {mustBeText,mustBeMember(iopt,["normal","conservative"])} = "normal"
        plot ...
            (1,:) {mustBeNumericOrLogical} = true
        plottype ...
            (1,:) {mustBeText,mustBeMember(plottype,["mesh","surface","contourf"])} = "mesh"
        samples (1,:) = 'all'
    end
    properties (SetAccess=private)
        description (1,:) {mustBeText} = 'Options for handlescatter.m'
    end
    methods (Static=true)
        function validate(data,options)
            if isstring(options.samples)||ischar(options.samples)||iscellstr(options.samples)
                if not(matches(options.samples,"all"))
                    error("handlescatter options.samples must be numeric or ""all""")
                end
            elseif isnumeric(options.samples)
                datasamples=1:data.nSample;
                if not(all(ismember(options.samples,datasamples)))
                    error("handlescatter options point at samples that do not exist in the dataset.")
                end
            else
                error('handlescatter option "samples" must be text or numeric')
            end

            if options.ray1(1)>options.d2zero&&options.interpolate(1)&&options.cutout(1)
                disp(' ')
                disp(' ')
                disp(sprintf(['    You are planning to cut and interpolate Rayleigh 1st order scatter\n'...
                    '    and then to force part of the interpolation to zero.'])); %#ok<DSPS>
                disp(sprintf('    It is advisable to leave some room between interpolation and forced zeros.')); %#ok<DSPS>
                disp(' ')
                pause(1)
                options.d2zero=options.ray1(1)+5;
            end

        end
    end
end