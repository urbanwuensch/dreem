%% Script that let's users manually export & plot component fingerprints
% This script was made in April 2026 based on a user inquiry about
% exporting PARAFAC componenent spectra as matrices to csv. At the same
% time, this script also let's users plot the fingerprints.



% Variables to modify script behavior
% Script assumes your dataset is called "samples"
C=5; % number of components
plot_it=true; % True to plot, false to skip plotting
nContours=10; % Number of black contour lines 
% (100 lineless contours will always be plotted)
colmap='turbo'; % Change colormap (doc colormap for options)



% Script begins here.
model=samples.models(C); % extracting the model
if plot_it
    f=drEEMtoolbox.dreemfig;
    t=tiledlayout('flow', ... % Change this for different layout
        'TileSpacing','compact','Padding','tight');
end
export_them=false;
for j=1:C
    exload_here=model.loads{3}(:,j);
    emload_here=model.loads{2}(:,j);

    eem_mat=emload_here*exload_here';
    if export_them
        mat=eem_mat;
        mat=[samples.Ex';mat];
        mat=[[nan;samples.Em],mat];
        writematrix(mat,['C',num2str(j),'.csv'])
    end
    if plot_it
       ax=nexttile(t);
       contourf(ax,samples.Ex,samples.Em,eem_mat, ...
           100,LineStyle='none');
       hold(ax,'on')
       contour(ax,samples.Ex,samples.Em,eem_mat, ...
           nContours,color='k');
       colormap(ax,colmap)

    end
    title(['C',num2str(j)])
end
if plot_it
    xlabel(t,'Excitation (nm)')
    ylabel(t,'Emission (nm)')
end