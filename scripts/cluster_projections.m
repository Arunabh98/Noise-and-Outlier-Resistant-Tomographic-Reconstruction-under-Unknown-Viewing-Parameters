function clustered_projections = cluster_projections(projections, sigmaNoise)
    % Number of clusters in which we want to cluster the projections.
    number_of_clusters = 90;
    
    % Denoise all the projections.
    projections = denoise(projections, sigmaNoise, 50, 200);
    projections(projections < 0) = 0;
    all_projections = max(0, projections);
    
    % Cluster all the projections.
    [idx, ~] = kmeans(all_projections', number_of_clusters);    
    idx = idx'; 
    [sorted_idx, idx_order] = sort(idx);
    sorted_projections = all_projections(:, idx_order);
    
    [unique_idx, ~, ~] = unique(sorted_idx);
    number_of_projections = histc(sorted_idx, unique_idx);
    
    mean_projections = zeros(size(projections, 1), number_of_clusters);
    
    c = 1;
    for i=1:size(number_of_projections, 2)
        cluster_projections = ...
            sorted_projections(:, c:c + number_of_projections(i) - 1);
        mean_projections(: , i) = mean(cluster_projections, 2);
        c = c + number_of_projections(i);
    end
    
    clustered_projections = zeros(size(mean_projections));
    
    unique_nop = unique(number_of_projections);
    for i=1:size(unique_nop, 2)
        idx = number_of_projections == unique_nop(i);
        projections_category = mean_projections(:, idx);
        clustered_projections(:, idx) = denoise(projections_category, sigmaNoise/unique_nop(i),...
            min(size(projections_category, 2), 10), min(size(projections_category, 2), 5));
    end
end