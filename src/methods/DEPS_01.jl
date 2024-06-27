using Pkg

# Libraries needed for Step_01.
libraries = ["HDF5", "JLD2", "Plots", "StatsBase", "Statistics", "Dates"]

# Funcion to chechk if a library is installed or not.
function is_installed(lib)
    try
        @eval using $(Symbol(lib))
        return true
    catch
        return false
    end
end

# Function to install a not installed library
function install_library(lib)
    println("Installing $lib library...")
    Pkg.add(lib)
end

# Checking if each required library is installed and install those that are not.
for lib in libraries
    if is_installed(lib)
        println("The $lib library is installed.")
    else
        println("The $lib library is NOT installed.")
        install_library(lib)
        if is_installed(lib)
            println("The $lib library has been installed successfully.")
        else
            println("There was a problem installing the $lib library")
        end
    end
end