function out_P = m_eLORETA_nvr(sa, pattern, chanlocs_labs, pattern_name, ...
    subject, cond, save_plot, save_format, dir_out, show_plot, colormap)

    %% Calculate eLORETA for a given topography
    %    INPUT:
    %       sa              leadfield info (read from 'sa_hyhead.mat') 
    %       pattern         vector - spatial pattern to reproject
    %       chanlocs_labs   vector - names of the sensors
    %       pattern_name    str - will be used for filename of result
    %       subject         str - subject ID in the NeVRo study (eg, 'NVR_S02')
    %       cond            str - movement condition ('mov' or 'nomov')
    %       save_plot       bool
    %       save_format     str - output format ('png' or 'epsc') 
    %       dir_out         str - path to save into
    %       show_plot       bool
    %       colormap        str - name of colormap to use ('rdbu' or 'viridis') 
    
    % Code written by Mina Jamshidi Idaji
    % w/ contributions from Guido Nolte and Stefan Haufe
    % and very slight adaptations to the NeVRO project by Felix Klotzsche. 
    %
    % For the original work, please refer to:
    % https://github.com/minajamshidi 
    % http://bbci.de/supplementary/EEGconnectivity/BBCB.html
    % and: 
    % METH toolbox 
    % https://www.uke.de/english/departments-institutes/institutes/neurophysiology-and-pathophysiology/research/research-groups/index.html 
    % (as of 06/11/2019)
    %
    % If you make use of code in `SourceReconstruction`, please cite the 
    % following paper:
    % Haufe, S., & Ewald, A. (2016):
    % A simulation framework for benchmarking EEG-based brain connectivity 
    % estimation methodologies. 
    % Brain topography, 1-18
    %
    % 2020 -- Felix Klotzsche -- 


    %% set up 

    % set the threshold set for the reconstructed sources; 
    % set to zero to ignore threshold
    TH = 0.0; 


    %% load 
    clab = chanlocs_labs;
    load cm17;
    cm_rdbu = brewermap(256, '*RdBu');
    cm_vir = viridis();
    X = pattern; % the topography to be inverse modeled

    %%
    sa = prepare_sourceanalysis(sa, clab, 'nyhead');
    V_fem_2k_new = sa.cortex75K.V_fem_normal(:, sa.cortex2K.in_from_cortex75K,:); % leadfield matrix
    % if u are interested in dipoles prependicular to the cortex, instead of
    % V_fem use V_fem_normal. In that case you dont need the tensor toolbox and
    % can easily multiply the demixing matrix to the sensor-space matrix.

    N_Ch = length(clab); % # of channels
    H = eye(N_Ch) - ones(N_Ch) ./ N_Ch; % this operator centralizes the matrix which is mltiplied to it
    V_fem_2k_new = double(ttm(tensor(V_fem_2k_new),H,1)); % centralized leadfiled
    gamma = 0.05; % eLORETA reg. factor, This value is suggested by Stefan and Vadim. Actually, I have not tried other values.
    A_eloreta = mkfilt_eloreta_v2(V_fem_2k_new,gamma); % eLORETA demixing matrix
    X = H*X; % centralized spaitial filter
    S_x = double(ttm(tensor(A_eloreta),X',1));
    S_x1 = double(tenmat(S_x,2)); % dipols have orientations in 3D space. Therefore each voxel is a 3D vector
    % in 3D case - normalize vectors:
    % S = sqrt(sum(S_x1.^2,2)); % For each dipole, I compute the norm of its vector as the inverse modeled sources. U can also do other thing. We can discuss.
    
    % in non-3D case - rectify and normalize values by L2-norm:
    S = abs(S_x1);
    S = S/norm(S);
    
    % threshold the sources 
    S_th = S;
    if (~(TH == 0))
        S_th(S_th<TH*max(S)) = 0;
    end

    % from this section: S_th and S can be plotted.
    %% plot the topography - with EEGlab
    % figure('Name','Topography of the spaitial filter'), topoplot(X,chanlocs)
    %% plot the sources
    % for plotting you need a 2004x1 vector, which you pass it to P in this
    % section.
    % close all
    P = S_th; % put the source in this matrix


    % views -----------
    % 1 = left lateral, 2 = left hem medial
    % 3 = rightlateral, 4 = right medial
    % 5 = dorsal, 6 = dorsal horizontal
    % 7 = ventral, 8 = ventral horizontal
    % ----------
    views = 1:8;
    savepath = fullfile(dir_out, cond, pattern_name, subject);
    %savepath = savepath{1};
    if (save_plot)
        if ~exist(savepath, 'dir'); mkdir(savepath); end
    end
    savename = fullfile(savepath, 'source');
    scale_unit = 'a.u.';
    switch colormap
        case 'rdbu'
            colormap_loc = cm_rdbu;
        case 'viridis'
            colormap_loc = cm_vir;
    end
    smooth = 1;
    
    if (show_plot | save_plot)
        allplots_cortex_mina(sa, P(sa.cortex2K.in_to_cortex75K_geod), ... 
            [min(P) max(P)], colormap_loc, scale_unit, smooth, 'views', views, ...
            'save', save_plot, 'savename', savename, ...
            'saveformat', save_format); % check the plotting function for the options
    end
    % return value:
    out_P = P;
