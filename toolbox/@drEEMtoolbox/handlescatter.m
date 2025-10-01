function dataout = handlescatter(data,option,ramanShift)
% <a href = "matlab:drEEMtoolbox.doc('handlescatter')">dataout = handlescatter(data,option) (click to access documentation)</a>
%
% <strong>Remove Rayleigh and Raman scatter</strong> from fluorescence data
%
% <strong>INPUTS - Required</strong>
% data      must be a drEEMdataset or the string "options"
% 
% <strong>INPUTS - Optional</strong>
% option    if supplied, must be a handlescatterOptions object or the string "gui"
%
% <strong>EXAMPLE(S)</strong>
%   1. retreive options for handlescatter for manipulation
%       scatteroptions = tbx.handlescatter('options');
%   2. carry out treatment based on existing options
%       samples = tbx.handlescatter(samples,scatteroptions);
%   3. get interactive help with option defintion
%       samples = tbx.handlescatter(samples,'gui');
%
% <a href = "matlab:drEEMtoolbox.doc('handlescatter')"><strong>-> full documentation</strong></a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data (1,:) {dataValidation(data)}
    option (1,:) {optionValidation(data,option)} = handlescatterOptions;
    ramanShift (1,1) {mustBeNumeric,mustBePositive} = 3382;
end

%% Check input arguments and react to different scenarios
% Scenario: Return options
if nargin==1&&not(isa(data,"drEEMdataset"))
    options=handlescatterOptions;
    dataout=options;
    return
end

% Scenario: No options provided
if nargin==1&&isa(data,"drEEMdataset")
    warning(sprintf(['No options were provided, the defaults were assumed.\n'...
        '     Please inspect the result and see if adjustments are necessary.\n'...
        '     Options can be obtained by calling ''handlescatter(''options'')'''])) %#ok<SPWRN>
end

% Scenario: User wants GUI for decision support
if isa(data,"drEEMdataset")&&not(isa(option,"handlescatterOptions"))
    % Start app with names
    handle=drEEMtoolbox.viewscatter(data);
    waitfor(handle,"finishedHere",true);
    try
        dataout=handle.dataTreated;
        delete(handle.deleteThis)
        delete(handle)
    catch
        error('App window closed before apply & exit button was pushed.')
    end
    return
end

% Scenario: data & options provided
if isa(data,"drEEMdataset")&&isa(option,"handlescatterOptions")
    options=option;
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
%% Check user input
if ischar(options.samples)||isstring(options.samples)
    allsamples=true;
else
    allsamples=false;
end


%% Preparation of matricies that will determine treatment
types={'ray1';'ram1';'ray2';'ram2'};

% If user provides all 0 for borders, set cutout to 0
for j=1:numel(types)
    if all(options.(types{j})==0)
        options.cutout(j)=0;
    end
