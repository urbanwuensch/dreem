
% Assume your dataset is called "samples"
C=5;
model=samples.models(C);
plot_it=true;
nContours=10;
colmap='turbo';
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