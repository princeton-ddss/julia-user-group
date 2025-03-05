### A Pluto.jl notebook ###
# v0.20.4

#> [frontmatter]
#> title = "Working with Julia everyday - (An introduction)"
#> date = "2024-11-13"

using Markdown
using InteractiveUtils

# ╔═╡ a1cb9035-bc71-499c-a7c3-d1849e3cd1c1
begin
	using PlutoUI
	using PkgTemplates
	TableOfContents(title="📚 Table of Contents")
end

# ╔═╡ 05354553-276a-4704-bd03-521b82930eed
begin
	struct TwoColumn{L, R}
    	left::L
    	right::R
	end

	function Base.show(io, mime::MIME"text/html", tc::TwoColumn)
	    write(io, """<div style="display: flex;"><div style="flex: 32%;">""")
	    show(io, mime, tc.left)
	    write(io, """</div><div style="flex: 68%;">""")
	    show(io, mime, tc.right)
	    write(io, """</div></div>""")
		write(io, """<br></br>""")
		show(io, mime, md"""
#### Turn Your Script into a Package in One Hour
##### Princeton Julia User Group, Feb 21, 2025
""")
	end

	TwoColumn(Resource("https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Princeton_seal.svg/800px-Princeton_seal.svg.png"),Resource("https://julialang.org/assets/infra/logo.svg"))
end

# ╔═╡ 38190363-c465-44b3-ac13-86494cfd42df
md"""
# Outline
* Why a package?
* The "script" scenario
* PkgTemplate.jl
* Setup the new Package
* Further steps
"""

# ╔═╡ f6a4c98e-dfff-4509-aba7-30e2fa85f01c
md"""
# Why a package?
"""

# ╔═╡ 73b46039-fb67-441e-8466-8b1f7bdb2378
md"""
## Motivations
* **Code Organization**: Structure your code in a maintainable way
* **Code quality**: Improve code quality following SWE best practices
* **Collaboration**: Make it easier for others to use and contribute
* **Dependency Management**: Clear specification of requirements
* **Reusability**: Share code across projects
* **Documentation**: Standardized documentation structure
* **Testing**: Formal testing infrastructure
* **Live Monitoring**
"""

# ╔═╡ a89366e8-d814-40b9-bd0b-94639fb558c8
md"""
## Examples
- [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)
- [JuMP.jl](https://github.com/jump-dev/JuMP.jl)
- [Dagger.jl](https://github.com/JuliaParallel/Dagger.jl)
- [GenX.jl](https://github.com/GenXProject/GenX.jl)
"""

# ╔═╡ 483d88a9-63b6-4fb5-8472-035e8853fa70
md"""
## Starting from a Script

### The Common Scenario
Most Julia projects begin with a simple script file. You create a `.jl` file, write a few useful functions, and everything works fine at first. As time goes on, your script grows. You add more functionality, more helper functions, and soon you find yourself with a substantial codebase. Then comes the moment when you need to use these functions in another project, so you copy the script over. A colleague sees your work and asks to use it in their research. Before you know it, you have multiple copies of your script floating around in different projects, each slightly different from the others.
"""

# ╔═╡ 44230292-5d72-44e8-8312-b41e486e2b8e
md"""
### Example (on VS Code)
```julia
# my_script.jl

using CSV, DataFrames, Plots

function get_data(path)
	# ... data import logic ...
end

function process_data(data)
	# ... data processing logic ...
end

function analyze_results(processed_data)
	# ... analysis logic ...
end

function plot_analysis(results)
	# ... plotting code ...
end

data = get_data("~/my_project/my_data/data.csv")

# Script usage
data = get_data("~/my_project/my_data/data.csv")
processed = process_data(data)
results = analyze_results(processed)
plot = plot_analysis(results)
savefig(plot, "analysis_results.png")

# Maybe add some print statements
println("Analysis complete!")
println("Total samples processed: $(results.total_samples)")
println("Anomaly rate: $(round(results.anomaly_rate * 100, digits=2))%")


# Script grows with more functions
# Dependencies start piling up
# Code organization becomes challenging
```
"""

# ╔═╡ b2ccfc77-f09c-46f2-b663-7e52ee2de763
md"""
This script demonstrates common real-world patterns:
- Reading data from files
- Data cleaning and processing
- Statistical analysis
- Visualization
"""

