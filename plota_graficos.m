function plota_graficos(time, freq_data, Vsa_values, Vta_values)
    % Lista dos modelos e estilos de linha para os gr�ficos
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    tipo_linha = {'m-', 'b-', 'g-', 'c-'};

    % Figura para o gr�fico de frequ�ncia
    figure;
    hold on;
    for i = 1:length(modelos)
        % Extrair o nome simples do modelo para a legenda
        [nome_simples, ~] = strtok(modelos{i}, '_');
        % Plotar a frequ�ncia da rede e do PLL
        freq_rede = freq_data{i}(:, 1);
        freq_pll = freq_data{i}(:, 2);
        if i == 1
            plot(time, freq_rede, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Frequ�ncia da Rede');
        end
        plot(time, freq_pll, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['Frequ�ncia ' nome_simples]);
    end
    xlabel('Tempo (s)');
    ylabel('Frequ�ncia (Hz)');
    title('Respostas dos PLLs e Frequ�ncia da Rede');
    legend;
    grid on;
    hold off;

    % Figura para os gr�ficos de tens�o Vs e Vta com subplots
    figure;
    subplot(2, 2, [1 2]);
    hold on;
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        if i == 1
            plot(time, Vsa_values{i}, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Vs');
        end
        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['Vta ' nome_simples]);
    end
    xlabel('Tempo (s)');
    ylabel('Tens�o (V)');
    title('Tens�es Vs e Vta para cada PLL');
    legend;
    grid on;
    hold off;

    % Subplot com zoom em 0.2 s e 0.4 s
    subplot(2, 2, 3);
    hold on;
    for i = 1:length(modelos)
        if i == 1
            plot(time, Vsa_values{i}, 'r-', 'LineWidth', 1.5);
        end
        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0);
    end
    xlabel('Tempo (s)');
    ylabel('Tens�o (V)');
    title('Zoom em torno de 0.2 s');
    xlim([0.1 0.3]);
    grid on;
    hold off;

    subplot(2, 2, 4);
    hold on;
    for i = 1:length(modelos)
        if i == 1
            plot(time, Vsa_values{i}, 'r-', 'LineWidth', 1.5);
        end
        plot(time, Vta_values{i}, tipo_linha{i}, 'LineWidth', 1.0);
    end
    xlabel('Tempo (s)');
    ylabel('Tens�o (V)');
    title('Zoom em torno de 0.4 s');
    xlim([0.3 0.5]);
    grid on;
    hold off;
end
