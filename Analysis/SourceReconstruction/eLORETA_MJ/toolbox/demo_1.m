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
sa=prepare_sourceanalysis(clab_example,'montreal');
%sa=prepare_sourceanalysis(clab_example,'curry1');

% now we need some function data;
load cs_example; % this a cross-spectrum at 10 Hz
[u s v]=svd(real(cs_example));field=u(:,2); % construct an example field for demo


%%%% the display-function

% show a field
figure;showfield(field,sa.locs_2D); 

%show e.g. the imaginary part of the cross-spectrum
figure; showcs(imag(cs_example),sa.locs_2D);

% plot cortex and head
figure;showsurface(sa.cortex);

clear para 
para.myviewdir=[0 0 1]; % changes the viewpoint 
figure;showsurface(sa.cortex,para);

dips=[[3 -3 9 0 0 1];[3 3 10 0 0 1]]; %difine two dipoles 
figure;showsurface(sa.cortex,[],dips); %plots dipoles with surface plot

figure;showsurface(sa.cortex,[],dips,sa.cortex.vc(:,2)); %coloring the surface

% sa.elec2head is matrix which maps values 
% on electrodes to values on the head 
% (calculated by elec2head.m). 
% here we plot alpha power on the head
figure;showsurface(sa.head,[],sa.elec2head*diag(cs_example));


% plot mri
figure; showmri(sa.mri);

para.orientation='coronal';
figure;showmri(sa.mri,para);
% you can show multiple sources of various types;
% e.g.:
s1=sa.cortex.vc; % all points an a cortex;
s2=randn(1000,4)+repmat([3 3 3 0],1000,1); %hypothetical source with values
s3=randn(1000,4)+repmat([-3 -3 7 0],1000,1);% another hypothetical source with values
s4=sa.locs_3D; %electrode location plus outward normals (treated as dipoles)
figure;showmri(sa.mri,[],s1,s2,s3,s4);


%%%% functional calculations 

% make a forward calculation 
dips=[0 3 8 0 0 1]; % defines dipole, location is [0 3 8] in cm
                    % and moment is [0 0 1] nAm. 
v0=forward_general(dips,sa.fp); %makes potential v for that dipole 
                               % dips can also be a Mx6 matrix 
                               % then v is a NxM matrix for N channels 
                               % and the ith. column is the  potential
                               % for the i.th dipole, i.e. the i.th 
			       %  row in dips   

%lets look the calculated potential 
noise=randn(118,1);
v=v0/norm(v0)+noise/norm(noise)/2;
figure;showfield(v,sa.locs_2D); 



% now we make dipole fits:
% dipoles are always with random initial guess!! 
% One should make a couple of runs to avoid local minima!!
% make a 1-dipole for one the above potential.  
ndip=1; %select number of dipoles 
[a,res_out,k,field_theo]=dipole_fit_field(v,sa.fp,ndip); %make the fit 
% a is the estimated dipole solution (each row defines one dipole
% as in dips) res_out is the relative error, k is the number of 
% iterations, and field_theo is the potential of the found 
% dipoles. (Of course, you can calculate field_theo also as   
% field_theo=forward_general(a,sa.fp) if a is just one dipole.)

figure;showmri(sa.mri,[],dips,a);


% you can fit a dipole model to a cross-spectrum; 
ndip=2; %two dipoles
xtype='imag'; %we only fit the imaginary part;
%Now comes the fit. This is commented out because it might take some minutes
%[dips_out,c_source,res_out,c_theo]=dipole_fit_cs(cs_example,sa.fp,ndip,xtype);
% dips_out are the estimated dipoles; c_source is source-cross-spectrum; res_out is error;
% c_theo is the cross-spectrum of the model; 



% next we load another example for functional data. 
% The final output, vv, is an Nx2 matrix consisting 
% of two potential, and the assumption is that 
% the potential of true dipoles is within the 
% span of vv. Here, vv is constrcuted from ISA, but 
% it could also be, e.g., the  first two eigenvectors 
% of a PCA analysis. It can also consist of 
% just one or more than 2 potentials. 

% now we construct an example with two dipoles  
dips=[[3 -3 9 0 0 1];[3 3 10 0 0 1]];
v=forward_general(dips,sa.fp); % calculate the fields;
noise=randn(118,2);
vv=(v/norm(v,'fro')+noise/norm(noise,'fro')/5); %add some noise



% now we calculate the inverse using the Music-algorithm
% the variable s an indicator of how well a dipole at the 
%  i.th locations fits with the model assumption.
% s can have several columns. The first column 
% indicates indicates the quality of the best dipole;
% the second the 'quality' of the best which is orthogonal
% to the first, etc. 
[s,vmax,imax,dip_mom,dip_loc]=music(vv,sa.V_fine,sa.grid_fine);
% s indicates fit-quality, vmax the field of the best dipole;
% imax its grid_index;dip_mom the dipole moment (normalized);
% and dip_loc the location 


% now we calculate a ngx4 matrix (ng is number of grid-points);
% the first three columns are the locations of the grid-poinnts;
% and the 4th column is the value (i.e. quality of fit - the higher the
% better)
grid_fine_val=[sa.grid_fine,1./(1-s(:,1).^2)];
dips_estimate=[dip_loc,dip_mom];
figure;showmri(sa.mri,[],grid_fine_val,dips,dips_estimate);

% Rapmusic:
ns=2; %number of dipoles
[s,vmax,imax,dip_mom,dip_loc]=rapmusic(vv,sa.V_fine,ns,sa.grid_fine);
dips_estimate=[dip_loc,dip_mom];
grid_fine_val=[sa.grid_fine,1./(1-s(:,2).^2)];
figure;showmri(sa.mri,[],grid_fine_val,dips,dips_estimate);

% you can also draw only points above a threshold 
thresh=3;
res=grid_fine_val(grid_fine_val(:,4)>thresh,:);
figure;showmri(sa.mri,[],res);



% here come some calculation for cortically constraint slolution
%dips=[[3 0 8 0 0 1];[-3 0 8 0 0 1]]; 
%load Vcortex;
%dips=[[2 3 10 0 0 1];[2 -3 9.5 0 0 1]];
%v=forward_general(dips,sa.fp);
%vv=v*[[1 1 ];[1 -1]];
%vv=vv+randn(118,2)*.02;
%[s,vmax,imax,dip_mom,dip_loc]=rapmusic(vv,Vcortex,ns);
%ss=1./(1-s(:,1).^2);
%figure;showsurface(sa.cortex,[],ss,dips);
% 
% 
% [ng, ndum]=size(sa.cortex.vc);
% Vcortex=zeros(118,ng,3);
% for i=1:3;i=i
%     E=eye(3);
%     dipsloc=[sa.cortex.vc,repmat(E(i,:),ng,1)];
%     Vcortex(:,:,i)=forward_general(dipsloc,sa.fp);
% end