# ╔═╡ 33761b97-5c9d-4040-8e7b-0dd56ff1c291
md"""
### Limitations
* **Dependency Management**: Hard to track what packages are needed
* **Version Control**: Difficult to manage different versions
* **Reusability**: Copy-pasting leads to multiple versions
* **Collaboration**: Others can't easily install or contribute
* **Testing**: No formal testing structure
* **Documentation**: Documentation lives in comments
"""

# ╔═╡ 4394867b-9381-4202-8096-aeaac609994e
md"""
### Solution: Convert to a Package!
* Organize code properly
* Manage dependencies explicitly
* Make it installable with one command
* Enable proper version control
* Add tests and documentation
"""

# ╔═╡ 077eefbd-f841-4086-831e-4b305ede64d2
md"""
## PkgTemplate.jl
### What is [PkgTemplate.jl](https://github.com/JuliaCI/PkgTemplates.jl)?
* Tool for creating new Julia packages with best practices
* Generates all necessary files and structure
* Configurable templates for different needs
"""

# ╔═╡ efbc9633-1323-468b-b24e-206a7202d9cf
md"""
### Basic Usage
```julia
using PkgTemplates

t = Template(; 
	user="YourGitHubUsername"
)

t("MyNewPackage")
```
"""

# ╔═╡ b5a44c38-ddc4-4f4e-999f-b924f02b8129
md"""
Executing the above command, `PkgTemplates` will generate the following folder structure (usually in the `~/.julia/dev` directory):

	MyNewPackage/
	├── .github/
	├── src/
	├── test/
	├── LICENSE
	├── Project.toml
	├── Manifest.toml
	├── README.md
	└── .gitignore
"""

# ╔═╡ 4b7be614-57b1-498a-9e95-015d3e3a632d
md"""
### PkgTemplates Plugins

PkgTemplates.jl offers a rich ecosystem of plugins that help automate various aspects of package development. Each plugin adds specific functionality to your package template, allowing you to customize your package structure according to your needs.

#### Essential Plugins

- The `Git` plugin sets up your package as a Git repository, initializing it with a `.gitignore` file tailored for Julia projects. It automatically excludes common files you don't want to track, such as build artifacts and system-specific files. 

- The `GitHubActions` plugin is crucial for continuous integration. It creates workflow files in the `.github/workflows` directory that automatically run your package's tests on different Julia versions and operating systems whenever you push changes. This ensures your package remains compatible across different environments and catches potential issues early.

#### Documentation Plugins

The `Documenter` plugin is particularly valuable as it sets up the infrastructure for your package's documentation. It creates a `docs` directory with a basic structure and configuration files, enabling you to write documentation in Markdown that can be automatically built and deployed. When used with `GitHubActions`, it can automatically deploy your documentation to GitHub Pages.

#### Code Quality Plugins

`Codecov` and `Coveralls` plugins help track your package's test coverage. They configure your CI pipeline to generate coverage reports and upload them to their respective services. This gives you and your users visibility into how well your code is tested.

The `TagBot` plugin automates version tagging. When you register a new version of your package, it automatically creates a corresponding Git tag, making it easier to track package versions and releases.

"""

# ╔═╡ 01026247-83f6-4de9-bdef-e031e49550b5
md"""
Let's explore now a more comprehensive package setup. The main reference is the great [PkgTemplate.jl documentation](https://juliaci.github.io/PkgTemplates.jl/stable/).

```julia
using PkgTemplates

t = Template(;
	user="YourGitHubUsername",
	dir="/path/to/outdir",
	julia=v"1.10", # Minimum Julia version
	plugins=[
		# Basic setup
		ProjectFile(; version=v"0.1.0-DEV"),
		Readme(; inline_badges=false),
		Citation(; readme=true),
		License(; name="MIT"),
		Git(;
		    ignore=["*.jl.cov", "*.DS_Store", "Manifest.toml", ".vscode/"],
		    name="YourGitUsername",
		    email="YourGitEmail",
		    ssh=true,
		    jl=true,
		    manifest=false,
		),
		# Documentation
		Documenter{GitHubActions}(;
			assets=["assets/style.css"],
			logo=Logo(;
				dark="assets/logo_dark.png",
				light="assets/logo_light.png",
			),
		),
		Tests(;
			project=true,
			aqua=true,
			jet=true,
		),
		# Comprehensive CI setup with GitHub integration
		GitHubActions(;     
			destination="CI.yml",
    		linux=true,
    		windows=true,
		    x64=true,
 		    coverage=true,
    		extra_versions=["1.9", "1.11", "pre"],
		),
		Codecov(),
		PkgBenchmark(),
		BlueStyleBadge(),
		ColPracBadge()
	]
)

t("DataAnalyzer")
```

"""

