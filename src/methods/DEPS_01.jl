push!( LOAD_PATH, dirname(@__FILE__) );

using Pkg
using Suppressor

# Libraries needed for all steps.
libraries = ["BinningAnalysis",
             "Dates",
             "DSP",
             "HDF5",
             "HistogramThresholding",
             "JLD2",
			 "InteractiveUtils",
             "Measures",
             "Plots",
			 "Primes",
             "StatsBase",
             "Suppressor"
        ];

# Funcion to chechk if a library is installed or not.
function is_installed(lib)
    try
        @eval using $(Symbol(lib));
        return true;
    catch
        return false;
    end
end

# Pkg.add(name="Example", version="0.3.1") # Specify version; exact release... Thinking About it

# Function to install a not installed library
function install_library(lib)
    println("Installing $lib library...");
    @suppress begin
        Pkg.add(lib);
    end
end

# Checking if each required library is installed and install those that are not.
for lib in libraries
    if is_installed(lib)
        println("The $lib library is installed.");
    else
        println("The $lib library is NOT installed.");
        install_library(lib)
    
        if is_installed(lib)
            println("The $lib library has been installed successfully.");
        else
            println("There was a problem installing the $lib library");
        end
    end
end

println("\n\n")
println("###################################################");
println("#### All libraries were installed successfully ####");
println("###################################################");
sleep(2);