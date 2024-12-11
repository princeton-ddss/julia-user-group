### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# ╔═╡ 60463811-49d9-4ddd-8169-b7731f0ef60d
using Distributed

# ╔═╡ b9260d61-f6d3-47d9-862f-be29837d58a2
@everywhere using DataFrames

# ╔═╡ d772d9f0-1d8f-4527-811d-1fe128c1d390
md"
# Concurreny with Julia

Julia prides itself on being a language that excels in terms of both development time and runtime. Researchers can write code that runs fast with minimal effort. One reason that Julia is fast for development is that there are few choices to make when it comes time to selecting packages, and, in many cases, no package is required because the Julia development team has prioritizes, builds and includes essential functionality for research developers in `Base`. Parallel programming is a case-in-point. The term \"parallel programming\" encompasses a wide range. Julia supports three classical parallel programming paradigms  \"out-of-the-box\", while the Julia ecosystem provides tightly-integrated support for recent advances, e.g., accelerators and GPUs.

## Summary
- Julia provides three types of \"concurrent\" programming out-of-the-box: **multiprocessing**, **multithreading** and **asynchronous programming**.
- The `Distributed` module provides support for multiprocessing or *distributed* computing.
- The `Threads` module provides support for multithreaded programs.
- `Tasks` are light-weight coroutines that support asynchronous programming.
- Code executed on a worker thread or process is run asynchronous. Results are communicated via `Future` or `Task` objects.
- Communication between processes and threads in managed by `Channels` and/or (in the case of threads) shared memory.
- Thread-safety is the responsibility of the developer.
"

# ╔═╡ 162f1ef4-8ee8-487e-b2a1-cfa5367679de
md"
## Concurrency Basics
Before diving into Julia, let's briefly review three \"classical\" concurrent programming paradigms: multiprocessed, multithreaded and asynchronous computing. 

Multiprocessing is the easiest of these concepts to understand. The laptop you are reading this on is running thousands of processes at any given time, most of which are idle most of the time. In scientific computing, multiprocessing works essentially the same way accept that we run programs that make heavy utilization of the available resources, and are thus limited to the number of \"logical\" cores available.

Threads are computations that take place *within* a process and therefore have access to shared memory.  Multithreading takes advantage of the multiple cores to perform tasks in parallel without having to pass data between processes at the cost of having to carefully manage access to shared data.

A program is asynchronous if it does not stop to execute (at least some) of its code. For example, a program might call an external API, continue without waiting for the response, and then run a bit of code when the response finally arrives. Such programs are unique in their ability to switch between functions.

Julia offers first-class support for all three of these paradigms. Let's start by taking a look at multiprocessing in Julia.
"

# ╔═╡ 34845c27-b09f-4d83-9684-015dcd71f61b
md"
## Multiprocessing (aka \"Distributed\")
Multiprocessing functionality is provided by the `Distributed` module. Supplying the `-p [NUM_WORKERS]` option at start-up creates a process pool with `NUM_WORKERS` workers.

```julia
julia -p 2
```

Creating a \"process pool\" this way also imports the `Distributed` module. For greater control, you can instead import `Distributed` after starting Julia and create or modify the pool *after* start-up using `Distributed.addprocs`.
"

# ╔═╡ 7e1ee601-82dc-4b9e-9ca6-d87f53a58fc1
Distributed.addprocs(4);

# ╔═╡ f04849e3-b927-4dd2-9d25-7395ea2f13d5
md"
Note that workers are in addition to the main process (which is always assigned `ID=1`) so that the maximum worker ID is `nworkers() == NUM_WORKERS + 1`. In addition, using `-p auto` to start Julia will launch as many workers as *logical* cores available. On modern laptops, this might not be the number you expect:
"

# ╔═╡ 1b1c6bb0-37c4-4d2b-96c1-5593c302b385
Sys.CPU_THREADS

# ╔═╡ b68ef98f-8a14-42e9-ab4c-923defba4c6c
md"
Did that work for you? On an machine running Apple's M2 Max, Julia only detects the number of \"performance\" cores, which is 8 out of 12 in my case.
"

# ╔═╡ 650cd20e-04da-4d08-b8b6-308ad05b4438
md"### Work is assigned to workers"