end
% labeler(nanin,iin,x,y,type,below,above,iswitch,cutswitch)
% Missing-number matrix (will be used to NaN the EEMs)
nanmat=false(data.nEm,data.nEx);
% Interpolation matrix (will be used to identify interpolation scenarios)
imat=ones(data.nEm,data.nEx); % imat: 1(don't handle) 2(interpolate) 3(do no interpolate) (2&3 are set by labeler)
for n=1:numel(types)
    [nanmat,imat]=labeler(nanmat,imat,data.Ex,data.Em,types{n},options.(types{n})(1),options.(types{n})(2),options.interpolate(n),options.cutout(n),ramanShift);
end
clearvars types

%% Data treatment
if allsamples
    X=data.X;  %X  -> raw data
    
else
    X=data.X(options.samples,:,:);  %X  -> raw data
end
Xc=X;      %Xc -> X (cut)
% (1) NaN the scatter diagonals
Xc(:,nanmat)=nan;



% (2) Zero negatives (they may otherwise impact interpolation)
if options.negativetozero
    Xc(Xc<0)=0;
end
Xi=Xc;     %Xi -> X (interpolated)


% (3) Interpolate ALL scatter types, some may be NaN'ed later (depends on settings)
if any(options.interpolate)
    Xi=interpolatetheeem(Xi,options.imethod);
end
Xi(:,imat==3&nanmat)=nan; % NaN the types that should not have been interpolated.


% (4) Zero negatives again to account for bad interpolation
if options.negativetozero
    Xi(Xi<0)=0;
end
% labeler(nanin,iin,x,y,type,below,above,iswitch,cutswitch)
% (5) Zero data below 1st order Rayleigh
if ~isempty(options.d2zero)
    d2zeromat=false(data.nEm,data.nEx);
    [d2zeromat,~]=labeler(d2zeromat,[],data.Ex,data.Em,'d2zero',options.d2zero,ramanShift);
    Xi(:,d2zeromat)=0;
end

% (6) NaN areas of intersecting scatter (if desired)
if strcmp(options.iopt,'conservative')
    ex=200:800;
    em=200:1000;
    imattemplate=ones(numel(em),numel(ex)); % imat: 1(don't handle) 2(interpolate) 3(do no interpolate) (2&3 are set by labeler)
    types={'ray1';'ram1';'ray2';'ram2'};
    for n=1:numel(types)
        if options.cutout(n)
            % labeler(nanin,iin,x,y,type,below,above,iswitch,cutswitch)
            [~,imat2{n}]=labeler([],imattemplate,ex,em,types{n},options.(types{n})(1),options.(types{n})(2),1,0,ramanShift);
            [compmat{n},]=labeler(false(data.nEm,data.nEx),[],data.Ex,data.Em,types{n},options.(types{n})(1),options.(types{n})(2),1,0,ramanShift);
        end
    end

    firstorderexcl=imat2{1}+imat2{2};
    secondorderexcl=imat2{3}+imat2{4};

    clearvars imattemplate imat2 types n

    exlim=ex(find(any(firstorderexcl==4,1),1,'last'));
    emlim=em(find(any(firstorderexcl==4,2),1,'last'));

    nanmat2=false(data.nEm,data.nEx);
    if exlim>=min(data.Ex)&&emlim>=min(data.Em)
        nanmat2(:,1:drEEMtoolbox.mindist(data.Ex,exlim))=true;
        nanmat2(1:drEEMtoolbox.mindist(data.Ex,exlim),:)=true;
    end
    nanmat3=nanmat2&compmat{1}|nanmat2&compmat{2};
    exlim=ex(find(any(secondorderexcl==4,1),1,'last'));
    emlim=em(find(any(secondorderexcl==4,2),1,'last'));

    nanmat2=false(data.nEm,data.nEx);
    if exlim>=min(data.Ex)&&emlim>=min(data.Em)
        nanmat2(:,1:drEEMtoolbox.mindist(data.Ex,exlim))=true;
        nanmat2(1:drEEMtoolbox.mindist(data.Ex,exlim),:)=true;
    end
    nanmat4=nanmat2==true&compmat{1}==true|nanmat2==true&compmat{2}==true;
    
    nanmat5=nanmat3|nanmat4;
    clearvars nanmat4 nanmat3 nanmat2 exlim emlim firstorderexcl secondorderexcl
    Xi(:,nanmat5)=NaN;
end

%% Output variable definition
dataout=data;
if allsamples
    dataout.X=Xi;
else
    dataout.X(options.samples,:,:)=Xi;
end
% Change the dataset status
dataout.status=...
    drEEMstatus.change(dataout.status,"scatterTreatment","applied by toolbox");
%% Plotting

if options.plot
    if data.toolboxOptions.uifig
        fh=drEEMtoolbox.dreemuifig;
    else
        fh=drEEMtoolbox.dreemfig;
    end
    set(fh, 'units','normalized','pos',[0.05    0.1611    0.9    0.3700]);
    t=tiledlayout(fh);
    for n=1:3
        ax(n)=nexttile(t); %#ok<AGROW>
    end
    huic = uicontrol(fh,'Style', 'pushbutton','String','Next',...
    'Units','normalized','Position', [0.9323 0.0240 0.0604 0.0500],...
    'Callback',{@pltnext});
    huic2 = uicontrol(fh,'Style', 'pushbutton','String','Close figure',...
    'Units','normalized','Position', [0.9323 0.0816 0.0604 0.0500],...
    'Callback',{@endfunc,fh});
    az=[83.2,83.2,83.2];
    el=[55.26,55.26,55.26];
    for n=1:dataout.nSample
        switch options.plottype
            case 'mesh'
                mesh(ax(1),dataout.Ex,dataout.Em,squeeze(X(n,:,:)))
                mesh(ax(2),dataout.Ex,dataout.Em,squeeze(Xc(n,:,:)))
                mesh(ax(3),dataout.Ex,dataout.Em,squeeze(Xi(n,:,:)))
                for k=1:3
                    view(ax(k),az(k),el(k))
                    colormap(ax(k),cmap)
                    ylabel(ax(k),'Emission (nm)')
                    xlabel(ax(k),'Excitation (nm)')
                    zlabel(ax(k),'Intensity')
                end
            case 'surface'
                for k=1:3,cla(ax(k),'reset');end
                surface(ax(1),dataout.Ex,dataout.Em,squeeze(X(n,:,:)),'EdgeAlpha',0.5)
                surface(ax(2),dataout.Ex,dataout.Em,squeeze(Xc(n,:,:)),'EdgeAlpha',0.5)
                surface(ax(3),dataout.Ex,dataout.Em,squeeze(Xi(n,:,:)),'EdgeAlpha',0.5)
                for k=1:3
                    view(ax(k),az(k),el(k))
                    colormap(ax(k),cmap)
                    ylabel(ax(k),'Emission (nm)')
                    xlabel(ax(k),'Excitation (nm)')
                    zlabel(ax(k),'Intensity')
                    hold(ax(k),'off')
                end
            case 'contourf'
                contourf(ax(1),dataout.Ex,dataout.Em,squeeze(X(n,:,:)),50,'LineStyle','none')
                contourf(ax(2),dataout.Ex,dataout.Em,squeeze(Xc(n,:,:)),50,'LineStyle','none')
                contourf(ax(3),dataout.Ex,dataout.Em,squeeze(Xi(n,:,:)),50,'LineStyle','none')
                for k=1:3
                    colormap(ax(k),cmap)
                    ylabel(ax(k),'Emission (nm)')
                    xlabel(ax(k),'Excitation (nm)')
                end
        end
        title(ax(1),'Raw data'),title(ax(2),'Cut'),title(ax(3),'Final')
        uicontrol(huic)
        uiwait(fh)
        if ~ishandle(fh); return; end % Ends function when plot is closed by user
        
        for k=1:3,[az(k),el(k)]=view(ax(k));end
    end
end

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,'scatter treated',options,dataout);

% Will only run if toolbox is set to overwrite workspace variable and user
% didn't provide an output argument
if drEEMtoolbox.outputscenario(nargout)=="implicitOut"
    assignin("base",inputname(1),dataout);
    disp(['<strong> "',inputname(1), '" processed. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
    return
else
    if nargout==0
        clearvars dataout
    end
end

end
%% Internal functions used above

%%
function [nanout,iout]=labeler(nanin,iin,x,y,type,below,above,iswitch,cutswitch,ramanShift)
nanout=nanin;
iout=iin;
syncx=nan(numel(x),numel(y));
% switch-case for different types (d2zero immediately returns)

switch type
    case 'ray1'
        for n=1:numel(x)
            syncx(n,:) = y-x(n);
        end
    case 'ray2'
        for n=1:numel(x)
            syncx(n,:) = y-2*x(n);
        end
    case 'ram1'
        for n=1:numel(x)
            syncx(n,:)= y -(1e7*((1e7)/(x(n))-ramanShift)^-1);
        end

    case 'ram2'
        for n=1:numel(x)
            syncx(n,:) = y - ((1e7*((1e7)/(x(n))-ramanShift)^-1)*2);
        end
    case 'd2zero'
        for n=1:numel(x)
            syncx=y-x(n);
            nanout(syncx<=-below,n)=true;
        end
        return
    otherwise
        error('Input to ''type'' must be one of these: ray1 ray2 ram1 ram2 d2zero')
end

for n=1:numel(x)
    if cutswitch
        nanout(syncx(n,:)>=-below&syncx(n,:)<=above,n)=true;
    else
        nanout(syncx(n,:)>=-below&syncx(n,:)<=above,n)=false;
    end
    if iswitch
         iout(syncx(n,:)>=-below&syncx(n,:)<=above,n)=2;
    else
        iout(syncx(n,:)>=-below&syncx(n,:)<=above,n)=3;
    end
end

end

%%
function Xout=interpolatetheeem(Xin,method)
Xout=zeros(size(Xin,1),size(Xin,2),size(Xin,3));


switch method
    case 'inpaint'
        %disp(['    inpaint-interpolation takes time. Please wait... (approx. ',num2str(round(1.6/40000*numel(Xin)*2/60,1)),'min)'])        
        doparallel=true;
        if isempty(gcp('nocreate'))
            doparallel=false;
        end
        if doparallel
            parfor n=1:size(Xin,1)
                x=squeeze(Xin(n,:,:));
                x=inpaint_nans(x,1);
                Xout(n,:,:)=x;
            end
        else
            for n=1:size(Xin,1)
                x=squeeze(Xin(n,:,:));
                x=inpaint_nans(x,1);
                Xout(n,:,:)=x;
            end
        end
    case 'fillmissing'
        for n=1:size(Xin,1)
            x=squeeze(Xin(n,:,:));
            x=fillmissing(x,'pchip',1,'EndValues','nearest');
            Xout(n,:,:)=x;
        end
end
        
end

%%
function pltnext(sosurce,event) %#ok<INUSD>
uiresume(sosurce.Parent)
end

%%
function endfunc(~,~,hfig) 
close(hfig)
end

%%
function cols=cmap
cols=parula;
end

function B=inpaint_nans(A,method)
% INPAINT_NANS: in-paints over nans in an array
% usage: B=INPAINT_NANS(A)          % default method
% usage: B=INPAINT_NANS(A,method)   % specify method used
%
% Solves approximation to one of several pdes to
% interpolate and extrapolate holes in an array
%
% arguments (input):
%   A - nxm array with some NaNs to be filled in
%
%   method - (OPTIONAL) scalar numeric flag - specifies
%       which approach (or physical metaphor to use
%       for the interpolation.) All methods are capable
%       of extrapolation, some are better than others.
%       There are also speed differences, as well as
%       accuracy differences for smooth surfaces.
%
%       methods {0,1,2} use a simple plate metaphor.
%       method  3 uses a better plate equation,
%                 but may be much slower and uses
%                 more memory.
%       method  4 uses a spring metaphor.
%       method  5 is an 8 neighbor average, with no
%                 rationale behind it compared to the
%                 other methods. I do not recommend
%                 its use.
%
%       method == 0 --> (DEFAULT) see method 1, but
%         this method does not build as large of a
%         linear system in the case of only a few
%         NaNs in a large array.
%         Extrapolation behavior is linear.
%         
%       method == 1 --> simple approach, applies del^2
%         over the entire array, then drops those parts
%         of the array which do not have any contact with
%         NaNs. Uses a least squares approach, but it
%         does not modify known values.
%         In the case of small arrays, this method is
%         quite fast as it does very little extra work.
%         Extrapolation behavior is linear.
%         
%       method == 2 --> uses del^2, but solving a direct
%         linear system of equations for nan elements.
%         This method will be the fastest possible for
%         large systems since it uses the sparsest
%         possible system of equations. Not a least
%         squares approach, so it may be least robust
%         to noise on the boundaries of any holes.
%         This method will also be least able to
%         interpolate accurately for smooth surfaces.
%         Extrapolation behavior is linear.
%
%         Note: method 2 has problems in 1-d, so this
%         method is disabled for vector inputs.
%         
%       method == 3 --+ See method 0, but uses del^4 for
%         the interpolating operator. This may result
%         in more accurate interpolations, at some cost
%         in speed.
%         
%       method == 4 --+ Uses a spring metaphor. Assumes
%         springs (with a nominal length of zero)
%         connect each node with every neighbor
%         (horizontally, vertically and diagonally)
%         Since each node tries to be like its neighbors,
%         extrapolation is as a constant function where
%         this is consistent with the neighboring nodes.
%
%       method == 5 --+ See method 2, but use an average
%         of the 8 nearest neighbors to any element.
%         This method is NOT recommended for use.
%
%
% arguments (output):
%   B - nxm array with NaNs replaced
%
%
% Example:
%  [x,y] = meshgrid(0:.01:1);
%  z0 = exp(x+y);
%  znan = z0;
%  znan(20:50,40:70) = NaN;
%  znan(30:90,5:10) = NaN;
%  znan(70:75,40:90) = NaN;
%
%  z = inpaint_nans(znan);
%
%
% See also: griddata, interp1
%
% Author: John D'Errico
% e-mail address: woodchips@rochester.rr.com
% Release: 2
% Release date: 4/15/06
% I always need to know which elements are NaN,
% and what size the array is for any method
[n,m]=size(A);
A=A(:);
nm=n*m;
k=isnan(A(:));
% list the nodes which are known, and which will
% be interpolated
nan_list=find(k);
known_list=find(~k);
% how many nans overall
nan_count=length(nan_list);
% convert NaN indices to (r,c) form
% nan_list==find(k) are the unrolled (linear) indices
% (row,column) form
[nr,nc]=ind2sub([n,m],nan_list);
% both forms of index in one array:
% column 1 == unrolled index
% column 2 == row index
% column 3 == column index
nan_list=[nan_list,nr,nc];
% supply default method
if (nargin<2) || isempty(method)
  method = 0;
elseif ~ismember(method,0:5)
  error 'If supplied, method must be one of: {0,1,2,3,4,5}.'
end
% for different methods
switch method
 case 0
  % The same as method == 1, except only work on those
  % elements which are NaN, or at least touch a NaN.
  
  % is it 1-d or 2-d?
  if (m == 1) || (n == 1)
    % really a 1-d case
    work_list = nan_list(:,1);
    work_list = unique([work_list;work_list - 1;work_list + 1]);
    work_list(work_list <= 1) = [];
    work_list(work_list >= nm) = [];
    nw = numel(work_list);
    
    u = (1:nw)';
    fda = sparse(repmat(u,1,3),bsxfun(@plus,work_list,-1:1), ...
      repmat([1 -2 1],nw,1),nw,nm);
  else
    % a 2-d case
    
    % horizontal and vertical neighbors only
    talks_to = [-1 0;0 -1;1 0;0 1];
    neighbors_list=identify_neighbors(n,m,nan_list,talks_to);
    
    % list of all nodes we have identified
    all_list=[nan_list;neighbors_list];
    
    % generate sparse array with second partials on row
    % variable for each element in either list, but only
    % for those nodes which have a row index > 1 or < n
    L = find((all_list(:,2) > 1) & (all_list(:,2) < n));
    nl=length(L);
    if nl>0
      fda=sparse(repmat(all_list(L,1),1,3), ...
        repmat(all_list(L,1),1,3)+repmat([-1 0 1],nl,1), ...
        repmat([1 -2 1],nl,1),nm,nm);
    else
      fda=spalloc(n*m,n*m,size(all_list,1)*5);
    end
    
    % 2nd partials on column index
    L = find((all_list(:,3) > 1) & (all_list(:,3) < m));
    nl=length(L);
    if nl>0
      fda=fda+sparse(repmat(all_list(L,1),1,3), ...
        repmat(all_list(L,1),1,3)+repmat([-n 0 n],nl,1), ...
        repmat([1 -2 1],nl,1),nm,nm);
    end
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  k=find(any(fda(:,nan_list(:,1)),2));
  
  % and solve...
  B=A;
  B(nan_list(:,1))=fda(k,nan_list(:,1))\rhs(k);
  
 case 1
  % least squares approach with del^2. Build system
  % for every array element as an unknown, and then
  % eliminate those which are knowns.
  % Build sparse matrix approximating del^2 for
  % every element in A.
  
  % is it 1-d or 2-d?
  if (m == 1) || (n == 1)
    % a 1-d case
    u = (1:(nm-2))';
    fda = sparse(repmat(u,1,3),bsxfun(@plus,u,0:2), ...
      repmat([1 -2 1],nm-2,1),nm-2,nm);
  else
    % a 2-d case
    
    % Compute finite difference for second partials
    % on row variable first
    [i,j]=ndgrid(2:(n-1),1:m);
    ind=i(:)+(j(:)-1)*n;
    np=(n-2)*m;
    fda=sparse(repmat(ind,1,3),[ind-1,ind,ind+1], ...
      repmat([1 -2 1],np,1),n*m,n*m);
    
    % now second partials on column variable
    [i,j]=ndgrid(1:n,2:(m-1));
    ind=i(:)+(j(:)-1)*n;
    np=n*(m-2);
    fda=fda+sparse(repmat(ind,1,3),[ind-n,ind,ind+n], ...
      repmat([1 -2 1],np,1),nm,nm);
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  k=find(any(fda(:,nan_list),2));
  
  % and solve...
  B=A;
  B(nan_list(:,1))=fda(k,nan_list(:,1))\rhs(k);
  
 case 2
  % Direct solve for del^2 BVP across holes
  % generate sparse array with second partials on row
  % variable for each nan element, only for those nodes
  % which have a row index > 1 or < n
  
  % is it 1-d or 2-d?
  if (m == 1) || (n == 1)
    % really just a 1-d case
    error('Method 2 has problems for vector input. Please use another method.')
    
  else
    % a 2-d case
    L = find((nan_list(:,2) > 1) & (nan_list(:,2) < n));
    nl=length(L);
    if nl>0
      fda=sparse(repmat(nan_list(L,1),1,3), ...
        repmat(nan_list(L,1),1,3)+repmat([-1 0 1],nl,1), ...
        repmat([1 -2 1],nl,1),n*m,n*m);
    else
      fda=spalloc(n*m,n*m,size(nan_list,1)*5);
    end
    
    % 2nd partials on column index
    L = find((nan_list(:,3) > 1) & (nan_list(:,3) < m));
    nl=length(L);
    if nl>0
      fda=fda+sparse(repmat(nan_list(L,1),1,3), ...
        repmat(nan_list(L,1),1,3)+repmat([-n 0 n],nl,1), ...
        repmat([1 -2 1],nl,1),n*m,n*m);
    end
    
    % fix boundary conditions at extreme corners
    % of the array in case there were nans there
    if ismember(1,nan_list(:,1))
      fda(1,[1 2 n+1])=[-2 1 1];
    end
    if ismember(n,nan_list(:,1))
      fda(n,[n, n-1,n+n])=[-2 1 1];
    end
    if ismember(nm-n+1,nan_list(:,1))
      fda(nm-n+1,[nm-n+1,nm-n+2,nm-n])=[-2 1 1];
    end
    if ismember(nm,nan_list(:,1))
      fda(nm,[nm,nm-1,nm-n])=[-2 1 1];
    end
    
    % eliminate knowns
    rhs=-fda(:,known_list)*A(known_list);
    
    % and solve...
    B=A;
    k=nan_list(:,1);
    B(k)=fda(k,k)\rhs(k);
    
  end
  
 case 3
  % The same as method == 0, except uses del^4 as the
  % interpolating operator.
  
  % del^4 template of neighbors
  talks_to = [-2 0;-1 -1;-1 0;-1 1;0 -2;0 -1; ...
      0 1;0 2;1 -1;1 0;1 1;2 0];
  neighbors_list=identify_neighbors(n,m,nan_list,talks_to);
  
  % list of all nodes we have identified
  all_list=[nan_list;neighbors_list];
  
  % generate sparse array with del^4, but only
  % for those nodes which have a row & column index
  % >= 3 or <= n-2
  L = find( (all_list(:,2) >= 3) & ...
            (all_list(:,2) <= (n-2)) & ...
            (all_list(:,3) >= 3) & ...
            (all_list(:,3) <= (m-2)));
  nl=length(L);
  if nl>0
    % do the entire template at once
    fda=sparse(repmat(all_list(L,1),1,13), ...
        repmat(all_list(L,1),1,13) + ...
        repmat([-2*n,-n-1,-n,-n+1,-2,-1,0,1,2,n-1,n,n+1,2*n],nl,1), ...
        repmat([1 2 -8 2 1 -8 20 -8 1 2 -8 2 1],nl,1),nm,nm);
  else
    fda=spalloc(n*m,n*m,size(all_list,1)*5);
  end
  
  % on the boundaries, reduce the order around the edges
  L = find((((all_list(:,2) == 2) | ...
             (all_list(:,2) == (n-1))) & ...
            (all_list(:,3) >= 2) & ...
            (all_list(:,3) <= (m-1))) | ...
           (((all_list(:,3) == 2) | ...
             (all_list(:,3) == (m-1))) & ...
            (all_list(:,2) >= 2) & ...
            (all_list(:,2) <= (n-1))));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(all_list(L,1),1,5), ...
      repmat(all_list(L,1),1,5) + ...
        repmat([-n,-1,0,+1,n],nl,1), ...
      repmat([1 1 -4 1 1],nl,1),nm,nm);
  end
  
  L = find( ((all_list(:,2) == 1) | ...
             (all_list(:,2) == n)) & ...
            (all_list(:,3) >= 2) & ...
            (all_list(:,3) <= (m-1)));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(all_list(L,1),1,3), ...
      repmat(all_list(L,1),1,3) + ...
        repmat([-n,0,n],nl,1), ...
      repmat([1 -2 1],nl,1),nm,nm);
  end
  
  L = find( ((all_list(:,3) == 1) | ...
             (all_list(:,3) == m)) & ...
            (all_list(:,2) >= 2) & ...
            (all_list(:,2) <= (n-1)));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(all_list(L,1),1,3), ...
      repmat(all_list(L,1),1,3) + ...
        repmat([-1,0,1],nl,1), ...
      repmat([1 -2 1],nl,1),nm,nm);
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  k=find(any(fda(:,nan_list(:,1)),2));
  
  % and solve...
  B=A;
  B(nan_list(:,1))=fda(k,nan_list(:,1))\rhs(k);
  
 case 4
  % Spring analogy
  % interpolating operator.
  
  % list of all springs between a node and a horizontal
  % or vertical neighbor
  hv_list=[-1 -1 0;1 1 0;-n 0 -1;n 0 1];
  hv_springs=[];
  for i=1:4
    hvs=nan_list+repmat(hv_list(i,:),nan_count,1);
    k=(hvs(:,2)>=1) & (hvs(:,2)<=n) & (hvs(:,3)>=1) & (hvs(:,3)<=m);
    hv_springs=[hv_springs;[nan_list(k,1),hvs(k,1)]];
  end
  % delete replicate springs
  hv_springs=unique(sort(hv_springs,2),'rows');
  
  % build sparse matrix of connections, springs
  % connecting diagonal neighbors are weaker than
  % the horizontal and vertical springs
  nhv=size(hv_springs,1);
  springs=sparse(repmat((1:nhv)',1,2),hv_springs, ...
     repmat([1 -1],nhv,1),nhv,nm);
  
  % eliminate knowns
  rhs=-springs(:,known_list)*A(known_list);
  
  % and solve...
  B=A;
  B(nan_list(:,1))=springs(:,nan_list(:,1))\rhs;
  
 case 5
  % Average of 8 nearest neighbors
  
  % generate sparse array to average 8 nearest neighbors
  % for each nan element, be careful around edges
  fda=spalloc(n*m,n*m,size(nan_list,1)*9);
  
  % -1,-1
  L = find((nan_list(:,2) > 1) & (nan_list(:,3) > 1)); 
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-n-1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  
  % 0,-1
  L = find(nan_list(:,3) > 1);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-n, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % +1,-1
  L = find((nan_list(:,2) < n) & (nan_list(:,3) > 1));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-n+1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % -1,0
  L = find(nan_list(:,2) > 1);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([-1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % +1,0
  L = find(nan_list(:,2) < n);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % -1,+1
  L = find((nan_list(:,2) > 1) & (nan_list(:,3) < m)); 
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([n-1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  
  % 0,+1
  L = find(nan_list(:,3) < m);
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([n, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  % +1,+1
  L = find((nan_list(:,2) < n) & (nan_list(:,3) < m));
  nl=length(L);
  if nl>0
    fda=fda+sparse(repmat(nan_list(L,1),1,2), ...
      repmat(nan_list(L,1),1,2)+repmat([n+1, 0],nl,1), ...
      repmat([1 -1],nl,1),n*m,n*m);
  end
  
  % eliminate knowns
  rhs=-fda(:,known_list)*A(known_list);
  
  % and solve...
  B=A;
  k=nan_list(:,1);
  B(k)=fda(k,k)\rhs(k);
  
end
% all done, make sure that B is the same shape as
% A was when we came in.
B=reshape(B,n,m);
% ====================================================
%      end of main function
% ====================================================
end
% ====================================================
%      begin subfunctions
% ====================================================
function neighbors_list=identify_neighbors(n,m,nan_list,talks_to)
% identify_neighbors: identifies all the neighbors of
%   those nodes in nan_list, not including the nans
%   themselves
%
% arguments (input):
%  n,m - scalar - [n,m]=size(A), where A is the
%      array to be interpolated
%  nan_list - array - list of every nan element in A
%      nan_list(i,1) == linear index of i'th nan element
%      nan_list(i,2) == row index of i'th nan element
%      nan_list(i,3) == column index of i'th nan element
%  talks_to - px2 array - defines which nodes communicate
%      with each other, i.e., which nodes are neighbors.
%
%      talks_to(i,1) - defines the offset in the row
%                      dimension of a neighbor
%      talks_to(i,2) - defines the offset in the column
%                      dimension of a neighbor
%      
%      For example, talks_to = [-1 0;0 -1;1 0;0 1]
%      means that each node talks only to its immediate
%      neighbors horizontally and vertically.
% 
% arguments(output):
%  neighbors_list - array - list of all neighbors of
%      all the nodes in nan_list
if ~isempty(nan_list)
  % use the definition of a neighbor in talks_to
  nan_count=size(nan_list,1);
  talk_count=size(talks_to,1);
  
  nn=zeros(nan_count*talk_count,2);
  j=[1,nan_count];
  for i=1:talk_count
    nn(j(1):j(2),:)=nan_list(:,2:3) + ...
        repmat(talks_to(i,:),nan_count,1);
    j=j+nan_count;
  end
  
  % drop those nodes which fall outside the bounds of the
  % original array
  L = (nn(:,1)<1)|(nn(:,1)>n)|(nn(:,2)<1)|(nn(:,2)>m); 
  nn(L,:)=[];
  
  % form the same format 3 column array as nan_list
  neighbors_list=[sub2ind([n,m],nn(:,1),nn(:,2)),nn];
  
  % delete replicates in the neighbors list
  neighbors_list=unique(neighbors_list,'rows');
  
  % and delete those which are also in the list of NaNs.
  neighbors_list=setdiff(neighbors_list,nan_list,'rows');
  
else
  neighbors_list=[];
end

end

function dataValidation(input)
input_class=class(input);
switch input_class
    case "drEEMdataset"
        try
            drEEMdataset.validate(input)
            drEEMdataset.sanityCheckScatter(input)
            drEEMdataset.mustContainSamples(input)
        catch ME
            throwAsCaller(ME)
        end
    case {'string','char'}
        if not(matches(input,'options'))
            mess='Retreive options by supplying the string <strong>"options"</strong> to the function';
            throwAsCaller(MException("drEEM:IncorrectInput",mess))
        end
    otherwise
        mess='Must be an object of type <strong>drEEMdataset</strong> or the string </strong>"options"</strong>.';
        throwAsCaller(MException("drEEM:IncorrectInput",mess))
end

end


function optionValidation(data,input)
input_class=class(input);

switch input_class
    case "handlescatterOptions"
        handlescatterOptions.validate(data,input)
    case {'string','char'}
        if not(matches(input,'gui'))
            mess='Use the GUI tool to handle scatter by supplying <strong>"gui"</strong> as the second input';
            throwAsCaller(MException("drEEM:IncorrectInput",mess))
        end
    otherwise
        mess='Must be an object of type <strong>handlescatterOptions</strong> or the string <strong>"gui"</strong>).';
        throwAsCaller(MException("drEEM:IncorrectInput",mess))
end
end