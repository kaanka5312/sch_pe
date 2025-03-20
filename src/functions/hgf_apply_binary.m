function bopars = hgf_apply_binary(data,id,plot)
inputs = data{data.denekId == id, "rakip"};  % Converts directly to a numeric array
responses = data{data.denekId == id, "yatirim"};

bopars = tapas_fitModel(responses,...
                         inputs,...
                         'tapas_hgf_binary_config',...
                         'tapas_bayes_optimal_binary_config',...
                         'tapas_quasinewton_optim_config'); % For optimal 

if plot==true
 tapas_hgf_binary_plotTraj(bopars);
end

end