# ╔═╡ 238e46e8-14bd-4a42-9de5-bd38728e9464
md"
Scheduling jobs to workers is performed with either `Distributed.remotecall` or `Distributed.@spawnat`:
"

# ╔═╡ 8663b8e7-fa7b-441c-b69b-d7b17ec2e257
x = remotecall(rand, 2, 3)

# ╔═╡ c85acf75-1a6d-4d38-91d5-70dc3c751953
y = @spawnat 2 1 .+ fetch(x)

# ╔═╡ 65bc4185-3f82-4898-a813-16ccebb2d40a
md"
These commands are quite similar, but while `remotecall` takes a function as its main argument, `@spawnat` takes an *expression*. Note that the `fetch(r)` will be run *on the worker*.

### Remote calls return `Future`s
The return type in both cases above is `Future`, an object that exists to communicate the result of a remote call at a *future* point in time. This is because both remote calls are run *asynchronously*. That is, these calls return immediately and do not wait for their job to finish execution.

You can check on the state of a `Future` using `isready`:
"

# ╔═╡ 5a878a26-3633-4814-955c-cd39fdebe27e
isready(x)

# ╔═╡ 0f50794a-8e0a-4f50-bd34-128824a07feb
md"
Alternatively, you can wait for the `Future` to finish and obtain its returned value using `fetch`:
"

# ╔═╡ 93a6b5ff-e821-4ae5-9ae8-1e04c5a8dbde
fetch(x)

# ╔═╡ 73d7b124-835c-4dee-a4cb-bf2a2d8949f5
md"
In order to wait for the `Future` *without* obtaining its returned value, use `wait`:
"

# ╔═╡ e78020dd-98b8-47bc-b490-1af6e6d3eca2
wait(y)

# ╔═╡ a8035b94-c67a-406a-a6bb-034c623be293
md"
### Processes do *not* share data
Processes are operating system processes: if you look at your activity monitor you'll see a `julia` process listed for each of the `nworkers` started by the main Julia process. As such, processes do not share data and they do not share code. This has two important implications:

1. Data needs to be copied
2. Code needs to be made available

The latter requirement is easy to satisfy using the `@everywhere` macro. This can be used to import modules, e.g.,
"

# ╔═╡ 862000c0-9537-4a81-a770-9494b45de6fd
md"or to share code from the main process, e.g.,"

# ╔═╡ eda0d634-d8b5-439d-bae9-132674bf0db5
@everywhere struct Foo
	x
end

# ╔═╡ c452ccb7-ea6d-4ca5-b2d0-a2006e37f294
remotecall_fetch(() -> Foo("bar"), 2)

# ╔═╡ b367b347-b460-4960-b0a6-3b0013999ad3
md"
The movement of data, on the other hand, is generally performed *implicitly*. For example, summing an array on a worker,
"

# ╔═╡ 1d38bfaa-2b31-44d0-b5c4-2bd7ce286cdf
X = rand(2, 2);

# ╔═╡ 083d8c4f-ffed-4558-bf18-a936f655ea26
remotecall_fetch(sum, 2, X)

# ╔═╡ 4a5c644d-6e42-46b7-8131-f5f242223501
md"
implicitly copies `X` to the worker. Thus, care must be taken to avoid unintentional data movement. If this proves to be a bottleneck for your use case, then you may find multithreading a better option.
"

# ╔═╡ 44c0d57d-84fe-4726-95ba-64eef33b637f
md"
### Globals are messy
🚧
"

# ╔═╡ 0ee1708c-14d8-4fbb-bcc2-b8ae8c506aa6
md"
### You probably want a `pmap`
It seems to very often be the case in numerical computing that the thing to do is run the same bit of code of different segments of data in parallel. While you *can* achieve this using the tools demonstrated thus far, Julia knows you want to do this and has kindly provided shortcuts.

First, for mapping a function over an array, we have `pmap`:
"

# ╔═╡ 033b8878-e736-4b40-bab1-26cac659754d
pmap(sum, [100, 200, 300])