# ╔═╡ 32fa049a-20da-4459-bdba-6fd2561ce94a
md"""
The resulting package structure will be more elaborate than our basic example:

	DataAnalyzer/
	├── .github/
	│ ├── workflows/
	│ │ ├── CI.yml
	│ │ ├── Documenter.yml
	│ │ └── TagBot.yml
	│ ├── dependabot.yml
	├── docs/
	│ ├── src/
	│ │ ├── index.md
	│ │ ├── api.md
	│ │ └── examples.md
	│ ├── assets/
	│ │ ├── logo.png
	│ │ └── custom.css
	│ └── make.jl
	├── src/
	│ ├── DataAnalyzer.jl
	│ └── core/
	├── test/
	│ ├── Project.toml
	│ ├── runtests.jl
	│ ├── testsuite/
	│ └── benchmarks/
	├── LICENSE
	├── Project.toml
	├── README.md
	└── .gitignore

The additional structure and configuration help maintain code quality and make the package more maintainable as it grows in complexity.
"""

# ╔═╡ 68c9dc19-e0b5-4336-af6b-72068a0caa24
md"""
Here's how this package structure addresses the original limitations:

1. **Dependencies are explicit**:
   - Project.toml clearly lists all dependencies and their versions
   - Compat section ensures version compatibility

2. **Testing infrastructure**:
   - Dedicated test suite with testsets
   - Tests for configuration, data processing, etc.
   - Edge cases and error conditions tested

3. **Documentation**:
   - Markdown documentation with examples
   - DocStrings for types and functions
   - Installation and usage instructions
   - API reference

4. **Reusability**:
   - Modular design with clear interfaces
   - Exported types and functions
   - Can be installed as a package
   - Version control ready

"""

# ╔═╡ d66e576d-3d0f-4fa7-8415-ecd89c8d2071
md"""
In the example above, as you can see we made use of `Plugins` which are particularly useful to automate common boilerplate tasks. Here are some examples:
"""

# ╔═╡ 2cde9ac1-ed98-4175-81ac-4876f45d37e5
md"""
#### `ProjectFile`
```julia
ProjectFile(; version=v"1.0.0-DEV")
```
Creates a Project.toml.
"""

# ╔═╡ 732a65e4-d4a4-49ce-be9e-dbae6a765f79
md"""
#### SrcDir
```julia
SrcDir(; file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/src/module.jlt")
```

Creates a module entrypoint. 

- `File`: template file for src/<module>.jl.
"""

# ╔═╡ c89be673-c67e-430b-970f-21f3d140f707
md"""
#### Readme

```julia
Readme(;
    file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/README.md",
    destination="README.md",
    inline_badges=false,
)
```
Creates a README file that contains badges for other included plugins.

**Keyword Arguments**

- `file`: Template file for the README.
- `destination`: File destination, relative to the repository root. 
"""

# ╔═╡ dfc89dbf-8444-4181-8c2b-99ba543a686d
md"""
#### Citation

```julia
Citation(; file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/CITATION.bib", readme=false)
```

Creates a CITATION.bib file for citing package repositories.

**Keyword Arguments**

- `file`: Template file for CITATION.bib.
- `readme::Bool`: Whether or not to include a section about citing in the README.
"""

