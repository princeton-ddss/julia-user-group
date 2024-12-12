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
# ╠═╡ disabled = true
#=╠═╡
x = remotecall(rand, 2, 3)
  ╠═╡ =#

# ╔═╡ c85acf75-1a6d-4d38-91d5-70dc3c751953
# ╠═╡ disabled = true
#=╠═╡
y = @spawnat 2 1 .+ fetch(x)
  ╠═╡ =#

# ╔═╡ 65bc4185-3f82-4898-a813-16ccebb2d40a
md"
These commands are quite similar, but while `remotecall` takes a function as its main argument, `@spawnat` takes an *expression*. Note that the `fetch(r)` will be run *on the worker*.

### Remote calls return `Future`s
The return type in both cases above is `Future`, an object that exists to communicate the result of a remote call at a *future* point in time. This is because both remote calls are run *asynchronously*. That is, these calls return immediately and do not wait for their job to finish execution.

You can check on the state of a `Future` using `isready`:
"

# ╔═╡ 5a878a26-3633-4814-955c-cd39fdebe27e
# ╠═╡ disabled = true
#=╠═╡
isready(x)
  ╠═╡ =#

# ╔═╡ 0f50794a-8e0a-4f50-bd34-128824a07feb
md"
Alternatively, you can wait for the `Future` to finish and obtain its returned value using `fetch`:
"

# ╔═╡ 93a6b5ff-e821-4ae5-9ae8-1e04c5a8dbde
# ╠═╡ disabled = true
#=╠═╡
fetch(x)
  ╠═╡ =#

# ╔═╡ 73d7b124-835c-4dee-a4cb-bf2a2d8949f5
md"
In order to wait for the `Future` *without* obtaining its returned value, use `wait`:
"

# ╔═╡ e78020dd-98b8-47bc-b490-1af6e6d3eca2
md"
```julia
wait(y)
```
"

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
md"
which allows us to safely run

```julia
remotecall_fetch(() -> Foo(\"bar\"), 2)
```
"

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
Multithreading is another familiar concurrent programming paradigm. As the name suggest, it uses multiple *threads* to perform actions simultaneously. Unlike processes, threads share memory. Thus, multithreaded programs can efficiently pass information between operations. On the other hand, getting access to a large number of cores *and* memory might be challenging. In addition, having shared data means having to worry about *race conditions*. Writing \"thread-safe\" code (i.e., code free from race conditions) is notoriously difficult.

### Highlights
- Julia provides support for multithreading via the `Threads` module.
- There are two commonly used macros: `@threads` for multithreaded for-loops and `@spawn` for background tasks.
- Threads are created at start-up via the `-t NUM_THREADS` option. Unlike processes, threads *must* be assigned at start-up.
- Julia provides `Channel`s, `ReentrantLock`s and `Atomic` to facilitate thread-safe code.
- **Thread-safety is the developers responsibility!**

### Start from the very beginning (with multiple threads)
In order to make use of threads, you need to start Julia with a threadpool using the `-t NUM_THREADS` option, e.g.,

```shell
julia -t 2
```

This will start Julia with two threads:
"

# ╔═╡ c275f17c-f725-4d18-8946-10a4acd5b2e7
Threads.nthreads()

# ╔═╡ 61d5baf2-7257-4b35-81ef-fa6c15a6cf09
md"
Notice that, unlike the case with distributed computing, we do not need to import the `Threads` module because it is part of `Base`. Nor do we need to mess around with `@everywhere` because every thread has access to code in the main process. However, unlike the distributed case, we *must* start Julia with threads if we plan to use them later: there is no equivalent to `Distributed.addprocs`.

> **Tip!** 
> The `-t` option can be combined with `-p` to start multiple processes with multiple threads per process (including the main process).
"

# ╔═╡ fe5b5269-19fe-44ad-b8e4-095a77666cbf
md"
### Set it and forget it!
Once we have a function defined, running it in a thread is trivial:
"

# ╔═╡ 59dc3e16-3743-4d90-bcc6-9ff85071611b
t3 = Threads.@spawn im_only_sleeping_take(3)

