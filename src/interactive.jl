function interactive_coupler_design(f₀ = 1.0)
    ## SETTINGS
    # Coupler
    n = 3
    BW_REL = 0.3
    K = 0.1
    POLYNOMIAL = :Butterworth

    # Plotting window
    _title = "Branch-Line Coupler Design"
    _res = (960, 360);
    _font = "Seaford";
    _fontsize = 30;
    _linewidth = 2;
    _color = :Hiroshige# TODO

    # Plots
    PTS = 1000
    fn_titles = ["Return losses", "Directivity", "Insertion Losses", "Coupling"]
    fn_labels = ["Γ", "D", "IL", "C"]
    f̄ = range(0.7, 1.3, length = PTS)
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
    supertitle = Label(fig[1,1:10], _title, textsize = 30)

    # Grid of plots
    plot_grid = GridLayout()
    fig.layout[2,1:10] = plot_grid
    ax = [Axis(plot_grid[reverse(fldmod1(i,2))...], 
                title = fn_titles[i],
                xlabel = "GHz",
                ylabel = "dB") for i in 1:4]
    for (ax_, fn_, lb_) in zip(ax, funs, fn_labels)
        lines!(ax_, f, db.(fn_.(t)), label = lb_)
        axislegend(ax_)
        xlims!(ax_, f[1], f[end])
    end
    


    ## ADMITTANCE DISPLAY
    ab_display = GridLayout()
    fig.layout[3,1:10] = ab_display
    a_labels = [ Label(ab_display[1,i], 
                    "", #@sprintf("%8.4f", a[i])
                    textsize = 10,
                    tellwidth = false) for i in 1:10]
    b_labels = [ Label(ab_display[2,i], 
                    "", #@sprintf("%8.4f", b[i])
                    textsize = 10,
                    tellwidth = false) for i in 1:10]
    

    ## PARAMETER INPUTS
    # n
    label_n = Label(fig[4,1], "n = $(n)")
    input_n = Slider(fig[4, 2:3], range = 1:1:10, startvalue = n)
    # K
    label_k = Label(fig[5,1], "K = $(K)")
    input_k = Textbox(fig[5,2:3], 
                placeholder = "Enter a coupling factor",
                stored_string = "0.1",
                validator = BigFloat, tellwidth = false)
    # BW_REL
    label_bwrel = Label(fig[6,1], "BW_REL = $(BW_REL)")
    input_bwrel = Textbox(fig[6,2:3], 
                    placeholder = "Enter a bandwidth factor",
                    stored_string = "0.3",
                    validator = BigFloat, tellwidth = false)
    # POLYNOMIAL
    label_polynomial = Label(fig[7,1], "Polynomial = $(String(POLYNOMIAL))")
    menu_polynomial = Menu(fig[7,2], 
                            options = zip(["Butterworth", "Chebyshev"], 
                                [:Butterworth,:Chebyshev]),
                            i_selected = 1,
                            selection = :Butterworth)

    # EVENT-DRIVEN PLOTTING
    # Observable coupler
    obs_c = @lift(
        [synthesise_coupler(
            $(input_n.value), 
            $(input_k.stored_string), 
            $(input_bwrel.stored_string), 
            $(menu_polynomial.selection))])

    # Event plot
    on(obs_c) do 
        _update_plot!(ax, a_labels, b_labels, to_value(obs_c)[1], fn_labels, t, f)
        label_n.text = "$(input_n.value)"
        label_k.text = "$(input_k.stored_string)"
        label_polynomial.text = "$(input_bwrel.stored_string)"
        label_polynomial.text = "$(String(menu_polynomial.selection))"
    end
    
    return fig
end
