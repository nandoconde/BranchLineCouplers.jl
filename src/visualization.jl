function plot_coupler(c::Coupler, f₀ = 1.0)
    # Constants
    PTS = 1000

    # Analysis functions
    funs = analysis_functions(c)

    # Create x-axis
    f̄ = range(0.7, 1.3, length = PTS)
    f = f̄ .* f₀
    t = im .* tan.(π/4 .* f̄)

    # Labels
    titles = ["Return losses", "Directivity", "Insertion Losses", "Coupling"]
    labels = ["Γ", "D", "IL", "C"]

    # CREATE FIGURE
    fig = Figure()

    # CREATE TITLE
    supertitle = Label(fig[1,:], _title, textsize = 30)
    
    # CREATE AXES
    plot_grid = GridLayout()
    fig.layout[2,:] = plot_grid
    axs = [Axis(plot_grid[reverse(fldmod1(i,2))...], title = titles[i]) for i in 1:4]
    

    # CREATE LABELS
    ab_display = GridLayout()
    fig.layout[3,:] = ab_display
    a_labels = [ Label(ab_display[1,i], 
                    @sprintf("%8.4f", a[i]),
                    textsize = 10,
                    tellwidth = false) for i in 1:10]
    b_labels = [ Label(ab_display[2,i], 
                    @sprintf("%8.4f", b[i]),
                    textsize = 10,
                    tellwidth = false) for i in 1:10]

    # PLOT EVERYTHING
    _update_plot!(axs, a_labels, b_labels, c, labels, t, f)

    # RETURN WHOLE FIGURE
    return fig
end

function _update_plot!(axs, a_labels, b_labels, coupler, labels, t, f)
    funs = analysis_functions(coupler)
    
    for (ax_, fn_, lb_) in zip(axs, funs, labels)
        empty!(ax_)
        lines!(ax_, f, db.(fn_.(t)), label = lb_)
        axislegend(ax_)
        xlims!(ax_, f[1], f[end])
    end

    ylims!(axs[1], -50, -10)
    ylims!(axs[2], -50, -10)

    for i in eachindex(a_labels)
        checkindex(Bool, eachindex(coupler.a), i) ?
        a_labels[i].text = @sprintf("%8.4f", coupler.a[i]) :
        a_labels[i].text = ""
    end
    for i in eachindex(b_labels)
        checkindex(Bool, eachindex(coupler.b), i) ?
            (b_labels[i].text = @sprintf("%8.4f", coupler.b[i]); 
                b_labels[i].color = (coupler.b[i] > 1) ? (:red) : (:blue)) :
            b_labels[i].text = ""
        
    end 
end