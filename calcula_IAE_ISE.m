function calcula_IAE_ISE()
    % Diretório base dos modelos
    base_dir = fullfile(pwd, 'Simulink');  % Usa o diretório de trabalho atual e 'Simulink'
    model_prefix = 'projeto_';

    % Lista dos modelos para simulação e seus parâmetros Kp e Ki
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    freq_teste_values = [2, 4, 6, 8, 10, 12]; % Valores de freq_teste a serem testados
    sim_time = 0.6; % Tempo total de simulação em segundos

    % Pré-alocar células para resultados organizados para cada modelo e frequência
    resultados = cell(length(modelos) * length(freq_teste_values), 4);
    row = 1;

    % Executar a simulação para cada modelo e calcular ISE e IAE para cada freq_teste
    for i = 1:length(modelos)
        model_name = [model_prefix modelos{i}];
        modelo_atual = fullfile(base_dir, model_name);
        
        % Carregar o sistema do modelo se não estiver carregado
        if ~bdIsLoaded(model_name)
            load_system(modelo_atual);
        end

        % Caminho dos blocos com `/`
        bloco_Kp = [model_name '/PLL/Kp_' modelos{i}];
        bloco_Ki = [model_name '/PLL/Ki_' modelos{i}];
        bloco_en_teste = [model_name '/Barra Infinita/Frequência da rede/en_teste'];
        bloco_freq_teste = [model_name '/Barra Infinita/Frequência da rede/freq_teste'];

        % Definir o valor do parâmetro en_teste para 1
        set_param(bloco_en_teste, 'Value', '1');

        % Definir os parâmetros Kp e Ki específicos para cada modelo
        set_param(bloco_Kp, 'Gain', num2str(Kp_values(i)));
        set_param(bloco_Ki, 'Gain', num2str(Ki_values(i)));

        % Loop para cada valor de freq_teste
        for j = 1:length(freq_teste_values)
            freq_teste = freq_teste_values(j);

            % Definir o valor do parâmetro freq_teste
            set_param(bloco_freq_teste, 'Value', num2str(freq_teste));

            % Executar a simulação e salvar as saídas na variável simOut
            simOut = sim(modelo_atual, 'StopTime', num2str(sim_time));

            % Acessar os dados diretamente de simOut
            time = simOut.(['freq_' modelos{i}]).time; % Tempo dos dados
            freq_data = simOut.(['freq_' modelos{i}]).signals.values; % Dados de frequência

            % Calcular o erro entre a frequência da rede e a frequência do PLL
            freq_rede = freq_data(:, 1); % Primeira coluna: frequência da rede
            freq_pll = freq_data(:, 2);  % Segunda coluna: frequência do PLL
            erro = freq_rede - freq_pll;

            % Calcular ISE e IAE para o modelo e freq_teste atual
            ISE = trapz(time, erro.^2);       % Integral do erro ao quadrado
            IAE = trapz(time, abs(erro));     % Integral do valor absoluto do erro

            % Armazenar os resultados com a estrutura da tabela de exemplo
            if j == 1
                resultados{row, 1} = modelos{i};  % Nome do modelo só na primeira linha do bloco
            else
                resultados{row, 1} = '';  % Linhas subsequentes vazias para "Metodo"
            end
            resultados{row, 2} = freq_teste;      % Freq_Teste
            resultados{row, 3} = IAE;             % IAE
            resultados{row, 4} = ISE;             % ISE
            row = row + 1;                        % Próxima linha
        end
    end
    
    % Fechar os modelos
    for i = 1:length(modelos)
        close_system([model_prefix modelos{i}], 0);
    end

    % Criar e exibir a tabela de resultados ISE e IAE
    resultados_table = cell2table(resultados, 'VariableNames', {'Metodo', 'Frequencia', 'IAE', 'ISE'});

    % Criar uma nova janela para exibir a tabela
    f = figure('Name', 'Resultados de ISE e IAE para Vários Freq_Teste', 'NumberTitle', 'off', 'Position', [100, 100, 600, 300]);
    uitable('Parent', f, 'Data', table2cell(resultados_table), 'ColumnName', resultados_table.Properties.VariableNames, ...
            'RowName', [], 'Units', 'normalized', 'Position', [0, 0, 1, 1]);
end
