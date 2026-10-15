classdef SyntheticData
    % Small datasets with known answers for the fitting tests.

    methods (Static)
        function [d,truth] = parafacDataset(nSample)
            % Exact 3-component trilinear EEMs: Gaussian excitation and emission
            % loadings, scores between 0.1 and 1 (fixed seed, independent of rng)
            arguments
                nSample (1,1) double = 20
            end
            s = RandStream("mt19937ar","Seed",7);
            ex = (240:5:400)';
            em = (300:4:560)';
            B = [gauss(em,350,25) gauss(em,420,35) gauss(em,480,40)];   % emission
            C = [gauss(ex,275,15) gauss(ex,320,25) gauss(ex,360,30)];   % excitation
            A = 0.1 + 0.9*rand(s,nSample,3);                              % scores
            X = zeros(nSample,numel(em),numel(ex));
            for i = 1:nSample
                X(i,:,:) = B*diag(A(i,:))*C';
            end
            d = SyntheticData.dataset(X,ex,em);
            truth.A = A;
            truth.B = B;
            truth.C = C;
            truth.fmax = A.*max(B).*max(C);
        end

        function d = constantDataset(values,ex,em)
            % One constant EEM per sample (values(k) everywhere in sample k)
            values = values(:);
            X = repmat(values,1,numel(em),numel(ex));
            d = SyntheticData.dataset(reshape(X,numel(values),numel(em),numel(ex)),ex,em);
        end

        function d = dataset(X,ex,em)
            % Valid drEEMdataset with a status that allows every processing step and PARAFAC
            n = size(X,1);
            d = drEEMdataset.create;
            d.X = X;
            d.Ex = ex(:);
            d.Em = em(:);
            d.nEx = numel(ex);
            d.nEm = numel(em);
            d.nSample = n;
            d.i = (1:n)';
            d.filelist = cellstr(compose("S%02d",(1:n)'));
            d.metadata = table((1:n)','VariableNames',{'i'});
            d.status = drEEMstatus(spectralCorrection="applied by instrument software", ...
                IFEcorrection="deemed unnecessary", blankSubtraction="applied by instrument software", ...
                signalCalibration="applied by instrument software (RU)", ...
                scatterTreatment="applied by instrument software", signalScaling="original scale", ...
                absorbanceUnit="not applicable (no data)", suppSpectraInfo="none");
            drEEMdataset.validate(d);
        end

        function [p,t] = match(trueLoads,modelLoads)
            % For each true component: index of the best-matching model component
            % and its Tucker congruence
            T = abs(trueLoads'*modelLoads) ./ (vecnorm(trueLoads)'*vecnorm(modelLoads));
            [t,p] = max(T,[],2);
        end
    end
end

function y = gauss(x,mu,sigma)
y = exp(-((x-mu)/sigma).^2);
end