# ╔═╡ 0a1618ac-07d4-41c3-9b7a-f0d30c4ab38e
md"""
#### Documentation

These plugins will help you build a documentation website.

```julia
Documenter{T}(;
    make_jl="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/docs/make.jlt",
    index_md="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/docs/src/index.md",
    assets=String[],
    logo=Logo(),
    canonical_url=make_canonical(T),
    devbranch=nothing,
    edit_link=:devbranch,
    makedocs_kwargs=Dict{Symbol,Any}(),
)
```

Sets up documentation generation via Documenter.jl. Documentation deployment depends on T, where T is some supported CI plugin, or Nothing to only support local documentation builds.

!!! note

    If you are deploying documentation with GitHub Actions or Travis CI, don't forget to complete the required configuration. In particular, you may need to run

	```julia
    using DocumenterTools
	DocumenterTools.genkeys(user="MyUser", repo="MyPackage.jl")
	```
    and follow the instructions there.

**Supported Type Parameters**

- `GitHubActions`: Deploys documentation to GitHub Pages with the help of GitHubActions.
- `TravisCI`: Deploys documentation to GitHub Pages with the help of TravisCI.
- `GitLabCI`: Deploys documentation to GitLab Pages with the help of GitLabCI.
- `NoDeploy` (default): Does not set up documentation deployment.

**Keyword Arguments**

- `make_jl`: Template file for make.jl.
- `index_md`: Template file for index.md.
- `assets`: Extra assets for the generated site.
- `logo`: A Logo containing documentation logo information.
- `devbranch`: Branch that will trigger docs deployment. If nothing, then the default branch according to the Template will be used.
- `makedocs_kwargs`: Extra keyword arguments to be inserted into makedocs.
"""

# ╔═╡ 50bc3ea4-77c8-480c-a071-b03616a3a68b
md"""
#### Tests
```julia
Tests(;
    file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/test/runtests.jlt",
    project=false,
    aqua=false,
    aqua_kwargs=NamedTuple(),
    jet=false,
)
```

Sets up Julia testing suite.

**Keyword Arguments**

- `file`: Template file for runtests.jl.
- `project::Bool`: Whether or not to create a new project for tests (`test/Project.toml`). See the Pkg docs for more details.
- `aqua::Bool`: Controls whether or not to add quality tests with [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl).
- `jet::Bool`: Controls whether or not to add a linting test with [JET.jl](https://github.com/aviatesk/JET.jl) (works best on type-stable code)

"""

# ╔═╡ 547cf7e1-cb42-4778-8c02-912a825a6b28
md"""
#### License

```julia
License(; name="MIT", path=nothing, destination="LICENSE")
```

Creates a license file.

**Keyword Arguments**

- `name`: Name of a license supported by PkgTemplates. Available licenses can be seen [here](https://github.com/JuliaCI/PkgTemplates.jl/tree/master/templates/licenses).
- `path`: Path to a custom license file. This keyword takes priority over name.
- `destination`: File destination, relative to the repository root. For example, "LICENSE.md" might be desired.
"""

# ╔═╡ 573333e5-a3a0-48b1-9e5b-317fa2f48790
md"""
#### Git

```julia
Git(;
    ignore=String[],
    name=nothing,
    email=nothing,
    branch=LibGit2.getconfig("init.defaultBranch", "main")
    ssh=false,
    jl=true,
    manifest=false,
    gpgsign=false,
)
```

Creates a Git repository and a .gitignore file.

**Keyword Arguments**

- `ignore::Vector{<:AbstractString}`: Patterns to add to the .gitignore. See also: gitignore.
- name`: Your real name, if you have not set user.name with Git.
- `email`: Your email address, if you have not set user.email with Git.
- `branch`: The desired name of the repository's default branch.
- `ssh::Bool`: Whether or not to use SSH for the remote. If left unset, HTTPS is used.
- `jl::Bool`: Whether or not to add a .jl suffix to the remote URL.
- `manifest::Bool`: Whether or not to commit Manifest.toml.
"""

# ╔═╡ c78aa780-7bd4-4267-97f5-1d7f6b839f06
md"""
#### GitHubActions

```julia
GitHubActions(;
    file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/github/workflows/CI.yml",
    destination="CI.yml",
    linux=true,
    osx=false,
    windows=false,
    x64=true,
    x86=false,
    coverage=true,
    extra_versions=["1.6", "1.11", "pre"],
)
```

Integrates your packages with [GitHub Actions](https://github.com/features/actions).

**Keyword Arguments**

- `file`: Template file for the workflow file.
- `destination`: Destination of the workflow file, relative to .github/workflows.
- `linux::Bool`: Whether or not to run builds on Linux.
- `osx::Bool`: Whether or not to run builds on OSX (MacOS).
- `windows::Bool`: Whether or not to run builds on Windows.
- `x64::Bool`: Whether or not to run builds on 64-bit architecture.
- `x86::Bool`: Whether or not to run builds on 32-bit architecture.
- `coverage::Bool`: Whether or not to publish code coverage. Another code coverage plugin such as Codecov must also be included.
- `extra_versions::Vector`: Extra Julia versions to test, as strings or VersionNumbers.
"""

