% This is a demo for a source-analysis toolbox;
% you need names your EEG-electrodes and some functional
% result like a potential at a time point, a CSP-pattern, 
% a cross-spectrum, etc. 
%
% you can 
% 1. view field and cross-spectra;
% 2. make a forward calculation
% 3. make inverse calculations (dipole fits,MUSIC, SMusic (see below))
% 4. view sources on MRI-data and cortex;

% All programs are actually executed in this demo
% apart from fitting N dipoles to a cross-spectrum. 
% That is commented out because it might take some minutes.  

% first we load a list of the names of EEG-channel 
% we had in a given experiment. Your list may ONLY contain 
% EEG channels (not EOG channels or others). Your list 
% must be a subset of the example below.   
load clab_example;

% Preparation of a structre which contains 
% all necessary information apart from functional 
% data. (The latter is the result of your specifc 
% measurement.)  
sa=prepare_sourceanalysis(clab_example);

% now we need some function data;
load cs_example; % this a cross-spectrum at 10 Hz
[u s v]=svd(real(cs_example));field=u(:,2); % construct an example field for demo

% now we can start

% show a field
figure;showfield_general(field,sa.locs_2D); 

%show e.g. the imaginary part of the cross-spectrum
figure; plot_coherence(imag(cs_example),sa.locs_2D);





% plot cortex
figure;show_vc_tri(sa.cortex);


% plot 4 random dipoles plus cortex;
dips=3*randn(4,3)+[zeros(4,2),5*ones(4,1)]; %random locations 
dips=[dips,randn(4,3)]; %locations plus random moments; 
figure;show_vc_tri(sa.cortex,dips); %plot all dipoles with unit moment; 
% here are some modifications:
clear para
para.myviewdir=[0 0 1]; % changes the viewpoint 
para.normalize=0; % without normalization of dipoles 
figure;show_vc_tri(sa.cortex,dips,para);


% make a forward calculation 
dips=[0 3 8 0 0 1]; % defines dipole, location is [0 3 8] in cm
                    % and moment is [0 0 1] nAm. 
v=forward_general(dips,sa.fp); %makes potential v for that dipole 
                               % dips can also be a Mx6 matrix 
                               % then v is a NxM matrix for N channels 
                               % and the ith. column is the  potential
                               % for the i.th dipole, i.e. the i.th 
			       %  row in dips   

%lets look the calculated potential 
figure;showfield_general(v,sa.locs_2D); 



% now we make dipole fits:
% dipoles are always with random initial guess!! 
% One should make a couple of runs to avoid local minima!!
% make a 1-dipole for one the above potential.  
ndip=1; %select number of dipoles 
[a,res_out,k,field_theo]=dipole_fit(v,sa.fp,ndip); %make the fit 
% a is the estimated dipole solution (each row defines one dipole
% as in dips) res_out is the relative error, k is the number of 
% iterations, and field_theo is the potential of the found 
% dipoles. (Of course, you can calculate field_theo also as   
% field_theo=forward_general(a,sa.fp) if a is just one dipole.)

% you can fit a dipole model to a cross-spectrum; 
ndip=2; %two dipoles
xtype='imag'; %we only fit the imaginary part;
%Now comes the fit. This is commented out because it might take some minutes
%[dips_out,c_source,res_out,c_theo]=lm_comp_general(cs_example,sa.fp,ndip,xtype);
% dips_out are the estimated dipoles; c_source is source-cross-spectrum; res_out is error;
% c_theo is the cross-spectrum of the model; 


% Plot the MRI without sources: 
figure;showmri(sa.mri);

% Here is an example how to change orientation
para.orientation='axial'; %orientations can be sagittal (default),axial, or coronal
figure;showmri(sa.mri,para);

% Here is how to show dipoles in the MRI
figure;showmri(sa.mri,[],dips); %the second argument is empty, i.e. use defaults 

% Here is how to show a set of points in the MRI; in this case
% we show a grid of points
figure;showmri(sa.mri,[],sa.grid_fine);

% next we load another example for functional data. 
% The final output, vv, is an Nx2 matrix consisting 
% of two potential, and the assumption is that 
% the potential of true dipoles is within the 
% span of vv. Here, vv is constrcuted from ISA, but 
% it could also be, e.g., the  first two eigenvectors 
% of a PCA analysis. It can also consist of 
% just one or more than 2 potentials. 
load pats;va=real(vi(:,10));vb=imag(vi(:,10));vv=[va,vb];

