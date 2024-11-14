### A Pluto.jl notebook ###
# v0.20.3

#> [frontmatter]
#> title = "Working with Julia everyday - (An introduction)"
#> date = "2024-11-13"

using Markdown
using InteractiveUtils

# ╔═╡ a1cb9035-bc71-499c-a7c3-d1849e3cd1c1
begin
	using PlutoUI
	using MethodAnalysis
	using BenchmarkTools
	using StaticArrays
	TableOfContents(title="📚 Table of Contents")
end

# ╔═╡ b4ad08f8-e292-4791-9cf0-a7f77cb32265
using LinearAlgebra

# ╔═╡ 642af113-3dbf-4d0c-885d-bfb7fc162d05
using Profile

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
#### Working with Julia everyday
##### Princeton Julia User Group, Nov 13, 2024
""")
	end

	TwoColumn(Resource("https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Princeton_seal.svg/800px-Princeton_seal.svg.png"),Resource("https://julialang.org/assets/infra/logo.svg"))
end

# ╔═╡ 38190363-c465-44b3-ac13-86494cfd42df
md"""
# Outline
* Setting up VS Code to run Julia on a cluster
* Recap on functions
* Multiple dispatch
* Benchmarking with BenchmarkTools.jl
* Profiling with Profile.jl
* Abstract vs Concrete types
* Bonus topics ("advanced")
  - Compiler optimization 
  - More on multiple dispatch