# ╔═╡ be7f5295-efd6-4801-b943-c2fd1709e19b
md"""
#### CompatHelper

```julia
CompatHelper(;
    file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/github/workflows/CompatHelper.yml",
    destination="CompatHelper.yml",
    cron="0 0 * * *",
)
```

Integrates your packages with [CompatHelper](https://github.com/JuliaTesting/CompatHelper.jl) via GitHub Actions.

**Keyword Arguments**

- `file`: Template file for the workflow file.
- `destination`: Destination of the workflow file, relative to .github/workflows.
- `cron`: Cron expression for the schedule interval.

!!! note

   If using coverage plugins, don't forget to manually add your API tokens as secrets, as described here.
"""

# ╔═╡ dde5a92d-2912-4d2a-8ff3-adc65fe39ca5
md"""
#### TagBot

```julia
TagBot(;
    file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/github/workflows/TagBot.yml",
    destination="TagBot.yml",
    trigger="JuliaTagBot",
    token=Secret("GITHUB_TOKEN"),
    ssh=Secret("DOCUMENTER_KEY"),
    ssh_password=nothing,
    changelog=nothing,
    changelog_ignore=nothing,
    gpg=nothing,
    gpg_password=nothing,
    registry=nothing,
    branches=nothing,
    dispatch=nothing,
    dispatch_delay=nothing,
)
```

Adds GitHub release support via [TagBot](https://github.com/JuliaRegistries/TagBot).

**Keyword Arguments**

- `file`: Template file for the workflow file.
- `destination`: Destination of the workflow file, relative to .github/workflows.
- `trigger`: Username of the trigger user for custom registries.
- `token`: Name of the token secret to use.
- `ssh`: Name of the SSH private key secret to use.
- `ssh_password`: Name of the SSH key password secret to use.
- `changelog`: Custom changelog template.
- `changelog_ignore`: Issue/pull request labels to ignore in the changelog.
- `gpg`: Name of the GPG private key secret to use.
- `gpg_password`: Name of the GPG private key password secret to use.
- `registry`: Custom registry, in the format owner/repo.
- `branches`: Whether not to enable the branches option.
- `dispatch`: Whether or not to enable the dispatch option.
- `dispatch_delay`: Number of minutes to delay for dispatch events.
"""

# ╔═╡ 9c749bd8-6a6c-460c-869c-73c5debbf491
md"""
#### Formatter

```julia
Formatter(;
    Formatter(;
        file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/.JuliaFormatter.toml",
        style="nostyle"
    )
```

Create a .JuliaFormatter.toml file, used by JuliaFormatter.jl and the Julia VSCode extension to configure automatic code formatting.

This file can be entirely customized by the user, see the JuliaFormatter.jl docs.

**Keyword Arguments**

- `file::String`: Template file for .JuliaFormatter.toml.
- `style::String`: Style name, defaults to "nostyle" for an empty style but can also be one of ("sciml", "blue", "yas") for a fully preconfigured style.
"""

# ╔═╡ 1179a323-17ab-4c40-ad91-15f66300b66c
md"""
#### Secret

```julia
Secret(name::AbstractString)
```

Represents a GitHub repository secret. When converted to a string, yields ${{ secrets.<name> }}.
"""

# ╔═╡ f4004bd1-0bb9-471d-9415-0ef97bda32a6
md"""
#### Dependabot

```julia
Dependabot(; file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/github/dependabot.yml")
```

Setups Dependabot to create PRs whenever GitHub actions can be updated. This is very similar to CompatHelper, which performs the same task for Julia package dependencies.
Only for GitHub actions

Currently, this plugin is configured to setup Dependabot only for the GitHub actions package ecosystem. For example, it will create PRs whenever GitHub actions such as uses: actions/checkout@v3 can be updated to uses: actions/checkout@v4. If you want to configure Dependabot to update other package ecosystems, please modify the resulting file yourself.

**Keyword Arguments**

- `file`: Template file for dependabot.yml.
"""

