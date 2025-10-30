function model = parafac3w(X,F,options)
timer=tic;
bg=0;

% SETTINGS
optionsDEF.ConvCrit = 1e-6;
optionsDEF.LSeveryIt = 5;
optionsDEF.MaxIt    = 3000;
optionsDEF.UpdateMiss = 7; % update missing data each xx iteration
optionsDEF.OldOrNew = 1;
optionsDEF.LineSe = 3; % When to do linesearch
optionsDEF.init = 4; % 1 means random numbers, 5 means five small runs
optionsDEF.orderby2=false; % true will order factors by max in second mode
if nargin<3
    options = optionsDEF;           LSeveryIt = optionsDEF.LSeveryIt;
    ConvCrit    = options.ConvCrit;
    MaxIt       = options.MaxIt;    UpdateMiss  = options.UpdateMiss;
    OldOrNew    = options.OldOrNew; init        = options.init;
    LineSe      = optionsDEF.LineSe;
else
    try
        ConvCrit    = options.ConvCrit;
    catch
        ConvCrit    = optionsDEF.ConvCrit;
    end
    try 
        LSeveryIt = options.LSeveryIt;
    catch
        LSeveryIt = optionsDEF.LSeveryIt;
    end
    try
        MaxIt       = options.MaxIt;
    catch
        MaxIt       = optionsDEF.MaxIt;
    end
    try
        UpdateMiss  = options.UpdateMiss;
    catch
        UpdateMiss  = optionsDEF.UpdateMiss;
    end
    try
        OldOrNew    = options.OldOrNew;
    catch
        OldOrNew    = optionsDEF.OldOrNew;
    end
    try
        init        = options.init;
    catch
        init        = optionsDEF.init;
    end
    try
        LineSe      = options.LineSe;
    catch
        LineSe      = optionsDEF.LineSe;
    end
end

[I J K] = size(X);



if init==1
    A = (rand(I,F));
    B = (rand(J,F));
    C = (rand(K,F));
elseif init>1
    op2 = options;
    op2.init = 1;
    op2.MaxIt = 15;
    s=[];
    for i=1:init
        mod{i} = parafac3w(X,F,op2);
        s=[s mod{i}.Fit];
    end
    [a,b]=sort(s);
    A = mod{b(1)}.A;
    B = mod{b(1)}.B;
    C = mod{b(1)}.C;
end

% Missing data
Xorig = X;
if any(isnan(X(:)))
    mis = 1;
    for j=1:size(X,1)
        X(j,:,:)=inpaint_nans(squeeze(X(j,:,:)),4);
    end
else
    mis = 0;
end

%NWAY
acc=-5;
acc_pow=5;  % Extrapolate to the iteration^(1/acc_pow) ahead
acc_fail=0; % Indicate how many times acceleration have failed
max_fail=4; % Increase acc_pow with one after max_fail failure
if bg
    disp(' Extrapolation acceleration scheme initialized')
end
%NESTEROV
gamma = 1.1;
gammah = 1.03;
ny = 1.5;
beta = 3;
betah = 1;



% Calculate fit
XA = tensorprod(X,A,1,1);
for f=1:F
    XAB(:,f)= XA(:,:,f)'*B(:,f);
end
SSX = squeeze(sum(sum(X.^2,1),2)); % for fast calculation of fit
fit = fitcal(X,A,B,C,SSX,XAB,K,OldOrNew);
oldfit = fit*2;
Fi=[];


%% ALS PART

% disp('PRELIMINARY')
% disp(' ')
% disp(['A ',num2str(F),'-component model will be fitted'])