"""

# ╔═╡ 1e908967-7c5d-43b4-bf13-dee6c6a2440a
md"""
# VS Code on the cluster
"""

# ╔═╡ cf398441-18d1-4a35-a935-3b86746cc654
md"""
One possible way to use Julia, VS Code, and a supercomputer together is to edit files locally in VS Code, then log into the cluster via a terminal to run the code. However, this approach doesn’t allow users to take advantage of all the useful features provided by the [Julia extension for VS Code](https://www.julia-vscode.org/).

The following instructions explain how to connect VS Code to a server component **running on the cluster** while keeping the GUI local. This setup enables the following components to run directly on the cluster:

- Julia VS Code extension and Integrated REPL
- Inline evaluation
- Debugger
- Plot panel
- Profiler
- etc..
"""

# ╔═╡ c796346f-09dc-4b29-928c-03e0e44e79bb
md"""
### 1. Launch VS Code on a login node
- Ensure that the `Remote - SSH` extension is installed.
- Press `F1` and run the `Remote-SSH: Open SSH Host...` command.
- Select a configured SSH host or manually enter `user@host`.
"""

# ╔═╡ 1b3c1832-9ac5-454d-a56c-07f8b797c058
md"""
### 2. Install the Julia extension on the VS Code server
- Open the extensions view (press `CTRL/CMD + SHIFT + X`).
- Search for julia.
- Click on `install`.
"""

# ╔═╡ 336a1020-dff1-428b-b56a-85cab33a5a31
md"""
### 3. Create a script to load and run Julia
- Create a script (e.g., called `julia_wrapper.sh`) with the following content. Each user may need to modify the section regarding the module command and the Julia version to be loaded in VS Code:
```bash
#!/bin/bash

# Make the module command available (this part is system-specific and can be uncommented and adjusted if needed)
# ------------------------------------------------------------
# export MODULEPATH=/etc/modulefiles:/usr/share/modulefiles
# export LMOD_SYSTEM_DEFAULT_MODULES="DefaultModules"
# source /usr/share/lmod/lmod/init/profile
# module --initial_load restore
# ------------------------------------------------------------

# Edit this part with the correct Julia version
# Load julia
module load julia/1.11.1

# Pass on all arguments to julia
exec julia "${@}"
```
"""

# ╔═╡ 2eb0ca4d-fe50-4d17-ad18-419402c86105
md"""
- Make the wrapper script executable: `chmod +x julia_wrapper.sh`
- Test that it works: `./julia_wrapper.sh`.
The last command should open the Julia REPL.
"""

# ╔═╡ 10377bc0-6487-4c8c-bc18-d75102e75bcc
md"""
### 4. Modify the Julia VS Code extension to point to the new file `julia_wrapper.sh`:
- Open the VS Code Settings (press `CTRL/CMD+,`).
- Click on the tab Remote [SSH: user@host].
- Search for Julia executable.
- Paste `/path/to/julia_wrapper.sh` into the text field under `Julia: Executable Path`.
"""

# ╔═╡ b60da347-65c4-43c4-abe2-38cf4fd7809e
md"""
### 5. Test the setup
If `ALT/OPTION + J` followed by `ALT/OPTION + O` (or pressing `F1` and executing `Julia: Start REPL`) successfully spins up the integrated Julia REPL, you know that the setup is working! 🎉
"""

# ╔═╡ 6b4ccd0d-b388-4399-82fa-8aad04c568f6
md"""
# Recap on functions
"""

# ╔═╡ 91068124-19e5-46d6-a2e0-c72e3def9765
md"""
In the previous talk, Colin introduced functions, which you can think of as the building blocks of your Julia code. We covered at least three different ways to define a function:
"""

# ╔═╡ f220d143-ffee-450e-bf90-b18519fb32ca
begin
	
	function say_it(s)
		println(s)
	end
	
	say_it(s) = println(s) # "assignment form"
	
	say_it(s) = begin
		println(s)
	end
	
end

# ╔═╡ 5534d191-6987-47d2-b623-fa6440feb43a
md"""
Colin also asked us the following questions:
- How do we know it's a function?
- What variables can be passed inside those parentheses?
"""

# ╔═╡ 39561c09-014d-4ac7-9939-d304a99e242a
md"""
We learned that what truly defines a function is the parentheses. In fact, functions in Julia are simply objects that map a tuple of argument values to a return value.
"""

# ╔═╡ fba5cc44-ee93-4474-8b0e-9807aa8bef72
md"""
It turns out that we can pass almost *anything* to the above function:
"""

# ╔═╡ 81ad049c-60ed-44bb-981b-d73bacc7fc71
say_it(1)	# Int

# ╔═╡ 057918e4-bf3a-486c-af97-bcbcbc3db8d9
say_it("hello")	# String

# ╔═╡ ef9b59a4-a0a5-41ce-8e54-2fdc23250b94
say_it(π) # Irrational number

# ╔═╡ 287f3b35-5f21-48c3-92f9-cde900b1001f
say_it(typeof(π))	# DataType

# ╔═╡ 688b78e6-c84f-4189-bc99-a96dbedea361
md"""
Julia is a **dynamically-typed language** with a **just-in-time compiler**. This means that every variable has a type and a value, and every function parameter has a type. The type can be specified using the double colon `::` symbol. If you omit the type, the parameter is implicitly typed as `Any`. So, the signature of our function is really:
```julia
function say_it(s::Any) end
```
"""

# ╔═╡ bb3c1915-1561-4f39-b777-1b19ff5da879
md"""
where `Any` represents the union of all types (the top-level supertype in Julia):
"""

# ╔═╡ 96a9b37e-e12d-4ce2-9a59-808f655eb91f
Int <: Any

# ╔═╡ 91b854ef-a215-4a54-a725-4606026e4f54
md"""
!!! note
	The `<:` operator represents an *is-a-subtype-of* relationship, and is used to determine whether a type is a subtype of another type. 
"""

# ╔═╡ 739d26cd-bb28-4b29-98f8-9b38b77ce7e7
isa(42, Any)

# ╔═╡ dc3bfbee-6884-4b59-8b89-c6a3c77609ef
md"""
!!! note
	The `isa()` function is used to check if a `value` is of a given type.  
"""

# ╔═╡ 181da10f-b6c4-4125-9e98-da730d8b60e2
String <: Any

# ╔═╡ 1633d744-57e1-48c9-8bc9-661b0b3524e8
isa('∞', Any)

# ╔═╡ 32d76a1c-f5a6-4fe5-acfc-3bb8345b18f6
isa(Inf, Any)

# ╔═╡ 333838f2-78af-43c5-9e18-0f722bd6508a
Union{Float64, String} <: Any

# ╔═╡ 18a1cff8-e9a0-4a1a-a1bb-5f4770f2c17d
Any <: Any

# ╔═╡ faa9c65f-849a-43a7-a4e9-1455d455c85d
md"""
And the number of subtypes of `Any` in the current scope is:
"""

# ╔═╡ 7e512d0a-3363-48e6-b277-513f3b220e45
length(subtypes(Any))

# ╔═╡ 1a0badaa-6aaa-49d6-8003-b04cb3bda7d0
md"""
Another example:
```julia
square(x::Int64) = x*x
```
"""

# ╔═╡ fd41a885-9c79-42e6-86e3-8242dbc987ca
md"""
!!! tip
	In Julia, there's a deep connection between functions, argument types, and compilation/performance. Throughout this talk, I hope to give you an idea of how important this connection is.
"""

# ╔═╡ 14fdce30-0957-412e-a6b0-28a8521a8fdf
md"""
Functions in Julia are considered **first-class citizens**, meaning they can be treated like any other data type, giving them the same flexibility as numbers or strings within the language.
- **Assignment to variables**: You can assign a function directly to a variable and use it later.
- **Passing as arguments**: Functions can be passed as arguments to other functions, enabling higher-order functions.
- **Returning as values**: Functions can be returned as the result of another function.
**Anonymous functions**: Julia supports creating anonymous functions using arrow notation, enhancing functional programming capabilities.
"""

# ╔═╡ 1fbe6ba4-e695-4b6e-9370-835f1d9d0a26
md"""
For example, we can write functions that call other functions passed as arguments:
"""

# ╔═╡ a637e98e-2657-4772-9a4d-d8f7157b0d0d
function apply_it!(f::Function, x::Vector)
    for (idx, val) in enumerate(x)
        x[idx] = f(val)
    end
    return x
end

# ╔═╡ 5b0c006e-a9ff-4379-a705-a2c61be92066
x = apply_it!(x -> 2x, [1, 1//2, π])

# ╔═╡ bfad4d98-e773-4308-9d47-298d76c51397
md"""
In this example, the anonymous function `x -> 2x` is used to double each element of the array. This is a common use case for anonymous functions in Julia: whenever you need a quick, throwaway function that doesn't require a full definition.

They are often used in functions like `map`, `filter`, or `sort`, where you want to apply a simple operation without the need to create a separate named function. 
"""

# ╔═╡ 9cbcefc4-54fc-4dd1-9d8f-5afe3861d300
md"""
In Julia, we can also write functions that return other functions (e.g., closures):
"""

# ╔═╡ 951e5c1f-4b33-462a-b801-9de0a1bfbf82
begin
	function multiplier(factor)
	    return x -> x * factor  # anonymous function that captures 'factor'
	end
	
	times_two = multiplier(2)
	times_three = multiplier(3)
end

# ╔═╡ 8201012e-7bab-4eea-b401-800b54c76ca3
times_two(5)

# ╔═╡ e0a083f0-3214-4d53-b8f5-b20ae38c3a0e
times_three(5)

# ╔═╡ fefffb76-6afb-4a5b-ab46-8d2b34c3d5fb
md"""
# Multiple dispatch
"""

# ╔═╡ 0c5376b2-dfde-44cf-a3e0-d1b99f6afa60
md"""
Multiple dispatch is arguably one of the most important features of Julia.

Let's start with an example. Imagine we need to write a function that sums two variables, but we want this function to **behave** differently based on the types of those variables.

One approach is as follows:
"""

# ╔═╡ c762f98c-c04e-465a-ae0d-b1352fcdeb0c
function sum_elements_ifelse(x, y)
	if isa(x, Number) && isa(y, Number) 
		return x+y
	elseif typeof(x) == typeof(y) == String
		return string(x, y)
	elseif isa(x, Array) && isa(y, Array) 
		return vcat(x, y)
	elseif isa(x, Number) && isa(y, String)
		return string(x, y)
	else
		return @warn "Method not implemented for $(x) of type $(typeof(x)) and $(y) of type $(typeof(y))"
	end
end

# ╔═╡ 4a6b9a63-3adc-4a13-b229-86dc610fed30
sum_elements_ifelse(1,2)

# ╔═╡ 3db269c8-57db-4768-a92c-bf64abac727d
sum_elements_ifelse("Hello","World")

# ╔═╡ 73b7abdb-ab9a-4f1c-a6c6-e9e56a17e42a
sum_elements_ifelse([1, 2], [3, 4])

# ╔═╡ e62043ba-33c7-49aa-8176-148bc209328c
sum_elements_ifelse(42, " is the answer")

# ╔═╡ fbe3aa11-91bf-416f-95b2-90c204518a28
sum_elements_ifelse(42, [1,2])

# ╔═╡ e1ada0b1-14a2-41bd-ae54-cf84f3f9a0e2
md"""
## Julian way!
Julia allows you to define multiple **methods** for a single function. Each method can be *tailored* to specific argument types, and Julia automatically selects the correct one at runtime. 

Therefore, the Julia version of `sum_elements_ifelse` above would look like this:
"""

# ╔═╡ 65d842f3-cfc0-40d7-93bc-724c5bd47332
sum_elements(x::Number, y::Number) = x + y

# ╔═╡ 4a3d0dd1-ff79-4251-9e01-b7b8a1a8cadf
sum_elements(x::String, y::String) = string(x, y)

# ╔═╡ 5004335e-d8b6-4d0f-829e-6be42c49b866
sum_elements(x::Array, y::Array) = vcat(x, y)

# ╔═╡ 5cb429c4-90cc-4853-b376-e55063d83304
sum_elements(x::Number, y::String) = string(x, y)

# ╔═╡ 76debf33-cd34-4b2d-a236-f1d4f26a8e1d
sum_elements(x, y) = @warn "Method not implemented for $(x) of type $(typeof(x)) and $(y) of type $(typeof(y))"

# ╔═╡ 25ebe2f7-0094-4ae6-bd29-a5f88214920c
sum_elements(5, 3)

# ╔═╡ 981bfa0e-eb67-45fb-ac34-5be4482711b2
sum_elements("Hello, ", "World!")

# ╔═╡ 8a268f53-550f-46d8-9e48-47b4fdfa6287
sum_elements([1, 2], [3, 4])

# ╔═╡ 37543da1-cc86-48f1-ba38-097baed20cef
sum_elements(42, " is the answer")

# ╔═╡ 3b9e1319-f665-4e41-a918-5de8410baff4
sum_elements(42, [1,2])

# ╔═╡ 1329aa06-a55c-4a24-85c0-57c58a599455
md"""
You can check which method will be called using the **@which** macro:
"""

# ╔═╡ f4b1dcf7-0c81-473d-ad1f-6b04ed937f9a
display(@which sum_elements(5, 3))

# ╔═╡ 53b3bfb1-6868-45b8-9f19-58eeaf44d5f3
display(@which sum_elements("a", "b"))

# ╔═╡ a90fd2b1-2346-4024-93fc-e6b4ebc3872a
md"""
This design enables Julia code to be both expressive and efficient, eliminating the need for verbose `if-else` checks and optimizing performance.
"""

# ╔═╡ 3a54e9eb-f576-497c-a9d8-8dd6827afb16
md"""
Now that we've seen some examples, let's summarize with a couple of definitions:
"""

# ╔═╡ 51d76486-1566-4d15-adfd-d2b1e323d032
md"""
!!! tip "Definition (Dispatch)"
	* The choice of which method to execute when a function is applied is called *dipatch*.

	* Depending on the *types* of the arguments, the appropriate method is dispatched and executed.
"""

# ╔═╡ 2e63646c-387c-42c5-b5c9-786460326cb7
md"""
!!! tip "Definition (Multiple Dispatch)"
	- Multiple dispatch means that this selection process considers the types of **all arguments**. 
	- This approach allows Julia to dynamically choose the most **specific** and **suitable** method for a given set of argument types, making code both powerful and flexible.
"""

# ╔═╡ 55389bfb-dfe9-4a36-8f73-68bd8c64c33e
md"""
## Pros of multiple dipatch
- Method specialization
- Expressing generic code/algorithms (massive code reuse)

As seen above, one of the main benefits of multiple dispatch is *method specialization*: Julia can generate highly efficient, type-specific code depending on the arguments being passed.

However, perhaps surprisingly, multiple dispatch also allows users to express **generic code**. For example, let's imagine we define a new algorithm, `inner_sum`, as follows:
"""

# ╔═╡ 6ef8e678-0f79-4749-b948-61d1f90dd4e1
md"""
where:
"""

# ╔═╡ 2aea8765-68ac-4b4e-bb2d-4a44247f7dfb
inner(v, A, w) = dot(v, A*w)

# ╔═╡ b32a8371-a44a-4be0-8de7-e4c8a14ec815
function inner_sum(A, vs)
	t = zero(eltype(A))
	for v in vs
		t += inner(v, A, v)
	end
	return t
end

# ╔═╡ 86e8f333-a732-4be5-ada8-b00fa856eab5
md"""
In the function above, we haven't specified anything about the types of `A` and `vs`—we might assume they could be matrices or vectors, but the function remains entirely general.

In fact, let's try it out:
"""

# ╔═╡ a33f07b6-d3c7-4995-adc0-31563798c71a
A = rand(4,4)

# ╔═╡ d5801c32-ae29-48e4-93a3-5b01e4a0cece
vs = [rand(4) for _ = 1:4]

# ╔═╡ 92b6f114-82a6-4ce1-9ea8-2924cc42ff75
inner_sum(A, vs)

# ╔═╡ 011e826e-22d5-408b-bfdc-8e37b1023589
md"""
It works!
"""

# ╔═╡ 0f92cf9a-4e09-4695-a78f-1e4b6c7ebc3e
md"""
Why is this so powerful?
"""

# ╔═╡ 3e0b7ccd-9f1e-474c-bdbe-096ace466c36
md"""
The crucial point here is that if, in one of our packages, we define a new custom vector type, the algorithm above will work seamlessly, as long as a `dot` function exists for the elements of this new vector type and a matrix (we're assuming that the new vector type implements a `Base.iterate` function so it can be looped over, but this seems like a fair assumption). No changes or imports are needed—it will 'just run.'

This capability allows users to overload functions and extend types in a highly flexible way without, for example, re-defining or wrapping types into new ones. This enables massive code reuse and adaptability.
"""

# ╔═╡ d2f43d65-ba19-446b-9d1e-d52682f224f4
md"""
# Benchmarking with BenchmarkTools.jl
"""

# ╔═╡ 6aecfd4d-29c7-4462-92c3-1d347ce18415
md"""
The **BenchmarkTools** pkg provides a framework for benchmarking Julia code.
The simplest way to run a benchmark is by using the `@benchmark` macro.
"""

# ╔═╡ 597b75ca-5ed1-42ec-87b9-9556ffdc3018
md"""
First, let's import the package:
"""

# ╔═╡ c1c7c241-4399-4bc5-af32-3899914798f2
md"""
```julia
using BenchmarkTools
```
"""

# ╔═╡ da795cba-4090-4acb-820c-4718710c96b4
@benchmark sin(0.42)

# ╔═╡ 2679f078-c100-4ba0-8ee6-5aec0affb550
md"""
!!! tip "Important: Variable interpolation"
	When passing variables to a function being evaluated, make sure to interpolate the variable with a `$` symbol into the benchmark expression. Any expression that is interpolated in such a way is "pre-computed" before the benchmarking begins.
"""

# ╔═╡ 06b21c20-bed3-416b-b367-501da230db13
md"""
For example:
"""

# ╔═╡ f494c589-23ed-4ad8-ad32-2a0a3f7b2ae3
# rand(1000) is executed for each evaluation
@benchmark sum(rand(1000))

# ╔═╡ 278f5906-ee71-4ae9-8e90-c9a0476a9ea1
md"""
and the `rand(1000)` is executed for each evaluation, and therefore is part of the benchmark.

On the other hand:
"""

# ╔═╡ 8f4f47ce-8fbf-4762-90a1-62563d44cfc2
# rand(1000) is evaluated at definition time, and the resulting
# value is interpolated into the benchmark expression
@benchmark sum($(rand(1000)))

# ╔═╡ be44a7b0-1a14-4a93-a955-c02efd833654
md"""
In this case, `rand(1000)` is evaluated at definition time, and the resulting value is interpolated into the benchmark expression. Note, for example, the different values for `memory estimate` and `allocs estimate`.
"""

# ╔═╡ 77a23437-fc27-4b54-aa97-22aa8d4e3811
md"""
Variables can be passed to functions being benchmarked either using the `$` symbol:
"""

# ╔═╡ c762aa8c-f1b4-410e-b590-953db7dfba3b
x1 = rand()

# ╔═╡ 1d5f4c74-b828-4a9b-91b8-eea2735dd74b
@benchmark sin($x1)

# ╔═╡ cdd4160d-5373-460c-91dd-881dc1b78ab0
md"""
Or by using the `setup` expression, which is run once per sample and is not included in the timing results:
"""

# ╔═╡ 99f71c13-8ee6-4090-ba84-4936b7fcaae0
@benchmark sin(x) setup=(x=rand())

# ╔═╡ a146a071-ca64-4219-8be3-5c02c21ae1f9
md"""
Another example:
"""

# ╔═╡ c8a6a52c-ff71-433f-8731-66d0b655eee4
A_bench = rand(1000);

# ╔═╡ c46ffb04-98a1-4596-b8fb-a96a9c644214
# BAD: A is a global variable in the benchmarking context
@benchmark [i*i for i in A_bench]

# ╔═╡ 60a4fc98-8894-4561-81e7-d216405337ab
# GOOD: A is a constant value in the benchmarking context
@benchmark [i*i for i in $A_bench]

# ╔═╡ cede4b42-0df6-4e37-b030-0548361d3196
md"""
The default parameters for the benchmark run are the following:
- `BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000`.
- `BenchmarkTools.DEFAULT_PARAMETERS.evals = 1`.
- The estimated loop overhead per evaluation in nanoseconds is automatically subtracted from every sample time measurement. 

Please check the [BenchmarkTools.jl manual](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/) for more information. 

Other useful macros provided by `BenchmarkTools.jl` include:
- `@btime`: prints the minimum time and memory allocation before returning the value of the expression.
- `@belapsed`: returns the minimum time in seconds.
"""

# ╔═╡ 7cf02ac4-4be6-45fb-afd3-91c42b15c10c
let
	M = rand(3,3);
	@btime inv($M);
end

# ╔═╡ a0b9fd18-93f5-45f1-8f66-e26f0bed9618
let
	M = rand(3,3);
	@belapsed inv($M);
end

# ╔═╡ 23638e0d-1d97-43b5-a37c-46e736158b31
md"""
## Let's have fun with types!
"""

# ╔═╡ 134c806e-1011-486e-b9b6-3080e137ee29
md"""
Now that we have a tool to measure performance, let's revisit our discussion on types and explore some other examples to understand why types and multiple dispatch are so important in Julia.
"""

# ╔═╡ 5a3d69a0-81d1-48a6-a721-d7e1c2b34a60
md"""
Let's define a simple function that sums the first two element of a colletion:
"""

# ╔═╡ e77851c0-2058-4b56-96a7-617b33bf7138
add2(x) = x[1] + x[2]

# ╔═╡ b1cb8f0c-8fce-4c40-a9ab-7e1e25d07e36
md"""
Let's call the function with different vector types:
"""

# ╔═╡ c9658f8e-56b1-4134-a138-4d8347013571
add2( [1.0, 2.0] )

# ╔═╡ 32cc3c25-b617-46fc-a5bf-e11604c5ea48
add2( [1, 2] )

# ╔═╡ f32c5fd9-d0ac-44eb-83f2-df7b6586fa1a
add2( (1, 2.0) )

# ╔═╡ 3e97e44b-1d90-4521-9bda-fb0907e01704
md"""
Every time the function is called with a new combination of arguments, Julia compiles that function. This can be verified using the `methodinstances` method provided by the `MethodAnalysis` package.
```julia
using MethodAnalysis
```
"""

# ╔═╡ 0dc452aa-42ff-4a57-a8ee-03a3c9c47d43
m = @which add2( [1, 2] );

# ╔═╡ 1e222d41-201d-4534-be7c-0495f1caa582
display(methodinstances(m))

# ╔═╡ 9a6a6fae-01bb-44b8-a2d4-48dc03ce24ab
md"""
How do these three methods look? Do they have the same implementation?

Let's first benchmark them!
"""

# ╔═╡ 1ac04b89-221d-49d5-aa84-f487496da5fe
@btime add2( [1, 2] )

# ╔═╡ 1380d091-e036-4652-a787-16b10c2f5c11
@btime add2( [1.0, 2.0] )

# ╔═╡ 2c182ec8-4f26-4a2c-9480-3892a36c00e1
@btime add2( [1, 2.0] )

# ╔═╡ 675c8874-619d-40b6-9ddd-7ae75858c75d
md"""
As we can see, the last call is a bit slower... Can you guess why?

How about this one?
"""

# ╔═╡ a4fdee1d-61af-4147-b02f-48d0a2722c4f
@btime add2(z) setup=(x = rand(1:5); y = rand(); z = Any[x, y])

# ╔═╡ 08f3c075-b63f-4054-8d6f-f8e38dd9059e
md"""
And the following one?
"""

# ╔═╡ d4b96b21-3442-4dc7-8e76-e3974744e927
@btime add2( (1, 2.0) )

# ╔═╡ 06da45e0-305e-4ee3-9b38-f0e116ac5a16
md"""
Now we can ask ourselves, why is the **performance so different**?
"""

# ╔═╡ 9a908b88-bd2b-407f-b231-f34caea1dee8
md"""
To answer this question, we need to look more closely at the actual implementation of those functions. This, for example, can be done using the `@code_typed` macro:
"""

# ╔═╡ f19509dc-3f0a-4749-8d98-20407152fa7f
@code_typed optimize=false add2([1, 2])

# ╔═╡ f77d9c5d-3a32-4e92-ba1c-cbfb1fa0ffbd
@code_typed optimize=false add2([1.0, 2.0])

# ╔═╡ 5861a4fd-026e-4810-939e-96843135e975
@code_typed optimize=false add2((1, 2.0))

# ╔═╡ d94bf15d-2124-4046-b013-2671d5c56f70
@code_typed optimize=false add2(Any[1, 2.0])

# ╔═╡ b2c72d13-4f98-4851-bc71-1a345dcd4112
md"""
They all look very similar, apart from the different type annotations.

However, the magic happens when we turn the `optimize` flag on. Now we can look at the code that Julia actually sees after it has been compiled:
"""

# ╔═╡ 8535d9d7-cace-4974-9011-75bd5d02cf3d
@code_typed add2([1, 2])

# ╔═╡ 87bdb7b4-ec1a-4c93-b744-d59c9b5b59e4
md"""
The above is the `add2` method for a vector of `Int`s. We notice that at the bottom, Julia calls a `Base.add_int` function:
"""

# ╔═╡ 3690f82a-572c-4050-9cb8-bafcc12f28a6
@code_typed Base.add_int(1, 2)

# ╔═╡ 62b67a64-1e2c-47a8-9770-a1058f4e42ce
md"""
`Base.add_int` is an `IntrinsicFunction`:
- special type of function that is built directly into Julia's compiler. 
- not written in Julia itself but are recognized and handled specially by the compiler for optimal performance.
"""

# ╔═╡ 5b2bb110-bff0-4334-9339-2c63fec07a96
md"""
And the same is true for the `Float64` case:
"""

# ╔═╡ 04326f0e-f1a0-44de-aa19-f6265fb991d8
@code_typed optimize=true add2([1.0, 2.0])

# ╔═╡ febb8eab-1181-41c4-8125-90cea5ae6393
md"""
However, when using the `Vector{Any}` type, Julia cannot call a specific method and instead defaults to the generic `+` function, leading to a performance degradation:
"""

# ╔═╡ 2d51ada5-27ae-4c01-9e26-db272de779db
@code_typed optimize=true add2( Any[1, 2.0] )

# ╔═╡ 92104c31-2287-4006-b82c-478d712aec08
md"""
An interesting case is that of `Tuple`s:
"""

# ╔═╡ 5fca4aa0-adc8-465e-ba86-210400ff27af
@code_typed optimize=false add2( (1, 2.0) )

# ╔═╡ 8da57226-17ed-4bf9-bbf2-63af182b2882
@code_typed optimize=false 1 + 2.0

# ╔═╡ 74a4e24e-1f6b-4a95-b05b-b427363ac213
@code_typed optimize=true add2( (1, 2.0) )

# ╔═╡ 56501158-7f96-4aec-ae17-b09be04fbe51
md"""
Since `Tuple`s are immutable (their elements cannot be changed after the object is created), the compiler is certain that the status of the object won't be modified and can therefore remove all the bounds checks and other types of runtime checks that are required for mutable objects. This leads to an incredible boost in performance.
"""

# ╔═╡ 89143b43-f7ff-4679-b4fc-bc0dc9d5c8fa
md"""
!!! tip "Type Stability"
	In Julia, **type stability** refers to the property where the type of a variable or expression can be determined at compile time. This means that Julia can predict the type of the result of an expression based on its inputs without having to rely on runtime checks, allowing the compiler to generate more efficient machine code. Therefore, type stability helps improve performance by enabling more aggressive optimizations and reducing unnecessary runtime overhead.

To summarize, writing code that is type stable is crucial for performance. For this reason, the Julia standard library provides the `@code_warntype` macro to check for type instabilities:
"""

# ╔═╡ 14095145-333d-4a59-a901-1089b7576270
@code_warntype add2( Any[1, 2.0] )

# ╔═╡ bf7285f8-2673-4db3-9a39-418e10a4cd9b
md"""
# Profiling with Profile.jl
"""

# ╔═╡ 78b1965f-c35c-410d-90ce-b2fe8f1854c0
md"""
Now that we've covered benchmarking, let's shift gears and look at profiling. Profiling helps us understand where time is being spent during the execution of our code.

`Profile.jl` implements a "sampling" or statistical profiler. It works by **periodically taking a backtrace** during the execution of any task. Each backtrace captures the currently-running function and line number, along with the complete chain of function calls that led to this line. This snapshot provides insight into the current state of execution.

The **cost of a given line** is proportional to how often it appears in the set of all backtraces.
"""

# ╔═╡ c62b3db0-d8f7-4f7f-aeb2-9ea71f892976
md"""
Let’s now consider an example where we define a more computationally intense version of a `wait` function:
"""

# ╔═╡ a6a3cf09-2a6a-48c0-b2e2-5c615fbe7f89
function busywait(t)
    x = 0
    for i = 1:round(Int, 2.1e10*t)
        x += i % 2
    end
    return x    # return `x` to prevent the compiler from optimizing out
end

# ╔═╡ 8fc17d7c-c955-4137-9cec-0e70cd91029d
@time busywait(0.8)

# ╔═╡ 4ffec39c-14e3-49a9-8cf2-61c552d2e57b
md"""
This is the function we want to profile:
"""

# ╔═╡ 065a19e8-5123-470f-b4ee-fa0877c416b9
work() = busywait(0.08)

# ╔═╡ 3a5f88d6-4679-42b1-8d39-a6b9eaaa7f19
gym() = busywait(0.01)

# ╔═╡ 9932c4a0-b0aa-4493-9b95-b461f541e9d7
function mydays(n)
    x = 0
    for i = 1:n
        x += work()
        x += gym()
    end
    return x
end

# ╔═╡ d8e75787-912c-401c-af33-e651e068f254
md"""
These are the steps to profile the function:
"""

# ╔═╡ 64dbb83b-53c6-4e63-8a0c-55c2b89c4149
md"""
1. Compile the new function by calling it once:
"""

# ╔═╡ bd184ed2-dc99-417e-a083-0dc8c2092887
mydays(1)

# ╔═╡ 66625fe0-8b94-46eb-8c7f-ed1538db2cfa
md"""
2. Clear all old results (not really needed on the first usage):
"""

# ╔═╡ 3275a8bf-0290-421b-b237-62d8ed8d65ae
Profile.clear()     # clear old results (not really needed on the first usage)

# ╔═╡ dd7c511a-4f35-469e-822d-273206250e05
md"""
3. Use the @profile macro:
"""

# ╔═╡ c8acd0e9-b116-48a2-9930-7a2d48943786
@profile mydays(30)

# ╔═╡ e4c11da3-09f3-45f0-9732-db7027b88ba8
md"""
4a. Print the results ("flat"):
"""

# ╔═╡ c9633eeb-397d-463a-918f-87a22e644909
Profile.print(format=:flat)

# ╔═╡ ae62e3e3-4dfd-43c9-a9d2-211db4b01087
md"""
4b. Print the results ("tree"):
"""

# ╔═╡ 3ff238ac-055b-425f-9ee6-a4620e35bc4d
Profile.print(format=:tree)

# ╔═╡ 3a30c17b-462a-4c56-aca1-ade797591390
md"""
5. (optional) Write results to a file:
"""

# ╔═╡ 14a4b1eb-4dc8-4c22-b80a-76bbeedba58c
md"""
```julia
open("/tmp/prof.txt", "w") do s
    Profile.print(IOContext(s, :displaysize => (24, 500)))
end
```
"""

# ╔═╡ 597014e7-7f5b-45a6-894a-d1a728fa4313
md"""
A more complex example: let’s imagine we need a function that takes two matrices and a vector, and returns the product of these three objects:
"""

# ╔═╡ 8843e817-e60a-4f4b-b7c8-8e5efdfd22fa
function mult(A, B, x)
    C = A * B
    return C * x
end

# ╔═╡ dbbf309b-7d3c-42d3-b23f-65435c0aa178
𝑨 = rand(10000, 2)

# ╔═╡ dbb7dd6f-be4e-4d8f-bc6c-9066a8577706
𝑩 = rand(2, 8000)

# ╔═╡ d46eaf52-69a7-4071-ab44-64a491334662
𝒙 = rand(8000)

# ╔═╡ 2b46a437-6815-402c-b99a-950537243f56
@time mult(𝑨, 𝑩, 𝒙)

# ╔═╡ 8c593e78-01aa-4b23-a20f-63afcb16ea3b
@btime mult($𝑨, $𝑩, $𝒙)

# ╔═╡ 4fb0ad22-3d54-4208-b352-fa4a4b17eb73
@benchmark mult($𝑨, $𝑩, $𝒙)

# ╔═╡ d6f70278-35e6-4d42-ac98-a2085476960e
md"""
Okay, it works. Let's now profile it:
"""

# ╔═╡ 8c4658d8-4b73-4a1b-8753-337827af2228
Profile.clear()

# ╔═╡ 8eb5f067-b11b-477a-8738-53f7c7303547
@profile mult(𝑨, 𝑩, 𝒙)

# ╔═╡ df822850-7950-4a7b-8b2f-86b5b821f2f9
Profile.print(C = true)

# ╔═╡ fe28ff06-cb70-4077-a2bd-7209c28c7bd7
md"""
!!! note
	The `C = true` keyword argument includes backtraces from C and Fortran code.
"""

# ╔═╡ 739ff1f9-331f-4021-b978-6556b4c62916
md"""
As we can see, the most expensive calls here are the [`dgemm` calls](https://www.netlib.org/lapack/explore-html/dd/d09/group__gemm_ga1e899f8453bcbfde78e91a86a2dab984.html#ga1e899f8453bcbfde78e91a86a2dab984).
"""

# ╔═╡ e33e26ac-4daf-476b-b5a6-682efd534c04
md"""
!!! tip "Matrix multiplication vs matrix-vector multiplication (complexity)"
	To optimize the above code, keep in mind that:
	- The computational complexity of matrix multiplication is $O(𝑁^{3})$ for square matrices, with two floating-point operations (flops) appearing in the innermost loop as a multiply-add. 
	- The worst-case computational complexity of matrix-vector multiplication is $O(𝑁^{2})$.
"""

# ╔═╡ bc99efab-88aa-4df6-962e-2dfb3bdd9580
md"""
So, let's rewrite the `mult` function as follows:
"""

# ╔═╡ 6ae685de-bf47-4a98-98c3-66e4ac69309b
function mult2(A, B, x)
#     C = A * B
#     return C * x
    y = B * x
    return A * y
end

# ╔═╡ e2c75d32-c5be-4a4f-b46d-a597a9c7627b
md"""
Check that we get the same results:
"""

# ╔═╡ a8143190-3bc1-4fcc-ae96-5678244301ce
mult2(𝑨, 𝑩, 𝒙) ≈ mult(𝑨, 𝑩, 𝒙)

# ╔═╡ 3132deba-d20c-4ce0-968f-7d4ced7562a5
md"""
And then let's profile it:
"""

# ╔═╡ 244c1693-0cef-4eef-b6ed-f1983e8dcc5f
Profile.clear()

# ╔═╡ ff36721a-708c-41d5-8b43-90a338da9d34
@profile mult2(𝑨, 𝑩, 𝒙)

# ╔═╡ 5419b524-483d-40a2-b368-d5b0b492603c
Profile.print(C = true)

# ╔═╡ cfd3b245-215e-4027-b7d3-fe1a0fa96a0a
md"""
Let's follow the warning message and adjust the code being profiled by running the function multiple times:
"""

# ╔═╡ d6a95ebf-aa80-4cbe-acb2-46a96d20205e
begin
	Profile.clear()
	@profile (for i = 1:100; mult2(𝑨, 𝑩, 𝒙); end)
	Profile.print(C = true)
end

# ╔═╡ f09ff3ce-3c77-4a0b-80b6-a2d68223fac0
md"""
As we can see, the function being called is now the much faster [`gemv`](https://www.netlib.org/lapack/explore-html/d7/dda/group__gemv_ga4ac1b675072d18f902db8a310784d802.html#ga4ac1b675072d18f902db8a310784d802) instead of the `dgemm`:
"""

# ╔═╡ a3a85bca-1901-4dc2-8b2f-0cb55c536753
@time mult2(𝑨, 𝑩, 𝒙)

# ╔═╡ 8909b2e6-0440-4f62-ac35-b182b99755a0
@btime mult2($𝑨, $𝑩, $𝒙)

# ╔═╡ be7872eb-f399-415e-91c1-25d2fb7cafb0
@benchmark mult2($𝑨, $𝑩, $𝒙)

# ╔═╡ e60c7076-c9e8-486e-b320-7eebbe9094f7
md"""
Final comparison:
"""

# ╔═╡ 30ad6a5b-7b7b-4a8a-a1b4-774e349c5940
begin
	Α = rand(10000, 2)
	Β = rand(2, 8000)
	v = rand(8000)
end

# ╔═╡ 1bdaf1e2-fa66-4b84-acbc-8d5fdb3a5e90
@btime mult($Α, $Β, $v);

# ╔═╡ 2d1559e1-02a6-4103-a6a9-713be284d299
@time mult2(Α, Β, v)

# ╔═╡ 2107bcd8-11aa-423e-96bc-73a6fc6c4e57
md"""
##### Live demo
Let’s now look at a more complex case and use `ProfileView.jl` to visualize a flame graph based on the results from the profiler.
"""

# ╔═╡ 6a0ab61d-1f47-40a8-bd6f-a217f104709e
md"""
# Abstract vs Concrete types
As we've seen, a fundamental aspect of Julia is multiple dispatch, which is based on the concept of **types**. 
Julia supports two main categories of types:
- **Abstract types**
- **Concrete types**
## 1. Abstract types
These are some of the most important features of abstract types:
- Abstract types are typically used to model real-world **data concepts** (e.g., Animal, Vehicle, Asset...)
- Julia allows the definition of a hierarchy of abstract types. For example, here is the hierarchy tree for the `Number` type:
$(LocalResource("/Users/lb9239/Documents/Julia/Princeton User Group /talk/types.svg"))""
- Abstract types are defined **without fields**
"""

# ╔═╡ c96efefe-05b0-4864-815f-e5e5a83c2ad0
md"""
###### Syntax for abstract types
"""

# ╔═╡ 083e588f-73ec-49ad-a19d-e882093c1fcb
# Define an Animal abstract type
abstract type Animal end

# ╔═╡ 733de24e-e95d-4f0a-821a-666f038770ca
md"""
## 2. Concrete types
- Concrete types define how data is organized.
- They can have attributes.
- Concrete types are defined using the `struct` keyword.
- Attributes of concrete types are accessed using the standard "dot notation".
- Instances of concrete types can be created using the default constructor, or by defining custom constructors using multiple dispatch.
"""

# ╔═╡ 7e7b00f5-5451-4296-aa68-39dbea510404
md"""
###### Syntax for concrete types:
"""

# ╔═╡ bb070bd5-e44f-44fc-b0ed-57d18a5cf66a
begin
	struct Dog <: Animal
		name::String
		age::Int
	end
	
	struct Cat <: Animal
		name::String
		age::Int
		lives_left::Int
	end
	
	# We can create actual dogs and cats (concrete instances)
	rex = Dog("Rex", 3)
	whiskers = Cat("Whiskers", 5, 9)

	# Access attributes with "dot notation"
	println("Alice's dog $(rex.name) is $(rex.age) years old.")
	println("Bob's cat $(whiskers.name) is $(whiskers.age) years old.")
end

# ╔═╡ 3b4d5909-0c15-4619-b336-db64757e4a38
begin
	# Check type relationships
	@show(Dog <: Animal)     # true
	@show(Cat <: Animal)     # true
	
	# Check concrete vs abstract
	@show(isconcretetype(Dog))    # true
	@show(isconcretetype(Animal))    # false
	@show(isabstracttype(Animal)) # true
end

# ╔═╡ c9f39bdf-244e-4fe6-be63-96d3a2834bd9
md"""
## Multiple Dispatch in Action with Abstract and Concrete Types

Now, let's see how multiple dispatch works in practice with both abstract and concrete types. Recall that multiple dispatch allows Julia to choose which function to call based on the types of all the arguments, not just one. This flexibility enables us to define generic functions that can behave differently depending on the types of their inputs.

Let's look at an example:
"""

# ╔═╡ 3562e271-a90a-4a54-8109-d2880e5751d5
begin
	# Type hierarchy example
	abstract type Shape end
	abstract type TwoDShape <: Shape end
	abstract type ThreeDShape <: Shape end
	
	struct Circle <: TwoDShape
	    radius::Float64
	end
	
	struct Rectangle <: TwoDShape
	    width::Float64
	    height::Float64
	end
	
	struct Sphere <: ThreeDShape
	    radius::Float64
	end
end

# ╔═╡ 9a5ec53b-ec65-407c-8e63-d5c3902ff564
# Multiple dispatch
begin
	area(s::Shape) = error("Area not implemented for $(typeof(s))")
	area(c::Circle) = π * c.radius^2
	area(r::Rectangle) = r.width * r.height
	perimeter(c::Circle) = 2π * c.radius
	perimeter(r::Rectangle) = 2 * (r.width + r.height)
	volume(s::ThreeDShape) = error("Volume not implemented for $(typeof(s))")
	volume(s::Sphere) = (4/3) * π * s.radius^3
end

# ╔═╡ 6df54e79-58de-4f3a-89f0-90c9cb8e706c
circle = Circle(5.0)

# ╔═╡ a19a14fe-33cb-4d02-ba9f-bc897e4f28c9
rectangle = Rectangle(4.0, 6.0)

# ╔═╡ ca80d732-d10f-4def-8bf4-4b24d4250ce4
sphere = Sphere(2.0)

# ╔═╡ 0ce756dc-8464-4e69-afaa-59b2b6b3b2e6
println("Circle area: ", area(circle))

# ╔═╡ 952273e2-7696-4b1c-9241-30c1a1bfc4ec
println("Rectangle area: ", area(rectangle))

# ╔═╡ 9bd70e3f-c42f-488e-b55b-2f146abab3f7
println("Circle perimeter: ", perimeter(circle))

# ╔═╡ 8da65f92-b68e-4b8f-b920-cda5c942030f
println("Rectangle perimeter: ", perimeter(rectangle))

# ╔═╡ ab2cf1b3-a23e-4a69-ac18-3989ac2f7fea
intersect(c1::Circle, c2::Circle) = sqrt((c1.radius - c2.radius)^2) <= (c1.radius + c2.radius)

# ╔═╡ 9ce7743c-e497-451f-b90b-8061ac1aabd5
intersect(r1::Rectangle, r2::Rectangle) = !(r1.width < 0 || r2.width < 0 || r1.height < 0 || r2.height < 0)

# ╔═╡ 2a34e484-8413-4028-abbb-f35681711433
begin
	c1 = Circle(5.0)
	c2 = Circle(3.0)
	println(intersect(c1, c2)) # Uses Circle-Circle intersection method
end

# ╔═╡ 886674ae-2e60-45dd-bf4b-f04c470ffabe
md"""
# Bonus 1: Compiler Optimization (Based on Static Analysis)

One of the key strengths of Julia is its ability to optimize code using static type analysis. In version 1.11, the Julia compiler has become even more adept at leveraging type information to generate highly efficient machine code. This means that, based on the types of the inputs to a function, Julia can apply aggressive optimizations at compile time, making your code run faster without requiring manual intervention.
"""

# ╔═╡ e91613d8-1391-4953-adde-22868d4275d4
md"""
!!! note "Static analysis"
	**Static analysis** refers to the process of examining code without executing it. It involves inspecting the code structure, type information, and other metadata at compile time. This allows for optimizations, error detection, and code insights based on the program's structure and types, without needing to run the program.

!!! note "Static analysis in Julia"
	In Julia, static analysis helps the compiler understand the types of variables and expressions in the code, allowing it to make decisions about optimizations, such as inlining functions, removing unnecessary checks, or selecting more efficient algorithms. The more information the compiler can gather about the types at compile time, the better it can optimize the code.

	For example, if the compiler knows that a certain variable is always an `Int64`, it can optimize calculations using that variable by avoiding generic code paths and using more specialized, efficient code paths. This process leads to faster execution times by removing overhead related to dynamic type checks during runtime.
"""

# ╔═╡ 7957e0e2-735f-4402-bd23-891e0374f21c
md"""
Let's explore how this optimization works in practice by looking at the `sum` function:
"""

# ╔═╡ c97bc4e3-e87d-436d-bd1f-0dd21443b4f5
# ╠═╡ show_logs = false
code_typed(sum, (Vector{Float64},))

# ╔═╡ 8f6e8bec-327c-4939-a199-f25b7e683e3f
md"""
The result above is how the `sum` function is implemented for a `Vector{Float64}`. As we can see, it's very elaborate, with several function calls, checks and mappings.
"""

# ╔═╡ 691035d8-9dde-4d13-85c6-422dbb88d90c
md"""
However, even with all that 'machinery,' the compiler in Julia `v1.11` is now able to optimize this into a single return statement with ease.
"""

# ╔═╡ 6068d26d-03dc-4b3d-bc60-da513aae7299
# let's now see an example
f_v() = sum([1,2,3,6])

# ╔═╡ 8ddf7013-549e-47ad-bebf-5ad2fd191f21
f_v()

# ╔═╡ 32eb5f4c-76ec-476b-af9b-6ff839789f4c
md"""
We can use the `@code_llvm` macro to view the compiled code, and the result is as follows:
"""

# ╔═╡ 00407cd2-ca70-42c6-8363-6086c0a608e1
@code_llvm f_v()

# ╔═╡ 0a56ec0f-9357-4875-a544-28d033787de2
md"""
Despite the combination of higher-order functions, it has been optimized into the execution of a single instruction.
"""

# ╔═╡ 81f19190-5984-4755-9e88-b68db7fb6777
md"""
And the same is true for `Tuple`s:
"""

# ╔═╡ 56040aac-7d81-4ed0-bd8f-93ab1d985d54
f_t() = sum((1,2,3))

# ╔═╡ be08f04a-2b5f-4feb-8635-e7746bfe95ff
@code_llvm f_t()

# ╔═╡ 6a79d367-e0da-4b3b-a7e2-6a9d5b2902d5
md"""
Unfortunately, if the elements of the collection are variables, the objects can mutate, and as a result, the compiler cannot make many assumptions about the sum function. Therefore, it has to fall back to the 'complex' implementation (even for a `Tuple`):
"""

# ╔═╡ 93486f47-870d-476c-ab3c-76f475a6b057
t_rand = tuple(rand(Int64, 5)...)

# ╔═╡ fa36b141-d290-464f-ade8-33a2349011df
f_tr() = sum(t_rand)

# ╔═╡ b0d862f7-8756-4b04-b589-a465b686f0b8
@code_llvm f_tr()

# ╔═╡ 632d16c7-317b-45d3-8e7c-40706f137e75
md"""
How can we solve this and regain the best performance?
"""

# ╔═╡ 14f8125c-250f-4cac-9ef8-a474764fc402
md"""
For `Tuple`s, it's simple: we can just initialize them as `const`:
"""

# ╔═╡ a9bd1e87-435c-430d-bc8a-baa15d45cbc6
const t_rand_const = tuple(rand(Int64, 5)...)

# ╔═╡ 2a69577a-0db1-4470-927f-90c9464d1e02
f_trc() = sum(t_rand_const)

# ╔═╡ 31efd891-7a40-437b-9e21-e27d57050e48
@code_llvm f_trc()

# ╔═╡ cf206077-f975-4040-9f5b-80e40dedd185
md"""
How about `Array`s?
"""

# ╔═╡ 7aef68b3-48c2-4f12-9026-bbfb4e806794
md"""
**Solution**: For arrays, we can use the `StaticArrays` package and define the static arrays as `const` as well.

```julia
using StaticArrays
```
"""

# ╔═╡ a9522f60-f87c-4e15-896a-b45ec4f9d332
n = 1000

# ╔═╡ 984a1fe8-988a-4f98-9171-ce3aaf241edc
v1 = @SArray rand(Int64, n)

# ╔═╡ d855d1bd-3514-40d3-829a-a0ef3490c93d
const v2 = @SArray rand(Int64, n)

# ╔═╡ e4433dd3-608d-4849-ae13-c8b6dadf17d7
f1() = sum(v1)

# ╔═╡ 60eaa20b-1fe4-488f-a5b8-e6d0093be43e
f2() = sum(v2)

# ╔═╡ fd2f78b0-4976-42fc-8e28-d371c71cc505
@code_llvm f1()

# ╔═╡ e96fc4cc-4577-4312-afb8-de242e0143ab
@code_llvm f2()

# ╔═╡ ffa9e0c0-7351-4c0a-a5c7-b77a6277263a
md"""
resulting in an incredible boost in performance:
"""

# ╔═╡ 4c015a64-c429-442f-87ef-bec2315cfb21
@benchmark f1()

# ╔═╡ ee157eb5-0039-4514-abe9-a708b1a2bf05
@benchmark f2()

# ╔═╡ 88228e78-fa13-4bba-9af9-9edb06fdc4d4
md"""
The last benchmark essentially shows that, by using `StaticArrays` and `const`, Julia can compute the sum of a vector of length 1000 in a single instruction, achieving a significant performance boost and zero memory allocations.
"""

# ╔═╡ 54f7e4c2-8c65-4b8e-92d5-182c24ea7683
md"""
# Bonus 2: Multiple Dispatch vs Function Overloading

In some languages, like C++ or Java, you may have function overloading, where you define multiple versions of a function are defined with the same name but different argument types. The appropriate version is selected based on the types of the arguments at **compile time**.

However, multiple dispatch in Julia works differently. As we've seen, the appropriate method is chosen based on the types of all arguments, not just one, and this dispatch occurs at **runtime**.

In certain cases, the type of the argument passed to the method may not be known until runtime. When this happens, the method is dispatched dynamically, based on the specific value passed at that moment. This is known as **dynamic dispatch**, and it's a crucial feature of multiple dispatch. It enables Julia to select the most appropriate method for the given argument types, allowing for more flexible and adaptable function calls.

Let's seen an example of this feature:
"""

# ╔═╡ 089d39e8-69ea-44e8-8a8a-6e51b68c172d
md"""
```julia
abstract type Pet end

struct Dog <: Pet
    name::String
end

struct Cat <: Pet
    name::String
end

function encounter(a::Pet, b::Pet)
    verb = meets(a,b)
    s = "$(a.name) meets $(b.name) and $verb"
    println(s)
    return s
end

meets(a::Dog, b::Dog) = "sniffs"
meets(a::Dog, b::Cat) = "chases"
meets(a::Cat, b::Dog) = "runs away"
meets(a::Cat, b::Cat) = "slinks away"

fido = Dog("Fido")
rex = Dog("Rex")
whiskers = Cat("Whiskers")
spots = Cat("Spots")

encounter(fido, rex)
encounter(fido, whiskers)
encounter(whiskers, fido)
encounter(spots, whiskers)
```
"""

# ╔═╡ 8abc95a3-afe8-436a-8895-160b329930c8
md"""
```c++
#include <string>
#include <iostream>


class Pet {
    public:
        std::string name;
};

std::string meets(Pet& a, Pet& b) { return "GENERIC"; }

void encounter(Pet& a, Pet& b) {
    std::string verb = meets(a, b);
    std::cout << a.name << " meets " << b.name << " and " << verb << std::endl;
}

class Dog : public Pet {};
class Cat : public Pet {};

std::string meets(Dog& a, Dog& b) { return "sniffs"; }
std::string meets(Dog& a, Cat& b) { return "chases"; }
std::string meets(Cat& a, Dog& b) { return "runs away"; }
std::string meets(Cat& a, Cat& b) { return "slinks away"; }

int main() {
    Dog fido; fido.name = "Fido";
    Dog rex; rex.name = "Rex";
    Cat whiskers; whiskers.name = "Whiskers";
    Cat spots; spots.name = "Spots";

    encounter(fido, rex);
    encounter(fido, whiskers);
    encounter(whiskers, fido);
    encounter(spots, whiskers);

    return 0;
}
```
"""

# ╔═╡ 62d5c9c3-4e4d-424a-bb13-a5ee13edf31c
md"""
#### Julia:
```bash
$ julia func_overloading.jl
```
Output
```bash
Fido meets Rex and sniffs
Fido meets Whiskers and chases
Whiskers meets Fido and runs away
Spots meets Whiskers and slinks away
```
And, as we can see, the function `encounter` is dynamically dispatched to the correct method based on the types of the arguments passed at runtime.

#### C++
```bash
$ g++ func_overloading.cpp -o program
$ ./program
```
Output
```bash
Fido meets Rex and GENERIC pet meeting
Fido meets Whiskers and GENERIC pet meeting
Whiskers meets Fido and GENERIC pet meeting
Spots meets Whiskers and GENERIC pet meeting
```
"""

# ╔═╡ 63bfd3ba-59f4-4012-bafe-c6430bf4f1cf
md"""
# Acknowledgements and References
I would like to thank the following references, without which this notebook would not have been possible:

- [The Julia Programming language](https://docs.julialang.org/en/v1/).
- [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl).
- [Profiling](https://docs.julialang.org/en/v1/manual/profile/).
- Swaney, Colin [Julia: the Tricky Bits](https://github.com/cswaney/julia-the-tricky-bits).
- Kwong, Tom and Karpinski Stefan (2020). Hands-On Design Patterns and Best Practices with Julia. ISBN 9781838648817.
- Storopoli, Huijzer and Alonso (2021). [Julia Data Science](https://juliadatascience.io). ISBN: 9798489859165.
- Bezanson, Jeff  [Julia as a Statically Compiled Language](https://www.youtube.com/watch?v=hUxnLunOU4w&t=1265s).
- Karpinski, Stefan  [The Unreasonable Effectiveness of Multiple Dispatch](https://www.youtube.com/watch?v=kc9HwsxE1OY) JuliaCon 2019.
- Bauer, Carsten  [Julia on HPC clusters](https://juliahpc.github.io/user_vscode/).
- Holy, Timothy  [Advanced Scientific Computing: producing better code](https://github.com/timholy/AdvancedScientificComputing/tree/main).
- [Julia for Optimization and Learning](https://juliateachingctu.github.io/Julia-for-Optimization-and-Learning/dev/)

Special thanks to the developers of Julia and the open-source community for their ongoing work and outstanding contributions.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
MethodAnalysis = "85b6ec6f-f7df-4429-9514-a64bcd9ee824"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Profile = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[compat]
BenchmarkTools = "~1.5.0"
MethodAnalysis = "~0.4.13"
PlutoUI = "~0.7.60"
StaticArrays = "~1.9.8"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.1"
manifest_format = "2.0"
project_hash = "94d0053e103cb617dc7ffc7b64d1a73387cd349d"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "f1dff6729bc61f4d49e140da1af55dcd1ac97b2f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.5.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

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

[[deps.MethodAnalysis]]
deps = ["AbstractTrees"]
git-tree-sha1 = "c2ee9b8f036c951f9ed0a47503a7f7dc0905b256"
uuid = "85b6ec6f-f7df-4429-9514-a64bcd9ee824"
version = "0.4.13"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

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

[[deps.Profile]]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
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

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "777657803913ffc7e8cc20f0fd04b634f871af8f"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.8"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

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
# ╟─1e908967-7c5d-43b4-bf13-dee6c6a2440a
# ╟─cf398441-18d1-4a35-a935-3b86746cc654
# ╟─c796346f-09dc-4b29-928c-03e0e44e79bb
# ╟─1b3c1832-9ac5-454d-a56c-07f8b797c058
# ╟─336a1020-dff1-428b-b56a-85cab33a5a31
# ╟─2eb0ca4d-fe50-4d17-ad18-419402c86105
# ╟─10377bc0-6487-4c8c-bc18-d75102e75bcc
# ╟─b60da347-65c4-43c4-abe2-38cf4fd7809e
# ╟─6b4ccd0d-b388-4399-82fa-8aad04c568f6
# ╟─91068124-19e5-46d6-a2e0-c72e3def9765
# ╠═f220d143-ffee-450e-bf90-b18519fb32ca
# ╟─5534d191-6987-47d2-b623-fa6440feb43a
# ╟─39561c09-014d-4ac7-9939-d304a99e242a
# ╟─fba5cc44-ee93-4474-8b0e-9807aa8bef72
# ╠═81ad049c-60ed-44bb-981b-d73bacc7fc71
# ╠═057918e4-bf3a-486c-af97-bcbcbc3db8d9
# ╠═ef9b59a4-a0a5-41ce-8e54-2fdc23250b94
# ╠═287f3b35-5f21-48c3-92f9-cde900b1001f
# ╟─688b78e6-c84f-4189-bc99-a96dbedea361
# ╟─bb3c1915-1561-4f39-b777-1b19ff5da879
# ╠═96a9b37e-e12d-4ce2-9a59-808f655eb91f
# ╟─91b854ef-a215-4a54-a725-4606026e4f54
# ╠═739d26cd-bb28-4b29-98f8-9b38b77ce7e7
# ╟─dc3bfbee-6884-4b59-8b89-c6a3c77609ef
# ╠═181da10f-b6c4-4125-9e98-da730d8b60e2
# ╠═1633d744-57e1-48c9-8bc9-661b0b3524e8
# ╠═32d76a1c-f5a6-4fe5-acfc-3bb8345b18f6
# ╠═333838f2-78af-43c5-9e18-0f722bd6508a
# ╠═18a1cff8-e9a0-4a1a-a1bb-5f4770f2c17d
# ╟─faa9c65f-849a-43a7-a4e9-1455d455c85d
# ╠═7e512d0a-3363-48e6-b277-513f3b220e45
# ╟─1a0badaa-6aaa-49d6-8003-b04cb3bda7d0
# ╟─fd41a885-9c79-42e6-86e3-8242dbc987ca
# ╟─14fdce30-0957-412e-a6b0-28a8521a8fdf
# ╟─1fbe6ba4-e695-4b6e-9370-835f1d9d0a26
# ╠═a637e98e-2657-4772-9a4d-d8f7157b0d0d
# ╠═5b0c006e-a9ff-4379-a705-a2c61be92066
# ╟─bfad4d98-e773-4308-9d47-298d76c51397
# ╟─9cbcefc4-54fc-4dd1-9d8f-5afe3861d300
# ╠═951e5c1f-4b33-462a-b801-9de0a1bfbf82
# ╠═8201012e-7bab-4eea-b401-800b54c76ca3
# ╠═e0a083f0-3214-4d53-b8f5-b20ae38c3a0e
# ╟─fefffb76-6afb-4a5b-ab46-8d2b34c3d5fb
# ╟─0c5376b2-dfde-44cf-a3e0-d1b99f6afa60
# ╠═c762f98c-c04e-465a-ae0d-b1352fcdeb0c
# ╠═4a6b9a63-3adc-4a13-b229-86dc610fed30
# ╠═3db269c8-57db-4768-a92c-bf64abac727d
# ╠═73b7abdb-ab9a-4f1c-a6c6-e9e56a17e42a
# ╠═e62043ba-33c7-49aa-8176-148bc209328c
# ╠═fbe3aa11-91bf-416f-95b2-90c204518a28
# ╟─e1ada0b1-14a2-41bd-ae54-cf84f3f9a0e2
# ╠═65d842f3-cfc0-40d7-93bc-724c5bd47332
# ╠═4a3d0dd1-ff79-4251-9e01-b7b8a1a8cadf
# ╠═5004335e-d8b6-4d0f-829e-6be42c49b866
# ╠═5cb429c4-90cc-4853-b376-e55063d83304
# ╠═76debf33-cd34-4b2d-a236-f1d4f26a8e1d
# ╠═25ebe2f7-0094-4ae6-bd29-a5f88214920c
# ╠═981bfa0e-eb67-45fb-ac34-5be4482711b2
# ╠═8a268f53-550f-46d8-9e48-47b4fdfa6287
# ╠═37543da1-cc86-48f1-ba38-097baed20cef
# ╠═3b9e1319-f665-4e41-a918-5de8410baff4
# ╟─1329aa06-a55c-4a24-85c0-57c58a599455
# ╠═f4b1dcf7-0c81-473d-ad1f-6b04ed937f9a
# ╠═53b3bfb1-6868-45b8-9f19-58eeaf44d5f3
# ╟─a90fd2b1-2346-4024-93fc-e6b4ebc3872a
# ╟─3a54e9eb-f576-497c-a9d8-8dd6827afb16
# ╟─51d76486-1566-4d15-adfd-d2b1e323d032
# ╟─2e63646c-387c-42c5-b5c9-786460326cb7
# ╟─55389bfb-dfe9-4a36-8f73-68bd8c64c33e
# ╠═b4ad08f8-e292-4791-9cf0-a7f77cb32265
# ╠═b32a8371-a44a-4be0-8de7-e4c8a14ec815
# ╟─6ef8e678-0f79-4749-b948-61d1f90dd4e1
# ╠═2aea8765-68ac-4b4e-bb2d-4a44247f7dfb
# ╟─86e8f333-a732-4be5-ada8-b00fa856eab5
# ╠═a33f07b6-d3c7-4995-adc0-31563798c71a
# ╠═d5801c32-ae29-48e4-93a3-5b01e4a0cece
# ╠═92b6f114-82a6-4ce1-9ea8-2924cc42ff75
# ╟─011e826e-22d5-408b-bfdc-8e37b1023589
# ╟─0f92cf9a-4e09-4695-a78f-1e4b6c7ebc3e
# ╟─3e0b7ccd-9f1e-474c-bdbe-096ace466c36
# ╟─d2f43d65-ba19-446b-9d1e-d52682f224f4
# ╟─6aecfd4d-29c7-4462-92c3-1d347ce18415
# ╟─597b75ca-5ed1-42ec-87b9-9556ffdc3018
# ╟─c1c7c241-4399-4bc5-af32-3899914798f2
# ╠═da795cba-4090-4acb-820c-4718710c96b4
# ╟─2679f078-c100-4ba0-8ee6-5aec0affb550
# ╟─06b21c20-bed3-416b-b367-501da230db13
# ╠═f494c589-23ed-4ad8-ad32-2a0a3f7b2ae3
# ╟─278f5906-ee71-4ae9-8e90-c9a0476a9ea1
# ╠═8f4f47ce-8fbf-4762-90a1-62563d44cfc2
# ╟─be44a7b0-1a14-4a93-a955-c02efd833654
# ╟─77a23437-fc27-4b54-aa97-22aa8d4e3811
# ╠═c762aa8c-f1b4-410e-b590-953db7dfba3b
# ╠═1d5f4c74-b828-4a9b-91b8-eea2735dd74b
# ╟─cdd4160d-5373-460c-91dd-881dc1b78ab0
# ╠═99f71c13-8ee6-4090-ba84-4936b7fcaae0
# ╟─a146a071-ca64-4219-8be3-5c02c21ae1f9
# ╠═c8a6a52c-ff71-433f-8731-66d0b655eee4
# ╠═c46ffb04-98a1-4596-b8fb-a96a9c644214
# ╠═60a4fc98-8894-4561-81e7-d216405337ab
# ╟─cede4b42-0df6-4e37-b030-0548361d3196
# ╠═7cf02ac4-4be6-45fb-afd3-91c42b15c10c
# ╠═a0b9fd18-93f5-45f1-8f66-e26f0bed9618
# ╟─23638e0d-1d97-43b5-a37c-46e736158b31
# ╟─134c806e-1011-486e-b9b6-3080e137ee29
# ╟─5a3d69a0-81d1-48a6-a721-d7e1c2b34a60
# ╠═e77851c0-2058-4b56-96a7-617b33bf7138
# ╟─b1cb8f0c-8fce-4c40-a9ab-7e1e25d07e36
# ╠═c9658f8e-56b1-4134-a138-4d8347013571
# ╠═32cc3c25-b617-46fc-a5bf-e11604c5ea48
# ╠═f32c5fd9-d0ac-44eb-83f2-df7b6586fa1a
# ╟─3e97e44b-1d90-4521-9bda-fb0907e01704
# ╠═0dc452aa-42ff-4a57-a8ee-03a3c9c47d43
# ╠═1e222d41-201d-4534-be7c-0495f1caa582
# ╟─9a6a6fae-01bb-44b8-a2d4-48dc03ce24ab
# ╠═1ac04b89-221d-49d5-aa84-f487496da5fe
# ╠═1380d091-e036-4652-a787-16b10c2f5c11
# ╠═2c182ec8-4f26-4a2c-9480-3892a36c00e1
# ╟─675c8874-619d-40b6-9ddd-7ae75858c75d
# ╠═a4fdee1d-61af-4147-b02f-48d0a2722c4f
# ╟─08f3c075-b63f-4054-8d6f-f8e38dd9059e
# ╠═d4b96b21-3442-4dc7-8e76-e3974744e927
# ╟─06da45e0-305e-4ee3-9b38-f0e116ac5a16
# ╟─9a908b88-bd2b-407f-b231-f34caea1dee8
# ╠═f19509dc-3f0a-4749-8d98-20407152fa7f
# ╠═f77d9c5d-3a32-4e92-ba1c-cbfb1fa0ffbd
# ╠═5861a4fd-026e-4810-939e-96843135e975
# ╠═d94bf15d-2124-4046-b013-2671d5c56f70
# ╟─b2c72d13-4f98-4851-bc71-1a345dcd4112
# ╠═8535d9d7-cace-4974-9011-75bd5d02cf3d
# ╟─87bdb7b4-ec1a-4c93-b744-d59c9b5b59e4
# ╠═3690f82a-572c-4050-9cb8-bafcc12f28a6
# ╟─62b67a64-1e2c-47a8-9770-a1058f4e42ce
# ╟─5b2bb110-bff0-4334-9339-2c63fec07a96
# ╠═04326f0e-f1a0-44de-aa19-f6265fb991d8
# ╟─febb8eab-1181-41c4-8125-90cea5ae6393
# ╠═2d51ada5-27ae-4c01-9e26-db272de779db
# ╟─92104c31-2287-4006-b82c-478d712aec08
# ╠═5fca4aa0-adc8-465e-ba86-210400ff27af
# ╠═8da57226-17ed-4bf9-bbf2-63af182b2882
# ╠═74a4e24e-1f6b-4a95-b05b-b427363ac213
# ╟─56501158-7f96-4aec-ae17-b09be04fbe51
# ╟─89143b43-f7ff-4679-b4fc-bc0dc9d5c8fa
# ╠═14095145-333d-4a59-a901-1089b7576270
# ╟─bf7285f8-2673-4db3-9a39-418e10a4cd9b
# ╟─78b1965f-c35c-410d-90ce-b2fe8f1854c0
# ╟─c62b3db0-d8f7-4f7f-aeb2-9ea71f892976
# ╠═642af113-3dbf-4d0c-885d-bfb7fc162d05
# ╠═a6a3cf09-2a6a-48c0-b2e2-5c615fbe7f89
# ╠═8fc17d7c-c955-4137-9cec-0e70cd91029d
# ╟─4ffec39c-14e3-49a9-8cf2-61c552d2e57b
# ╠═9932c4a0-b0aa-4493-9b95-b461f541e9d7
# ╠═065a19e8-5123-470f-b4ee-fa0877c416b9
# ╠═3a5f88d6-4679-42b1-8d39-a6b9eaaa7f19
# ╟─d8e75787-912c-401c-af33-e651e068f254
# ╟─64dbb83b-53c6-4e63-8a0c-55c2b89c4149
# ╠═bd184ed2-dc99-417e-a083-0dc8c2092887
# ╟─66625fe0-8b94-46eb-8c7f-ed1538db2cfa
# ╠═3275a8bf-0290-421b-b237-62d8ed8d65ae
# ╟─dd7c511a-4f35-469e-822d-273206250e05
# ╠═c8acd0e9-b116-48a2-9930-7a2d48943786
# ╟─e4c11da3-09f3-45f0-9732-db7027b88ba8
# ╠═c9633eeb-397d-463a-918f-87a22e644909
# ╟─ae62e3e3-4dfd-43c9-a9d2-211db4b01087
# ╠═3ff238ac-055b-425f-9ee6-a4620e35bc4d
# ╟─3a30c17b-462a-4c56-aca1-ade797591390
# ╟─14a4b1eb-4dc8-4c22-b80a-76bbeedba58c
# ╟─597014e7-7f5b-45a6-894a-d1a728fa4313
# ╠═8843e817-e60a-4f4b-b7c8-8e5efdfd22fa
# ╠═dbbf309b-7d3c-42d3-b23f-65435c0aa178
# ╠═dbb7dd6f-be4e-4d8f-bc6c-9066a8577706
# ╠═d46eaf52-69a7-4071-ab44-64a491334662
# ╠═2b46a437-6815-402c-b99a-950537243f56
# ╠═8c593e78-01aa-4b23-a20f-63afcb16ea3b
# ╠═4fb0ad22-3d54-4208-b352-fa4a4b17eb73
# ╟─d6f70278-35e6-4d42-ac98-a2085476960e
# ╠═8c4658d8-4b73-4a1b-8753-337827af2228
# ╠═8eb5f067-b11b-477a-8738-53f7c7303547
# ╠═df822850-7950-4a7b-8b2f-86b5b821f2f9
# ╟─fe28ff06-cb70-4077-a2bd-7209c28c7bd7
# ╟─739ff1f9-331f-4021-b978-6556b4c62916
# ╟─e33e26ac-4daf-476b-b5a6-682efd534c04
# ╟─bc99efab-88aa-4df6-962e-2dfb3bdd9580
# ╠═6ae685de-bf47-4a98-98c3-66e4ac69309b
# ╟─e2c75d32-c5be-4a4f-b46d-a597a9c7627b
# ╠═a8143190-3bc1-4fcc-ae96-5678244301ce
# ╟─3132deba-d20c-4ce0-968f-7d4ced7562a5
# ╠═244c1693-0cef-4eef-b6ed-f1983e8dcc5f
# ╠═ff36721a-708c-41d5-8b43-90a338da9d34
# ╠═5419b524-483d-40a2-b368-d5b0b492603c
# ╟─cfd3b245-215e-4027-b7d3-fe1a0fa96a0a
# ╠═d6a95ebf-aa80-4cbe-acb2-46a96d20205e
# ╟─f09ff3ce-3c77-4a0b-80b6-a2d68223fac0
# ╠═a3a85bca-1901-4dc2-8b2f-0cb55c536753
# ╠═8909b2e6-0440-4f62-ac35-b182b99755a0
# ╠═be7872eb-f399-415e-91c1-25d2fb7cafb0
# ╟─e60c7076-c9e8-486e-b320-7eebbe9094f7
# ╠═30ad6a5b-7b7b-4a8a-a1b4-774e349c5940
# ╠═1bdaf1e2-fa66-4b84-acbc-8d5fdb3a5e90
# ╠═2d1559e1-02a6-4103-a6a9-713be284d299
# ╟─2107bcd8-11aa-423e-96bc-73a6fc6c4e57
# ╟─6a0ab61d-1f47-40a8-bd6f-a217f104709e
# ╟─c96efefe-05b0-4864-815f-e5e5a83c2ad0
# ╠═083e588f-73ec-49ad-a19d-e882093c1fcb
# ╟─733de24e-e95d-4f0a-821a-666f038770ca
# ╟─7e7b00f5-5451-4296-aa68-39dbea510404
# ╠═bb070bd5-e44f-44fc-b0ed-57d18a5cf66a
# ╠═3b4d5909-0c15-4619-b336-db64757e4a38
# ╟─c9f39bdf-244e-4fe6-be63-96d3a2834bd9
# ╠═3562e271-a90a-4a54-8109-d2880e5751d5
# ╠═9a5ec53b-ec65-407c-8e63-d5c3902ff564
# ╠═6df54e79-58de-4f3a-89f0-90c9cb8e706c
# ╠═a19a14fe-33cb-4d02-ba9f-bc897e4f28c9
# ╠═ca80d732-d10f-4def-8bf4-4b24d4250ce4
# ╠═0ce756dc-8464-4e69-afaa-59b2b6b3b2e6
# ╠═952273e2-7696-4b1c-9241-30c1a1bfc4ec
# ╠═9bd70e3f-c42f-488e-b55b-2f146abab3f7
# ╠═8da65f92-b68e-4b8f-b920-cda5c942030f
# ╠═ab2cf1b3-a23e-4a69-ac18-3989ac2f7fea
# ╠═9ce7743c-e497-451f-b90b-8061ac1aabd5
# ╠═2a34e484-8413-4028-abbb-f35681711433
# ╟─886674ae-2e60-45dd-bf4b-f04c470ffabe
# ╟─e91613d8-1391-4953-adde-22868d4275d4
# ╟─7957e0e2-735f-4402-bd23-891e0374f21c
# ╠═c97bc4e3-e87d-436d-bd1f-0dd21443b4f5
# ╟─8f6e8bec-327c-4939-a199-f25b7e683e3f
# ╟─691035d8-9dde-4d13-85c6-422dbb88d90c
# ╠═6068d26d-03dc-4b3d-bc60-da513aae7299
# ╠═8ddf7013-549e-47ad-bebf-5ad2fd191f21
# ╟─32eb5f4c-76ec-476b-af9b-6ff839789f4c
# ╠═00407cd2-ca70-42c6-8363-6086c0a608e1
# ╟─0a56ec0f-9357-4875-a544-28d033787de2
# ╟─81f19190-5984-4755-9e88-b68db7fb6777
# ╠═56040aac-7d81-4ed0-bd8f-93ab1d985d54
# ╠═be08f04a-2b5f-4feb-8635-e7746bfe95ff
# ╟─6a79d367-e0da-4b3b-a7e2-6a9d5b2902d5
# ╠═93486f47-870d-476c-ab3c-76f475a6b057
# ╠═fa36b141-d290-464f-ade8-33a2349011df
# ╠═b0d862f7-8756-4b04-b589-a465b686f0b8
# ╟─632d16c7-317b-45d3-8e7c-40706f137e75
# ╟─14f8125c-250f-4cac-9ef8-a474764fc402
# ╠═a9bd1e87-435c-430d-bc8a-baa15d45cbc6
# ╠═2a69577a-0db1-4470-927f-90c9464d1e02
# ╠═31efd891-7a40-437b-9e21-e27d57050e48
# ╟─cf206077-f975-4040-9f5b-80e40dedd185
# ╟─7aef68b3-48c2-4f12-9026-bbfb4e806794
# ╠═a9522f60-f87c-4e15-896a-b45ec4f9d332
# ╠═984a1fe8-988a-4f98-9171-ce3aaf241edc
# ╠═d855d1bd-3514-40d3-829a-a0ef3490c93d
# ╠═e4433dd3-608d-4849-ae13-c8b6dadf17d7
# ╠═60eaa20b-1fe4-488f-a5b8-e6d0093be43e
# ╠═fd2f78b0-4976-42fc-8e28-d371c71cc505
# ╠═e96fc4cc-4577-4312-afb8-de242e0143ab
# ╟─ffa9e0c0-7351-4c0a-a5c7-b77a6277263a
# ╠═4c015a64-c429-442f-87ef-bec2315cfb21
# ╠═ee157eb5-0039-4514-abe9-a708b1a2bf05
# ╟─88228e78-fa13-4bba-9af9-9edb06fdc4d4
# ╟─54f7e4c2-8c65-4b8e-92d5-182c24ea7683
# ╟─089d39e8-69ea-44e8-8a8a-6e51b68c172d
# ╟─8abc95a3-afe8-436a-8895-160b329930c8
# ╟─62d5c9c3-4e4d-424a-bb13-a5ee13edf31c
# ╟─63bfd3ba-59f4-4012-bafe-c6430bf4f1cf
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