# ╔═╡ 724a2884-c574-40dc-9a8f-4a4b4f49a823
md"""
#### Code Coverage

These plugins will enable code coverage reporting from CI.

```julia
Codecov(; file=nothing)
```

Sets up code coverage submission from CI to Codecov.

**Keyword Arguments**

- `file`: Template file for .codecov.yml, or nothing to create no file.
"""

# ╔═╡ 8595eabb-a3e2-4f25-81ec-6b9f51ff9085
md"""
#### Coveralls

```julia
Coveralls(; file=nothing)
```

Sets up code coverage submission from CI to Coveralls.

**Keyword Arguments**

- `file`: Template file for .coveralls.yml, or nothing to create no file.
"""

# ╔═╡ ec2c9bad-c812-4146-8bf1-15e9d84f4086
md"""
#### Logo

```julia
Logo(; light=nothing, dark=nothing)
```

Logo information for documentation.

**Keyword Arguments**

- `light::AbstractString`: Path to a logo file for the light (default) theme.
- `dark::AbstractString`: Path to a logo file for the dark theme.
"""

# ╔═╡ 5582c1a8-5033-427b-8421-8693106ed724
md"""
#### Badges

These plugins will add badges to the README.

```julia
BlueStyleBadge()
```

Adds a BlueStyle badge to the Readme file.

```julia
ColPracBadge()
```
"""

# ╔═╡ bacfb9dc-beda-45eb-80ff-ff4d6de10b2c
md"""
#### PkgBenchmark

```julia
PkgBenchmark(; file="~/work/PkgTemplates.jl/PkgTemplates.jl/templates/benchmark/benchmarks.jlt")
```

Sets up a `PkgBenchmark.jl` benchmark suite.

!!! note

   To ensure benchmark reproducibility, you will need to manually create an environment in the benchmark subfolder (for which the Manifest.toml is committed to version control). In this environment, you should at the very least:
```julia
pkg> add BenchmarkTools
pkg> dev your new package.
```

**Keyword Arguments**

- `file`: Template file for benchmarks.jl.

"""

# ╔═╡ caeece1e-7f23-4946-a87d-6aa2d0bd6c2e
md"""
# Following steps (on VS Code)
1. **Edit the Source Code**
2. **Build the Package**
```julia
pkg> add <deps>
```
3. **Import and Run the new Package**
```julia
using DataAnalyzer

data = get_data("data.csv")
processed = process_data(data)
results = analyze_results(processed)
plot = plot_analysis(results)
savefig(plot, "analysis_results.png")

println("Total samples processed: $(results.total_samples)")
println("Anomaly rate: $(round(results.anomaly_rate * 100, digits=2))%")
```
4. **Run `tests` locally**
```julia
pkg> test
```
5. **Build `docs` locally**
```julia
pkg> activate docs
pkg> dev .
pkg> instantiate
julia> include("docs/make.jl")
```
6. **Create GitHub Repository**
```bash
git remote add origin https://github.com/username/DataAnalyzer.jl.git
git push -u origin main
```

7. **Setup docs to be deployed on GitHub**
```julia
using DocumenterTools
DocumenterTools.genkeys(user="YourGitHubUsername", repo="DataAnalyzer.jl")
```
8. **Test Continuous Integration**
   * GitHub Actions automatically set up
   * Tests run on each push
   * Documentation builds automatically
"""

