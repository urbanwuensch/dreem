function dataout = ifecorrection(data,options)
% <a href = "matlab:drEEMtoolbox.doc('ifecorrection')">dataout = ifecorrection(data) (click to access documentation)</a>
%
% <strong>Correct inner-filter effects</strong> with the absorbance-based approach
%
% <strong>INPUTS - Required</strong>
% data (1,1) {mustBeA("drEEMdataset"),drEEMdataset.validate,drEEMdataset.sanityCheckIFE}
% options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
% figurefile (1,:) {mustBeText} = ""
%
% <strong>EXAMPLE(S)</strong>
%   1. samples = ifecorrection(samples)
%   2. samples = ifecorrection(samples,plot=false) (no final overview over IFE)
%
% <a href = "matlab:drEEMtoolbox.doc('ifecorrection')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,1) {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),...
        drEEMdataset.sanityCheckIFE(data),drEEMdataset.mustContainSamples(data)}
    options.plot (1,1) {mustBeNumericOrLogical} = data.toolboxOptions.plotByDefault;
    options.figurefile (1,:) {mustBeText} = "";
end
% Experimental feature; overwrite workspace variable, needs no outputarg check
if drEEMtoolbox.outputscenario(nargout)=="explicitOut"
    if nargout>0
        nargoutchk(1,1)
    else
        disp('<strong>Diagnostic mode</strong>, no output will be assigned (no variable was specified).')
        options.plot=true;
    end
end
% Assign the final output variable based on input
dataout=data;
dataout=absorbanceConverter(dataout,dataout.status.absorbanceUnit);



% IFE correction only works for the EEM wavelengths covered by CDOM abs.
AbsRange=[min(data.absWave) max(data.absWave)];
emout=logical(double(dataout.Em<AbsRange(1))+ double(dataout.Em>AbsRange(2)));
exout=logical(double(dataout.Ex<AbsRange(1))+ double(dataout.Ex>AbsRange(2)));

% Make sure that the right information is given to the user
message='Abs-based IFE correction applied. ';
if any(emout)||any(exout)
    message=[message,'CDOM and FDOM coverage different (subdataset applied). '];
end
% Remove wavelengths not covered by absorbance from DS
dataout=drEEMtoolbox.subdataset(dataout,outEm=emout,outEx=exout);

% Calculate the IFE correction factors based on ABA
IFCmat=ABAife(dataout.Ex,dataout.Em,[rcvec(dataout.absWave,'row');dataout.abs]);  %or use Abs.Aug here
IFCmat=real(IFCmat);
if any(data.abs(:)>2)
    message=[message,'Some samples had very high absorbance (>2). These areas were NaN''ed. '];
    warning('Some samples had very high absorbance (>2). This function produces NaN correction factors and thus deletes the affected data.')
end
% Perform the correction
dataout.X=dataout.X.*IFCmat;
dataout.status=...
    drEEMstatus.change(dataout.status,"IFEcorrection","applied by toolbox");

% drEEMhistory entry
idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,message,[],dataout);
dataout.validate(dataout);

disp(message)


if options.plot
    if data.toolboxOptions.uifig
        f=drEEMtoolbox.dreemuifig;
    else
        f=drEEMtoolbox.dreemfig;
    end
    f.Name='drEEM: ifecorrection.m';
    t=tiledlayout(f);
    ax(1)=nexttile(t);
    mesh(ax(1),dataout.Ex,dataout.Em,squeeze(mean(IFCmat,1,"omitmissing")))
    title(ax(1),'Average')
    zlabel(ax(1),'IFE correction factor')

    ax(2)=nexttile(t);
    mesh(ax(2),dataout.Ex,dataout.Em,squeeze(min(IFCmat,[],1,"omitmissing")))
    title(ax(2),'Minimum')
    zlabel(ax(2),'IFE correction factor')

    ax(3)=nexttile(t);
    mesh(ax(3),dataout.Ex,dataout.Em,squeeze(max(IFCmat,[],1,"omitmissing")))
    title(ax(3),'Maximum')
    xlabel(t,'Excitation (nm)')
    ylabel(t,'Emission (nm)')
    zlabel(ax(3),'IFE correction factor')
    title(t,'IFE matrices')

    figurefile=char(options.figurefile);
    if not(isempty(figurefile))
        % Pause for figure rendering
        pause(3)
        try
            dreemgui.saveAfterFunctionCall(f,figurefile)
        catch ME
            throwAsCaller(ME)
        end
    end