# ╔═╡ ab962e49-b52b-409f-b072-b25b2e31989e
md"
The `Threads.@spawn` macro creates a `Task` and immediately schedules it to run in an available thread. How is this different from the `@async` coroutines (discussed below)? The task is scheduled to run *in parallel* on a thread, whereas the coroutine is scheduled to run interleaved with other tasks on a single process. Thus, the usefulness of multithreaded tasks is *not* restricted to I/O bound operations.

Because the return of `Threads.@spawn` is a (started) `Task`, we can wait for it or fetch its results the same as with coroutines.
"

# ╔═╡ f9d68ac9-bbeb-4bc8-8fe7-fb4913f57ed5
fetch(t3)

# ╔═╡ c8c71e29-a825-4413-99b6-2fce7adf1b30
md"
### @threads to the rescue

As with multiprocessing, one of the most common use cases of multithreading is to run parallel for-loops. `Threads.@threads` macro is our hero in this case:
"

# ╔═╡ bebc3ac9-993c-4df6-8175-286c1d9461ac
Threads.@threads for i = 1:10
	println("Hello from $(Threads.threadid()). I have task $i.")
end

# ╔═╡ f22e4bd2-f1a7-4f72-be3c-3d607ce71da5
md"
### Message in a bottle (ooh)

There are two primary ways that threads communicate: by sharing state or by sending messages. Julia supports both approaches. Sending messages is somewhat easier to understand, so let's take a look at that. A `Channel` is a *thread-safe* first-in-first-out (\"FIFO\") queue that contains an internal buffer. Senders `put!` values in the channel and receivers `take!` values from the channel. If the channel's buffer is full, then senders must wait until a spot opens up; if the channel's buffer is empty, then receivers must wait until a value is available. Creating a channel is straight-forward:
"

# ╔═╡ b4cfc8e6-12ae-4506-9e05-3dd962034b47
c = Channel{Int}(32)

# ╔═╡ 4d832cf5-e3a7-4d93-ab19-f48fa01a56a0
md"
The only argument is an integer size that determines how many items the channel can hold. The *type parameter* determines the type of item the channel can hold. In this case, our channel only accepts `Int` values. Omitting the type parameter results in channel that holds `Any` value, while omitting the size parameter results in a size-zero or \"unbuffered channel\"—senders must wait until a receiver requests a value to place their value in the channel (at which point it is immmediately consumed).

To send a message, we simply `put!` a value on the channel:
"

# ╔═╡ 889aad56-dc95-403c-b84b-604af9538929
put!(c, 1)

# ╔═╡ 6895a47f-4cbc-456f-a488-df4ee8f64db2
md"
We can check if a channel has a value available with `isready`: 
"

# ╔═╡ 186c484b-264a-423a-ac74-068f8369c501
isready(c)

# ╔═╡ 0bd51569-ac87-469a-911f-3803e972a080
md"
To fetch a value, we can use `take!` to remove an item or `fetch` to return the value without removing it:
"

# ╔═╡ b79ae203-7665-41f4-856f-b4cf8c5dfc03
fetch(c)

# ╔═╡ 135252dd-bf84-4a80-915a-a42c142839b9
take!(c)

# ╔═╡ 16fed2f2-8583-4cbc-92ab-87e119044b71
isready(c)

# ╔═╡ e0e7ce1d-471f-453e-9acd-968374b41fff
md"
When we're done with the channel, we should `close` it to stop senders and receivers from using it:
"

# ╔═╡ ab94f65f-46db-4ca7-a7fc-5d9108cf63cd
close(c)

# ╔═╡ 6653f45d-637e-4268-9eb2-5b8804cdf034
try
    put!(c, 2)
catch
	println("Nuh uh uh. You can do that.")
end

# ╔═╡ 0d9ebff1-56a7-4988-9e42-62cf620c4646
md"
> Tip! To automatically close a channel when a task completes, `bind` it to the channel: `bind(chnl, task)`.
"