# ╔═╡ 5beb3205-1b2c-4af7-bea4-7b794198ecd0
md"""
# Further steps
### Register Your Package in the General Registry

1. **Review the [General registry README](https://github.com/JuliaRegistries/General#readme) for package registration rules**

2. **Install and Use [Registrator.jl](https://github.com/JuliaRegistries/Registrator.jl?tab=readme-ov-file):**
   * If your package is on GitHub, install the [JuliaRegistrator GitHub App](https://github.com/apps/juliateam-registrator/installations/new).
   * Otherwise, manually trigger the registration by running:
```julia
using Registrator
Registrator.register()
```

3. **Submit to the General Registry**

   * Once registered, a pull request will be automatically opened in the [General registry](https://github.com/JuliaRegistries/General)
   * Wait for the automated checks (RegistryCI) to pass.

4. **Register a New Release**

   * When releasing a new version, tag a new release in your repo and trigger registration again with:
```bash
@JuliaRegistrator register
```
   * Ensure the version follows Semantic Versioning ([SemVer](https://semver.org/)).
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PkgTemplates = "14b8a8f1-9102-5b29-a752-f990bacb7fe1"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PkgTemplates = "~0.7.53"
PlutoUI = "~0.7.60"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.3"
manifest_format = "2.0"
project_hash = "951dfa78ea432f57b45af933bbb113a35564ff8b"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.Mocking]]
deps = ["Compat", "ExprTools"]
git-tree-sha1 = "c74e5e7c5f83ccb0bca0377d316d966d296106d4"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.7.9"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.Mustache]]
deps = ["Printf", "Tables"]
git-tree-sha1 = "3b2db451a872b20519ebb0cec759d3d81a1c6bcb"
uuid = "ffc61752-8dc7-55ee-8c37-f3e9cdd09e70"
version = "1.0.20"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PkgTemplates]]
deps = ["Dates", "InteractiveUtils", "LibGit2", "Mocking", "Mustache", "Parameters", "Pkg", "REPL", "UUIDs"]
git-tree-sha1 = "18626dfafdd45a49c47b66071498d75ab08633f7"
uuid = "14b8a8f1-9102-5b29-a752-f990bacb7fe1"
version = "0.7.53"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─a1cb9035-bc71-499c-a7c3-d1849e3cd1c1
# ╟─05354553-276a-4704-bd03-521b82930eed
# ╟─38190363-c465-44b3-ac13-86494cfd42df
# ╟─f6a4c98e-dfff-4509-aba7-30e2fa85f01c
# ╟─73b46039-fb67-441e-8466-8b1f7bdb2378
# ╟─a89366e8-d814-40b9-bd0b-94639fb558c8
# ╟─483d88a9-63b6-4fb5-8472-035e8853fa70
# ╟─44230292-5d72-44e8-8312-b41e486e2b8e
# ╟─b2ccfc77-f09c-46f2-b663-7e52ee2de763
# ╟─33761b97-5c9d-4040-8e7b-0dd56ff1c291
# ╟─4394867b-9381-4202-8096-aeaac609994e
# ╟─077eefbd-f841-4086-831e-4b305ede64d2
# ╟─efbc9633-1323-468b-b24e-206a7202d9cf
# ╟─b5a44c38-ddc4-4f4e-999f-b924f02b8129
# ╟─4b7be614-57b1-498a-9e95-015d3e3a632d
# ╟─01026247-83f6-4de9-bdef-e031e49550b5
# ╟─32fa049a-20da-4459-bdba-6fd2561ce94a
# ╟─68c9dc19-e0b5-4336-af6b-72068a0caa24
# ╟─d66e576d-3d0f-4fa7-8415-ecd89c8d2071
# ╟─2cde9ac1-ed98-4175-81ac-4876f45d37e5
# ╟─732a65e4-d4a4-49ce-be9e-dbae6a765f79
# ╟─c89be673-c67e-430b-970f-21f3d140f707
# ╟─dfc89dbf-8444-4181-8c2b-99ba543a686d
# ╟─0a1618ac-07d4-41c3-9b7a-f0d30c4ab38e
# ╟─50bc3ea4-77c8-480c-a071-b03616a3a68b
# ╟─547cf7e1-cb42-4778-8c02-912a825a6b28
# ╟─573333e5-a3a0-48b1-9e5b-317fa2f48790
# ╟─c78aa780-7bd4-4267-97f5-1d7f6b839f06
# ╟─be7f5295-efd6-4801-b943-c2fd1709e19b
# ╟─dde5a92d-2912-4d2a-8ff3-adc65fe39ca5
# ╟─9c749bd8-6a6c-460c-869c-73c5debbf491
# ╟─1179a323-17ab-4c40-ad91-15f66300b66c
# ╟─f4004bd1-0bb9-471d-9415-0ef97bda32a6
# ╟─724a2884-c574-40dc-9a8f-4a4b4f49a823
# ╟─8595eabb-a3e2-4f25-81ec-6b9f51ff9085
# ╟─ec2c9bad-c812-4146-8bf1-15e9d84f4086
# ╟─5582c1a8-5033-427b-8421-8693106ed724
# ╟─bacfb9dc-beda-45eb-80ff-ff4d6de10b2c
# ╟─caeece1e-7f23-4946-a87d-6aa2d0bd6c2e
# ╟─5beb3205-1b2c-4af7-bea4-7b794198ecd0
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
