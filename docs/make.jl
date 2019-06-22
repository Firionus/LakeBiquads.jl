using Documenter, DocumenterMarkdown
using LakeBiquads

makedocs(
    format = Markdown(),
    modules = [LakeBiquads],
    clean=false
)

cp("docs\\build\\README.md", "README.md", force=true)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