# ╔═╡ f2c94c73-4851-4198-8091-6bd9c48622c6
md"
In terms of thread safety, passing messages this way serves as a way to denote the \"owner\" of data: when a sender places a value in the channel, it gives up ownership of that data (and the eventual receiver takes ownership).
"

# ╔═╡ af7c5f6a-0998-4230-98e4-1127df5ca347
md"
## Asynchronous (aka Coroutines)

Asynchronous programming refers to code in which the process does not stop to execute (at least some) functions. A typical example is a function that fetches data from an external API, immediately returns control to a main event loop, and then resumes execution in order to perform an action when the API response arrives. 

This type of logical flow is especially useful for application development because it provides a way to lift blocking operations from the main process. But asynchronous programs can help reduce the latency of any I/O bound code, such as database operations, background processes, disk access, and even GPU bound code. **Asynchronous programs do *not* rely on additional threads or processes, although they *may* involve these.**

In Julia, asynchronous programming is supported via `Task`s. The computer science term for a `Task` is a \"coroutine\"—a function that can be suspended and resumed without calling a subroutine (thanks, Wikipedia 🙏). At its core, asynchronous programming is all about *yielding* execution. Normally, a function only yields to call another function:

```julia
function do_something():
    # start doing the thing...
    fetch_data()
    # keep doing the thing...
end
```

In this example, `fetch_data` is added to the call stack, its routine runs and eventually returns to `do_something`. There may be operations following the `fetch_data` call that do not depend on its result. With a normal function call, we are forced to wait for the result, but a coroutine can yield control back to `do_something` when it reaches an I/O bound operation and can resume executing—taking control back from the calling function—when non-blocking code is reached.
"

# ╔═╡ 027ba1a0-92c1-420e-884e-e6de93c10da6
md"
### Anything can be coroutined...
`Task`s, or coroutines, follow a `create-start-run-finish` life-cycle. Given a function, say
"

# ╔═╡ 086d27a2-eb2f-463f-98fa-9fd7d12f0b42
function im_only_sleeping_take(n::Int)
    println("I'm only sleeping for $n seconds.")
	sleep(n)
	return "Wakey wakey!"
end

# ╔═╡ e7cd09c8-13d1-4132-bd5f-a163a8448679
md"
**Create** a task via the `@task` macro:
"

# ╔═╡ 4bc255fe-8e43-4f24-9f81-b4427b6ab152
t1 = @task im_only_sleeping_take(1)

# ╔═╡ 4f8f921c-be5b-4566-82f4-3a6fdf9246fa
md"**Schedule** the task using `schedule`:"

# ╔═╡ 788563fb-50c4-48ea-bcb0-896566669a90
schedule(t1)

# ╔═╡ 43e53a95-b765-482a-b8fe-964a94814e46
md"**Wait** for the task to finish running—if desired—using `wait`:" 

# ╔═╡ bd902a37-abf7-4d1d-9728-f8d6b2592994
md"
```julia
wait(t1)
```
"

# ╔═╡ d8034844-511c-4f73-9a6d-fe88675ea112
md"And, finally, **fetch** the task's result—if any—using `fetch`:"

# ╔═╡ c2eed6d1-75a1-47d0-8a14-8166c6b4efc2
fetch(t1)

# ╔═╡ 3d0c8d8b-5f5a-46a9-a088-a94b2ceffa79
md"The `schedule` and `wait` functions can often be left out because `fetch` already waits for the result, and because the `@async` macro will create *and* schedule a task. Thus, typical usage is often as simple as"

# ╔═╡ e6fb0d4d-184a-4541-bf65-fb42303f22c1
t2 = @async im_only_sleeping_take(2)

# ╔═╡ a2f37831-b28e-4602-9d62-9bcbd3bf97af
fetch(t2)

# ╔═╡ 315c5882-f7eb-47e8-a029-006f936c292f
md"
### ...but not everything should
It might be useful to contrast asynchronous Julia with JavaScript. Since ECMAScript 2017 (ES8), JavaScript provides the `async` and `await` keywords that indicate whether a function should be run asynchronously and whether to wait for the result before proceeding, respectively. For example,

