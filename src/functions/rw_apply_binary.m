function rw_results = rw_apply_binary(data,id,plot)
inputs = data{data.denekId == id, "rakip"};  % Converts directly to a numeric array
responses = data{data.denekId == id, "yatirim"};

rw_results = tapas_fitModel(responses, ...
    inputs, ...,
    'tapas_rw_binary_config', ...
    'tapas_softmax_binary_config',...
    'tapas_quasinewton_optim_config');

if plot==true
 tapas_hgf_binary_plotTraj(rw_results);
end

end