function interactive_coupler_design(f₀ = 1.0)
    ## SETTINGS
    # Coupler
    n = 3
    K = "0.1"
    BW_REL = "0.3"
    POLYNOMIAL = :Butterworth

    # Plotting window
    _title = "Branch-Line Coupler Design"
    _res = (1920, 1080);
    _font = "Seaford";
    _fontsize = 20;
    _linewidth = 2;
    _color = :Hiroshige# TODO

    # Plots
    PTS = 1000
    fn_titles = ["Return losses", "Directivity", "Insertion Losses", "Coupling"]
    fn_labels = ["Γ", "D", "IL", "C"]
    f̄ = range(0.85, 1.15, length = PTS)
    f = f̄ .* f₀
    t = im .* tan.(π/4 .* f̄)


    ## SYNTHESISE FIRST COUPLER
    c = synthesise_coupler(n, K, BW_REL, POLYNOMIAL)
    funs = analysis_functions(c)


    ## MAKIE
    # Create figure
    set_theme!(font = _font,
        fontsize = _fontsize,
        linewidth = _linewidth,
        palette = ( colormap = _color,)); # color = _color
    fig = Figure(resolution = _res)

    # Title
    supertitle = Label(fig[1,1:10], _title, textsize = 40)

    # Grid of plots
    plot_grid = GridLayout()
    fig.layout[2,1:10] = plot_grid
    axs = [Axis(plot_grid[reverse(fldmod1(i,2))...], 
                title = fn_titles[i],
                xlabel = "GHz",
                ylabel = "dB") for i in 1:4]
    # for (ax_, fn_, lb_) in zip(axs, funs, fn_labels)
    #     lines!(ax_, f, db.(fn_.(t)), label = lb_)
    #     axislegend(ax_)
    #     xlims!(ax_, f[1], f[end])
    # end

    
    
    # ## ADMITTANCE DISPLAY
    ab_display = GridLayout()
    fig.layout[3,1:10] = ab_display
    a_labels = [ Label(ab_display[1,i], 
                    "", 
                    textsize = 13,
                    tellwidth = false) for i in 1:10]
    b_labels = [ Label(ab_display[2,i], 
                    "", 
                    textsize = 13,
                    tellwidth = false) for i in 1:10]

    ## GENERATE FIRST PLOT
    _update_plot!(axs, a_labels, b_labels, c, fn_labels, t, f)

    ## PARAMETER INPUTS
    # n
    label_n = Label(fig[4,1], "n = ", halign = :right)
    input_n = Textbox(fig[4, 2], 
                placeholder = "Enter number of branches",
                stored_string = "$(n)",
                validator = Int,
                tellwidth = false, 
                halign = :left)
    # K
    label_k = Label(fig[5,1], "K = ", halign = :right)
    input_k = Textbox(fig[5,2], 
                placeholder = "Enter a coupling factor",
                stored_string = K,
                validator = BigFloat, 
                tellwidth = false, 
                halign = :left)
    # BW_REL
    label_bwrel = Label(fig[6,1], "BW_REL = ", halign = :right)
    input_bwrel = Textbox(fig[6,2], 
                    placeholder = "Enter a bandwidth factor",
                    stored_string = BW_REL,
                    validator = BigFloat, 
                    tellwidth = false, 
                    halign = :left)
    # POLYNOMIAL
    label_polynomial = Label(fig[7,1], "Polynomial = ", halign = :right)
    menu_polynomial = Menu(fig[7,2], 
                            options = zip(["Butterworth", "Chebyshev"], 
                                [:Butterworth,:Chebyshev]),
                            i_selected = 1,
                            selection = POLYNOMIAL, 
                            halign = :left)

    ## EVENT-DRIVEN PLOTTING
    # n event
    on(input_n.stored_string) do new_n
        new_c = synthesise_coupler(parse(Int,to_value(new_n)), 
                        to_value(input_k.stored_string), 
                        to_value(input_bwrel.stored_string), 
                        to_value(menu_polynomial.selection))
        _update_plot!(axs, a_labels, b_labels, new_c, fn_labels, t, f)
    end

    # K event
    on(input_k.stored_string) do new_k
        new_c = synthesise_coupler(parse(Int,to_value(input_n.stored_string)), 
                        to_value(new_k), 
                        to_value(input_bwrel.stored_string), 
                        to_value(menu_polynomial.selection))
        _update_plot!(axs, a_labels, b_labels, new_c, fn_labels, t, f)
    end

    # BW event
    on(input_bwrel.stored_string) do new_bw
        new_c = synthesise_coupler(parse(Int,to_value(input_n.stored_string)), 
                        to_value(input_k.stored_string), 
                        to_value(new_bw), 
                        to_value(menu_polynomial.selection))
        _update_plot!(axs, a_labels, b_labels, new_c, fn_labels, t, f)
    end

    # Polynomial event
    on(menu_polynomial.selection) do new_pol
        new_c = synthesise_coupler(parse(Int,to_value(input_n.stored_string)), 
                        to_value(input_k.stored_string), 
                        to_value(input_bwrel.stored_string), 
                        to_value(new_pol))
        _update_plot!(axs, a_labels, b_labels, new_c, fn_labels, t, f)
    end

    
    return fig
end
