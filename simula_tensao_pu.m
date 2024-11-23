function simula_tensao_pu()
    modelos = {'SRF_PLL', 'SOGI_PLL', 'EPLL', 'QPLL'};
    tipo_linha = {'g-', 'b-', 'c-', 'm-'};
    Kp_values = [100, 154.8, 180, 9.9];
    Ki_values = [4228, 7871.2, 5202.3, 1440];
    sim_time = 0.6;
    Vp = 127 * sqrt(2);

    [source_voltage, vta_voltage, time_vector] = executa_testes(modelos, Kp_values, Ki_values, sim_time, Vp);
    plota_resultados(source_voltage, vta_voltage, time_vector, modelos, tipo_linha);
end

function [source_voltage, vta_voltage, time_vector] = executa_testes(modelos, Kp_values, Ki_values, sim_time, Vp)
    base_dir = fullfile(pwd, 'Simulink');
    model_prefix = 'projeto_';

    source_voltage = cell(2, 1);
    vta_voltage = cell(2, length(modelos));
    time_vector = cell(2, 1);

    for test = 1:2
        for i = 1:length(modelos)
            model_name = [model_prefix modelos{i}];
            modelo_atual = fullfile(base_dir, model_name);

            if ~bdIsLoaded(model_name)
                load_system(modelo_atual);
            end

            configura_blocos(model_name, modelos{i}, Kp_values(i), Ki_values(i), test);

            simOut = sim(modelo_atual, 'StopTime', num2str(sim_time));
            time = simOut.(['Va_' modelos{i}]).time;
            vta_data = simOut.(['Va_' modelos{i}]).signals.values(:, 1);

            if i == 1
                source_data = simOut.(['Va_' modelos{i}]).signals.values(:, 2);
                source_voltage{test} = source_data / (0.5 * Vp);
                time_vector{test} = time;
            end
            vta_voltage{test, i} = vta_data / (0.5 * Vp);
        end
    end

    for i = 1:length(modelos)
        close_system([model_prefix modelos{i}], 0);
    end
end

function configura_blocos(model_name, modelo, Kp, Ki, test)
    set_param([model_name '/PLL/Kp_' modelo], 'Gain', num2str(Kp));
    set_param([model_name '/PLL/Ki_' modelo], 'Gain', num2str(Ki));
    set_param([model_name '/Barra Infinita/Frequência da rede/en_teste'], 'Value', '1');
    set_param([model_name '/Barra Infinita/Amplitude da Rede/en_teste_v_pu'], 'Value', '1');
    set_param([model_name '/Barra Infinita/Amplitude da Rede/teste_v_pu'], 'Value', num2str(test - 1));
end

function plota_resultados(source_voltage, vta_voltage, time_vector, modelos, tipo_linha)
    plota_graficos_completos(source_voltage, vta_voltage, time_vector, modelos, tipo_linha);
    plota_graficos_zoom(source_voltage, vta_voltage, time_vector, modelos, tipo_linha);
end

function plota_graficos_completos(source_voltage, vta_voltage, time_vector, modelos, tipo_linha)
    figure('Name', 'Testes com variação de tensão em PU', 'NumberTitle', 'off', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    ax1 = subplot(2, 1, 1);
    plota_tensao_pu(time_vector{1}, source_voltage{1}, vta_voltage(1, :), modelos, tipo_linha, '(a)');

    ax2 = subplot(2, 1, 2);
    plota_tensao_pu(time_vector{2}, source_voltage{2}, vta_voltage(2, :), modelos, tipo_linha, '(b)');
end

function plota_graficos_zoom(source_voltage, vta_voltage, time_vector, modelos, tipo_linha)
    figure('Name', 'Zoom dos Testes', 'NumberTitle', 'off', 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

    ax3 = subplot(2, 1, 1);
    plota_tensao_pu_zoom(time_vector{1}, source_voltage{1}, vta_voltage(1, :), modelos, tipo_linha, '(a)', [0.25, 0.35]);

    ax4 = subplot(2, 1, 2);
    plota_tensao_pu_zoom(time_vector{2}, source_voltage{2}, vta_voltage(2, :), modelos, tipo_linha, '(b)', [0.25, 0.35]);
end

function plota_tensao_pu(time, source_voltage, vta_voltage, modelos, tipo_linha, letra)
    hold on;
    plot(time, source_voltage, 'r--', 'LineWidth', 1.5, 'DisplayName', '$V_{sa}$');
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(time, vta_voltage{i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['$V_{ta}~' nome_simples '$']);
    end
    hold off;
    formatar_grafico(letra);
end

function plota_tensao_pu_zoom(time, source_voltage, vta_voltage, modelos, tipo_linha, letra, x_limits)
    hold on;
    plot(time, source_voltage, 'r--', 'LineWidth', 1.5, 'DisplayName', '$V_{sa}$');
    for i = 1:length(modelos)
        [nome_simples, ~] = strtok(modelos{i}, '_');
        plot(time, vta_voltage{i}, tipo_linha{i}, 'LineWidth', 1.0, 'DisplayName', ['$V_{ta}~' nome_simples '$']);
    end
    hold off;
    xlim(x_limits);
    formatar_grafico(letra);
end

function formatar_grafico(letra)
    xlabel('Tempo (s)', 'FontSize', 16);
    ylabel('Tensão (pu)', 'FontSize', 16);
    lgd = legend('Location', 'northoutside', 'Orientation', 'horizontal');
    set(lgd, 'FontSize', 14, 'Interpreter', 'latex');
    lgd.ItemTokenSize = [40, 20];
    grid on;
    add_letra(letra);
end

function add_letra(letra)
    pos = get(gca, 'Position');
    annotation('textbox', [pos(1) + (pos(3) / 2) - 0.02, pos(2) - 0.1, 0.04, 0.03], ...
        'String', letra, 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontSize', 14);
end
