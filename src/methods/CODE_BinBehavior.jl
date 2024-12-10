"""
    Collection of functions for analysis of BRW (HDF5) files generated with the BrainWave program from the company 3Brain.
    Laboratory 19 of the CINVESTAV in charge of Dr. Rafael Gutierrez Aguilar.
    Work developed mainly by Isabel Romero-Maldonado (2020 - )
    isabelrm.biofisica@gmail.com
    https://github.com/LBitn
    https://github.com/LBitn/Hippocampus-HDMEA-CSDA.git
"""
push!( LOAD_PATH, dirname(@__FILE__) );

using AllSTEPs

using JLD2
using StatsBase
using Plots

# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
# Variables for Qt GUI
# •·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·•·•·•·••·•·•·•·•·•·• #
#PATHINFO = "C:/Users/murph/OneDrive/Escritorio/BRW's/version03/Info"

println("Iniciando...");
println("Path selected: ", PATHINFO );

PATHMAIN = dirname( PATHINFO );
PATHFIGURES = joinpath( PATHMAIN, "Figures" );
PATHFIGURES_GENERAL = joinpath( PATHFIGURES, "GENERAL" ); mkpath( PATHFIGURES_GENERAL );

FILESTEP00 = joinpath( PATHMAIN, "Info", "STEP00.jld2" );
FILEPARAMETERS = joinpath( PATHINFO, "Parameters.jld2" );

step00 = LoadDict( FILESTEP00 );
Parameters = LoadDict( FILEPARAMETERS );

N = Parameters[ "N" ];

# All for Raw Bin Behavior
aux_Cardinality = []

for n = 1:N
    if step00["Cardinality"][n] != Any[]
        push!(aux_Cardinality, step00["Cardinality"][n])
    end
end

#aux = vcat( sum.( step00[ "Cardinality" ], dims = 1 )... );
aux = vcat( sum.( aux_Cardinality, dims = 1 )... );
W = zscore( aux );
fc = :royalblue3;
t = "\n" ^ 1 * "Raw Bin Behavior";
xl = "n bin";
yl = "zscore of Σ( Cardinality )";
plotfonts = Plots.font( pointsize = 10, family = "sans-serif" );

P = BarPlot( W, fc, t, xl, yl );
P = plot( 
    P, 
    plotfont = plotfonts,
    xticks =  ( 0:5:N )
);

FILEFIGURE_RawBinBehavior = joinpath( PATHFIGURES_GENERAL,"RawBinBehavior" );
Plots.png( P, FILEFIGURE_RawBinBehavior );