# ╔═╡ 6d52b0f1-61e3-4b1b-b778-8eb693949333
md"`pmap` works just like `map`, but a remote call is created for each element of the array being mapped over. As always, data needs to be copied to processes where it is needed. If your data is produced via a costly process, consider mapping over an object with minimal data-transfer requirements instead, e.g.
```julia
pmap(fname -> sum(load(fname)), [a.csv, b.csv, c.csv])
```

Note also that any values used by the mapped function should be *read-only* as any side effects will be local to the worker that receives the remote call. (Of course, it's perfectly fine for code to have effects *outside* of Julia, e.g., writing to disk).
"

# ╔═╡ 6dec68fe-1e42-4742-bd12-5df6db752eda
md"
## Multithreading

"

# ╔═╡ af7c5f6a-0998-4230-98e4-1127df5ca347
md"
## Asynchronous (aka Coroutines)
"

# ╔═╡ 380acb60-4c61-4b48-ac9d-4627d506ef89
md"
## Example: Background Jobs
"

# ╔═╡ 64393438-236c-4d8e-b451-3ef7ad9232d4
md"
## Example: Event Loops
"

# ╔═╡ 7b736ac2-9620-41ea-bfea-f489c981667a
md"
## Cheatsheet

### Start a job on a worker process
"

# ╔═╡ b2b6e334-16ae-485d-8b79-30ae01940588
f1 = @spawnat 2 rand(2, 2) # remotecall_fetch(rand, 2, 2, 2)

# ╔═╡ 2c97a49c-1d3b-4e6a-a43c-d2ea3d4b332c
md"
### Run a map-reduce job
"

# ╔═╡ a6a0d06e-b19b-4917-8e4a-8fa3eae41081
val = @distributed (+) for i = 1:100_000
	Int(rand(Bool))
end

# ╔═╡ a7659676-c856-4b84-985e-8cf350213b36
md"
### Run a parallel map job
"

# ╔═╡ e2c4e531-71b7-479b-a06d-5a67926ff140
vals = pmap(sum, [1:100, 1:200, 1:300])

# ╔═╡ 7fd85ce0-e672-4405-8515-5f32ac3dbf7a
md"
### Start a task on a worker thread
"

# ╔═╡ 25a57f19-3314-439c-b58e-766bb2826627
res = Threads.@spawn rand(2, 2)

# ╔═╡ 4b6d1323-3d4a-4b82-8f21-31d91ce4d475
md"
### Run a multithreaded for loop
"

# ╔═╡ c3ce1147-9402-4614-8912-0669b6f0b49e
Threads.@threads for i = 1:3
	println("Hello from $(Threads.threadid())")
end

# ╔═╡ 03c9d293-3369-4a17-8a05-e1dcc14e6e53
md"
### Start a task as a coroutine
"

# ╔═╡ c48e769f-9171-44ab-bba1-7f86ec157f60
task = @async rand(2, 2)

# ╔═╡ 32193e98-711c-4bbc-a8f5-c2da2e4d3b55
md"
### Communicate between tasks
"

# ╔═╡ b2b98b83-f322-4527-99f7-fcaa75852ec9
chnl = Channel{String}(8);

# ╔═╡ e80116ee-29c2-4cf3-a0cd-53a5eab66db9
put!(chnl, "Hello");

# ╔═╡ 8b1935d2-fe6e-482a-be4b-2b1f1db7a782
msg = take!(chnl)

# ╔═╡ 19839f82-e158-4df3-a90a-9e3fc6e64f71
md"
### Lock a 
"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[compat]
DataFrames = "~1.7.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.2"
manifest_format = "2.0"
project_hash = "c675c90661f2cde22d3542cda8db404735e8e2ca"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

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

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "fb61b4812c49343d7ef0b533ba982c46021938a6"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.7.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.InlineStrings]]
git-tree-sha1 = "45521d31238e87ee9f9732561bfee12d4eebd52d"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.2"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

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

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "1101cd475833706e4d0e7b122218257178f48f34"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
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

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "d0553ce4031a081cc42387a9b9c8441b7d99f32d"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.7"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "a6b1675a536c5ad1a60e5a5153e1fee12eb146e3"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.0"

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

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"
"""

# ╔═╡ Cell order:
# ╟─d772d9f0-1d8f-4527-811d-1fe128c1d390
# ╟─162f1ef4-8ee8-487e-b2a1-cfa5367679de
# ╟─34845c27-b09f-4d83-9684-015dcd71f61b
# ╠═60463811-49d9-4ddd-8169-b7731f0ef60d
# ╠═7e1ee601-82dc-4b9e-9ca6-d87f53a58fc1
# ╟─f04849e3-b927-4dd2-9d25-7395ea2f13d5
# ╠═1b1c6bb0-37c4-4d2b-96c1-5593c302b385
# ╟─b68ef98f-8a14-42e9-ab4c-923defba4c6c
# ╟─650cd20e-04da-4d08-b8b6-308ad05b4438
# ╟─238e46e8-14bd-4a42-9de5-bd38728e9464
# ╠═8663b8e7-fa7b-441c-b69b-d7b17ec2e257
# ╠═c85acf75-1a6d-4d38-91d5-70dc3c751953
# ╟─65bc4185-3f82-4898-a813-16ccebb2d40a
# ╠═5a878a26-3633-4814-955c-cd39fdebe27e
# ╟─0f50794a-8e0a-4f50-bd34-128824a07feb
# ╠═93a6b5ff-e821-4ae5-9ae8-1e04c5a8dbde
# ╟─73d7b124-835c-4dee-a4cb-bf2a2d8949f5
# ╠═e78020dd-98b8-47bc-b490-1af6e6d3eca2
# ╟─a8035b94-c67a-406a-a6bb-034c623be293
# ╠═b9260d61-f6d3-47d9-862f-be29837d58a2
# ╟─862000c0-9537-4a81-a770-9494b45de6fd
# ╠═eda0d634-d8b5-439d-bae9-132674bf0db5
# ╠═c452ccb7-ea6d-4ca5-b2d0-a2006e37f294
# ╟─b367b347-b460-4960-b0a6-3b0013999ad3
# ╠═1d38bfaa-2b31-44d0-b5c4-2bd7ce286cdf
# ╠═083d8c4f-ffed-4558-bf18-a936f655ea26
# ╟─4a5c644d-6e42-46b7-8131-f5f242223501
# ╟─44c0d57d-84fe-4726-95ba-64eef33b637f
# ╟─0ee1708c-14d8-4fbb-bcc2-b8ae8c506aa6
# ╠═033b8878-e736-4b40-bab1-26cac659754d
# ╠═6d52b0f1-61e3-4b1b-b778-8eb693949333
# ╠═6dec68fe-1e42-4742-bd12-5df6db752eda
# ╠═af7c5f6a-0998-4230-98e4-1127df5ca347
# ╠═380acb60-4c61-4b48-ac9d-4627d506ef89
# ╠═64393438-236c-4d8e-b451-3ef7ad9232d4
# ╟─7b736ac2-9620-41ea-bfea-f489c981667a
# ╠═b2b6e334-16ae-485d-8b79-30ae01940588
# ╟─2c97a49c-1d3b-4e6a-a43c-d2ea3d4b332c
# ╠═a6a0d06e-b19b-4917-8e4a-8fa3eae41081
# ╟─a7659676-c856-4b84-985e-8cf350213b36
# ╠═e2c4e531-71b7-479b-a06d-5a67926ff140
# ╟─7fd85ce0-e672-4405-8515-5f32ac3dbf7a
# ╠═25a57f19-3314-439c-b58e-766bb2826627
# ╟─4b6d1323-3d4a-4b82-8f21-31d91ce4d475
# ╠═c3ce1147-9402-4614-8912-0669b6f0b49e
# ╟─03c9d293-3369-4a17-8a05-e1dcc14e6e53
# ╠═c48e769f-9171-44ab-bba1-7f86ec157f60
# ╟─32193e98-711c-4bbc-a8f5-c2da2e4d3b55
# ╠═b2b98b83-f322-4527-99f7-fcaa75852ec9
# ╠═e80116ee-29c2-4cf3-a0cd-53a5eab66db9
# ╠═8b1935d2-fe6e-482a-be4b-2b1f1db7a782
# ╠═19839f82-e158-4df3-a90a-9e3fc6e64f71
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