```javascript
async function fetch_api(url) {
	let res = await fetch(url)
    // handle the response...
    return res.json()
}
```

Defining `fetch_api` as `async` allows me to use other `async` method within its body, such as `fetch`, as well as `await` this function elsewhere in my code:

```javascript
async function handleButtonClick() {
    let data = await fetch_data()
    console.debug(\"from handleButtonClick: received data\", data)
}
```

Notice that after a function is defined as `async`, I do not need to tell JavaScript that it should be run asynchronously. I only need to indicate whether I want to wait for its result.

In Julia, I can instead turn *any* function call into a task. In fact, you will generally tell Julia both whether you want to run a function asynchronous and whether to wait for its result in the same location, e.g., using `@async`.

The disadvantage of this approach is that it can be hard to tell what code can *benefit* from running asynchronously. JavaScript functions that are defined as `async` can generally be counted on to perform an async action, and the `async` keyword communicates this fact to other developers. There is no such clarity in Julia.
"

# ╔═╡ 380acb60-4c61-4b48-ac9d-4627d506ef89
md"
## Example: Redis Queue

A job queue is a server that accepts requests to run programs or functions in process pool. When it receives a request, it places it in a FIFO queue. If there is a process available, the job is scheduled to run.

For example, here's the RQ package:

```python
def count_words(string):
    return len(string)

q = Queue(connection=Redis())
res = q.enqueue(count_words, 'You're a silly bean!')
```

In Julia, we can create an \"internal\" job queue at start-up using the `-p` option (or *after* start-up using the `Distributed.addprocs` function). But this isn't useful if we need run Julia *across* programs. Let's try re-implementing the RQ package, Julia style.

```julia
using Redis

conn = RedisConnection() # requires running Redis server

id = 123
set(conn, 123, println(\"hello\"))

# On the second Julia REPL
using Redis

conn = RedisConnection()

f = get(conn, 123) # typeof(f) == String
r = @spawnat eval(Meta.parse(f))
```