it=0;
while it<MaxIt & abs((fit-oldfit)/oldfit)>ConvCrit
    it = it+1;
    acc=acc+1;

    % Line-search
    if rem(it,LSeveryIt)==0
        if ~(rem(it,UpdateMiss) == 0) % DOn't do it when missing data are being updated
        if LineSe==1
            acc=0;
            pw = (it^(1/acc_pow));
            An=A+(A-Aold)*pw;
            Bn=B+(B-Bold)*pw;
            Cn=C+(C-Cold)*pw;
            fitn = fitcal(X,An,Bn,Cn,SSX,XAB,K,OldOrNew);
            if fitn>fit
                acc_fail=acc_fail+1;
                if acc_fail==max_fail
                    acc_pow=acc_pow+1+1;
                    acc_fail=0;
                    if bg
                        disp(' Reducing acceleration');
                    end
                end
            else
                A = An;
                B = Bn;
                C = Cn;
                if bg
                    disp('Eviva')
                end
            end
        elseif LineSe == 2
            acc=0;
            %            beta = 10
            An=A+(A-Aold)*beta;
            Bn=B+(B-Bold)*beta;
            Cn=C+(C-Cold)*beta;
            fitn = fitcal(X,An,Bn,Cn,SSX,XAB,K,OldOrNew);
            if fitn<fit
                beta = min(betah,gamma*beta);
                betah = min(1,gammah*betah);
                A = An;
                B = Bn;
                C = Cn;
            else
                beta= beta/ny;
                betah = beta;
            end
        elseif LineSe == 3
            acc=0;
            %            beta = 10
            An=A+(A-Aold)*beta;
            Bn=B+(B-Bold)*beta;
            Cn=C+(C-Cold)*beta;
            fitn = fitcal(X,An,Bn,Cn,SSX,XAB,K,OldOrNew);
            if fitn<fit
                beta = max(betah,gamma*beta);
                betah = min(1,gammah*betah);
                A = An;
                B = Bn;
                C = Cn;
            else
                beta= beta/ny;
                betah = beta;
            end
        elseif LineSe == 4
            acc=0;
            beta = 5;
            An=A+(A-Aold)*beta;
            Bn=B+(B-Bold)*beta;
            Cn=C+(C-Cold)*beta;
            fitn = fitcal(X,An,Bn,Cn,SSX,XAB,K,OldOrNew);
            if fitn>fit
                
            else
                A = An;
                B = Bn;
                C = Cn;
                
            end
        end
        end
    end

    Aold = A;
    if OldOrNew~=1
        XBC = X(:,:)*kr(C,B);
    else
        XB = tensorprod(X,B,2,1);
        for f=1:F
            XBC(:,f)= XB(:,:,f)*C(:,f);
        end
    end
    BC = (B'*B).*(C'*C);
    if OldOrNew~=1
        for i=1:I
            A(i,:)=fastnnls(BC,XBC(i,:)')';
        end
    else
        A = fcnnls([],[],BC,XBC')';
    end
    if any(sum(A)<100*eps*I)
        A = .99*Aold+.01*A; % To prevent a matrix with zero columns
        if bg
            disp(['A wrong ',num2str(it)])
        end
    end
    if bg
        disp('A')
        fprintf(' %12.10f \n',fitcal(X,A,B,C,SSX,XAB,K,OldOrNew));
    end

    Bold = B;
    if OldOrNew~=1
        Xb = permute(X,[2 1 3]);
        XAC = Xb(:,:)*kr(C,A);
    else
        XA = tensorprod(X,A,1,1);
        for f=1:F
            XAC(:,f)= XA(:,:,f)*C(:,f);
        end
    end
    AC = (A'*A).*(C'*C);
    if OldOrNew~=1
        for j=1:J
            B(j,:)=fastnnls(AC,XAC(j,:)')';
        end
    else
        B = fcnnls([],[],AC,XAC')';
    end
    if any(sum(B)<100*eps*J)
        B = .99*Bold+.01*B; % To prevent a matrix with zero columns
        if bg
            disp(['B wrong ',num2str(it)])
        end
    end
    B = B*diag(sum(B.^2).^(-.5));
    if bg
        disp('B')
        fprintf(' %12.10f \n',fitcal(X,A,B,C,SSX,XAB,K,OldOrNew));
    end

    Cold = C;
    if OldOrNew~=1
        Xc = permute(X,[3 1 2]);
        XAB = Xc(:,:)*kr(B,A);
    else
        XA = tensorprod(X,A,1,1);
        for f=1:F
            XAB(:,f)= XA(:,:,f)'*B(:,f);
        end
    end
    AB = (B'*B).*(A'*A);
    if OldOrNew~=1
        for k=1:K
            C(k,:)=fastnnls(AB,XAB(k,:)')';
        end
    else
        C = fcnnls([],[],AB,XAB')';
    end
    if any(sum(C)<100*eps*K)
        C = .99*Cold+.01*C; % To prevent a matrix with zero columns
        if bg
            disp(['C wrong ',num2str(it)])
        end
    end
    if bg
        disp('C')
        fprintf(' %12.10f \n',fitcal(X,A,B,C,SSX,XAB,K,OldOrNew));
    end
    C = C*diag(sum(C.^2).^(-.5));

    oldfit = fit;
    fit = fitcal(X,A,B,C,SSX,XAB,K,OldOrNew);
    Fi = [Fi fit];
    %Fi=[Fi;[fitcal(X,A,B,C,SSX,XAB,K,1) fitcal(X,A,B,C,SSX,XAB,K,0)]];
    if rem(it,1)==-1
        disp(['Convergence ',num2str(fit),' after ',num2str(it),' iterations'])
        %if bg
        if 7==7
            subplot(3,3,1),plot(A)
            subplot(3,3,2),plot(B)
            subplot(3,3,3),plot(C)
            for i=1:5 
                subplot(3,3,i+3)
                mesh(squeeze(X(i,:,:)))
            end
            shg
        end
    end


    if mis % impute if there are missing values
        % but not too often
        if rem(it,UpdateMiss) == 0; % Only every UpdateMissth time
            for k=1:K
                Xk = Xorig(:,:,k);
                id = isnan(Xk);
                if any(id(:))
                    Mk = A*diag(C(k,:))*B';
                    Xk(id)=Mk(id);
                    X(:,:,k) = Xk;
                end
            end
            SSX = squeeze(sum(sum(X.^2,1),2)); % for fast calculation of fit
        end
    end


end
%disp(['The algorithm converged ',num2str(fit),' after ',num2str(it),' iterations'])
tela=toc(timer);

if optionsDEF.orderby2
    for j=1:size(B,2)
        [~,i(j)]=max(B(:,j));
    end
    [~,idx]=sort(i);
    A=A(:,idx);
    B=B(:,idx);
    C=C(:,idx);
end

model.A = A;
model.B = B;
model.C = C;
model.Fit = fit;
model.allfits = Fi;
model.tela=tela;
model.it=it;



function [K, Pset] = fcnnls(C, A, CtC, CtA)
% NNLS using normal equations and the fast combinatorial strategy
%
% I/O: [K, Pset] = fcnnls(C, A);
% K = fcnnls(C, A);
%
% C is the nObs x lVar coefficient matrix
% A is the nObs x pRHS matrix of observations
% K is the lVar x pRHS solution matrix
% Pset is the lVar x pRHS passive set logical array
%
% Pset: set of passive sets, one for each column
% Fset: set of column indices for solutions that have not yet converged
% Hset: set of column indices for currently infeasible solutions
% Jset: working set of column indices for currently optimal solutions
%
% Implementation is based on [1] with bugfixes, direct passing of sufficient stats,
% and preserving the active set over function calls.
%
% [1] Van Benthem, M. H., & Keenan, M. R. (2004). Fast algorithm for the
%   solution of large‐scale non‐negativity‐constrained least squares problems.
%   Journal of Chemometrics: A Journal of the Chemometrics Society, 18(10), 441-450.


% Check the input arguments for consistency and initialize
if nargin == 2
    error(nargchk(2,2,nargin))
    [nObs, lVar] = size(C);

    if size(A,1)~= nObs, error('C and A have imcompatible sizes'), end
    if size(C,1) == size(C,2)
        %         warning('A square matrix "C" was input, ensure this is on purpose.')
    end
    pRHS = size(A,2);
    % Precompute parts of pseudoinverse
    CtC = C'*C; CtA = C'*A;
else
    [lVar,pRHS] = size(CtA);

end


W = zeros(lVar, pRHS);
iter = 0;
maxiter = 6*lVar;


% Obtain the initial feasible solution and corresponding passive set
K = cssls(CtC, CtA);
Pset=K>0;
K(~Pset) = 0;
D=K;
Fset = find(~all(Pset));

% Active set algorithm for NNLS main loop
iter_outer = 1;
while ~isempty(Fset) && iter_outer < maxiter
    iter_outer = iter_outer + 1;
    % Solve for the passive variables (uses subroutine below)
    K(:,Fset) = cssls(CtC, CtA(:,Fset), Pset(:,Fset));
    % Find any infeasible solutions
    %     Hset = Fset(find(any(K(:,Fset) < 0)));
    Hset = Fset((any(K(:,Fset) < 0)));

    % Make infeasible solutions feasible (standard NNLS inner loop)
    if ~isempty(Hset)
        nHset = length(Hset);
        alpha = zeros(lVar, nHset);

        while ~isempty(Hset) && (iter < maxiter)
            iter = iter + 1;
            alpha(:,1:nHset) = Inf;
            % Find indices of negative variables in passive set
            [i, j] = find(Pset(:,Hset) & (K(:,Hset) < 0));
            hIdx = sub2ind([lVar nHset], i, j);
            %             if length(i) ~= length(j)
            %                 keyboard
            %             end
            %             negIdx = sub2ind(size(K), i, Hset(j)'); % org
            negIdx = sub2ind(size(K), i, reshape(Hset(j),size(i)));  % jlh mod
            alpha(hIdx) = D(negIdx)./(D(negIdx) - K(negIdx));
            [alphaMin,minIdx] = min(alpha(:,1:nHset));
            alpha(:,1:nHset) = repmat(alphaMin, lVar, 1);
            D(:,Hset) = D(:,Hset)-alpha(:,1:nHset).*(D(:,Hset)-K(:,Hset));
            idx2zero = sub2ind(size(D), minIdx, Hset);
            D(idx2zero) = 0;
            Pset(idx2zero) = 0;
            K(:, Hset) = cssls(CtC, CtA(:,Hset), Pset(:,Hset));
            Hset = find(any(K < 0));
            nHset = length(Hset);
        end
    end
    % Make sure the solution has converged
    %if iter == maxiter, warning('Maximum number iterations exceeded'), end
    % Check solutions for optimality
    W(:,Fset) = CtA(:,Fset)-CtC*K(:,Fset);
    Jset = find(all(~Pset(:,Fset).*W(:,Fset) <= 0));
    Fset = setdiff(Fset, Fset(Jset));
    % For non-optimal solutions, add the appropriate variable to Pset
    if ~isempty(Fset)
        [mx, mxidx] = max(~Pset(:,Fset).*W(:,Fset));
        Pset(sub2ind([lVar pRHS], mxidx, Fset)) = 1;
        D(:,Fset) = K(:,Fset);
    end
end

% ****************************** Subroutine****************************
function [K] = cssls(CtC, CtA, Pset)
% Solve the set of equations CtA = CtC*K for the variables in set Pset
% using the fast combinatorial approach
K = zeros(size(CtA));
if (nargin == 2) || isempty(Pset) || all(Pset(:))
    K = CtC\CtA; % Not advisable if matrix is close to singular or badly scaled
    %     K = pinv(CtC)*CtA;
else
    [lVar, pRHS] = size(Pset);
    codedPset = 2.^(lVar-1:-1:0)*Pset;
    [sortedPset, sortedEset] = sort(codedPset);
    breaks = diff(sortedPset);
    breakIdx = [0 find(breaks) pRHS];
    for k = 1:length(breakIdx)-1
        cols2solve = sortedEset(breakIdx(k)+1:breakIdx(k+1));
        vars = Pset(:,sortedEset(breakIdx(k)+1));
        K(vars,cols2solve) = CtC(vars,vars)\CtA(vars,cols2solve);
        %         K(vars,cols2solve) = pinv(CtC(vars,vars))*CtA(vars,cols2solve);
    end
end


function fit = fitcal(X,A,B,C,SSX,XAB,K,OldOrNew)
fit = 0;

if OldOrNew~=1
    for k=1:K
        fit = fit+sum(sum((X(:,:,k)-A*diag(C(k,:))*B').^2));
    end
else
    MtM = (A'*A).*(B'*B).*(C'*C);
    fit =sum(SSX)+sum(MtM(:))-2*trace(C'*XAB);
end


function [x,w] = fastnnls(XtX,Xty,tol)
%NNLS	Non-negative least-squares.
%	b = fastnnls(XtX,Xty) returns the vector b that solves X*b = y
%	in a least squares sense, subject to b >= 0, given the inputs
%       XtX = X'*X and Xty = X'*y.
%
%	A default tolerance of TOL = MAX(SIZE(X)) * NORM(X,1) * EPS
%	is used for deciding when elements of b are less than zero.
%	This can be overridden with b = fastnnls(X,y,TOL).
%
%	[b,w] = fastnnls(XtX,Xty) also returns dual vector w where
%	w(i) < 0 where b(i) = 0 and w(i) = 0 where b(i) > 0.
%
%
%	L. Shure 5-8-87 Copyright (c) 1984-94 by The MathWorks, Inc.
%
%  Revised by:
%	Copyright
%	Rasmus Bro 1995
%	Denmark
%	E-mail rb@kvl.dk
%  According to Bro & de Jong, J. Chemom, 1997, 11, 393-401

% initialize variables


if nargin < 3
    tol = 10*eps*norm(XtX,1)*max(size(XtX));
end
[m,n] = size(XtX);
P = zeros(1,n);
Z = 1:n;
x = P';
ZZ=Z;
w = Xty-XtX*x;

% set up iteration criterion
iter = 0;
itmax = 30*n;

% outer loop to put variables into set to hold positive coefficients
while any(Z) & any(w(ZZ) > tol)
    [wt,t] = max(w(ZZ));
    t = ZZ(t);
    P(1,t) = t;
    Z(t) = 0;
    PP = find(P);
    ZZ = find(Z);
    nzz = size(ZZ);
    z(PP')=(Xty(PP)'/XtX(PP,PP)');
    z(ZZ) = zeros(nzz(2),nzz(1))';
    z=z(:);
    % inner loop to remove elements from the positive set which no longer belong

    while any((z(PP) <= tol)) & iter < itmax

        iter = iter + 1;
        QQ = find((z <= tol) & P');
        alpha = min(x(QQ)./(x(QQ) - z(QQ)));
        x = x + alpha*(z - x);
        ij = find(abs(x) < tol & P' ~= 0);
        Z(ij)=ij';
        P(ij)=zeros(1,max(size(ij)));
        PP = find(P);
        ZZ = find(Z);
        nzz = size(ZZ);
        z(PP)=(Xty(PP)'/XtX(PP,PP)');
        z(ZZ) = zeros(nzz(2),nzz(1));
        z=z(:);
    end
    x = z;
    w = Xty-XtX*x;
end

x=x(:);


function AB = kr(A,B)
%KR Khatri-Rao product

[I,F]=size(A);
[J,F1]=size(B);

if F~=F1
   error(' Error in kr.m - The matrices must have the same number of columns')
end

AB=zeros(I*J,F);
for f=1:F
   ab=B(:,f)*A(:,f).';
   AB(:,f)=ab(:);
end