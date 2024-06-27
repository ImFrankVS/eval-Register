QtitleGraph = "# V values conv Qt 7w7"
Qcolor = :Spectral
Qcbar = false

println("Iniciando...");
println("FILEBRW Julia: ", FILEBRW);
println("LimUpperChunk Julia: ", limUpperChunk);

Variables = GetVarsHDF5( FILEBRW );
FILEVARIABLES = FindContent( "Variables.jld", FILEBRW );
PATHINFO = dirname( FILEVARIABLES );
PATHMAIN = pwd( );
PATHVOLTAGE = joinpath( PATHMAIN, "Voltage" ); mkpath( PATHVOLTAGE );
FILESTEP0Ws = joinpath( PATHINFO, "STEP_01_WS.jld" );
PATHDISCARDED = joinpath( PATHINFO, "Discarded" ); mkpath( PATHDISCARDED );
PATHVOLTAGEDESAT = joinpath( dirname( PATHINFO ), "Desaturation" ); mkpath( PATHVOLTAGEDESAT );
PATHFIGURES = joinpath( PATHMAIN, "Figures" ); mkpath( PATHFIGURES );

nChs = Variables[ "nChs" ];
N = ChunkSizeSpace( Variables, limUpperChunk );
nFrs = Int( Variables[ "NRecFrames" ] / N );
n0s = length( string( N ) );

#dataValues = []
#
#@time for n = 1 : N;
#    BINRAW = OneSegment( Variables, n, N );
#    BINRAW = Digital2Analogue( Variables, BINRAW );
#    NΔV = stdΔV( Variables, BINRAW, ΔT );
#    RowCount = UniqueCount( BINRAW );
#    h = copy( RowCount ); hg = convgauss( sigma, h );
#    data = vec( RemoveInfs( abs.( log.( hg ) ) ) ); push!(dataValues, data);
#    P = Zplot( data, "W", Qcolor ); PP = title!( QtitleGraph );
#    PF = plot( P, layout = ( 1, 1 ), wsize = ( 800, 800 ), cbar = Qcbar);
#    FIGNAME = joinpath( PATHFIGURES, string( "BIN", lpad( n, n0s, "0" ), ".svg" ));
#    FIGNAME = joinpath( PATHFIGURES, FIGNAME );
#    savefig( PF, FIGNAME );
#
#    println("$n listo de $N");
#end
#
#println(dataValues);


#FILEBRW = "C:\\Users\\murph\\OneDrive\\Escritorio\\BRW's\\BRW\\0-20s.brw"
#limUpperChunk = 0.2