Cool! With a few lines of code we have the makings of a job queue. (Okay—so we have some issues to work out in terms of code availability, but I'm sure we can figure it out 😅).
"

# ╔═╡ 64393438-236c-4d8e-b451-3ef7ad9232d4
md"
## Example: Event Loop

In this example, we'll create a simple \"server\" that handles requests. The server will be implemented as an event loop that continuously checks for requests in the form of messages passed via a `Channel`. When the server receives a request, it executes the request *asynchronous*, i.e., as a `Task`, and continues to check for new requests.

```julia
using Dates

struct Request
    id
    duration
    message
end

function (req::Request)()
    start = now()
    println(\"[$start] Starting request $(req.id) (duration=$(req.duration)).\")
    sleep(req.duration)
    finish = now()
    dt = finish - start
    println(\"[$finish] From request $(req.id): $(req.message) (elapsed=$(dt.value / 1000)).\")
end

function generate_requests(max_requests)
    n = 0
    while n < max_requests
        waittime = rand()
        sleep(waittime)
        req = Request(rand(1:128), 5.0 * rand(), \"Hello!\")
        put!(chnl, req)
        n += 1
    end
end

chnl = Channel{Request}(128)
Threads.@spawn generate_requests(6)
while true
    req = take!(chnl)
    @async req()
end
```
"

# ╔═╡ 1fca9173-e103-48fd-b6e6-347d76b9b02a
md"
## Packages
In addition to the built-in support, there are a number of popular and useful community packages. Here are a few you may find useful:
- Dagger.jl
- CUDA.jl
- Metal.jl
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
# ╟─e78020dd-98b8-47bc-b490-1af6e6d3eca2
# ╟─a8035b94-c67a-406a-a6bb-034c623be293
# ╠═b9260d61-f6d3-47d9-862f-be29837d58a2
# ╟─862000c0-9537-4a81-a770-9494b45de6fd
# ╠═eda0d634-d8b5-439d-bae9-132674bf0db5
# ╟─c452ccb7-ea6d-4ca5-b2d0-a2006e37f294
# ╟─b367b347-b460-4960-b0a6-3b0013999ad3
# ╠═1d38bfaa-2b31-44d0-b5c4-2bd7ce286cdf
# ╠═083d8c4f-ffed-4558-bf18-a936f655ea26
# ╟─4a5c644d-6e42-46b7-8131-f5f242223501
# ╟─44c0d57d-84fe-4726-95ba-64eef33b637f
# ╟─0ee1708c-14d8-4fbb-bcc2-b8ae8c506aa6
# ╠═033b8878-e736-4b40-bab1-26cac659754d
# ╟─6d52b0f1-61e3-4b1b-b778-8eb693949333
# ╟─6dec68fe-1e42-4742-bd12-5df6db752eda
# ╠═c275f17c-f725-4d18-8946-10a4acd5b2e7
# ╟─61d5baf2-7257-4b35-81ef-fa6c15a6cf09
# ╟─fe5b5269-19fe-44ad-b8e4-095a77666cbf
# ╠═59dc3e16-3743-4d90-bcc6-9ff85071611b
# ╟─ab962e49-b52b-409f-b072-b25b2e31989e
# ╠═f9d68ac9-bbeb-4bc8-8fe7-fb4913f57ed5
# ╟─c8c71e29-a825-4413-99b6-2fce7adf1b30
# ╠═bebc3ac9-993c-4df6-8175-286c1d9461ac
# ╟─f22e4bd2-f1a7-4f72-be3c-3d607ce71da5
# ╠═b4cfc8e6-12ae-4506-9e05-3dd962034b47
# ╟─4d832cf5-e3a7-4d93-ab19-f48fa01a56a0
# ╠═889aad56-dc95-403c-b84b-604af9538929
# ╟─6895a47f-4cbc-456f-a488-df4ee8f64db2
# ╠═186c484b-264a-423a-ac74-068f8369c501
# ╟─0bd51569-ac87-469a-911f-3803e972a080
# ╠═b79ae203-7665-41f4-856f-b4cf8c5dfc03
# ╠═135252dd-bf84-4a80-915a-a42c142839b9
# ╠═16fed2f2-8583-4cbc-92ab-87e119044b71
# ╟─e0e7ce1d-471f-453e-9acd-968374b41fff
# ╠═ab94f65f-46db-4ca7-a7fc-5d9108cf63cd
# ╠═6653f45d-637e-4268-9eb2-5b8804cdf034
# ╟─0d9ebff1-56a7-4988-9e42-62cf620c4646
# ╟─f2c94c73-4851-4198-8091-6bd9c48622c6
# ╟─af7c5f6a-0998-4230-98e4-1127df5ca347
# ╟─027ba1a0-92c1-420e-884e-e6de93c10da6
# ╠═086d27a2-eb2f-463f-98fa-9fd7d12f0b42
# ╟─e7cd09c8-13d1-4132-bd5f-a163a8448679
# ╠═4bc255fe-8e43-4f24-9f81-b4427b6ab152
# ╟─4f8f921c-be5b-4566-82f4-3a6fdf9246fa
# ╠═788563fb-50c4-48ea-bcb0-896566669a90
# ╟─43e53a95-b765-482a-b8fe-964a94814e46
# ╟─bd902a37-abf7-4d1d-9728-f8d6b2592994
# ╟─d8034844-511c-4f73-9a6d-fe88675ea112
# ╠═c2eed6d1-75a1-47d0-8a14-8166c6b4efc2
# ╟─3d0c8d8b-5f5a-46a9-a088-a94b2ceffa79
# ╠═e6fb0d4d-184a-4541-bf65-fb42303f22c1
# ╠═a2f37831-b28e-4602-9d62-9bcbd3bf97af
# ╟─315c5882-f7eb-47e8-a029-006f936c292f
# ╟─380acb60-4c61-4b48-ac9d-4627d506ef89
# ╟─64393438-236c-4d8e-b451-3ef7ad9232d4
# ╟─1fca9173-e103-48fd-b6e6-347d76b9b02a
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
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
