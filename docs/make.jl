
using Documenter, AxisIndices, LinearAlgebra, Statistics

makedocs(;
    modules=[AxisIndices],
    format=Documenter.HTML(),
    pages=[
        "Introduction" => "index.md",
        "Quick Start" => "quick_start.md",
        "Manual" => [
            "The Axis" => "axis.md",
            "Internals of Indexing" => "internals_of_indexing.md",
            #"Combining Axes" => "combining_axes.md", TODO better document this and test LazyArrays.Vcat more
            "Pretty Printing" => "pretty_printing.md",
            "Compatibility" => "compatibility.md",
        ],
        "Examples" => [
            "Indexing Tutorial" => "indexing.md",
            "CoefTable" => "coeftable.md",
            "TimeAxis Guide" => "time.md",
        ],
        "Reference" => [
            "Public API" => "public_api.md",
            "Standard Library API" => "standard_library_api.md",
            "Internal API" => "internal_api.md",
            "Experimental API" => "experimental.md",
        ],
        "Comparison to Other Packages" => "comparison.md",
        "Acknowledgments" => "acknowledgments.md"
    ],
    repo="https://github.com/Tokazma/AxisIndices.jl/blob/{commit}{path}#L{line}",
    sitename="AxisIndices.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/AxisIndices.jl.git",
)