end

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',char(inputname(1)), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
else
    if nargout==0
        clearvars dataout
    end
end

end

function [vout] = rcvec(v,rc)
% Make row or column vector
% v: vector
% rc: either 'row' ([1:5])or 'column' ([1:5]')
sz=size(v);
if ~any(sz==1)
    error('Input is not a vector')
end

switch rc
    case 'row'
        if ~(sz(1)<sz(2))
            vout=v';
        else
            vout=v;
        end
    case 'column'
        if ~(sz(1)>sz(2))
            vout=v';
        else
            vout=v;
        end
    otherwise
            error('Input ''rc'' not recognized. Options are: ''row'' and ''column''.')
end

end



function [IFC,K]=ABAife(Ex,Em,A,X)
%
% <strong>Syntax</strong>
%   [IFC,K]=<strong>ABAife</strong>(Ex,Em,A,X)
%
% <a href="matlab: doc ABAife">help for ABAife</a> <- click on the link

% USEAGE:
%  [IFC,K]=ABAife(Ex,Em,A,X)
%
% Absorbance (ABA) Method for correcting fluorescence inner filter effects.
% Assumes that EEMs and Absorbance were measured in a square cuvette with
% standard right-angle geometry.
% All samples must have the same wavelengths.
%
% Input Variables:
%   Ex      excitation wavelengths
%   Em      emission wavelengths
%   A       absorbance scans for n samples over the full range of Ex and Em, 
%               with wavelengths in 1st row, samples in rows 2:n+1.
% Optional
%   X       fluorescence EEM (n x Em rows x Ex columns) measured in a 1 cm cell
%
% Output Variables:
%   IFC     inner filter matrix (n x Em rows x Ex columns)
%   K       corrected EEM (n x Em rows x Ex columns), only if X was given
%
% Examples          
%   IFC=ABAife(Ex,Em,A)
%   [IFC,K]=ABAife(Ex,Em,A,X)
%
%Reference for ABA algorithm:
% Parker, C. A.; Barnes, W. J., Some experiments with spectrofluorimeters
% and filter fluorimeters. Analyst 1957, 82, 606-618.
%
% Notice:
% This mfile is part of the drEEM toolbox. Please cite the toolbox
% as follows:
%
% Murphy K.R., Stedmon C.A., Graeber D. and R. Bro, Fluorescence
%     spectroscopy and multi-way techniques. PARAFAC, Anal. Methods, 
%     5, 6557-6566, 2013. DOI:10.1039/c3ay41160e. 

narginchk(3,4) %check input arguments
K=[];
N_samples=size(A,1)-1;
N_em=length(Em);
N_ex=length(Ex);
IFC=NaN*ones([N_samples,N_em,N_ex]);

for i=1:N_samples
    Atot=zeros(N_em,N_ex);
    Ak=[A(1,:);A(i+1,:)];
    
    Aem=MatchWave(Ak,Em,0);
    Aex=MatchWave(Ak,Ex,0);
    

    
    for j=1:size(Aem,1)
        for k=1:size(Aex,1)
            Aex_t=Aex(k,2);
            Aem_t=Aem(j,2);
            
            % if Aex_t>2
            %     Aex_t=NaN;
            % end
            % if Aem_t>2
            %     Aem_t=NaN;
            % end
            % 
            Atot(j,k)=Aex_t+Aem_t;
        end
    end
    ifc=10.^(1/2*Atot);
    IFC(i,:,:)=ifc;
end 
if nargin==4
K=IFC.*X;
end  
end

function Y=MatchWave(V1,V2,doplot)
%Y=MatchWave(V1,V2,doplot)
%Automatically match the size of two vectors, interpolating if necessary.
%Vector V1 is resized and interpolated to have the same wavelengths as V2;
%For example, V1 is a correction file (0.5nm intervals) and V2 is an Emission scan in 2 nm intervals.
%Errors are produced if 
%(1) there are wavelengths in V2 that are outside the upper or lower limit of V1.
%(2) Be aware of rounding errors. For example, 200.063 is NOT equivalent to 200 nm.
% Errors can often be resolved by restricting the wavelength range of V2
% Copyright K.R. Murphy
% July 2010

if size(V1,2)>2; V1=V1';end  %V1 should have multiple rows
if size(V2,2)>2; V2=V2';end  %V2 should have multiple rows

%Restrict the wavelength range of V1 so it is the same as V2
t=V1(find(V1(:,1)<=V2(1,1),1,'last'):find(V1(:,1)>=V2(end,1),1,'first'),:); 
if isempty(t)
    fprintf('\n')
    fprintf(['Error - Check that your VECTOR 1 (e.g. correction file) '...
        'encompasses \n the full range of wavelengths in VECTOR 2 (e.g. emission scan)\n'])
    fprintf('\n Hit any key to continue...')
    pause
    fprintf(['\n VECTOR 1 range is ' num2str(V1(1,1)) ' to ' num2str(V1(end,1)) ' in increments of ' num2str(V1(2,1)-V1(1,1)) '.']),pause
    fprintf(['\n VECTOR 2 range is ' num2str(V2(1,1)) ' to ' num2str(V2(end,1)) ' in increments of ' num2str(V2(2,1)-V2(1,1)) '.']),pause
    fprintf('\n\n This error can usually be resolved by restricting the wavelength range of VECTOR 2,');
    fprintf('\n also, be aware of rounding errors (e.g. 200.063 is NOT equivalent to 200 nm)\n');
    error('fdomcorrect:wavelength','Error - abandoning calculations.');
else
    Y=[V2(:,1) interp1(t(:,1),t(:,2),V2(:,1))]; %V1 corresponding with EEM wavelengths
end

if doplot==true;    
figure, 
plot(V1(:,1),V1(:,2)), hold on, plot(Y(:,1),Y(:,2),'ro')
legend('VECTOR 1', 'VECTOR 2')
end
end

function dataout = absorbanceConverter(data,unitIn)
            arguments
                data (1,1) {mustBeA(data,'drEEMdataset')}
                unitIn (1,:) {mustBeText(unitIn),mustBeMember(unitIn,["absorbance per cm","absorbance per 5 cm","absorbance per 10 cm","napierian absorption coefficient","linear decadic absorption coefficient"])}
            end
            unitOut="per cm";
            dataout=data;
            switch unitIn
                case "absorbance per cm"
                    switch unitOut
                        case "per cm"
                            return
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs./0.01;
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./0.01.*2.303;
                    end
                case "absorbance per 5 cm"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs./5;
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs./5./0.01;
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./5./0.01.*2.303;
                    end
                case "absorbance per 10 cm"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs./10;
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs./10./0.01;
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./10./0.01.*2.303;
                    end
                case "napierian absorption coefficient"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs.*0.01./2.303;
                        case "decadal absorption coefficient"
                            dataout.abs=dataout.abs.*2.303;
                        case "naperian absorption coefficient"
                            return
                    end
                case "linear decadic absorption coefficient"
                    switch unitOut
                        case "per cm"
                            dataout.abs=dataout.abs.*0.01;
                        case "decadal absorption coefficient"
                            return
                        case "naperian absorption coefficient"
                            dataout.abs=dataout.abs./2.303;
                    end
            end
        end