% now we calculate the inverse using the Music-algorithm
% the variable s an indicator of how well a dipole at the 
%  i.th locations fits with the model assumption.
% s can have several columns. The first column 
% indicates indicates the quality of the best dipole;
% the second the 'quality' of the best which is orthogonal
% to the first, etc. 
[s,vmax,imax,dip_mom,dip_loc]=Music(vv,sa.V_fine,sa.grid_fine);
% s indicates fit-quality, vmax the field of the best dipole;
% imax its grid_index;dip_mom the dipole moment (normalized);
% and dip_loc the location 


% now we calculate a ngx4 matrix (ng is number of grid-points);
% the first three columns are the locations of the grid-poinnts;
% and the 4th column is the value (i.e. quality of fit - the higher the
% better)
grid_fine_val=[sa.grid_fine,1./(sqrt(1-s(:,1).^2))];
figure;showmri(sa.mri,[],grid_fine_val);


% Here comes a new approach called SMusic (selfconsistent Music)
% first we prepare a demo-case
dips=[[3 0 8 0 0 1];[-3 0 8 0 0 1]]; %define two dipoles
v=forward_general(dips,sa.fp); % calculate the fields;
vv=v*[[1 1 ];[1 -1]]; %mix the the fields
% now SMusic calculates two distributions; each representing one source:
[s,vmax,imax,dip_mom,dip_loc]=SMusic_v1(vv,sa.V_fine,sa.grid_fine);
grid_fine_val=[sa.grid_fine,1./(sqrt(1-s(:,1).^2))]; % s(:,1) is the 'distribution of first source
figure;showmri(sa.mri,[],grid_fine_val);
grid_fine_val=[sa.grid_fine,1./(sqrt(1-s(:,2).^2))]; % s(:,2) from second source
figure;showmri(sa.mri,[],grid_fine_val);


% you can also draw only points above a threshold 
thresh=5;
res=grid_fine_val(grid_fine_val(:,4)>thresh,:);
figure;showmri(sa.mri,[],res);

% you can show multiple sources of various types;
% e.g.:
s1=sa.cortex.vc; % all points an a cortex;
s2=randn(1000,4)+repmat([3 3 3 0],1000,1); %hypothetical source with values
s3=randn(1000,4)+repmat([-3 -3 7 0],1000,1);% another hypothetical source with values
s4=sa.locs_3D; %electrode location plus outward normals (treated as dipoles)
figure;showmri(sa.mri,[],s1,s2,s3,s4);

% it actually also works e.g. if only the sum of the fields is known! (i.e.
% if the sources are perfectly correlated.) Careful: The iteration can
% converge to false minima. Comment out the following 6 lines for
% %demonstration
% [s,vmax,imax,dip_mom,dip_loc]=SMusic_e(vv(:,1),sa.V_fine,sa.grid_fine);
% grid_fine_val=[sa.grid_fine,1./(sqrt(1-s(:,1).^2))]; % s(:,1) is the 'distribution of first source
% figure;showmri(sa.mri,[],grid_fine_val);
% grid_fine_val=[sa.grid_fine,1./(sqrt(1-s(:,2).^2))]; % s(:,2) from second source
% figure;showmri(sa.mri,[],grid_fine_val);
% figure;showmri(sa.mri,[],dips); % here we look again at the true solution;




% Here's an analysis of some real data. We observe a local interaction 
% in left moter area. % Uncomment the following 8 lines to run it.
%Here, we observe a local interaction 

load pats;va=real(vi(:,8));vb=imag(vi(:,8));vv=[va,vb]; % loading an ISA-pattern 
[s,vmax,imax,dip_mom,dip_loc]=SMusic_v1(vv,sa.V_fine,sa.grid_fine); % inverse calculation
grid_fine_val_1=[sa.grid_fine,1./(sqrt(1-s(:,1).^2))]; % define 1st 'valued source'
grid_fine_val_2=[sa.grid_fine,1./(sqrt(1-s(:,2).^2))]; % define 2nd 'valued source'
grid_fine_val_1=[sa.grid_fine,1./(1-s(:,1))]; % define 1st 'valued source'
grid_fine_val_2=[sa.grid_fine,1./(1-s(:,2))]; % define 2nd 'valued source'
dip=[dip_loc,dip_mom]; % combine locations and moments of dipoles
clear para;para.dslice_shown=.5; %set a finer spatial resolution of slices
figure;showmri(sa.mri,para,grid_fine_val_1,dip(1,:)); %show first source 
figure;showmri(sa.mri,para,grid_fine_val_2,dip(2,:)); %show first source
para.orientation='sagittal';
figure;showmri(sa.mri,para,dip(1,:),dip(2,:));
[s,vmax,imax,dip_mom,dip_loc]=rapmusic(vv,sa.V_fine,2,sa.grid_fine);
diprap=[dip_loc,dip_mom]; 
figure;showmri(sa.mri,para,diprap(1,:),diprap(2,:));